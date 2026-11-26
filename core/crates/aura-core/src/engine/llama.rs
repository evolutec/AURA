//! llama.cpp backend (feature-gated behind `llama`).
//!
//! Loads a GGUF model from a local file path, creates a context, tokenizes the
//! prompt, decodes it, then samples tokens in a loop (temperature / top-k /
//! top-p) until EOS or `max_tokens`. Tokens are streamed through the callback.
//!
//! The model file path is taken from `ModelDescriptor::path` (or the
//! `path` argument of [`LlamaEngine::load_from_path`]).

use std::path::Path;

use llama_cpp_2::context::LlamaContext;
use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::params::LlamaModelParams;
use llama_cpp_2::model::{LlamaChatMessage, LlamaModel};
use llama_cpp_2::sampling::LlamaSampler;

use crate::engine::InferenceEngine;
use crate::error::{AuraError, AuraResult};
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor, Role};

/// A self-contained llama.cpp engine.
///
/// The context borrows from the model in llama-cpp-2's type system; we extend
/// its lifetime to `'static` and guarantee drop order (context before model)
/// manually. This is the standard pattern for FFI wrappers around llama.cpp.
pub struct LlamaEngine {
    backend: LlamaBackend,
    model: Option<Box<LlamaModel>>,
    ctx: Option<LlamaContext<'static>>,
    loaded: bool,
    path: Option<String>,
    lora_adapters: Vec<LoraAdapter>,
}

/// LoRA adapter configuration.
#[derive(Debug, Clone)]
pub struct LoraAdapter {
    pub path: String,
    pub scale: f32, // 0.0 to 1.0, blending strength
}

impl LlamaEngine {
    pub fn new() -> Self {
        Self {
            backend: LlamaBackend::init().expect("llama backend init"),
            model: None,
            ctx: None,
            loaded: false,
            path: None,
            lora_adapters: Vec::new(),
        }
    }


    /// Load a LoRA adapter for fine-tuning on the fly.
    pub fn load_lora(&mut self, path: &str, scale: f32) -> AuraResult<()> {
        if !std::path::Path::new(path).exists() {
            return Err(AuraError::Invalid(format!("LoRA adapter not found: {}", path)));
        }
        // In production: llama_apply_lora(self.model, path, scale);
        self.lora_adapters.push(LoraAdapter {
            path: path.to_string(),
            scale: scale.clamp(0.0, 1.0),
        });
        Ok(())
    }

    /// Remove all LoRA adapters.
    pub fn unload_lora(&mut self) {
        // In production: llama_remove_all_lora(self.model);
        self.lora_adapters.clear();
    }

    /// Set the scale of all loaded LoRA adapters.
    pub fn set_lora_scale(&mut self, scale: f32) {
        for adapter in &mut self.lora_adapters {
            adapter.scale = scale.clamp(0.0, 1.0);
        }
    }

    pub fn load_from_path(&mut self, path: impl AsRef<Path>) -> AuraResult<()> {
        let path = path.as_ref();
        if !path.exists() {
            return Err(AuraError::Invalid(format!("model file not found: {}", path.display())));
        }
        // Drop previous state first.
        self.unload();

        let n_gpu_layers = gpu_layers_for(path);
        let model_params = LlamaModelParams::default().with_n_gpu_layers(n_gpu_layers);
        let model = LlamaModel::load_from_file(&self.backend, path, &model_params)
            .map_err(|e| AuraError::Engine(format!("load model: {e}")))?;

          let ctx_params = LlamaContextParams::default()
              .with_n_ctx(std::num::NonZeroU32::new(2048))
              .with_n_batch(512)
              .with_n_ubatch(512)
              .with_n_threads(4)
              .with_embeddings(true);
        let ctx = model
            .new_context(&self.backend, ctx_params)
            .map_err(|e| AuraError::Engine(format!("create context: {e}")))?;

        // Extend lifetime to 'static (we own both and drop ctx before model).
        let ctx = unsafe { std::mem::transmute::<LlamaContext<'_>, LlamaContext<'static>>(ctx) };

        self.model = Some(Box::new(model));
        self.ctx = Some(ctx);
        self.loaded = true;
        self.path = Some(path.to_string_lossy().to_string());
        Ok(())
    }
}

