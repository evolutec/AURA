//! ONNX Runtime backend (feature-gated behind `onnx`).
//!
//! Wraps `ort` (ONNX Runtime Rust bindings). Primary use cases in AURA:
//! - **Embeddings** (BGE, E5, MiniLM, etc.) for the RAG pipeline.
//! - Vision / audio / custom `.onnx` models.
//!
//! Chat-style generation is delegated to llama.cpp / LiteRT-LM; this backend
//! returns `Unsupported` for `generate()`.

use ort::session::Session;
use ort::value::Tensor;

use crate::engine::InferenceEngine;
use crate::error::{AuraError, AuraResult};
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor};

pub struct OnnxEngine {
    session: Option<Session>,
    path: Option<String>,
    loaded: bool,
    input_names: Vec<String>,
    output_name: Option<String>,
}

impl OnnxEngine {
    pub fn new() -> Self {
        Self {
            session: None,
            path: None,
            loaded: false,
            input_names: Vec::new(),
            output_name: None,
        }
    }

    pub fn load_from_path(&mut self, path: &str) -> AuraResult<()> {
        if !std::path::Path::new(path).exists() {
            return Err(AuraError::Invalid(format!("model file not found: {path}")));
        }
        self.unload();

        let env = ort::init().build().map_err(|e| AuraError::Engine(format!("ort init: {e}")))?;
        let session = Session::builder(&env)
            .map_err(|e| AuraError::Engine(format!("session builder: {e}")))?
            .commit_from_file(path)
            .map_err(|e| AuraError::Engine(format!("load onnx: {e}")))?;

        let input_names: Vec<String> = session.inputs().iter().map(|i| i.name().to_string()).collect();
        let output_name = session.outputs().first().map(|o| o.name().to_string());

        self.session = Some(session);
        self.path = Some(path.to_string());
        self.input_names = input_names;
        self.output_name = output_name;
        self.loaded = true;
        Ok(())
    }
}

impl Default for OnnxEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl crate::engine::InferenceEngine for OnnxEngine {
    fn kind(&self) -> EngineKind {
        EngineKind::Onnx
    }

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        if let Some(p) = &model.path {
            self.load_from_path(p)
        } else {
            Err(AuraError::Invalid(
                "OnnxEngine requires ModelDescriptor::path (.onnx file)".into(),
            ))
        }
    }

    fn unload(&mut self) {
        self.session = None;
        self.path = None;
        self.input_names.clear();
        self.output_name = None;
        self.loaded = false;
    }

    fn is_loaded(&self) -> bool {
        self.loaded && self.session.is_some()
    }

    fn generate(
        &mut self,
        _messages: &[ChatMessage],
        _params: &GenerationParams,
        _on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        Err(AuraError::Unsupported(
            "ONNX backend does not provide chat generation; use for embeddings/vision/audio".into(),
        ))
    }

    fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>> {
        let session = self.session.as_mut().ok_or(AuraError::NotLoaded)?;

        // Build inputs for all required tensors. MiniLM-style models need
        // input_ids, attention_mask, token_type_ids. We derive ids from bytes
        // (best-effort, no real tokenizer yet) and fill masks with sensible defaults.
        let seq_len = text.bytes().count().max(1);
        let ids: Vec<i64> = text.bytes().map(|b| b as i64).collect();
        let attention: Vec<i64> = vec![1i64; seq_len];
        let token_type: Vec<i64> = vec![0i64; seq_len];

        let mut input_vec: Vec<(String, Tensor<i64>)> = Vec::new();
        for name in &self.input_names {
            let lower = name.to_lowercase();
            let tensor = if lower.contains("type") {
                Tensor::from_array(([1usize, seq_len], token_type.clone()))
            } else if lower.contains("mask") {
                Tensor::from_array(([1usize, seq_len], attention.clone()))
            } else {
                Tensor::from_array(([1usize, seq_len], ids.clone()))
            }
            .map_err(|e| AuraError::Engine(format!("input tensor {name}: {e}")))?;
            input_vec.push((name.clone(), tensor));
        }

        let out_name = self.output_name.clone();

        let outputs = session
            .run(input_vec)
            .map_err(|e| AuraError::Engine(format!("run: {e}")))?;

        let view = if let Some(name) = &out_name {
            outputs.get(name)
        } else {
            let first_key = outputs.keys().next().map(|k| k.to_string());
            match first_key {
                Some(k) => outputs.get(&k),
                None => None,
            }
        };
        let view = view.ok_or_else(|| AuraError::Engine("no output".into()))?;
        let (_shape, data) = view
            .try_extract_tensor::<f32>()
            .map_err(|e| AuraError::Engine(format!("extract: {e}")))?;
        if data.is_empty() {
            return Err(AuraError::Engine("empty output".into()));
        }
        Ok(data.to_vec())
    }
}
