#!/usr/bin/env pwsh
# AURA Core Cross-Compilation Script for Linux
# Builds the Rust core for Linux (x86_64 and aarch64)

param(
    [string]$BuildType = "release",
    [string]$OutputDir = "dist/linux"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AURA Core for Linux..." -ForegroundColor Cyan

# Build for x86_64
cargo build --target x86_64-unknown-linux-gnu --$BuildType -p aura-core

# Build for aarch64 (if cross-compiler available)
try {
    cargo build --target aarch64-unknown-linux-gnu --$BuildType -p aura-core
    $hasArm = $true
} catch {
    $hasArm = $false
    Write-Warning "aarch64-linux build skipped (cross-compiler not available)"
}

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy libraries
Copy-Item "target/x86_64-unknown-linux-gnu/$BuildType/libaura_core.so" "$OutputDir/libaura_core_x86_64.so" -Force
if ($hasArm) {
    Copy-Item "target/aarch64-unknown-linux-gnu/$BuildType/libaura_core.so" "$OutputDir/libaura_core_aarch64.so" -Force
}

Write-Host "Linux build complete:" -ForegroundColor Green
Write-Host "  x86_64: $OutputDir/libaura_core_x86_64.so"
if ($hasArm) { Write-Host "  aarch64: $OutputDir/libaura_core_aarch64.so" }