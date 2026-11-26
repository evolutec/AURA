use std::sync::{Mutex, OnceLock};
use sysinfo::System;

/// Realtime RAM monitor. Keeps a single `System` handle and refreshes memory
/// on demand. Used by the engine selector to avoid loading models that would
/// not fit (and to prevent loading several heavy engines at once).
pub struct RamMonitor {
    sys: Mutex<Option<System>>,
}

impl RamMonitor {
    pub fn new() -> Self {
        RamMonitor { sys: Mutex::new(System::new_all().ok()) }
    }

    /// Returns `(total_mb, available_mb)`.
    pub fn sample(&self) -> (u64, u64) {
        let mut guard = self.sys.lock().expect("ram monitor lock poisoned");
        if guard.is_none() {
            *guard = System::new_all().ok();
        }
        match guard.as_mut() {
            Some(sys) => {
                sys.refresh_memory();
                (sys.total_memory() / 1_048_576, sys.available_memory() / 1_048_576)
            }
            None => (0, 0),
        }
    }

    pub fn available_mb(&self) -> u64 {
        self.sample().1
    }

    /// Whether `required_mb` fits with `headroom_mb` kept free.
    /// If RAM cannot be measured (0), we do not block (best-effort).
    pub fn can_fit(&self, required_mb: u32, headroom_mb: u64) -> bool {
        let (_total, avail) = self.sample();
        if avail == 0 {
            return true;
        }
        avail >= required_mb as u64 + headroom_mb
    }
}

impl Default for RamMonitor {
    fn default() -> Self {
        Self::new()
    }
}

/// Global process-wide RAM monitor.
pub fn global() -> &'static RamMonitor {
    static GLOBAL: OnceLock<RamMonitor> = OnceLock::new();
    GLOBAL.get_or_init(RamMonitor::new)
}
