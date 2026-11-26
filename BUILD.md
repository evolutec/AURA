# AURA Build Guide

## Prerequisites

### All Platforms
- Rust 1.98+ (`rustup`)
- Flutter 3.50+ (`flutter`)
- Node.js 24+ (for Node binding)
- Git

### Platform-Specific
- **Android**: Android SDK, NDK
- **iOS**: Xcode (macOS only)
- **macOS**: Xcode Command Line Tools
- **Linux**: GCC, CMake
- **Windows**: Visual Studio 2022/2026 with C++ workload

## Quick Start

### 1. Build the Rust Core for All Platforms
```powershell
cd core
.\build_all.ps1
```

### 2. Build the Flutter App
```powershell
cd flutter_app
.\build.ps1 -Platform all
```

## Individual Platform Builds

### Rust Core Only

```powershell
# Windows
.\build_windows.ps1

# Android
.\build_android.ps1

# iOS (requires macOS)
.\build_ios.ps1

# macOS (requires macOS)
.\build_macos.ps1

# Linux
.\build_linux.ps1
```

### Flutter App Only

```powershell
# Web (for testing)
flutter build web

# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS (requires macOS)
flutter build macos --release

# iOS (requires macOS + Xcode)
flutter build ios --release --no-codesign
```

## Output Locations

### Rust Core
- `core/dist/windows/aura_core.dll`
- `core/dist/android/libaura_core.so`
- `core/dist/ios/device/libaura_core.a`
- `core/dist/macos/libaura_core.dylib`
- `core/dist/linux/libaura_core_x86_64.so`

### Flutter App
- `flutter_app/build/web/` (web)
- `flutter_app/build/app/outputs/flutter-apk/app-release.apk` (Android)
- `flutter_app/build/windows/x64/runner/Release/aura_app.exe` (Windows)
- `flutter_app/build/linux/x64/release/bundle/` (Linux)
- `flutter_app/build/macos/Build/Products/Release/aura_app.app` (macOS)

## CI/CD

### GitHub Actions Example

```yaml
name: Build AURA

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        include:
          - os: ubuntu-latest
            platform: linux
          - os: windows-latest
            platform: windows
          - os: macos-latest
            platform: macos
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: subosito/flutter-action@v2
      - run: cd core && ./build_all.ps1 -Platforms ${{ matrix.platform }}
      - run: cd flutter_app && flutter pub get && flutter build ${{ matrix.platform }} --release
```

## Notes

- iOS builds require macOS with Xcode
- Android NDK is required for native builds
- The Flutter app includes pre-built native libraries for each platform
- FFI bindings use conditional imports: `ffi_stub.dart` for web, `ffi_native.dart` for native