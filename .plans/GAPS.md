# ASL-Pack Gap Audit & Architectural Review

**Audit Date**: 2026-09-05  
**Target Repository**: `@genseam/asl-pack` (`/Users/purplelephant/projects/asex/pack`) & `@genseam/asl` (`/Users/purplelephant/projects/asex/asl`)  
**Review Standard**: Critic (`gap/SKILL.md`) — Zero Python dependency, zero bloat, anti-overengineering, cross-platform parity.  
**Verdict**: **APPROVE-WITH-AMENDMENTS**

---

## 1. Executive Summary

While the AgentScript compiler pipeline (`asl-parser`, `asl-checker`, `asl-codegen`, `asl-gates`, `asl-cli`) is already fully written in pure AgentScript (`.asl`), the developer launcher (`asl/agentscript`), verification gate (`checker/gate.py`), and test runners still depend on a Python 3 virtual environment (`.venv`).

To fulfill the mission of complete self-hosting and zero Python presence, `asl-pack` must package the compiled toolchain into standalone single-binary executables for **macOS (arm64/x64)**, **Linux (x64/arm64)**, and **Windows (x64)**, while providing native bridges for C/PC libraries, Swift, and Kotlin.

---

## 2. Identified Gaps & Required Amendments

### GAP-1: Standalone Single-Binary Executable Packaging
- **Location**: `pack/src/standalone.asl` (to be created)
- **Issue**: Deploying an ASL application or CLI currently requires a host Node or Python runtime.
- **Risk**: High distribution barrier for end users and non-developer machines; non-compliance with zero-dependency mandate.
- **Remediation & Contract**:
  - Implement `pack/src/standalone.asl` appending compiled Wasm bytecode + ASN manifest to lightweight precompiled static runners, emitting zero-dependency standalone executables.
  - **Amendment 1 (Binary Footer Contract)**: To avoid parsing the whole binary from start to end, `standalone.asl` must write a fixed 16-byte footer:
    `[payload_bytes] + [payload_length: u64 big-endian (8 bytes)] + [magic: "ASLPACK!" (8 bytes)]`.
    The runner seeks to `EOF - 16`, validates the magic, reads the length, seeks back, and maps the payload in memory in $O(1)$ time.
  - **Amendment 2 (macOS Ad-hoc Code Signing)**: On macOS (Apple Silicon), mutating an executable by appending data invalidates Mach-O code signatures, triggering `Killed: 9` (AMFI). `standalone.asl` must invoke `codesign -s -` (ad-hoc signing) on the generated Mach-O binary.
  - **Amendment 3 (Windows Subsystem)**: On Windows, ensure console subsystem (`IMAGE_SUBSYSTEM_WINDOWS_CUI`) so standard I/O (stdin/stdout/stderr) connects immediately to `cmd.exe`/PowerShell.

### GAP-2: Native Self-Hosted CLI & Gate Driver
- **Location**: `asl/agentscript`, `asl/checker/gate.py`
- **Issue**: `asl/agentscript` and `asl/checker/gate.py` are written in Python.
- **Risk**: Python remains an ecosystem dependency, violating the primary architectural goal.
- **Remediation**: Compile `packages/asl-cli` and `packages/asl-gates` into native `asl` binary; replace `asl/agentscript` with direct native CLI invocation.

### GAP-3: Native FFI & Dynamic C/PC-Library Resolver
- **Location**: `pack/src/ffi_linker.asl`
- **Issue**: Linking platform-native C libraries (e.g. SQLite, audio codecs, hardware accelerators) requires manual OS-specific flags.
- **Risk**: Platform breakage when building on Windows or Linux without unified library resolution.
- **Remediation**: Implement `pack/src/ffi_linker.asl` to handle `.dylib`, `.so`, `.dll`, pkg-config, and C headers deterministically.

### GAP-4: Mobile Target Bridges (Swift & Kotlin Multiplatform)
- **Location**: `pack/src/targets/swift.asl`, `pack/src/targets/kotlin.asl`
- **Issue**: Mobile apps (iOS and Android) have strict runtime restrictions (Apple forbids JIT; Android uses JNI/NDK).
- **Risk**: Inability to ship AgentScript agents inside native iOS/Android apps.
- **Remediation**: Implement `pack/src/targets/swift.asl` (Swift Package with AOT C-bridge) and `pack/src/targets/kotlin.asl` (Kotlin/JNI bridge with Intel WAMR).

### GAP-5: Decommissioning and Final Python Elimination
- **Location**: `asl/.venv/`, `asl/checker/gate.py`
- **Issue**: Python bootstrap scripts, virtual environment, and lark remnants still occupy disk space in `asl`.
- **Risk**: Regressive re-introduction of Python tooling.
- **Remediation**: Delete `asl/.venv/`, `gate.py`, and Python helper scripts once the self-hosted `asl` binary passes all test fixtures natively.

---

## 3. Anti-Overengineering (Critic Filter)

- **Do NOT compile a massive 200MB LLVM toolchain inside ASL**: Use precompiled static runner stubs and Wasm AOT/JIT backends.
- **Do NOT build a custom C compiler**: Rely on system `clang` / `msvc` via standard CLI invocations for native linking.
- **Do NOT invent a complex proprietary package format**: Standalone executables are standard OS binaries (Mach-O, ELF, PE/COFF) with trailing payload.
- **Do NOT maintain duplicate platform code**: Use `PlatformDescriptor` in `pack/src/platform.asl` as the single source of truth for triples, extensions, and OS flags.

---

## 4. Verdict & Authorization

**Verdict**: **APPROVE-WITH-AMENDMENTS**  
The DAG in `pack/.plans/PHASES.md` is approved. Amendments 1, 2, and 3 are incorporated into Phase 1 (`pack-standalone-bundler`).
Roadmap execution is cleared to proceed.
