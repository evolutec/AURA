#!/usr/bin/env pwsh
# AURA Core Cross-Compilation Script for Android
# Builds the Rust core for Android arm64-v8a

param(
    [string]$BuildType = "release",
    [string]$OutputDir = "dist/android"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AURA Core for Android (aarch64-linux-android)..." -ForegroundColor Cyan

# Build for arm64-v8a
cargo build --target aarch64-linux-android --$BuildType -p aura-core

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy the library
Copy-Item "target/aarch64-linux-android/$BuildType/libaura_core.so" "$OutputDir/libaura_core.so" -Force

Write-Host "Android build complete: $OutputDir/libaura_core.so" -ForegroundColor Green