// Stub implementation for platforms without FFI (web)
// Returns mock data for demonstration

import 'dart:ffi';

String auraVersion() => '0.1.0 (stub)';
String auraLastError() => '';

// ... existing ...

Pointer<Void> auraEngineCreate(String modelId) => nullptr;

String auraEngineGenerate(Pointer<Void> engine, String prompt, String paramsJson) => 'Mock response: $prompt';

Pointer<Void> auraEngineCreateFromPath(String path) => nullptr;

void auraEngineDispose(Pointer<Void> engine) {}

Pointer<Void> auraSessionCreate(Pointer<Void> engine, String? systemPrompt) => nullptr;

String auraSessionSend(Pointer<Void> session, String text, String paramsJson) => 'Mock response: $text';

void auraSessionDispose(Pointer<Void> session) {}

String auraHardwareJson() => '''
{
  "os": "Web",
  "arch": "wasm32",
  "cpu_name": "Browser",
  "cores": 4,
  "total_ram_mb": 0,
  "available_ram_mb": 0,
  "backends": ["CPU"],
  "npu": null
}
''';

String auraCatalogJson() => '''
[
  {"id": "mock", "name": "Mock Model", "kind": "mock", "params_b": 1.0, "ram_required_mb": 100},
  {"id": "llama", "name": "Llama 3.2 1B", "kind": "llama", "params_b": 1.2, "ram_required_mb": 1600}
]
''';

String auraCatalogCompatibleJson() => auraCatalogJson();
// Stub - no-op for web
