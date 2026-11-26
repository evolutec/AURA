#!/usr/bin/env pwsh
# AURA Core Cross-Compilation Script for macOS
# Builds the Rust core for macOS (Intel and Apple Silicon)

param(
    [string]$BuildType = "release",
    [string]$OutputDir = "dist/macos"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AURA Core for macOS..." -ForegroundColor Cyan

# Build for Intel (x86_64)
cargo build --target x86_64-apple-darwin --$BuildType -p aura-core

# Build for Apple Silicon (arm64)
cargo build --target aarch64-apple-darwin --$BuildType -p aura-core

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy libraries
Copy-Item "target/x86_64-apple-darwin/$BuildType/libaura_core.dylib" "$OutputDir/libaura_core_x86_64.dylib" -Force
Copy-Item "target/aarch64-apple-darwin/$BuildType/libaura_core.dylib" "$OutputDir/libaura_core_arm64.dylib" -Force

# Create universal binary with lipo
if (Get-Command lipo -ErrorAction SilentlyContinue) {
    lipo -create "$OutputDir/libaura_core_x86_64.dylib" "$OutputDir/libaura_core_arm64.dylib" -output "$OutputDir/libaura_core.dylib"
    Write-Host "Universal binary created: $OutputDir/libaura_core.dylib" -ForegroundColor Green
} else {
    Write-Host "macOS build complete (separate binaries):" -ForegroundColor Green
    Write-Host "  Intel: $OutputDir/libaura_core_x86_64.dylib"
    Write-Host "  ARM: $OutputDir/libaura_core_arm64.dylib"
}