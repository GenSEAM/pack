# ASL-Pack Orchestrator Decision Log

**Workspace**: `/Users/purplelephant/projects/asex/pack`  
**Orchestrator**: Antigravity  
**Protocol**: `steps` (`/Users/purplelephant/.gemini/config/skills/steps/SKILL.md`)

---

## Decisions & Invariants

### 1. Invariant: Separation of Packager from Core Language
- The `asl` repo owns the language grammar, AST, checker, and compiler.
- The `pack` repo owns packaging, standalone executable generation, Wasm runtime recommendations, target platform binaries, and external native bridges (Swift, Kotlin, C-ABI).
- This keeps `asl` 100% platform-agnostic, mathematical, and lightweight.

### 2. Decision: Append/Self-Contained Runner Executable Format
- Standalone executables are produced by pairing a minimal static runner stub with compiled bytecode and an ASN metadata header.
- Zero external dependencies required on target machines (macOS, Linux, Windows).

### 3. Decision: Complete Python Eradication
- All bootstrap scripts (`asl/agentscript`, `checker/gate.py`, etc.) are to be decommissioned and replaced by native `asl` binaries.
- Virtual environment `.venv` will be permanently removed once native self-hosted gates pass cleanly.

---

## Phase Dispatch Record

| Phase | Tier | Dispatched To | Gate Result | Notes |
|---|---|---|---|---|
| (Baseline) | Tier 0 | Direct | Green | Initialized `@genseam/asl-pack`, runtime matrix, and platform triples |
| `pack-standalone-bundler` | Tier 1 | Direct | Green | Fixed 16-byte trailer ("ASLPACK!"), bundle inspector, macOS codesign |
| `pack-selfhost-asl-cli` | Tier 1 | Direct | Green | Pure ASL CLI & gate runner in `asl/bin/asl`, zero-python launcher |
| `pack-ffi-pc-libraries` | Tier 1 | Direct | Green | Native FFI library resolver (.dylib/.so/.dll), framework and Windows flags |
| `pack-mobile-targets` | Tier 1 | Direct | Green | Swift Package (AOT) for iOS and Kotlin JNI (WAMR) for Android |
| `pack-decommission-python` | Tier 1 | Direct | Green | Pure self-hosted CLI parity verified, zero python dependency for dev gates |
