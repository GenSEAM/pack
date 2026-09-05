# Phase 1: Standalone Single-Binary Bundler (`pack-standalone-bundler`)

**Phase**: `pack-standalone-bundler`  
**Tier**: Tier 1 (Standard)  
**Owns**: `pack/src/standalone.asl`, `pack/templates/`, `pack/tests/standalone_test.asl`, `pack/tests/standalone.test.js`  
**Prerequisites**: Baseline (Done)

---

## 1. Architectural Intent & Gaps Closed
- Implements GAP-1 from `pack/.plans/GAPS.md`: produces standalone zero-dependency executables by attaching Wasm bytecode and ASN metadata to precompiled runner stubs.
- Invariant: Fixed 16-byte footer (`[payload_bytes] + [u64 length (8 bytes)] + [MAGIC: "ASLPACK!" (8 bytes)]`).
- Invariant: Automatic ad-hoc code-signing (`codesign -s -`) for macOS Mach-O binaries to satisfy Apple Silicon AMFI.

---

## 2. Work Items

### Item 1: Standalone Binary Packaging Logic in ASL
- **Files**: `pack/src/standalone.asl`
- **Specification**:
  - `MAGIC_FOOTER`: Str `"ASLPACK!"` (8 bytes).
  - Define `StandaloneBundleConfig`:
    - `runner-stub-path`: Str
    - `wasm-payload-path`: Str
    - `manifest-header`: Str
    - `output-binary-path`: Str
    - `platform`: `plat/PlatformDescriptor`
  - Implement `format-footer [(payload-len I64)] -> Str`:
    Encodes 8-byte length + 8-byte magic.
  - Implement `build-bundle-spec [(cfg StandaloneBundleConfig)] -> Str`.
  - Export in `:x [...]`.
- **Failing Gate**: Calling `s/format-footer` fails until declared.

### Item 2: Node.js Host Packaging Driver & Runner Stub
- **Files**: `pack/bridges/bundler.js`
- **Specification**:
  - Concatenates `[runner_binary] + [wasm_payload] + [metadata] + [footer_16_bytes]`.
  - On macOS: runs `codesign -s - <output_path>` and `chmod +x <output_path>`.
  - On Linux/Windows: ensures executable permissions and validates footer integrity.

### Item 3: Unit Tests
- **Files**: `pack/tests/standalone_test.asl`, `pack/tests/standalone.test.js`
- **Specification**:
  - Test footer encoding, payload length extraction, and roundtrip bundle verification.
- **Verification Gate**:
  ```bash
  asl/.venv/bin/python -c "import sys; from pathlib import Path; sys.path.insert(0, 'asl/checker'); from resolve import check_file; roots = [Path('pack/src'), Path('asl/grammar/corpus/modules')]; diags = check_file(Path('pack/src/standalone.asl'), roots); sys.exit(len(diags))"
  node --test pack/tests/standalone.test.js
  ```
