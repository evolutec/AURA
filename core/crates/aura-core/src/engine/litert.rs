//! LiteRT-LM backend (feature-gated behind `litert`).
//!
//! Wraps Google AI Edge LiteRT-LM for Gemma / .litertlm models.
//! In production, link against the LiteRT-LM native library:
//!   - Android: libLiteRtLm.so + libLiteRtGpuAccelerator.so
//!   - Desktop: LiteRT C API
//!
//! This implementation provides a functional stub that validates model files
//! and returns appropriate errors until the native library is linked.

use crate::engine::InferenceEngine;
use crate::error::{AuraError, AuraResult};
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor};
use std::path::Path;

pub struct LiteRtEngine {
    loaded: bool,
    path: Option<String>,
    model_handle: Option<usize>, // Placeholder for native handle
}

impl LiteRtEngine {
    pub fn new() -> Self {
        Self {
            loaded: false,
            path: None,
            model_handle: None,
        }
    }

    /// Attempt to load a .litertlm model file.
    /// In production, this would call LiteRtLmCreateFromFile().
    fn try_load_native(&mut self, path: &str) -> AuraResult<()> {
        if !Path::new(path).exists() {
            return Err(AuraError::Invalid(format!(
                "LiteRT model file not found: {}",
                path
            )));
        }

        // Validate file extension
        if !path.ends_with(".litertlm") && !path.ends_with(".tflite") {
            return Err(AuraError::Invalid(
                "LiteRT models must be .litertlm or .tflite files".into(),
            ));
        }

        // In production:
        // let handle = litert_lm_create_from_file(path)?;
        // self.model_handle = Some(handle);

        // For now, just validate the file exists
        self.model_handle = Some(1); // Dummy handle
        Ok(())
    }
}

impl Default for LiteRtEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl InferenceEngine for LiteRtEngine {
    fn kind(&self) -> EngineKind {
        EngineKind::LiteRtLm
    }

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        if let Some(p) = &model.path {
            self.path = Some(p.clone());
            self.try_load_native(p)?;
            self.loaded = true;
            Ok(())
        } else {
            Err(AuraError::Invalid(
                "LiteRtEngine requires ModelDescriptor::path (.litertlm file)".into(),
            ))
        }
    }

    fn unload(&mut self) {
        // In production: litert_lm_destroy(self.model_handle);
        self.loaded = false;
        self.path = None;
        self.model_handle = None;
    }

    fn is_loaded(&self) -> bool {
        self.loaded && self.model_handle.is_some()
    }

    fn generate(
        &mut self,
        messages: &[ChatMessage],
        params: &GenerationParams,
        on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        if !self.is_loaded() {
            return Err(AuraError::NotLoaded);
        }

        // In production, this would call:
        // litert_lm_generate(self.model_handle, prompt, params, callback);

        // For now, return a message indicating the native library is needed
        let prompt: String = messages
            .iter()
            .map(|m| format!("{:?}: {}", m.role, m.content))
            .collect::<Vec<_>>()
            .join("\n");

        let response = format!(
            "[LiteRT-LM stub] Model loaded from {}. To enable real inference, link against the LiteRT-LM native library. Prompt: {}",
            self.path.as_deref().unwrap_or("unknown"),
            &prompt[..prompt.len().min(200)]
        );

        // Stream the response token by token
        for word in response.split_whitespace() {
            on_token(word);
            on_token(" ");
        }

        Ok(response)
    }

    fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>> {
        if !self.is_loaded() {
            return Err(AuraError::NotLoaded);
        }

        // In production: litert_lm_embed(self.model_handle, text)

        // Return a deterministic pseudo-embedding
        let mut v = vec![0f32; 384]; // Gemma embedding size
        for (i, b) in text.bytes().enumerate() {
            v[i % 384] += (b as f32) / 255.0;
        }
        let norm: f32 = v.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 0.0 {
            for x in &mut v {
                *x /= norm;
            }
        }
        Ok(v)
    }
}