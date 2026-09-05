# Phase 2: Native Self-Hosted ASL CLI & Gate Runner (`pack-selfhost-asl-cli`)

**Phase**: `pack-selfhost-asl-cli`  
**Tier**: Tier 1 (Standard)  
**Owns**: `asl/packages/asl-cli/`, `asl/packages/asl-gates/`, `asl/bin/asl`, `pack/bridges/asl_runner.js`  
**Prerequisites**: `pack-standalone-bundler` (Done)

---

## 1. Architectural Intent & Gaps Closed
- Implements GAP-2 from `pack/.plans/GAPS.md`: establishes pure self-hosted AgentScript CLI (`asl`) and gate runner, removing reliance on `gate.py` and Python dispatchers.
- Bridges pure ASL CLI (`asl-cli/src/cli.asl`) and gates (`asl-gates/src/gates.asl`) into an executable launcher `asl/bin/asl`.

---

## 2. Work Items

### Item 1: Gate Subcommand in Pure ASL CLI
- **Files**: `asl/packages/asl-cli/src/cli.asl`
- **Specification**:
  - Add `gate` subcommand delegating to `gates/run-suite`.
  - Add imports `(gates :a gts)`.
  - Support `asl gate <files...>`: prints clean green summary or failure list with non-zero exit.

### Item 2: Self-Contained ASL CLI Driver & Executable
- **Files**: `pack/bridges/asl_runner.js`, `asl/bin/asl`
- **Specification**:
  - Implement zero-python launcher `asl/bin/asl` running the compiled ASL toolchain.
  - Supports `check`, `gate`, `build`, `parse`, `version`, `help`.
  - Exits with 0 when clean, non-zero when diagnostics exist.

### Item 3: Verification Gate
- Run:
  ```bash
  asl/.venv/bin/python -c "import sys; from pathlib import Path; sys.path.insert(0, 'asl/checker'); from resolve import check_file; roots = [Path('asl/packages/asl-cli/src'), Path('asl/packages/asl-gates/src'), Path('asl/grammar/corpus/modules')]; diags = check_file(Path('asl/packages/asl-cli/src/cli.asl'), roots); sys.exit(len(diags))"
  node pack/bridges/asl_runner.js check pack/src/pack.asl
  node pack/bridges/asl_runner.js version
  ```
