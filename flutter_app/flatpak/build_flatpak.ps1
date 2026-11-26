#!/usr/bin/env pwsh
# AURA Flatpak Build Script (Linux)
# Build et installe AURA en Flatpak
#
# Prérequis : flatpak, flatpak-builder, Flutter SDK
# Usage : pwsh -File build_flatpak.ps1

param(
    [switch]$SkipBuild,
    [switch]$Install
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA Flatpak Build (Linux)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check flatpak
if (-not (Get-Command flatpak -ErrorAction SilentlyContinue)) {
    Write-Error "flatpak not found. Install: sudo apt install flatpak flatpak-builder"
    exit 1
}

if (-not (Get-Command flatpak-builder -ErrorAction SilentlyContinue)) {
    Write-Error "flatpak-builder not found. Install: sudo apt install flatpak-builder"
    exit 1
}

# Install runtime if needed
Write-Host "--- Installing Flatpak runtime ---" -ForegroundColor Yellow
flatpak install --user flathub org.freedesktop.Platform/x86_64/24.08 --noninteractive 2>&1 | Out-Null
flatpak install --user flathub org.freedesktop.Sdk/x86_64/24.08 --noninteractive 2>&1 | Out-Null

if (-not $SkipBuild) {
    Write-Host "--- Building Flatpak ---" -ForegroundColor Yellow
    flatpak-builder --user --install --force-clean build-flatpak com.aura.Aura.yml
}

if ($Install) {
    Write-Host "--- Installing Flatpak ---" -ForegroundColor Yellow
    flatpak install --user build-flatpak com.aura.Aura
}

# Export bundle
Write-Host "--- Exporting bundle ---" -ForegroundColor Yellow
flatpak build-bundle ~/.local/share/flatpak/repo aura.flatpak com.aura.Aura

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Flatpak Build Complete!" -ForegroundColor Green
Write-Host "Bundle: aura.flatpak" -ForegroundColor Green
Write-Host "Install: flatpak install --user aura.flatpak" -ForegroundColor Green
Write-Host "Run: flatpak run com.aura.Aura" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green