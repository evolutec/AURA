use std::fmt;

/// Result alias for the AURA core.
pub type AuraResult<T> = Result<T, AuraError>;

/// Errors returned by the portable core.
#[derive(Debug, Clone)]
pub enum AuraError {
    /// The requested engine/backend is not implemented or not enabled in this build.
    Unsupported(String),
    /// Not enough free RAM to load the model (with headroom).
    OutOfMemory { required_mb: u32, available_mb: u64 },
    /// An engine operation requires a loaded model.
    NotLoaded,
    /// Invalid argument / input.
    Invalid(String),
    /// Generic engine failure.
    Engine(String),
}

impl fmt::Display for AuraError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AuraError::Unsupported(s) => write!(f, "unsupported: {s}"),
            AuraError::OutOfMemory { required_mb, available_mb } => write!(
                f,
                "out of memory: need {required_mb} MB, only {available_mb} MB available"
            ),
            AuraError::NotLoaded => write!(f, "no model loaded"),
            AuraError::Invalid(s) => write!(f, "invalid: {s}"),
            AuraError::Engine(s) => write!(f, "engine error: {s}"),
        }
    }
}

impl std::error::Error for AuraError {}