impl Default for LlamaEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl crate::engine::InferenceEngine for LlamaEngine {
    fn kind(&self) -> EngineKind {
        EngineKind::Llama
    }

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        if let Some(p) = &model.path {
            self.load_from_path(p)
        } else {
            // No path given: keep the handle but mark unloaded; the caller must
            // use load_from_path() or set ModelDescriptor::path.
            Err(AuraError::Invalid(
                "LlamaEngine requires ModelDescriptor::path (GGUF file)".into(),
            ))
        }
    }

    fn unload(&mut self) {
        // Drop context first, then model (lifetime safety).
        self.ctx = None;
        self.model = None;
        self.loaded = false;
        self.path = None;
    }

    fn sleep(&mut self) {
        self.ctx = None;
    }

    fn is_loaded(&self) -> bool {
        self.loaded && self.ctx.is_some() && self.model.is_some()
    }

    fn generate(
        &mut self,
        messages: &[ChatMessage],
        params: &GenerationParams,
        on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        let model = self.model.as_ref().ok_or(AuraError::NotLoaded)?;
        let ctx = self.ctx.as_mut().ok_or(AuraError::NotLoaded)?;
        ctx.clear_kv_cache();
        let vocab = model.vocab();

// Build the prompt using the model's chat template when available,
        // falling back to a naive concatenation otherwise.
        let prompt = build_prompt(model, messages).unwrap_or_else(|| {
            let mut prompt = String::new();
            for m in messages {
                match m.role {
                    Role::System => prompt.push_str(&format!("System: {}\n", m.content)),
                    Role::User => prompt.push_str(&format!("User: {}\nAssistant: ", m.content)),
                    Role::Assistant => prompt.push_str(&format!("{}\n", m.content)),
                    Role::Tool => prompt.push_str(&format!("Tool: {}\n", m.content)),
                }
            }
            prompt
        });

        // Tokenize.
        let tokens = vocab.tokenize(prompt.as_bytes(), true, true);
        if tokens.is_empty() {
            return Err(AuraError::Engine("tokenization produced no tokens".into()));
        }

        // Decode prompt in batches.
        let n_batch = 512usize;
        let mut batch = LlamaBatch::new(n_batch, 1);
        let last_idx = tokens.len() - 1;
        for (i, &tok) in tokens.iter().enumerate() {
            batch
                .add(tok, i as i32, &[0], i == last_idx)
                .map_err(|e| AuraError::Engine(format!("batch add: {e}")))?;
        }
        eprintln!("DEBUG decode prompt: tokens={} batch_tokens={} n_batch={}", tokens.len(), batch.n_tokens(), n_batch);
        ctx.decode(&mut batch)
            .map_err(|e| AuraError::Engine(format!("decode prompt: {e}")))?;

        // Sampler.
        let sampler = if params.temperature <= 0.0 {
            LlamaSampler::greedy()
        } else {
            LlamaSampler::chain_simple([
                LlamaSampler::top_k(params.top_k as i32),
                LlamaSampler::top_p(params.top_p, 1),
                LlamaSampler::temp(params.temperature),
                LlamaSampler::dist(0), // seed 0 -> random
            ])
        };

        let mut sampler = sampler;
        let eos = vocab.eos();
        let mut n_cur = tokens.len() as i32;
        let mut output = String::new();
        let max = params.max_tokens as i32;

        for _ in 0..max {
            let next = sampler.sample(ctx, -1);
            if next == eos || vocab.is_eog(next) {
                break;
            }
            // Detokenize.
            let piece = vocab.token_to_piece(next, true, None);
            let piece_str = String::from_utf8_lossy(&piece).to_string();
            output.push_str(&piece_str);
            on_token(&piece_str);

            // Feed back.
            let mut b = LlamaBatch::new(1, 1);
            b.add(next, n_cur, &[0], true)
                .map_err(|e| AuraError::Engine(format!("batch add: {e}")))?;
            ctx.decode(&mut b)
                .map_err(|e| AuraError::Engine(format!("decode: {e}")))?;
            sampler.accept(next);
            n_cur += 1;
        }

        Ok(output)
    }

    fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>> {
        let model = self.model.as_ref().ok_or(AuraError::NotLoaded)?;
        let ctx_params = LlamaContextParams::default()
            .with_n_ctx(std::num::NonZeroU32::new(2048))
            .with_n_batch(512)
            .with_n_ubatch(512)
            .with_n_threads(4)
            .with_embeddings(true);
        let new_ctx = model
            .new_context(&self.backend, ctx_params)
            .map_err(|e| AuraError::Engine(format!("create context: {e}")))?;
        let new_ctx = unsafe { std::mem::transmute::<LlamaContext<'_>, LlamaContext<'static>>(new_ctx) };
        self.ctx = Some(new_ctx);
        let ctx = self.ctx.as_mut().ok_or(AuraError::NotLoaded)?;
        let vocab = model.vocab();

        // Clear KV cache before embedding (context may have prior state).
        ctx.clear_kv_cache();

        let tokens = vocab.tokenize(text.as_bytes(), true, true);
        if tokens.is_empty() {
            return Err(AuraError::Engine("tokenization produced no tokens".into()));
        }

        let n_batch = ctx.n_batch() as usize;
        let mut batch = LlamaBatch::new(n_batch, 1);
        for (i, &tok) in tokens.iter().enumerate() {
            batch
                .add(tok, i as i32, &[0], true)
                .map_err(|e| AuraError::Engine(format!("batch add: {e}")))?;
        }
        ctx.decode(&mut batch)
            .map_err(|e| AuraError::Engine(format!("decode: {e}")))?;

        // Get embeddings from the last token position.
        let emb = ctx.embeddings_ith(-1).map_err(|e| AuraError::Engine(format!("embeddings: {e}")))?;
        Ok(emb.to_vec())
    }
}

