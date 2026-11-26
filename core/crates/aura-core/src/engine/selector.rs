use super::{create_engine, InferenceEngine};
use crate::error::{AuraError, AuraResult};
use crate::ram::global as ram_global;
use crate::types::{ChatMessage, GenerationParams, ModelDescriptor};

/// Default RAM kept free to avoid OOM / OS-killing the process.
pub const DEFAULT_HEADROOM_MB: u64 = 512;

/// Owns at most one loaded engine and manages model switching + RAM safety.
///
/// This is the heart of the "auto-select engine + never load two heavy engines"
/// rule: switching to another model unloads the current one first, and loading
/// is refused if the model does not fit in available RAM minus headroom.
pub struct EngineManager {
    engine: Option<Box<dyn InferenceEngine>>,
    model: Option<ModelDescriptor>,
    headroom_mb: u64,
}

impl EngineManager {
    pub fn new() -> Self {
        Self {
            engine: None,
            model: None,
            headroom_mb: DEFAULT_HEADROOM_MB,
        }
    }

    pub fn with_headroom(mut self, mb: u64) -> Self {
        self.headroom_mb = mb;
        self
    }

    pub fn current_model(&self) -> Option<&ModelDescriptor> {
        self.model.as_ref()
    }

    pub fn is_loaded(&self) -> bool {
        self.engine.as_ref().map(|e| e.is_loaded()).unwrap_or(false)
    }

    /// Ensure `model` is loaded, swapping engines if needed.
    pub fn ensure_model(&mut self, model: &ModelDescriptor) -> AuraResult<()> {
        // Already loaded and same model -> no-op.
        if let (Some(cur), true) = (self.model.as_ref(), self.is_loaded()) {
            if cur.id == model.id {
                return Ok(());
            }
        }

        // RAM guard.
        let ram = ram_global();
        if !ram.can_fit(model.ram_required_mb, self.headroom_mb) {
            let (_total, avail) = ram.sample();
            return Err(AuraError::OutOfMemory {
                required_mb: model.ram_required_mb,
                available_mb: avail,
            });
        }

        // Unload previous engine before creating a new one (single heavy engine).
        self.unload();

        let mut engine = create_engine(model.kind)?;
        engine.load(model)?;
        self.engine = Some(engine);
        self.model = Some(model.clone());
        Ok(())
    }

    pub fn generate(
        &mut self,
        messages: &[ChatMessage],
        params: &GenerationParams,
        on_token: &mut dyn FnMut(&str),
    ) -> AuraResult<String> {
        match &mut self.engine {
            Some(e) if e.is_loaded() => e.generate(messages, params, on_token),
            _ => Err(AuraError::NotLoaded),
        }
    }

    pub fn embed(&mut self, text: &str) -> AuraResult<Vec<f32>> {
        match &mut self.engine {
            Some(e) if e.is_loaded() => e.embed(text),
            _ => Err(AuraError::NotLoaded),
        }
    }

    pub fn unload(&mut self) {
        if let Some(e) = self.engine.as_mut() {
            e.unload();
        }
        self.engine = None;
        self.model = None;
    }

    pub fn sleep(&mut self) {
        if let Some(e) = self.engine.as_mut() {
            e.sleep();
        }
    }
}

impl Default for EngineManager {
    fn default() -> Self {
        Self::new()
    }
}
