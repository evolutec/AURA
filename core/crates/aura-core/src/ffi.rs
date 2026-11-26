//! Stable C ABI. Consumed by Flutter (`dart:ffi`), Kotlin Multiplatform
//! (`cinterop`), Tauri, and any other FFI-capable frontend.
//!
//! Memory contract:
//! - Strings returned as `*mut c_char` MUST be freed with [`aura_string_free`].
//! - Opaque handles (`*mut AuraEngine`, `*mut AuraSession`) MUST be freed with
//!   the matching `*_free` function.
//! - On error, functions returning strings/pointers return NULL; call
//!   [`aura_last_error`] (then free it) for details.
//! - A session borrows its engine: the engine must outlive the session.

use std::cell::RefCell;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_void};
use std::ptr;

use serde::Serialize;

use crate::engine::selector::EngineManager;
use crate::hardware;
use crate::model::ModelRegistry;
use crate::session::ChatSession;
use crate::types::{ChatMessage, EngineKind, GenerationParams, ModelDescriptor, Role};

thread_local! {
    static LAST_ERR: RefCell<Option<String>> = const { RefCell::new(None) };
}

fn set_err(msg: impl Into<String>) {
    LAST_ERR.with(|e| *e.borrow_mut() = Some(msg.into()));
}

fn cstr_to_string(p: *const c_char) -> Option<String> {
    if p.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(p).to_str().ok().map(|s| s.to_string()) }
}

fn json_to_c<T: Serialize>(v: &T) -> *mut c_char {
    match serde_json::to_string(v) {
        Ok(s) => CString::new(s)
            .map(|c| c.into_raw())
            .unwrap_or(ptr::null_mut()),
        Err(e) => {
            set_err(e.to_string());
            ptr::null_mut()
        }
    }
}

fn parse_params(p: *const c_char) -> GenerationParams {
    match cstr_to_string(p) {
        Some(s) if !s.trim().is_empty() => serde_json::from_str(&s).unwrap_or_default(),
        _ => GenerationParams::default(),
    }
}

/// Streaming callback: receives each token chunk and the opaque `user_data`.
pub type AuraTokenCb = extern "C" fn(token: *const c_char, user_data: *mut c_void);

// --- version / errors -------------------------------------------------------

