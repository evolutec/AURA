/**
 * AURA portable native core — stable C ABI.
 *
 * Consume from Flutter (dart:ffi), Kotlin Multiplatform (cinterop), Tauri, C/C++...
 *
 * Memory contract:
 *  - Any `char*` returned here MUST be freed with `aura_string_free`.
 *  - Opaque handles MUST be freed with their matching `*_free`.
 *  - On error, functions returning a string/pointer return NULL; call
 *    `aura_last_error` (then free it) for details.
 *  - `aura_session_create` borrows `engine`: the engine must outlive the session.
 */
#ifndef AURA_CORE_H
#define AURA_CORE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AuraEngine AuraEngine;
typedef struct AuraSession AuraSession;

/** Streaming token callback. `token` is only valid during the call. */
typedef void (*AuraTokenCb)(const char *token, void *user_data);

/* --- version / errors --------------------------------------------------- */
const char *aura_version(void);
void        aura_string_free(char *s);
char       *aura_last_error(void);

/* --- hardware / catalog ------------------------------------------------- */
/** JSON of HardwareCaps { os, arch, cpu_name, cores, total_ram_mb, available_ram_mb, backends[], npu } */
char *aura_hardware_json(void);
/** JSON array of all catalog ModelDescriptor. */
char *aura_catalog_json(void);
/** JSON array of catalog models compatible with detected hardware (512 MB headroom). */
char *aura_catalog_compatible_json(void);

/* --- engine ------------------------------------------------------------- */
AuraEngine *aura_engine_create(const char *model_id);
char       *aura_engine_loaded_model(AuraEngine *engine);
char       *aura_engine_generate(AuraEngine *engine, const char *prompt, const char *params_json);
char       *aura_engine_generate_stream(AuraEngine *engine, const char *prompt,
                                        const char *params_json, AuraTokenCb cb, void *user_data);
/** JSON array of f32 embedding values. */
char       *aura_engine_embed(AuraEngine *engine, const char *text);
void        aura_engine_unload(AuraEngine *engine);
void        aura_engine_free(AuraEngine *engine);

/* --- session ------------------------------------------------------------ */
AuraSession *aura_session_create(AuraEngine *engine, const char *system_prompt);
char        *aura_session_send(AuraSession *session, const char *text, const char *params_json);
/** JSON array of ChatMessage { role, content }. */
char        *aura_session_messages_json(AuraSession *session);
void         aura_session_free(AuraSession *session);

#ifdef __cplusplus
}
#endif

#endif /* AURA_CORE_H */
