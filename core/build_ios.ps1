#!/usr/bin/env pwsh
# AURA Core Cross-Compilation Script for iOS
# Builds the Rust core for iOS arm64

param(
    [string]$BuildType = "release",
    [string]$OutputDir = "dist/ios"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AURA Core for iOS (aarch64-apple-ios)..." -ForegroundColor Cyan

# Build for device (arm64)
cargo build --target aarch64-apple-ios --$BuildType -p aura-core

# Build for simulator (x86_64)
cargo build --target x86_64-apple-ios --$BuildType -p aura-core

# Create output directories
New-Item -ItemType Directory -Path "$OutputDir/device" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir/simulator" -Force | Out-Null

# Copy libraries
Copy-Item "target/aarch64-apple-ios/$BuildType/libaura_core.a" "$OutputDir/device/libaura_core.a" -Force
Copy-Item "target/x86_64-apple-ios/$BuildType/libaura_core.a" "$OutputDir/simulator/libaura_core.a" -Force

Write-Host "iOS build complete:" -ForegroundColor Green
Write-Host "  Device: $OutputDir/device/libaura_core.a"
Write-Host "  Simulator: $OutputDir/simulator/libaura_core.a"