#[no_mangle]
pub extern "C" fn aura_version() -> *mut c_char {
    CString::new("0.1.0").map(|c| c.into_raw()).unwrap_or(ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn aura_string_free(p: *mut c_char) {
    if !p.is_null() {
        unsafe {
            drop(CString::from_raw(p));
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_last_error() -> *mut c_char {
    LAST_ERR.with(|e| {
        let guard = e.borrow();
        match &*guard {
            Some(s) => CString::new(s.as_str()).map(|c| c.into_raw()).unwrap_or(ptr::null_mut()),
            None => ptr::null_mut(),
        }
    })
}

// --- hardware / catalog -----------------------------------------------------

#[no_mangle]
pub extern "C" fn aura_hardware_json() -> *mut c_char {
    let hw = hardware::detect();
    json_to_c(&hw)
}

#[no_mangle]
pub extern "C" fn aura_catalog_json() -> *mut c_char {
    let reg = ModelRegistry::with_builtin_catalog();
    json_to_c(&reg.all().to_vec())
}

/// Catalog filtered by detected hardware (all modalities), keeping 512 MB headroom.
#[no_mangle]
pub extern "C" fn aura_catalog_compatible_json() -> *mut c_char {
    let hw = hardware::detect();
    let reg = ModelRegistry::with_builtin_catalog();
    let owned: Vec<ModelDescriptor> = reg
        .compatible(&hw, &[], 512)
        .into_iter()
        .cloned()
        .collect();
    json_to_c(&owned)
}

// --- engine handle ----------------------------------------------------------

/// Opaque engine handle.
pub struct AuraEngine {
    mgr: EngineManager,
}

#[no_mangle]
pub extern "C" fn aura_engine_create(model_id: *const c_char) -> *mut AuraEngine {
    let id = match cstr_to_string(model_id) {
        Some(s) => s,
        None => {
            set_err("model_id is null");
            return ptr::null_mut();
        }
    };
    let reg = ModelRegistry::with_builtin_catalog();
    let model = match reg.get(&id) {
        Some(m) => m.clone(),
        None => {
            set_err(format!("unknown model id: {id}"));
            return ptr::null_mut();
        }
    };
    let mut mgr = EngineManager::new();
    if let Err(e) = mgr.ensure_model(&model) {
        set_err(e.to_string());
        return ptr::null_mut();
    }
    Box::into_raw(Box::new(AuraEngine { mgr }))
}

#[no_mangle]
pub extern "C" fn aura_engine_create_from_path(path: *const c_char) -> *mut AuraEngine {
    let p = match cstr_to_string(path) {
        Some(s) => s,
        None => {
            set_err("path is null");
            return ptr::null_mut();
        }
    };
    let model = ModelDescriptor {
        id: p.clone(),
        name: p.clone(),
        family: "llama".into(),
        kind: EngineKind::Llama,
        modalities: vec![],
        params_b: 0.0,
        quant: "".into(),
        size_mb: 0,
        ram_required_mb: 0,
        license: "".into(),
        source: "local".into(),
        path: Some(p),
        download_url: None,
        mmproj_url: None,
    };
    let mut mgr = EngineManager::new();
    if let Err(e) = mgr.ensure_model(&model) {
        set_err(e.to_string());
        return ptr::null_mut();
    }
    Box::into_raw(Box::new(AuraEngine { mgr }))
}

#[no_mangle]
pub extern "C" fn aura_engine_loaded_model(engine: *mut AuraEngine) -> *mut c_char {
    if engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let e = unsafe { &*engine };
    match e.mgr.current_model() {
        Some(m) => json_to_c(m),
        None => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn aura_engine_generate(
    engine: *mut AuraEngine,
    prompt: *const c_char,
    params_json: *const c_char,
) -> *mut c_char {
    if engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let e = unsafe { &mut *engine };
    let user = match cstr_to_string(prompt) {
        Some(s) => s,
        None => {
            set_err("prompt is null");
            return ptr::null_mut();
        }
    };
    let params = parse_params(params_json);
    let msgs = vec![ChatMessage { role: Role::User, content: user }];
    match e.mgr.generate(&msgs, &params, &mut |_tok| {}) {
        Ok(s) => CString::new(s).map(|c| c.into_raw()).unwrap_or(ptr::null_mut()),
        Err(err) => {
            set_err(err.to_string());
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_engine_generate_stream(
    engine: *mut AuraEngine,
    prompt: *const c_char,
    params_json: *const c_char,
    cb: Option<AuraTokenCb>,
    user_data: *mut c_void,
) -> *mut c_char {
    if engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let e = unsafe { &mut *engine };
    let user = match cstr_to_string(prompt) {
        Some(s) => s,
        None => {
            set_err("prompt is null");
            return ptr::null_mut();
        }
    };
    let params = parse_params(params_json);
    let msgs = vec![ChatMessage { role: Role::User, content: user }];
    let mut acc = String::new();
    let mut cb = cb;
    let result = e.mgr.generate(&msgs, &params, &mut |tok: &str| {
        acc.push_str(tok);
        if let Some(f) = cb {
            if let Ok(cs) = CString::new(tok) {
                f(cs.as_ptr(), user_data);
            }
        }
    });
    match result {
        Ok(_) => CString::new(acc).map(|c| c.into_raw()).unwrap_or(ptr::null_mut()),
        Err(err) => {
            set_err(err.to_string());
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_engine_embed(engine: *mut AuraEngine, text: *const c_char) -> *mut c_char {
    if engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let e = unsafe { &mut *engine };
    let txt = match cstr_to_string(text) {
        Some(s) => s,
        None => {
            set_err("text is null");
            return ptr::null_mut();
        }
    };
    match e.mgr.embed(&txt) {
        Ok(v) => json_to_c(&v),
        Err(err) => {
            set_err(err.to_string());
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_engine_unload(engine: *mut AuraEngine) {
    if !engine.is_null() {
        unsafe {
            (*engine).mgr.unload();
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_engine_free(engine: *mut AuraEngine) {
    if !engine.is_null() {
        unsafe {
            drop(Box::from_raw(engine));
        }
    }
}

pub struct AuraSession {
    engine: *mut AuraEngine,
    session: ChatSession,
}

#[no_mangle]
pub extern "C" fn aura_session_create(
    engine: *mut AuraEngine,
    system_prompt: *const c_char,
) -> *mut AuraSession {
    if engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let sp = cstr_to_string(system_prompt);
    Box::into_raw(Box::new(AuraSession {
        engine,
        session: ChatSession::new(sp),
    }))
}

#[no_mangle]
pub extern "C" fn aura_session_send(
    session: *mut AuraSession,
    text: *const c_char,
    params_json: *const c_char,
) -> *mut c_char {
    if session.is_null() {
        set_err("session is null");
        return ptr::null_mut();
    }
    let s = unsafe { &mut *session };
    if s.engine.is_null() {
        set_err("engine is null");
        return ptr::null_mut();
    }
    let txt = match cstr_to_string(text) {
        Some(s) => s,
        None => {
            set_err("text is null");
            return ptr::null_mut();
        }
    };
    let params = parse_params(params_json);
    s.session.push_user(txt);
    let e = unsafe { &mut *s.engine };
    match e.mgr.generate(&s.session.messages, &params, &mut |_tok| {}) {
        Ok(resp) => {
            s.session.push_assistant(resp.clone());
            CString::new(resp).map(|c| c.into_raw()).unwrap_or(ptr::null_mut())
        }
        Err(err) => {
            set_err(err.to_string());
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn aura_session_messages_json(session: *mut AuraSession) -> *mut c_char {
    if session.is_null() {
        set_err("session is null");
        return ptr::null_mut();
    }
    let s = unsafe { &*session };
    json_to_c(&s.session.messages)
}

#[no_mangle]
pub extern "C" fn aura_session_free(session: *mut AuraSession) {
    if !session.is_null() {
        unsafe {
            drop(Box::from_raw(session));
        }
    }
}
