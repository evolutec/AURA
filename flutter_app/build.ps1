#!/usr/bin/env pwsh
# AURA Flutter App Build Script
# Builds the Flutter app for all supported platforms

param(
    [ValidateSet("all", "android", "ios", "macos", "linux", "windows", "web")]
    [string]$Platform = "all",
    [ValidateSet("debug", "release", "profile")]
    [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

$flutterDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $flutterDir

# Add Flutter to PATH
$env:PATH = "C:\Users\evolu\flutter\bin;" + $env:PATH

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA Flutter App Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Build-Platform {
    param([string]$Platform, [string]$BuildType)
    
    Write-Host "--- Building for $Platform ---" -ForegroundColor Yellow
    
    switch ($Platform.ToLower()) {
        "android" {
            flutter build apk --$BuildType
            if ($LASTEXITCODE -eq 0) {
                Write-Host "APK built: build/app/outputs/flutter-apk/app-$BuildType.apk" -ForegroundColor Green
            }
        }
        "ios" {
            flutter build ios --$BuildType --no-codesign
            if ($LASTEXITCODE -eq 0) {
                Write-Host "iOS build complete" -ForegroundColor Green
            }
        }
        "macos" {
            flutter build macos --$BuildType
            if ($LASTEXITCODE -eq 0) {
                Write-Host "macOS build complete: build/macos/Build/Products/$BuildType/aura_app.app" -ForegroundColor Green
            }
        }
        "linux" {
            flutter build linux --$BuildType
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Linux build complete: build/linux/x64/$BuildType/bundle" -ForegroundColor Green
            }
        }
        "windows" {
            flutter build windows --$BuildType
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Windows build complete: build/windows/x64/runner/$BuildType/aura_app.exe" -ForegroundColor Green
            }
        }
        "web" {
            flutter build web --$BuildType
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Web build complete: build/web" -ForegroundColor Green
            }
        }
    }
    Write-Host ""
}

# Build platforms
if ($Platform -eq "all") {
    $platforms = @("web", "windows", "android", "macos", "linux", "ios")
} else {
    $platforms = @($Platform)
}

foreach ($p in $platforms) {
    Build-Platform -Platform $p -BuildType $BuildType
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green