use aura_core::engine::selector::EngineManager;
use aura_core::model::ModelRegistry;
use aura_core::types::{ChatMessage, GenerationParams, Modality, Role};

fn main() {
    println!("AURA core v{}", aura_core::VERSION);

    // 1) Hardware detection
    let hw = aura_core::hardware::detect();
    println!("\n== Hardware ==");
    println!("{}", serde_json::to_string_pretty(&hw).unwrap_or_default());

    // 2) Catalog filtered by this machine's specs
    let reg = ModelRegistry::with_builtin_catalog();
    println!("\n== Compatible models (text) ==");
    for m in reg.compatible(&hw, &[Modality::Text], 512) {
        println!(
            "  - {:<28} kind={:<10} {:.1}B  {} MB RAM  [{}]",
            m.name, m.kind.as_str(), m.params_b, m.ram_required_mb, m.quant
        );
    }
    if let Some(r) = reg.recommend(&hw, Modality::Text, 512) {
        println!("  => recommandé : {}", r.name);
    }

    // 3) Engine selection + streaming generation (mock backend)
    println!("\n== Génération (MockEngine, streaming) ==");
    let model = reg.get("aura-mock-1b").cloned().expect("catalog model");
    let mut mgr = EngineManager::new();
    mgr.ensure_model(&model).expect("load model");

    let msgs = vec![ChatMessage { role: Role::User, content: "Bonjour AURA, présente-toi.".into() }];
    let params = GenerationParams::default();
    let mut acc = String::new();
    mgr.generate(&msgs, &params, &mut |tok: &str| {
        print!("{tok}");
        acc.push_str(tok);
    })
    .expect("generate");

    // 4) Embeddings
    let emb = mgr.embed("AURA portable core").expect("embed");
    println!("\n\n== Embedding ==");
    println!("dim={} first={:?}", emb.len(), &emb[..emb.len().min(4)]);

    println!("\nOK: {} caractères générés.", acc.len());
}
