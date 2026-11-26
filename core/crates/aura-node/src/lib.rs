//! Node.js / Electron binding for the AURA portable core (N-API).
//!
//! Lets a JavaScript frontend consume the native core directly:
//! ```js
//! const aura = require('./aura-node')
//! console.log(aura.detectHardware())
//! const engine = aura.AuraEngine.create('aura-mock-1b')
//! console.log(engine.generate('Bonjour AURA'))
//! ```
//!
//! After `cargo build -p aura-node`, copy the produced `aura_node.dll`
//! (Windows) / `libaura_node.so` (Linux) / `libaura_node.dylib` (macOS) to
//! `aura_node.node` next to your JS entry, or use `@napi-rs/cli`.

use napi::bindgen_prelude::*;
use napi_derive::napi;

use aura_core::engine::selector::EngineManager;
use aura_core::hardware;
use aura_core::model::ModelRegistry;
use aura_core::types::{ChatMessage, GenerationParams, Role};

#[napi]
pub fn version() -> String {
    aura_core::VERSION.to_string()
}

#[napi]
pub fn detect_hardware() -> Result<String> {
    let hw = hardware::detect();
    serde_json::to_string(&hw).map_err(|e| Error::from_reason(e.to_string()))
}

#[napi]
pub fn catalog() -> Result<String> {
    let reg = ModelRegistry::with_builtin_catalog();
    serde_json::to_string(reg.all()).map_err(|e| Error::from_reason(e.to_string()))
}

#[napi]
pub struct AuraEngine {
    mgr: EngineManager,
}

#[napi]
impl AuraEngine {
    /// Create (and load) an engine for a catalog model id.
    #[napi(factory)]
    pub fn create(model_id: String) -> Result<Self> {
        let reg = ModelRegistry::with_builtin_catalog();
        let model = reg
            .get(&model_id)
            .cloned()
            .ok_or_else(|| Error::from_reason(format!("unknown model id: {model_id}")))?;
        let mut mgr = EngineManager::new();
        mgr.ensure_model(&model)
            .map_err(|e| Error::from_reason(e.to_string()))?;
        Ok(AuraEngine { mgr })
    }

    /// Non-streaming generation.
    #[napi]
    pub fn generate(&mut self, prompt: String) -> Result<String> {
        let msgs = vec![ChatMessage { role: Role::User, content: prompt }];
        let params = GenerationParams::default();
        let mut noop = |_t: &str| {};
        self.mgr
            .generate(&msgs, &params, &mut noop)
            .map_err(|e| Error::from_reason(e.to_string()))
    }

    /// Compute an embedding vector for the given text.
    #[napi]
    pub fn embed(&mut self, text: String) -> Result<Vec<f64>> {
        self.mgr
            .embed(&text)
            .map(|v| v.into_iter().map(|x| x as f64).collect())
            .map_err(|e| Error::from_reason(e.to_string()))
    }

    /// Unload the model to free RAM.
    #[napi]
    pub fn unload(&mut self) {
        self.mgr.unload();
    }
}
