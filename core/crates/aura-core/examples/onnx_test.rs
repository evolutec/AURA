use aura_core::engine::selector::EngineManager;
use aura_core::types::{EngineKind, ModelDescriptor, Modality};
use std::path::Path;

fn main() {
    let model_path = r"C:\Users\evolu\.cache\huggingface\hub\models--sentence-transformers--all-MiniLM-L6-v2\blobs\1391c6fc20b5530250bc15cbe1f47578ffeca55ab0551d335cc668b6299a88ec";
    if !Path::new(model_path).exists() {
        println!("Model not found: {model_path}");
        return;
    }

    let model = ModelDescriptor {
        id: "minilm-onnx".into(),
        name: "MiniLM-L6-v2 ONNX".into(),
        family: "minilm".into(),
        kind: EngineKind::Onnx,
        modalities: vec![Modality::Embedding],
        params_b: 0.022,
        quant: "FP32".into(),
        size_mb: 90,
        ram_required_mb: 256,
        license: "Apache-2.0".into(),
        source: "local".into(),
        path: Some(model_path.into()),
    };

    let mut mgr = EngineManager::new();
    mgr.ensure_model(&model).expect("load onnx model");
    println!("Loaded: {}", mgr.current_model().unwrap().name);

    match mgr.embed("AURA portable core") {
        Ok(v) => println!("Embedding dim={} first={:?}", v.len(), &v[..v.len().min(4)]),
        Err(e) => println!("Embed error: {e}"),
    }
}
