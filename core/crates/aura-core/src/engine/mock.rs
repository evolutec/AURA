use super::InferenceEngine;
use crate::error::AuraResult;
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor, Role};

/// Deterministic engine used to scaffold and test the full pipeline without any
/// native dependency. It echoes a summary of the conversation and produces
/// hashed embedding vectors. Replace with real backends in production.
pub struct MockEngine {
    loaded: bool,
    model_name: Option<String>,
}

impl MockEngine {
    pub fn new() -> Self {
        Self { loaded: false, model_name: None }
    }
}

impl Default for MockEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl InferenceEngine for MockEngine {
    fn kind(&self) -> EngineKind {
        EngineKind::Mock
    }

    fn load(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        self.loaded = true;
        self.model_name = Some(model.name.clone());
        Ok(())
    }

    fn unload(&mut self) {
        self.loaded = false;
        self.model_name = None;
    }

    fn is_loaded(&self) -> bool {
        self.loaded
    }

    fn generate(
        &mut self,
        messages: &[ChatMessage],
        _params: &GenerationParams,
        on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        let last_user = messages
            .iter()
            .rev()
            .find(|m| matches!(m.role, Role::User))
            .map(|m| m.content.clone())
            .unwrap_or_default();

        let reply = format!(
            "[AURA mock engine · modèle « {} »] Reçu {} message(s). Dernier message utilisateur : « {} ». \
             Ceci est un moteur factice — branche un vrai backend (llama.cpp / ONNX Runtime / LiteRT-LM) pour l'inférence réelle.",
            self.model_name.as_deref().unwrap_or("inconnu"),
            messages.len(),
            last_user
        );

        // Stream token-ish chunks (word + trailing space).
        for chunk in reply.split_inclusive(' ') {
            on_token(chunk);
        }
        Ok(reply)
    }

    fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>> {
        // Deterministic pseudo-embedding (32-dim), normalized.
        let mut v = vec![0f32; 32];
        for (i, b) in text.bytes().enumerate() {
            v[i % 32] += (b as f32) / 255.0;
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