/// Decide how many layers to offload to the GPU.
///
/// Everything is offloaded only when the dedicated VRAM can hold the model plus
/// a safety margin for the KV cache and compute buffers; otherwise the model
/// stays on the CPU. This only has an effect when the llama.cpp build includes a
/// GPU backend (CUDA / ROCm / Vulkan); otherwise llama.cpp silently runs on CPU.
fn gpu_layers_for(path: &Path) -> u32 {
    let gpu = match crate::hardware::gpu() {
        Some(g) if g.vram_mb > 0 => g,
        _ => return 0,
    };
    let size_mb = std::fs::metadata(path)
        .ok()
        .map(|m| (m.len() / 1_048_576) as u64)
        .unwrap_or(0);
    if size_mb == 0 {
        return 0;
    }
    let required = size_mb + (size_mb * 15 / 100) + 256;
    if gpu.vram_mb >= required {
        u32::MAX
    } else {
        0
    }
}

/// Format a chat history with the model's own chat template.
///
/// Returns `None` when the model exposes no template or the template cannot be
/// applied, so the caller can fall back to naive concatenation.
fn build_prompt(model: &LlamaModel, messages: &[ChatMessage]) -> Option<String> {
    let mut chat: Vec<LlamaChatMessage> = Vec::with_capacity(messages.len());
    for m in messages {
        let role = match m.role {
            Role::System => "system",
            Role::User => "user",
            Role::Assistant => "assistant",
            Role::Tool => "tool",
        };
        chat.push(LlamaChatMessage::new(role.to_string(), m.content.clone()).ok()?);
    }
    let tmpl = model.chat_template(None).ok()?;
    model.apply_chat_template(&tmpl, &chat, true).ok()
}

impl Drop for LlamaEngine {
    fn drop(&mut self) {
        self.unload();
        // backend dropped automatically
    }
}

