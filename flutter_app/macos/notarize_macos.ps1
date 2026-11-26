#!/usr/bin/env pwsh
# AURA macOS Notarization Script
# Notarise et staple l'app macOS pour distribution Gatekeeper
#
# PRÉREQUIS : macOS avec Xcode, compte Apple Developer
# Usage : pwsh -File notarize_macos.ps1 -AppleId <email> -TeamId <team> -Password <app-specific>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppleId,
    [Parameter(Mandatory=$true)]
    [string]$TeamId,
    [Parameter(Mandatory=$true)]
    [string]$Password,
    [string]$AppPath = "build/macos/Build/Products/Release/aura_app.app"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA macOS Notarization" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check platform
if (-not $IsMacOS -and $env:OS -ne "Mac") {
    Write-Error "Notarization requires macOS"
    exit 1
}

# Build if needed
if (-not (Test-Path $AppPath)) {
    Write-Host "--- Building macOS app ---" -ForegroundColor Yellow
    flutter build macos --release
}

# Create a zip for notarization
$zipPath = "build/aura_app.zip"
Write-Host "--- Creating zip ---" -ForegroundColor Yellow
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
ditto -c -k --keepParent $AppPath $zipPath

# Submit for notarization
Write-Host "--- Submitting for notarization ---" -ForegroundColor Yellow
$result = xcrun notarytool submit $zipPath `
    --apple-id $AppleId `
    --team-id $TeamId `
    --password $Password `
    --wait 2>&1 | Out-String

Write-Host $result

if ($result -match "Accepted") {
    Write-Host "--- Stapling ---" -ForegroundColor Yellow
    xcrun stapler staple $AppPath

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Notarization Complete!" -ForegroundColor Green
    Write-Host "App: $AppPath" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Error "Notarization failed: $result"
}

# Create DMG
Write-Host "--- Creating DMG ---" -ForegroundColor Yellow
$dmgPath = "build/AURA.dmg"
if (Test-Path $dmgPath) { Remove-Item $dmgPath -Force }
hdiutil create -volname "AURA" -srcfolder $AppPath -ov -format UDZO $dmgPath

Write-Host ""
Write-Host "DMG created: $dmgPath" -ForegroundColor Green