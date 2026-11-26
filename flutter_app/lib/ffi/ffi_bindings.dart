// Platform-agnostic AURA core interface
// Conditional imports for platform-specific FFI

export 'ffi_stub.dart'
    if (dart.library.ffi) 'ffi_native.dart';