// Native FFI implementation for mobile/desktop
// Uses dart:ffi to call the Rust core

import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// Resolve the platform-specific library name
String _getLibraryName() {
  if (Platform.isAndroid) return 'libaura_core.so';
  if (Platform.isIOS) return 'aura_core.framework/aura_core';
  if (Platform.isMacOS) return 'libaura_core.dylib';
  if (Platform.isLinux) return 'libaura_core.so';
  if (Platform.isWindows) return 'aura_core.dll';
  throw UnsupportedError('Unsupported platform');
}

// Load the dynamic library
final DynamicLibrary _dylib = DynamicLibrary.open(_getLibraryName());

// C function signatures
typedef _AuraVersionC = Pointer<Utf8> Function();
typedef _AuraVersionDart = Pointer<Utf8> Function();

typedef _AuraHardwareJsonC = Pointer<Utf8> Function();
typedef _AuraHardwareJsonDart = Pointer<Utf8> Function();

typedef _AuraCatalogJsonC = Pointer<Utf8> Function();
typedef _AuraCatalogJsonDart = Pointer<Utf8> Function();
typedef _AuraCatalogCompatibleJsonC = Pointer<Utf8> Function();
typedef _AuraCatalogCompatibleJsonDart = Pointer<Utf8> Function();

typedef _AuraStringFreeC = Void Function(Pointer);
typedef _AuraStringFreeDart = void Function(Pointer);

typedef _AuraLastErrorC = Pointer<Utf8> Function();
typedef _AuraLastErrorDart = Pointer<Utf8> Function();

typedef _AuraEngineCreateC = Pointer<Void> Function(Pointer<Utf8>);
typedef _AuraEngineCreateDart = Pointer<Void> Function(Pointer<Utf8>);

typedef _AuraEngineGenerateC = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _AuraEngineGenerateDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _AuraEngineFreeC = Void Function(Pointer<Void>);
typedef _AuraEngineFreeDart = void Function(Pointer<Void>);

typedef _AuraSessionCreateC = Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>);
typedef _AuraSessionCreateDart = Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>);

typedef _AuraSessionSendC = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _AuraSessionSendDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _AuraSessionFreeC = Void Function(Pointer<Void>);
typedef _AuraSessionFreeDart = void Function(Pointer<Void>);

typedef _AuraEngineCreateFromPathC = Pointer<Void> Function(Pointer<Utf8>);
typedef _AuraEngineCreateFromPathDart = Pointer<Void> Function(Pointer<Utf8>);

// Function lookups
final _auraVersion = _dylib.lookupFunction<_AuraVersionC, _AuraVersionDart>('aura_version');
final _auraHardwareJson = _dylib.lookupFunction<_AuraHardwareJsonC, _AuraHardwareJsonDart>('aura_hardware_json');
final _auraCatalogJson = _dylib.lookupFunction<_AuraCatalogJsonC, _AuraCatalogJsonDart>('aura_catalog_json');
final _auraCatalogCompatibleJson = _dylib.lookupFunction<_AuraCatalogCompatibleJsonC, _AuraCatalogCompatibleJsonDart>('aura_catalog_compatible_json');
final _auraStringFree = _dylib.lookupFunction<_AuraStringFreeC, _AuraStringFreeDart>('aura_string_free');
final _auraLastError = _dylib.lookupFunction<_AuraLastErrorC, _AuraLastErrorDart>('aura_last_error');
final _auraEngineCreate = _dylib.lookupFunction<_AuraEngineCreateC, _AuraEngineCreateDart>('aura_engine_create');
final _auraEngineGenerate = _dylib.lookupFunction<_AuraEngineGenerateC, _AuraEngineGenerateDart>('aura_engine_generate');
final _auraSessionCreate = _dylib.lookupFunction<_AuraSessionCreateC, _AuraSessionCreateDart>('aura_session_create');
final _auraSessionSend = _dylib.lookupFunction<_AuraSessionSendC, _AuraSessionSendDart>('aura_session_send');
final _auraSessionFree = _dylib.lookupFunction<_AuraSessionFreeC, _AuraSessionFreeDart>('aura_session_free');
final _auraEngineFree = _dylib.lookupFunction<_AuraEngineFreeC, _AuraEngineFreeDart>('aura_engine_free');
final _auraEngineCreateFromPath = _dylib.lookupFunction<_AuraEngineCreateFromPathC, _AuraEngineCreateFromPathDart>('aura_engine_create_from_path');

/// Get the AURA core version
String auraVersion() {
  final ptr = _auraVersion();
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

/// Get hardware information as JSON
String auraHardwareJson() {
  final ptr = _auraHardwareJson();
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

/// Get last error
String auraLastError() {
  final ptr = _auraLastError();
  if (ptr == nullptr) return '';
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

/// Get model catalog filtered by detected hardware
String auraCatalogCompatibleJson() {
  final ptr = _auraCatalogCompatibleJson();
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

Pointer<Utf8> _toNative(String s) {
  final units = utf8.encode(s);
  final ptr = malloc.allocate<Uint8>(units.length + 1);
  final list = ptr.asTypedList(units.length + 1);
  list.setRange(0, units.length, units);
  list[units.length] = 0;
  return ptr.cast<Utf8>();
}

/// Create an inference engine for a model id
Pointer<Void> auraEngineCreate(String modelId) {
  final ptr = _toNative(modelId);
  final engine = _auraEngineCreate(ptr);
  malloc.free(ptr);
  return engine;
}

/// Generate text synchronously
String auraEngineGenerate(Pointer<Void> engine, String prompt, String paramsJson) {
  final pPrompt = _toNative(prompt);
  final pParams = _toNative(paramsJson);
  final ptr = _auraEngineGenerate(engine, pPrompt, pParams);
  malloc.free(pPrompt);
  malloc.free(pParams);
  if (ptr == nullptr) return '';
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

/// Free an engine
void auraEngineDispose(Pointer<Void> engine) {
  _auraEngineFree(engine);
}

/// Create a chat session
Pointer<Void> auraSessionCreate(Pointer<Void> engine, String? systemPrompt) {
  final ptr = systemPrompt == null ? nullptr : _toNative(systemPrompt);
  final s = _auraSessionCreate(engine, ptr == nullptr ? nullptr : ptr);
  if (ptr != nullptr) malloc.free(ptr);
  return s;
}

/// Send a message in a session
String auraSessionSend(Pointer<Void> session, String text, String paramsJson) {
  final pText = _toNative(text);
  final pParams = _toNative(paramsJson);
  final ptr = _auraSessionSend(session, pText, pParams);
  malloc.free(pText);
  malloc.free(pParams);
  if (ptr == nullptr) return '';
  final str = ptr.toDartString();
  _auraStringFree(ptr);
  return str;
}

/// Free a session
void auraSessionDispose(Pointer<Void> session) {
  _auraSessionFree(session);
}

/// Create an engine from a local model file path
Pointer<Void> auraEngineCreateFromPath(String path) {
  final ptr = _toNative(path);
  final engine = _auraEngineCreateFromPath(ptr);
  malloc.free(ptr);
  return engine;
}


