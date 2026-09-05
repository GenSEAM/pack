# Phase 5: Python Decommissioning & End-to-End Self-Hosting (`pack-decommission-python`)

**Phase**: `pack-decommission-python`  
**Tier**: Tier 1 (Standard)  
**Owns**: `asl/bin/asl`, `asl/agentscript`, `pack/bridges/asl_runner.js`, `pack/.plans/STATUS.md`  
**Prerequisites**: `pack-selfhost-asl-cli` (Done), `pack-ffi-pc-libraries` (Done), `pack-mobile-targets` (Done)

---

## 1. Architectural Intent & Gaps Closed
- Implements GAP-5 from `pack/.plans/GAPS.md`: complete transition to self-hosted AgentScript binary execution across developer tools, gates, and tests.
- Establishes standalone `asl` binary as default launcher for all 13 repositories.

---

## 2. Work Items

### Item 1: Complete Subcommand Parity in `asl_runner.js`
- **Files**: `pack/bridges/asl_runner.js`
- **Specification**:
  - Support `test`, `check`, `gate`, `build`, `parse`, `version`, `help`.
  - Ensure zero Python requirement for all standard development tasks.

### Item 2: Replace `asl/agentscript` with Native ASL Launcher
- **Files**: `asl/agentscript`
- **Specification**:
  - Direct executable delegating to `pack/bridges/asl_runner.js`.

### Item 3: End-to-End Workspace Verification Gate
- Run:
  ```bash
  asl/bin/asl version
  asl/bin/asl check pack/src/pack.asl
  asl/bin/asl gate pack/src/runtime.asl pack/src/platform.asl pack/src/pack.asl
  python3 tools/sync_workspace.py --check
  ```
