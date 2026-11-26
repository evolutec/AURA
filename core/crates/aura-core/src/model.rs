use crate::types::{EngineKind, HardwareCaps, Modality, ModelDescriptor};

/// In-memory model catalog. The built-in catalog is a curated set of real,
/// downloadable GGUF chat models (HuggingFace); a remote/updatable catalog can
/// replace it later (same shape, JSON-serializable).
pub struct ModelRegistry {
    models: Vec<ModelDescriptor>,
}

#[allow(clippy::too_many_arguments)]
fn gguf(
    id: &str,
    name: &str,
    family: &str,
    params_b: f32,
    size_mb: u32,
    ram_required_mb: u32,
    license: &str,
    download_url: String,
) -> ModelDescriptor {
    ModelDescriptor {
        id: id.into(),
        name: name.into(),
        family: family.into(),
        kind: EngineKind::Llama,
        modalities: vec![Modality::Text],
        params_b,
        quant: "Q4_K_M".into(),
        size_mb,
        ram_required_mb,
        license: license.into(),
        source: "huggingface".into(),
        path: None,
        download_url: Some(download_url),
        mmproj_url: None,
    }
}

#[allow(clippy::too_many_arguments)]
fn vision(
    id: &str,
    name: &str,
    family: &str,
    params_b: f32,
    size_mb: u32,
    ram_required_mb: u32,
    license: &str,
    download_url: String,
    mmproj_url: String,
) -> ModelDescriptor {
    ModelDescriptor {
        id: id.into(),
        name: name.into(),
        family: family.into(),
        kind: EngineKind::Llama,
        modalities: vec![Modality::Text, Modality::Vision],
        params_b,
        quant: "Q4_K_M".into(),
        size_mb,
        ram_required_mb,
        license: license.into(),
        source: "huggingface".into(),
        path: None,
        download_url: Some(download_url),
        mmproj_url: Some(mmproj_url),
    }
}

impl ModelRegistry {
    pub fn new(models: Vec<ModelDescriptor>) -> Self {
        Self { models }
    }

    pub fn all(&self) -> &[ModelDescriptor] {
        &self.models
    }

    pub fn get(&self, id: &str) -> Option<&ModelDescriptor> {
        self.models.iter().find(|m| m.id == id)
    }

    /// Models compatible with the given hardware and required modalities,
    /// keeping `headroom_mb` free.
    pub fn compatible(
        &self,
        hw: &HardwareCaps,
        required_modalities: &[Modality],
        headroom_mb: u64,
    ) -> Vec<&ModelDescriptor> {
        let budget = hw.available_ram_mb.saturating_sub(headroom_mb);
        self.models
            .iter()
            .filter(|m| m.ram_required_mb as u64 <= budget)
            .filter(|m| m.supports_all(required_modalities))
            .collect()
    }

    /// Best model among compatible ones (largest params that still fits),
    /// optionally restricted to a modality.
    pub fn recommend(
        &self,
        hw: &HardwareCaps,
        modality: Modality,
        headroom_mb: u64,
    ) -> Option<&ModelDescriptor> {
        self.compatible(hw, &[modality], headroom_mb)
            .into_iter()
            .filter(|m| m.params_b > 0.0)
            .max_by(|a, b| a.params_b.partial_cmp(&b.params_b).unwrap_or(std::cmp::Ordering::Equal))
    }

