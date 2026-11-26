#!/usr/bin/env pwsh
# AURA MSIX Build Script (Windows)
# Build et package AURA en MSIX pour Microsoft Store
#
# Prérequis : Flutter, MakeAppx.exe (Windows SDK), Visual Studio
# Usage : pwsh -File build_msix.ps1

param(
    [ValidateSet("debug", "release")]
    [string]$BuildType = "release",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA MSIX Build (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Add Flutter to PATH
$env:PATH = "C:\Users\evolu\flutter\bin;" + $env:PATH

if (-not $SkipBuild) {
    Write-Host "--- Building Flutter Windows ($BuildType) ---" -ForegroundColor Yellow
    flutter build windows --$BuildType
}

# Find Flutter Windows output
$flutterOutput = "build\windows\x64\runner\$BuildType"
if (-not (Test-Path $flutterOutput)) {
    Write-Error "Flutter build output not found: $flutterOutput"
    exit 1
}

# Create MSIX package structure
$msixDir = "build\msix"
$msixContent = "$msixDir\AURA"
Remove-Item -LiteralPath $msixDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $msixContent -Force | Out-Null

# Copy build output
Copy-Item -Path "$flutterOutput\*" -Destination $msixContent -Recurse -Force

# Copy native core DLL
if (Test-Path "..\..\core\dist\windows\aura_core.dll") {
    Copy-Item "..\..\core\dist\windows\aura_core.dll" $msixContent -Force
}

# Copy manifest
Copy-Item -Path "Package.appxmanifest" -Destination $msixDir -Force

# Copy logo (use Aura-icon.jpg as logo.png)
if (Test-Path "..\..\Aura-icon.jpg") {
    # Convert to PNG using .NET
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile("..\..\Aura-icon.jpg")
    $img.Save("$msixDir\logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    # Create different sizes
    foreach ($size in @(44, 150, 310)) {
        $bmp = New-Object System.Drawing.Bitmap($size, $size)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $img = [System.Drawing.Image]::FromFile("..\..\Aura-icon.jpg")
        $g.DrawImage($img, 0, 0, $size, $size)
        $img.Dispose()
        $bmp.Save("$msixDir\logo_$size.png", [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $g.Dispose()
    }
    # Splash screen (620x300)
    $bmp = New-Object System.Drawing.Bitmap(620, 300)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(11, 13, 18))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $img = [System.Drawing.Image]::FromFile("..\..\Aura-icon.jpg")
    $size = 200
    $g.DrawImage($img, 210, 50, $size, $size)
    $img.Dispose()
    $bmp.Save("$msixDir\splash.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $g.Dispose()
}

# Create MSIX package
$makeAppx = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter "MakeAppx.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $makeAppx) {
    Write-Warning "MakeAppx.exe not found. Install Windows SDK."
    Write-Host "MSIX package created at: $msixDir (manual packaging needed)"
    exit 0
}

$msixFile = "build\AURA.msix"
& $makeAppx.FullName pack /d $msixDir /p $msixFile /o

if ($LASTEXITCODE -eq 0) {
    Write-Host "MSIX built: $msixFile" -ForegroundColor Green
} else {
    Write-Error "MSIX build failed"
}

# Sign (optional, requires certificate)
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "MSIX Build Complete!" -ForegroundColor Green
Write-Host "Package: $msixFile" -ForegroundColor Green
Write-Host "Install: Add-AppxPackage -Path $msixFile" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green