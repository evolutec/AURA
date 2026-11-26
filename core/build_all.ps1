#!/usr/bin/env pwsh
# AURA Core Master Build Script
# Builds the Rust core for all supported platforms

param(
    [string]$BuildType = "release",
    [string[]]$Platforms = @("windows", "android", "ios", "macos", "linux"),
    [switch]$SkipNode
)

$ErrorActionPreference = "Continue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA Core Master Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Build for each platform
foreach ($platform in $Platforms) {
    Write-Host "--- Building for $platform ---" -ForegroundColor Yellow
    
    switch ($platform.ToLower()) {
        "windows" {
            & "$scriptDir/build_windows.ps1" -BuildType $BuildType
        }
        "android" {
            & "$scriptDir/build_android.ps1" -BuildType $BuildType
        }
        "ios" {
            & "$scriptDir/build_ios.ps1" -BuildType $BuildType
        }
        "macos" {
            & "$scriptDir/build_macos.ps1" -BuildType $BuildType
        }
        "linux" {
            & "$scriptDir/build_linux.ps1" -BuildType $BuildType
        }
        default {
            Write-Warning "Unknown platform: $platform"
        }
    }
    Write-Host ""
}

# Copy to Flutter app if it exists
$flutterAppDir = Join-Path (Split-Path $scriptDir -Parent) "flutter_app"
if (Test-Path $flutterAppDir) {
    Write-Host "Copying libraries to Flutter app..." -ForegroundColor Cyan
    
    # Android
    $androidDir = Join-Path $flutterAppDir "android/app/src/main/jniLibs/arm64-v8a"
    New-Item -ItemType Directory -Path $androidDir -Force | Out-Null
    if (Test-Path "dist/android/libaura_core.so") {
        Copy-Item "dist/android/libaura_core.so" "$androidDir/libaura_core.so" -Force
    }
    
    # iOS - handled via CocoaPods
    # macOS
    $macosDir = Join-Path $flutterAppDir "macos/Runner"
    if (Test-Path "dist/macos/libaura_core.dylib") {
        Copy-Item "dist/macos/libaura_core.dylib" "$macosDir/libaura_core.dylib" -Force
    }
    
    # Linux
    $linuxDir = Join-Path $flutterAppDir "linux"
    if (Test-Path "dist/linux/libaura_core_x86_64.so") {
        Copy-Item "dist/linux/libaura_core_x86_64.so" "$linuxDir/libaura_core.so" -Force
    }
    
    # Windows
    $windowsDir = Join-Path $flutterAppDir "windows"
    if (Test-Path "dist/windows/aura_core.dll") {
        Copy-Item "dist/windows/aura_core.dll" "$windowsDir/aura_core.dll" -Force
    }
    
    Write-Host "Flutter app libraries updated" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green