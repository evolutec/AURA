#!/usr/bin/env pwsh
# AURA Core Cross-Compilation Script for Windows
# Builds the Rust core for Windows (x86_64 and optionally aarch64)

param(
    [string]$BuildType = "release",
    [string]$OutputDir = "dist/windows"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AURA Core for Windows..." -ForegroundColor Cyan

# Build for x86_64
cargo build --target x86_64-pc-windows-msvc --$BuildType -p aura-core
if ($LASTEXITCODE -ne 0) { throw "x86_64 build failed" }

# Build for aarch64 (optional - only if target installed)
$hasArm = $false
$targets = rustup target list --installed 2>&1
if ($targets -match "aarch64-pc-windows-msvc") {
    cargo build --target aarch64-pc-windows-msvc --$BuildType -p aura-core
    if ($LASTEXITCODE -eq 0) { $hasArm = $true }
    else { Write-Warning "aarch64-pc-windows build failed, skipping" }
} else {
    Write-Host "aarch64-pc-windows-msvc target not installed, skipping ARM64" -ForegroundColor DarkGray
}

# Create output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy libraries
Copy-Item "target/x86_64-pc-windows-msvc/$BuildType/aura_core.dll" "$OutputDir/aura_core.dll" -Force
if ($hasArm) {
    Copy-Item "target/aarch64-pc-windows-msvc/$BuildType/aura_core.dll" "$OutputDir/aura_core_arm64.dll" -Force
}

# Also build the node binding
cargo build --target x86_64-pc-windows-msvc --$BuildType -p aura-node
if ($LASTEXITCODE -eq 0) {
    Copy-Item "target/x86_64-pc-windows-msvc/$BuildType/aura_node.dll" "$OutputDir/aura_node.node" -Force
}

Write-Host "Windows build complete:" -ForegroundColor Green
Write-Host "  Core: $OutputDir/aura_core.dll"
Write-Host "  Node: $OutputDir/aura_node.node"
if ($hasArm) { Write-Host "  Core ARM64: $OutputDir/aura_core_arm64.dll" }