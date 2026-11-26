use std::io::{self, BufRead, Write};

use aura_core::engine::selector::EngineManager;
use aura_core::types::{
    ChatMessage, EngineKind, GenerationParams, ModelDescriptor, Modality, Role,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: aura-server <model.gguf>");
        std::process::exit(1);
    }
    let path = args[1].clone();
    let name = std::path::Path::new(&path)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("model")
        .to_string();

    let model = ModelDescriptor {
        id: name.clone(),
        name: name.clone(),
        family: "llama".into(),
        kind: EngineKind::Llama,
        modalities: vec![Modality::Text],
        params_b: 0.0,
        quant: String::new(),
        size_mb: 0,
        ram_required_mb: 0,
        license: String::new(),
        source: "local".into(),
        path: Some(path),
    };

    let mut mgr = EngineManager::new();
    if let Err(e) = mgr.ensure_model(&model) {
        eprintln!("load error: {e}");
        std::process::exit(1);
    }
    println!("READY");
    let _ = io::stdout().flush();

    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut history: Vec<ChatMessage> = Vec::new();
    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        if line.trim().is_empty() {
            continue;
        }
        if line.trim() == "quit" {
            break;
        }
        if line.trim() == "sleep" {
            mgr.sleep();
            let mut lock = stdout.lock();
            let _ = writeln!(lock, "OK");
            let _ = lock.flush();
            continue;
        }
        let v: serde_json::Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(_) => continue,
        };
        let prompt = v["prompt"].as_str().unwrap_or("");
        let max_tokens = v["max_tokens"].as_u64().unwrap_or(64) as u32;
        let reasoning = v["reasoning"].as_bool().unwrap_or(false);
        let params = GenerationParams {
            max_tokens,
            ..Default::default()
        };
        let final_prompt = if reasoning {
            format!("/think\n{}", prompt)
        } else {
            format!("/no_think\n{}", prompt)
        };
        history.push(ChatMessage { role: Role::User, content: final_prompt.clone() });
        let mut out = String::new();
        let res = mgr.generate(&history, &params, &mut |tok: &str| out.push_str(tok));
        let mut lock = stdout.lock();
        match res {
            Ok(_) => {
                let cleaned = strip_think(&out);
                history.push(ChatMessage { role: Role::Assistant, content: cleaned.clone() });
                let _ = writeln!(lock, "{}", serde_json::json!({ "text": cleaned }));
            }
            Err(e) => {
                let _ = writeln!(lock, "{}", serde_json::json!({ "error": e.to_string() }));
            }
        }
        let _ = lock.flush();
    }
}

/// Remove reasoning blocks and stray think tags from a model response.
///
/// Handles both `<...>` and `<|...|>` style tags. Never returns an empty
/// string: if stripping would remove everything, the raw text is returned so
/// the chat always shows a reply.
fn strip_think(out: &str) -> String {
    let open = ["<", "think>"].concat();
    let open_alt = ["<", "|think>"].concat();
    let close = ["<", "/think>"].concat();
    let close_alt = ["<", "|/think>"].concat();

    let mut s = out.to_string();
    for (open, close) in [(&open, &close), (&open_alt, &close_alt)] {
        loop {
            let start = match s.find(open.as_str()) {
                Some(i) => i,
                None => break,
            };
            let rel = match s[start + open.len()..].find(close.as_str()) {
                Some(i) => i,
                None => break,
            };
            let end = start + open.len() + rel + close.len();
            s.replace_range(start..end, "");
        }
    }
    for tag in [open.as_str(), close.as_str(), open_alt.as_str(), close_alt.as_str()] {
        s = s.replace(tag, "");
    }
    let trimmed = s.trim();
    if trimmed.is_empty() {
        out.trim().to_string()
    } else {
        trimmed.to_string()
    }
}