//! Inference engine abstraction + registry.

pub mod mock;
pub mod selector;

#[cfg(feature = "llama")]
pub mod llama;

#[cfg(feature = "onnx")]
pub mod onnx;

#[cfg(feature = "litert")]
pub mod litert;

#[cfg(feature = "sherpa")]
pub mod sherpa;

#[cfg(feature = "rpc")]
pub mod rpc;

use crate::error::{AuraError, AuraResult};
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor};

/// A portable inference engine.
///
/// Implementations wrap native libraries (llama.cpp, ONNX Runtime, LiteRT-LM,
/// sherpa-onnx, ...) or the built-in mock. Streaming is done through the
/// `on_token` callback so the UI can render tokens as they arrive.
pub trait InferenceEngine: Send {
    fn kind(&self) -> EngineKind;

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()>;

    fn unload(&mut self);

    fn is_loaded(&self) -> bool;

    fn generate(
        &mut self,
        messages: &[ChatMessage],
        params: &GenerationParams,
        on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String>;

    fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>>;

    fn sleep(&mut self) {}
}

/// Create an engine for the given kind (feature-gated per backend).
pub fn create_engine(kind: EngineKind) -> AuraResult<Box<dyn InferenceEngine>> {
    match kind {
        EngineKind::Mock => Ok(Box::new(mock::MockEngine::new())),

        #[cfg(feature = "llama")]
        EngineKind::Llama => Ok(Box::new(llama::LlamaEngine::new())),

        #[cfg(feature = "onnx")]
        EngineKind::Onnx => Ok(Box::new(onnx::OnnxEngine::new())),

        #[cfg(feature = "onnx")]
        EngineKind::SherpaOnnx => Ok(Box::new(onnx::OnnxEngine::new())),

        #[cfg(feature = "litert")]
        EngineKind::LiteRtLm => Ok(Box::new(litert::LiteRtEngine::new())),

        #[cfg(feature = "sherpa")]
        EngineKind::Whisper => Ok(Box::new(sherpa::SherpaEngine::new())),

        #[cfg(not(feature = "llama"))]
        EngineKind::Llama => Err(AuraError::Unsupported(
            "llama engine not enabled in this build (enable feature `llama`)".into(),
        )),

        #[cfg(not(feature = "onnx"))]
        EngineKind::Onnx => Err(AuraError::Unsupported(
            "onnx engine not enabled in this build (enable feature `onnx`)".into(),
        )),

        #[cfg(not(feature = "onnx"))]
        EngineKind::SherpaOnnx => Err(AuraError::Unsupported(
            "onnx engine not enabled in this build (enable feature `onnx`)".into(),
        )),

        #[cfg(not(feature = "litert"))]
        EngineKind::LiteRtLm => Err(AuraError::Unsupported(
            "litert engine not enabled in this build (enable feature `litert`)".into(),
        )),

        #[cfg(not(feature = "sherpa"))]
        EngineKind::Whisper => Err(AuraError::Unsupported(
            "sherpa engine not enabled in this build (enable feature `sherpa`)".into(),
        )),

        other => Err(AuraError::Unsupported(format!(
            "engine '{}' not implemented yet",
            other.as_str()
        ))),
    }
}