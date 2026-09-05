# Phase 4: Mobile Target Bridges (`pack-mobile-targets`)

**Phase**: `pack-mobile-targets`  
**Tier**: Tier 1 (Standard)  
**Owns**: `pack/src/targets/swift.asl`, `pack/src/targets/kotlin.asl`, `pack/tests/mobile_test.asl`, `pack/tests/mobile.test.js`  
**Prerequisites**: `pack-standalone-bundler` (Done)

---

## 1. Work Items

### Item 1: Swift Package & iOS AOT Bridge Generator
- **Files**: `pack/src/targets/swift.asl`
- **Specification**:
  - `SwiftPackageSpec`:
    - `pkg-name`: Str
    - `ios-min-version`: Str (e.g. "15.0")
    - `macos-min-version`: Str (e.g. "12.0")
    - `c-bridge-header`: Str
  - Implement `generate-package-swift [(spec SwiftPackageSpec)] -> Str`.
  - Implement `generate-c-bridge-header [(pkg-name Str)] -> Str`.
  - Export in `:x [...]`.

### Item 2: Kotlin Multiplatform & Android JNI Generator
- **Files**: `pack/src/targets/kotlin.asl`
- **Specification**:
  - `KotlinTargetSpec`:
    - `package-id`: Str (e.g. "io.genseam.asl")
    - `class-name`: Str (e.g. "ASLAgent")
  - Implement `generate-jni-binding [(spec KotlinTargetSpec)] -> Str`.
  - Implement `generate-gradle-dependency [(spec KotlinTargetSpec)] -> Str`.
  - Export in `:x [...]`.

### Item 3: Unit Tests
- **Files**: `pack/tests/mobile_test.asl`, `pack/tests/mobile.test.js`
- **Specification**:
  - Verify generated `Package.swift`, C-bridge header, JNI bindings, and Gradle config.
- **Verification Gate**:
  ```bash
  asl/.venv/bin/python -c "import sys; from pathlib import Path; sys.path.insert(0, 'asl/checker'); from resolve import check_file; roots = [Path('pack/src'), Path('asl/grammar/corpus/modules')]; diags = [check_file(p, roots) for p in [Path('pack/src/targets/swift.asl'), Path('pack/src/targets/kotlin.asl'), Path('pack/tests/mobile_test.asl')]]; sys.exit(sum(len(d) for d in diags))"
  node --test pack/tests/mobile.test.js
  ```
