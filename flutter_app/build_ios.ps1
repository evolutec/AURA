#!/usr/bin/env pwsh
# AURA iOS Build Script
# Build l'app iOS + Widget extension
#
# PRÉREQUIS : macOS avec Xcode, CocoaPods
# Usage : pwsh -File build_ios.ps1 [-ExportOptions <path>]

param(
    [ValidateSet("debug", "release", "profile")]
    [string]$BuildType = "release",
    [string]$ExportOptionsPath = "ios/ExportOptions.plist",
    [switch]$BuildIpa
)

$ErrorActionPreference = "Stop"
$flutterDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $flutterDir

$env:PATH = "C:\Users\evolu\flutter\bin;" + $env:PATH

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA iOS Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check platform
if (-not $IsMacOS -and $env:OS -ne "Mac") {
    Write-Error "iOS builds require macOS with Xcode"
    exit 1
}

# Install pods
Write-Host "--- Installing CocoaPods ---" -ForegroundColor Yellow
if (Test-Path "ios/Podfile") {
    pod install --repo-update
}

# Build
Write-Host "--- Building Flutter iOS ($BuildType) ---" -ForegroundColor Yellow
flutter build ios --$BuildType --no-codesign

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

if ($BuildIpa) {
    Write-Host "--- Building IPA ---" -ForegroundColor Yellow
    xcodebuild -workspace ios/Runner.xcworkspace `
        -scheme Runner `
        -configuration $BuildType `
        -archivePath build/ios/archive `
        -allowProvisioningUpdates `
        archive

    xcodebuild -exportArchive `
        -archivePath build/ios/archive `
        -exportPath build/ios/ipa `
        -exportOptionsPlist $ExportOptionsPath

    Write-Host "IPA built: build/ios/ipa/" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "iOS Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green