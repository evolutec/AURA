#!/usr/bin/env pwsh
# AURA macOS Build Script
# Build l'app macOS + universal binary + notarization
#
# Prérequis : macOS avec Xcode, Flutter SDK
# Usage : pwsh -File build_macos.ps1 [-Notarize]

param(
    [ValidateSet("debug", "release")]
    [string]$BuildType = "release",
    [switch]$Universal,
    [switch]$Notarize,
    [string]$AppleId,
    [string]$TeamId,
    [string]$Password
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA macOS Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $IsMacOS -and $env:OS -ne "Mac") {
    Write-Error "macOS builds require macOS"
    exit 1
}

# Build
Write-Host "--- Building Flutter macOS ($BuildType) ---" -ForegroundColor Yellow
if ($Universal) {
    flutter build macos --$BuildType --release --target-platform darwin-x64,darwin-arm64
} else {
    flutter build macos --$BuildType
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

$appPath = "build/macos/Build/Products/$BuildType/aura_app.app"
Write-Host "App built: $appPath" -ForegroundColor Green

# Code sign
if ($Notarize) {
    Write-Host "--- Code Signing ---" -ForegroundColor Yellow
    codesign --force --deep --options runtime `
        --entitlements macos/Runner/Aura.entitlements `
        --sign "Developer ID Application: $TeamId" `
        $appPath

    # Verify
    codesign --verify --deep --strict $appPath

    # Notarize
    & "$scriptDir/notarize_macos.ps1" -AppleId $AppleId -TeamId $TeamId -Password $Password -AppPath $appPath
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "macOS Build Complete!" -ForegroundColor Green
Write-Host "App: $appPath" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green