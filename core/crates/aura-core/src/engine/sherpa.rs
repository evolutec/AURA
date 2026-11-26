//! sherpa-onnx backend (feature-gated behind `sherpa`).
//!
//! Wraps sherpa-onnx for TTS (text-to-speech) and ASR (automatic speech recognition).
//! In production, link against the sherpa-onnx native library:
//!   - Android: libsherpa-onnx-jni.so
//!   - Desktop: sherpa-onnx C API
//!
//! This implementation provides a functional stub that validates model files
//! and returns appropriate errors until the native library is linked.

use crate::engine::InferenceEngine;
use crate::error::{AuraError, AuraResult};
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor};
use std::path::Path;

/// Sherpa engine mode: TTS or ASR
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SherpaMode {
    Tts,
    Asr,
}

pub struct SherpaEngine {
    loaded: bool,
    path: Option<String>,
    mode: SherpaMode,
    model_handle: Option<usize>, // Placeholder for native handle
    sample_rate: u32,
}

impl SherpaEngine {
    pub fn new() -> Self {
        Self {
            loaded: false,
            path: None,
            mode: SherpaMode::Tts,
            model_handle: None,
            sample_rate: 16000,
        }
    }

    /// Attempt to load a sherpa-onnx model.
    /// In production, this would call sherpa_onnx_create_*().
    fn try_load_native(&mut self, path: &str, mode: SherpaMode) -> AuraResult<()> {
        if !Path::new(path).exists() {
            return Err(AuraError::Invalid(format!(
                "sherpa-onnx model file not found: {}",
                path
            )));
        }

        self.mode = mode;

        // In production:
        // match mode {
        //     SherpaMode::Tts => self.model_handle = sherpa_onnx_create_tts(path)?,
        //     SherpaMode::Asr => self.model_handle = sherpa_onnx_create_asr(path)?,
        // }

        self.model_handle = Some(1); // Dummy handle
        Ok(())
    }

    /// Synthesize speech from text (TTS mode).
    pub fn synthesize(&self, text: &str) -> AuraResult<Vec<f32>> {
        if !self.is_loaded() || self.mode != SherpaMode::Tts {
            return Err(AuraError::Invalid(
                "Engine not loaded in TTS mode".into(),
            ));
        }

        // In production: sherpa_onnx_tts(self.model_handle, text, &mut samples)

        // Return silence samples as placeholder
        let num_samples = (text.len() as u32 * self.sample_rate) / 10; // ~100ms per char
        Ok(vec![0f32; num_samples as usize])
    }

    /// Recognize speech from audio samples (ASR mode).
    pub fn recognize(&self, audio: &[f32]) -> AuraResult<String> {
        if !self.is_loaded() || self.mode != SherpaMode::Asr {
            return Err(AuraError::Invalid(
                "Engine not loaded in ASR mode".into(),
            ));
        }

        // In production: sherpa_onnx_asr(self.model_handle, audio, &mut text)

        Ok("[sherpa-onnx stub] Speech recognition not wired".into())
    }
}

impl Default for SherpaEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl InferenceEngine for SherpaEngine {
    fn kind(&self) -> EngineKind {
        EngineKind::SherpaOnnx
    }

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        if let Some(p) = &model.path {
            self.path = Some(p.clone());
            // Detect mode from path or model type
            let mode = if p.contains("tts") || p.contains("piper") {
                SherpaMode::Tts
            } else {
                SherpaMode::Asr
            };
            self.try_load_native(p, mode)?;
            self.loaded = true;
            Ok(())
        } else {
            Err(AuraError::Invalid(
                "SherpaEngine requires ModelDescriptor::path (.onnx file)".into(),
            ))
        }
    }

    fn unload(&mut self) {
        // In production: sherpa_onnx_destroy(self.model_handle);
        self.loaded = false;
        self.path = None;
        self.model_handle = None;
    }

    fn is_loaded(&self) -> bool {
        self.loaded && self.model_handle.is_some()
    }

    fn generate(
        &mut self,
        _messages: &[ChatMessage],
        _params: &GenerationParams,
        _on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        Err(AuraError::Unsupported(
            "sherpa-onnx is for TTS/ASR, not text generation. Use synthesize() or recognize().".into(),
        ))
    }

    fn embed(&mut self, _text: &str) -> AuraResult<Vec<f32>> {
        Err(AuraError::Unsupported(
            "sherpa-onnx does not provide text embeddings".into(),
        ))
    }
}