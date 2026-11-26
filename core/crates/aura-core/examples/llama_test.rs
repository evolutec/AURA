use aura_core::engine::selector::EngineManager;
use aura_core::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor, Modality, Role};
use std::path::Path;

fn main() {
    let model_path = r"C:\Users\evolu\.lmstudio\models\Perso\llama\llama3.2-1b.gguf";
    if !Path::new(model_path).exists() {
        println!("Model not found: {model_path}");
        return;
    }

    let model = ModelDescriptor {
        id: "llama-3.2-1b-local".into(),
        name: "Llama 3.2 1B (local GGUF)".into(),
        family: "llama".into(),
        kind: EngineKind::Llama,
        modalities: vec![Modality::Text],
        params_b: 1.2,
        quant: "Q4".into(),
        size_mb: 1260,
        ram_required_mb: 1_600,
        license: "Llama-3.2".into(),
        source: "local".into(),
        path: Some(model_path.into()),
    };

    let mut mgr = EngineManager::new();
    mgr.ensure_model(&model).expect("load model");
    println!("Loaded: {}", mgr.current_model().unwrap().name);

    let msgs = vec![ChatMessage { role: Role::User, content: "Say hello in one short sentence.".into() }];
    let params = GenerationParams { max_tokens: 64, temperature: 0.7, ..Default::default() };

    print!("Assistant: ");
    let mut acc = String::new();
    mgr.generate(&msgs, &params, &mut |tok: &str| {
        print!("{tok}");
        acc.push_str(tok);
    }).expect("generate");
    println!("\n\n--- {} chars ---", acc.len());

    // Embedding
    let emb = mgr.embed("AURA portable core").expect("embed");
    println!("Embedding dim={} first={:?}", emb.len(), &emb[..emb.len().min(4)]);
}
