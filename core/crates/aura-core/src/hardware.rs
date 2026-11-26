use std::sync::OnceLock;

use crate::types::{Backend, GpuInfo, HardwareCaps};
use sysinfo::System;

/// Detect hardware capabilities and available acceleration backends.
///
/// This is a best-effort, cross-platform probe. NPU/GPU detection is refined by
/// the platform layer (JNI / platform channels) later and can be injected via
/// [`HardwareCaps`] overrides in a future revision.
pub fn detect() -> HardwareCaps {
    let os_default = std::env::consts::OS.to_string();
    let arch = std::env::consts::ARCH.to_string();

    let (total_ram_mb, available_ram_mb, cores, cpu_name, os) = match System::new_all() {
        Ok(mut sys) => {
            sys.refresh_memory();
            let total = sys.total_memory() / 1_048_576;
            let avail = sys.available_memory() / 1_048_576;
            let cores = sys.cpus().len();
            let cpu = sys
                .cpus()
                .first()
                .map(|c| c.brand().trim().to_string())
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| arch.clone());
            let os = System::name().unwrap_or_else(|_| os_default.clone());
            (total, avail, cores, cpu, os)
        }
        Err(_) => (0, 0, 0, arch.clone(), os_default.clone()),
    };

    let mut backends = vec![Backend::Cpu];
    match std::env::consts::OS {
        "android" => {
            backends.extend([Backend::Vulkan, Backend::OpenCl, Backend::Nnapi, Backend::Qnn]);
        }
        "ios" | "macos" => {
            backends.extend([Backend::Metal, Backend::CoreMl]);
        }
        "windows" => {
            backends.extend([Backend::DirectMl, Backend::Vulkan, Backend::Cuda, Backend::Rocm]);
        }
        "linux" => {
            backends.extend([Backend::Vulkan, Backend::OpenCl, Backend::Cuda, Backend::Rocm]);
        }
        _ => {}
    }

    // NPU: only reliably known on Android with specific SoCs; refined later via JNI.
    let npu = None;

    HardwareCaps {
        os,
        arch,
        cpu_name,
        cores,
        total_ram_mb,
        available_ram_mb,
        backends,
        npu,
        gpu: gpu(),
    }
}

/// Detect the primary GPU once and cache it (detection can be slow).
pub fn gpu() -> Option<GpuInfo> {
    static GPU: OnceLock<Option<GpuInfo>> = OnceLock::new();
    GPU.get_or_init(detect_gpu).clone()
}

fn detect_gpu() -> Option<GpuInfo> {
    #[cfg(target_os = "windows")]
    {
        detect_gpu_windows()
    }
    #[cfg(target_os = "linux")]
    {
        detect_gpu_linux()
    }
    #[cfg(target_os = "macos")]
    {
        detect_gpu_macos()
    }
    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {
        None
    }
}

/// Classify a GPU from its device name and return the recommended runtime.
fn gpu_from_name(name: String, vram_mb: u64) -> GpuInfo {
    let lower = name.to_lowercase();
    let vendor = if lower.contains("nvidia")
        || lower.contains("geforce")
        || lower.contains("quadro")
        || lower.contains("rtx")
        || lower.contains("gtx")
    {
        "NVIDIA"
    } else if lower.contains("amd")
        || lower.contains("radeon")
        || lower.contains("firepro")
        || lower.contains(" instinct")
    {
        "AMD"
    } else if lower.contains("intel") || lower.contains("arc") || lower.contains("iris") {
        "Intel"
    } else {
        "Other"
    };

    let recommended_backend = match vendor {
        "NVIDIA" => Backend::Cuda,
        "AMD" => Backend::Rocm,
        // Intel has no dedicated llama.cpp backend in this build; Vulkan is the
        // portable GPU path (SYCL/oneAPI is possible but not wired up here).
        "Intel" => Backend::Vulkan,
        _ => Backend::Vulkan,
    };

    GpuInfo {
        name,
        vendor: vendor.to_string(),
        vram_mb,
        recommended_backend,
    }
}

#[cfg(target_os = "windows")]
fn detect_gpu_windows() -> Option<GpuInfo> {
    // Pick the adapter with the most reported memory (discrete GPU on laptops),
    // then read the true dedicated VRAM from the display-class registry key.
    let script = "$g = Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1; \
        $vram = (Get-ChildItem 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | \
        ForEach-Object { (Get-ItemProperty $_.PSPath -Name 'HardwareInformation.qwMemorySize' -ErrorAction SilentlyContinue).'HardwareInformation.qwMemorySize' } | \
        Measure-Object -Maximum).Maximum; \
        if ($vram) { $ram = $vram } else { $ram = $g.AdapterRAM }; \
        [pscustomobject]@{ Name = $g.Name; AdapterRAM = $ram } | ConvertTo-Json -Compress";

    let out = std::process::Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", script])
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&out.stdout);
    let text = text.trim();
    if text.is_empty() {
        return None;
    }
    let value: serde_json::Value = serde_json::from_str(text).ok()?;
    let first = if value.is_array() {
        value.as_array()?.first()?.clone()
    } else {
        value
    };
    let name = first.get("Name")?.as_str()?.trim().to_string();
    if name.is_empty() {
        return None;
    }
    let vram_bytes = first
        .get("AdapterRAM")
        .and_then(|v| v.as_u64())
        .unwrap_or(0);
    Some(gpu_from_name(name, vram_bytes / 1_048_576))
}

#[cfg(target_os = "linux")]
fn detect_gpu_linux() -> Option<GpuInfo> {
    let out = std::process::Command::new("bash")
        .args(["-c", "lspci 2>/dev/null | grep -Ei 'vga|3d|display' | head -n 1"])
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let line = String::from_utf8_lossy(&out.stdout).trim().to_string();
    if line.is_empty() {
        return None;
    }
    // "01:00.0 VGA compatible controller: NVIDIA GeForce ..." -> keep the part after ': '.
    let name = line
        .split(": ")
        .nth(1)
        .unwrap_or(&line)
        .trim()
        .to_string();
    Some(gpu_from_name(name, 0))
}

#[cfg(target_os = "macos")]
fn detect_gpu_macos() -> Option<GpuInfo> {
    let out = std::process::Command::new("system_profiler")
        .args(["SPDisplaysDataType"])
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&out.stdout);
    let name = text
        .lines()
        .find_map(|l| l.trim().strip_prefix("Chipset Model:"))
        .map(|s| s.trim().to_string())?;
    let vram_mb = text
        .lines()
        .find_map(|l| l.trim().strip_prefix("VRAM (MB):"))
        .and_then(|s| s.trim().parse::<u64>().ok())
        .unwrap_or(0);
    Some(gpu_from_name(name, vram_mb))
}