    pub fn with_builtin_catalog() -> Self {
        let hf = |repo: &str, file: &str| {
            format!("https://huggingface.co/{repo}/resolve/main/{file}?download=true")
        };
        Self::new(vec![
            // ---- Tiny (< 2 GB RAM) ----
            gguf("qwen2.5-0.5b-q4", "Qwen2.5 0.5B Instruct (Q4_K_M)", "qwen", 0.5, 398, 900, "Apache-2.0",
                hf("Qwen/Qwen2.5-0.5B-Instruct-GGUF", "qwen2.5-0.5b-instruct-q4_k_m.gguf")),
            gguf("llama-3.2-1b-q4", "Llama 3.2 1B Instruct (Q4_K_M)", "llama", 1.2, 808, 1500, "Llama-3.2",
                hf("bartowski/Llama-3.2-1B-Instruct-GGUF", "Llama-3.2-1B-Instruct-Q4_K_M.gguf")),
            gguf("qwen2.5-1.5b-q4", "Qwen2.5 1.5B Instruct (Q4_K_M)", "qwen", 1.5, 1100, 1800, "Apache-2.0",
                hf("Qwen/Qwen2.5-1.5B-Instruct-GGUF", "qwen2.5-1.5b-instruct-q4_k_m.gguf")),
            gguf("deepseek-r1-1.5b-q4", "DeepSeek R1 Distill Qwen 1.5B (Q4_K_M)", "deepseek", 1.5, 1100, 1800, "MIT",
                hf("bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF", "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf")),
            gguf("qwen2.5-coder-1.5b-q4", "Qwen2.5 Coder 1.5B Instruct (Q4_K_M)", "qwen", 1.5, 1100, 1800, "Apache-2.0",
                hf("bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF", "Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf")),
            // ---- Small (2-4 GB RAM) ----
            gguf("llama-3.2-3b-q4", "Llama 3.2 3B Instruct (Q4_K_M)", "llama", 3.2, 2020, 3500, "Llama-3.2",
                hf("bartowski/Llama-3.2-3B-Instruct-GGUF", "Llama-3.2-3B-Instruct-Q4_K_M.gguf")),
            gguf("qwen2.5-3b-q4", "Qwen2.5 3B Instruct (Q4_K_M)", "qwen", 3.0, 2000, 3500, "Apache-2.0",
                hf("Qwen/Qwen2.5-3B-Instruct-GGUF", "qwen2.5-3b-instruct-q4_k_m.gguf")),
            gguf("phi-3.5-mini-q4", "Phi-3.5 mini Instruct (Q4_K_M)", "phi", 3.8, 2400, 4000, "MIT",
                hf("bartowski/Phi-3.5-mini-instruct-GGUF", "Phi-3.5-mini-instruct-Q4_K_M.gguf")),
            gguf("gemma-2-2b-q4", "Gemma 2 2B Instruct (Q4_K_M)", "gemma", 2.6, 1700, 3000, "Gemma",
                hf("bartowski/gemma-2-2b-it-GGUF", "gemma-2-2b-it-Q4_K_M.gguf")),
            gguf("deepseek-r1-7b-q4", "DeepSeek R1 Distill Qwen 7B (Q4_K_M)", "deepseek", 7.0, 4700, 6000, "MIT",
                hf("bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF", "DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf")),
            gguf("qwen2.5-coder-3b-q4", "Qwen2.5 Coder 3B Instruct (Q4_K_M)", "qwen", 3.0, 2000, 3500, "Apache-2.0",
                hf("Qwen/Qwen2.5-Coder-3B-Instruct-GGUF", "qwen2.5-coder-3b-instruct-q4_k_m.gguf")),
            // ---- Medium (5-10 GB RAM) ----
            gguf("qwen2.5-7b-q4", "Qwen2.5 7B Instruct (Q4_K_M)", "qwen", 7.0, 4700, 6000, "Apache-2.0",
                hf("bartowski/Qwen2.5-7B-Instruct-GGUF", "Qwen2.5-7B-Instruct-Q4_K_M.gguf")),
            gguf("llama-3.1-8b-q4", "Llama 3.1 8B Instruct (Q4_K_M)", "llama", 8.0, 4900, 6500, "Llama-3.1",
                hf("bartowski/Meta-Llama-3.1-8B-Instruct-GGUF", "Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf")),
            gguf("deepseek-r1-8b-q4", "DeepSeek R1 Distill Llama 8B (Q4_K_M)", "deepseek", 8.0, 4900, 6500, "MIT",
                hf("bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF", "DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf")),
            gguf("gemma-2-9b-q4", "Gemma 2 9B Instruct (Q4_K_M)", "gemma", 9.0, 5800, 7500, "Gemma",
                hf("bartowski/gemma-2-9b-it-GGUF", "gemma-2-9b-it-Q4_K_M.gguf")),
            gguf("mistral-7b-v0.3-q4", "Mistral 7B Instruct v0.3 (Q4_K_M)", "mistral", 7.0, 4400, 6000, "Apache-2.0",
                hf("bartowski/Mistral-7B-Instruct-v0.3-GGUF", "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf")),
            gguf("qwen2.5-coder-7b-q4", "Qwen2.5 Coder 7B Instruct (Q4_K_M)", "qwen", 7.0, 4700, 6000, "Apache-2.0",
                hf("bartowski/Qwen2.5-Coder-7B-Instruct-GGUF", "Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf")),
            // ---- Large (12-20 GB RAM) ----
            gguf("phi-4-14b-q4", "Phi-4 14B (Q4_K_M)", "phi", 14.0, 8800, 11000, "MIT",
                hf("bartowski/phi-4-GGUF", "phi-4-Q4_K_M.gguf")),
            gguf("qwen2.5-14b-q4", "Qwen2.5 14B Instruct (Q4_K_M)", "qwen", 14.0, 8800, 11000, "Apache-2.0",
                hf("Qwen/Qwen2.5-14B-Instruct-GGUF", "qwen2.5-14b-instruct-q4_k_m.gguf")),
            gguf("deepseek-r1-14b-q4", "DeepSeek R1 Distill Qwen 14B (Q4_K_M)", "deepseek", 14.0, 8800, 11000, "MIT",
                hf("bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF", "DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf")),
            gguf("gemma-2-27b-q4", "Gemma 2 27B Instruct (Q4_K_M)", "gemma", 27.0, 16500, 20000, "Gemma",
                hf("bartowski/gemma-2-27b-it-GGUF", "gemma-2-27b-it-Q4_K_M.gguf")),
            gguf("qwen2.5-coder-14b-q4", "Qwen2.5 Coder 14B Instruct (Q4_K_M)", "qwen", 14.0, 8800, 11000, "Apache-2.0",
                hf("bartowski/Qwen2.5-Coder-14B-Instruct-GGUF", "Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf")),
            // ---- XL (24-48 GB RAM) ----
            gguf("qwen2.5-32b-q4", "Qwen2.5 32B Instruct (Q4_K_M)", "qwen", 32.0, 19500, 24000, "Apache-2.0",
                hf("Qwen/Qwen2.5-32B-Instruct-GGUF", "qwen2.5-32b-instruct-q4_k_m.gguf")),
            gguf("deepseek-r1-32b-q4", "DeepSeek R1 Distill Qwen 32B (Q4_K_M)", "deepseek", 32.0, 19500, 24000, "MIT",
                hf("bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF", "DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf")),
            gguf("qwen2.5-coder-32b-q4", "Qwen2.5 Coder 32B Instruct (Q4_K_M)", "qwen", 32.0, 19500, 24000, "Apache-2.0",
                hf("bartowski/Qwen2.5-Coder-32B-Instruct-GGUF", "Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf")),
            // ---- XXL (48+ GB RAM) ----
            gguf("llama-3.1-70b-q4", "Llama 3.1 70B Instruct (Q4_K_M)", "llama", 70.0, 42500, 48000, "Llama-3.1",
                hf("bartowski/Meta-Llama-3.1-70B-Instruct-GGUF", "Meta-Llama-3.1-70B-Instruct-Q4_K_M.gguf")),
            gguf("qwen2.5-72b-q4", "Qwen2.5 72B Instruct (Q4_K_M)", "qwen", 72.0, 44000, 50000, "Apache-2.0",
                hf("Qwen/Qwen2.5-72B-Instruct-GGUF", "qwen2.5-72b-instruct-q4_k_m.gguf")),
            // ---- Vision (mmproj requis) ----
            vision("smolvlm-500m-q8", "SmolVLM 500M Instruct (vision)", "smolvlm", 0.5, 1200, 2000, "Apache-2.0",
                hf("ggml-org/SmolVLM-500M-Instruct-GGUF", "SmolVLM-500M-Instruct-Q8_0.gguf"),
                hf("ggml-org/SmolVLM-500M-Instruct-GGUF", "mmproj-SmolVLM-500M-Instruct-f16.gguf")),
            vision("qwen2-vl-2b-q4", "Qwen2-VL 2B Instruct (vision)", "qwen", 2.0, 1900, 3500, "Apache-2.0",
                hf("ggml-org/Qwen2-VL-2B-Instruct-GGUF", "qwen2-vl-2b-instruct-q4_k_m.gguf"),
                hf("ggml-org/Qwen2-VL-2B-Instruct-GGUF", "mmproj-qwen2-vl-2b-instruct-f16.gguf")),
        ])
    }
}