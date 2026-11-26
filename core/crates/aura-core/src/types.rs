use serde::{Deserialize, Serialize};

/// Inference engine families supported by AURA.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum EngineKind {
    /// Built-in deterministic engine (no native deps) — used for tests / scaffolding.
    Mock,
    /// llama.cpp / ggml (GGUF models). Requires the `llama` feature + native lib.
    Llama,
    /// Google LiteRT-LM (Gemma / `.litertlm`).
    LiteRtLm,
    /// ONNX Runtime (`.onnx` models: embeddings, vision, audio, etc.).
    Onnx,
    /// sherpa-onnx (TTS / ASR).
    SherpaOnnx,
    /// Whisper (speech-to-text).
    Whisper,
    /// MiniCPM-V and similar vision-language models.
    MiniCpmV,
    /// Diffusion image generation (Flux / SD / Nano Banana-like).
    Diffusion,
}

impl EngineKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            EngineKind::Mock => "mock",
            EngineKind::Llama => "llama",
            EngineKind::LiteRtLm => "litertlm",
            EngineKind::Onnx => "onnx",
            EngineKind::SherpaOnnx => "sherpa-onnx",
            EngineKind::Whisper => "whisper",
            EngineKind::MiniCpmV => "minicpm-v",
            EngineKind::Diffusion => "diffusion",
        }
    }
}

/// Modalities a model can handle.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Modality {
    Text,
    Vision,
    Audio,
    Embedding,
    Image,
}

/// Hardware acceleration backends.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Backend {
    Cpu,
    OpenCl,
    Vulkan,
    Metal,
    Cuda,
    DirectMl,
    Nnapi,
    Qnn,
    CoreMl,
    Rocm,
}

/// A model descriptor in the catalog.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelDescriptor {
    pub id: String,
    pub name: String,
    pub family: String,
    pub kind: EngineKind,
    pub modalities: Vec<Modality>,
    /// Parameter count in billions (0.0 if not applicable, e.g. embeddings).
    pub params_b: f32,
    pub quant: String,
    pub size_mb: u32,
    /// Approximate RAM required to run the model.
    pub ram_required_mb: u32,
    pub license: String,
    pub source: String,
    /// Optional local file path (GGUF / ONNX / LiteRT). Used by the llama backend.
    #[serde(default)]
    pub path: Option<String>,
    /// Optional direct download URL (e.g. HuggingFace GGUF) for the catalog.
    #[serde(default)]
    pub download_url: Option<String>,
    /// Optional mmproj (vision projector) download URL for multimodal models.
    #[serde(default)]
    pub mmproj_url: Option<String>,
}

impl ModelDescriptor {
    pub fn supports_all(&self, required: &[Modality]) -> bool {
        required
            .iter()
            .all(|r| self.modalities.iter().any(|m| m == r))
    }
}

/// A detected GPU / dedicated accelerator.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuInfo {
    /// Marketing / device name (e.g. "NVIDIA GeForce RTX 4070").
    pub name: String,
    /// Normalised vendor: "NVIDIA", "AMD", "Intel" or "Other".
    pub vendor: String,
    /// Dedicated video memory in MB (best-effort; may be capped on some drivers).
    pub vram_mb: u64,
    /// The llama.cpp runtime best suited for this vendor.
    pub recommended_backend: Backend,
}

/// Detected hardware capabilities.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HardwareCaps {
    pub os: String,
    pub arch: String,
    pub cpu_name: String,
    pub cores: usize,
    pub total_ram_mb: u64,
    pub available_ram_mb: u64,
    pub backends: Vec<Backend>,
    pub npu: Option<String>,
    /// Primary GPU, when one can be detected.
    pub gpu: Option<GpuInfo>,
}

/// Chat role.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Role {
    System,
    User,
    Assistant,
    Tool,
}

/// A single chat message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: Role,
    pub content: String,
}

/// Generation parameters (sampling).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerationParams {
    pub temperature: f32,
    pub top_p: f32,
    pub top_k: u32,
    pub max_tokens: u32,
    pub repeat_penalty: f32,
    pub seed: u64,
}

impl Default for GenerationParams {
    fn default() -> Self {
        Self {
            temperature: 0.7,
            top_p: 0.95,
            top_k: 40,
            max_tokens: 512,
            repeat_penalty: 1.1,
            seed: 0,
        }
    }
}
