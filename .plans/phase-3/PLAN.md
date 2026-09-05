# Phase 3: Native FFI & PC-Library Linker (`pack-ffi-pc-libraries`)

**Phase**: `pack-ffi-pc-libraries`  
**Tier**: Tier 1 (Standard)  
**Owns**: `pack/src/ffi_linker.asl`, `pack/tests/ffi_test.asl`, `pack/tests/ffi.test.js`  
**Prerequisites**: `pack-standalone-bundler` (Done)

---

## 1. Work Items

### Item 1: Native FFI & PC Library Resolver in ASL
- **Files**: `pack/src/ffi_linker.asl`
- **Specification**:
  - `LibraryType`: enum (`lib-dynamic`, `lib-static`, `lib-framework`)
  - `NativeLibrarySpec`:
    - `name`: Str (e.g. "sqlite3", "portaudio")
    - `type`: `LibraryType`
    - `pkg-config-name`: Str
    - `header-include`: Str
  - `ResolvedLinkerFlags`:
    - `lib-flags`: (List Str) (e.g. `["-lsqlite3"]` or `["sqlite3.lib"]`)
    - `include-flags`: (List Str)
    - `shared-lib-name`: Str (e.g. `"libsqlite3.dylib"`, `"libsqlite3.so"`, `"sqlite3.dll"`)
  - Implement `resolve-library-target [(spec NativeLibrarySpec) (plat plat/PlatformDescriptor)] -> ResolvedLinkerFlags`.
  - Export in `:x [...]`.
- **Failing Gate**: Calling `ffi/resolve-library-target` fails until declared.

### Item 2: Unit Tests
- **Files**: `pack/tests/ffi_test.asl`, `pack/tests/ffi.test.js`
- **Specification**:
  - Verify library name resolution across macOS, Linux, and Windows for dynamic, static, and Apple Framework libraries.
- **Verification Gate**:
  ```bash
  asl/.venv/bin/python -c "import sys; from pathlib import Path; sys.path.insert(0, 'asl/checker'); from resolve import check_file; roots = [Path('pack/src'), Path('asl/grammar/corpus/modules')]; diags = check_file(Path('pack/src/ffi_linker.asl'), roots); sys.exit(len(diags))"
  node --test pack/tests/ffi.test.js
  ```
