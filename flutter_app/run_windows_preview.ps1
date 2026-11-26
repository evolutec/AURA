# AURA Flutter Windows Preview Launcher
# Sets up PATH safely (handles spaces) and runs the Flutter app on Windows.

$ErrorActionPreference = 'Stop'

# Prepend Flutter to PATH (array-safe, no string splitting issues)
$flutterBin = 'C:\Users\evolu\flutter\bin'
$env:PATH = "$flutterBin;$env:PATH"

Set-Location -LiteralPath 'C:\Users\evolu\Documents\Github-repo\Aura\flutter_app'

Write-Host "Launching AURA on Windows (debug)..." -ForegroundColor Cyan
& flutter run -d windows