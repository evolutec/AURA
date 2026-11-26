use aura_core::engine::selector::EngineManager;
use aura_core::model::ModelRegistry;
use aura_core::types::{ChatMessage, EngineKind, Modality, Role};
use aura_core::hardware;

#[test]
fn hardware_detects_ram() {
    let hw = hardware::detect();
    assert!(hw.total_ram_mb > 0, "total RAM should be detected");
    assert!(hw.available_ram_mb > 0, "available RAM should be detected");
    assert!(!hw.backends.is_empty(), "at least CPU backend");
    assert!(hw.backends.contains(&aura_core::types::Backend::Cpu));
}

#[test]
fn mock_engine_generates_and_streams() {
    let reg = ModelRegistry::with_builtin_catalog();
    let model = reg.get("aura-mock-1b").cloned().unwrap();
    let mut mgr = EngineManager::new();
    mgr.ensure_model(&model).unwrap();
    assert!(mgr.is_loaded());

    let msgs = vec![ChatMessage { role: Role::User, content: "hi".into() }];
    let params = aura_core::types::GenerationParams::default();
    let mut chunks = 0usize;
    let out = mgr.generate(&msgs, &params, &mut |_t| { chunks += 1; }).unwrap();
    assert!(!out.is_empty());
    assert!(chunks > 0, "should stream at least one chunk");
}

#[test]
fn ram_guard_rejects_oversized_model() {
    // Force a model that needs more RAM than available by overriding headroom.
    let mut mgr = EngineManager::new().with_headroom(u64::MAX / 2);
    let reg = ModelRegistry::with_builtin_catalog();
    let big = reg.get("llama-3.1-8b-q4").cloned().unwrap();
    // With absurd headroom, even a small-ish model should be rejected.
    let res = mgr.ensure_model(&big);
    assert!(res.is_err(), "should reject when not enough RAM");
}

#[test]
fn catalog_filters_by_modality() {
    let hw = hardware::detect();
    let reg = ModelRegistry::with_builtin_catalog();
    let text_models = reg.compatible(&hw, &[Modality::Text], 0);
    assert!(!text_models.is_empty());
    for m in &text_models {
        assert!(m.supports_all(&[Modality::Text]));
    }
}

#[test]
fn engine_kind_roundtrip() {
    assert_eq!(EngineKind::Llama.as_str(), "llama");
    assert_eq!(EngineKind::Mock.as_str(), "mock");
}
