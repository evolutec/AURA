//! AURA portable native core.
//!
//! This crate is UI-agnostic and designed to be consumed by any frontend:
//! - Flutter / Kotlin Multiplatform / Tauri via the stable **C ABI** (`ffi` module).
//! - Node.js / Electron via the `aura-node` N-API binding.
//!
//! It provides:
//! - hardware capability detection ([`hardware`])
//! - a model registry / catalog filtered by specs ([`model`])
//! - an engine abstraction + RAM-aware selection ([`engine`])
//! - a realtime RAM monitor ([`ram`])
//! - a chat session manager ([`session`])
//! - a stable C ABI ([`ffi`])

pub mod error;
pub mod types;
pub mod hardware;
pub mod ram;
pub mod model;
pub mod engine;
pub mod session;
pub mod ffi;

/// Core version string.
pub const VERSION: &str = "0.1.0";
