(module asl-pack/test
  :d "Unit tests for runtime matrix recommendations, platform descriptors, and packaging plans."
  :x [run-tests]
  :i [(runtime :a rt)
      (platform :a plat)
      (pack :a pk)])

(df test-runtime-recommendation-cli [] -> Bool
  :d "Verifies CLI environment selects Wasmtime JIT for high throughput and SIMD."
  (let [(profile (rt/recommend-runtime-profile (rt/env-cli) true false))]
    (assert (.-supports-simd profile) "CLI profile must support SIMD")
    (assert (= (rt/runtime-name (.-runtime profile)) "Wasmtime (Cranelift)") "Runtime must be Wasmtime")
    (assert (= (rt/mode-name (.-mode profile)) "JIT (Just-In-Time)") "Mode must be JIT")
    true))

(df test-runtime-recommendation-ios [] -> Bool
  :d "Verifies iOS environment enforces Apple App Store compliant AOT without JIT."
  (let [(profile (rt/recommend-runtime-profile (rt/env-mobile-ios) true false))]
    (assert (.-apple-appstore-compliant profile) "iOS profile must be App Store compliant")
    (assert (= (rt/runtime-name (.-runtime profile)) "LLVM / Cranelift AOT Native") "iOS runtime must be AOT Native")
    (assert (= (rt/mode-name (.-mode profile)) "AOT (Ahead-Of-Time)") "iOS mode must be AOT")
    true))

(df test-runtime-recommendation-android [] -> Bool
  :d "Verifies Android environment selects compact WAMR AOT engine."
  (let [(profile (rt/recommend-runtime-profile (rt/env-mobile-android) true false))]
    (assert (.-apple-appstore-compliant profile) "Android profile must be compliant")
    (assert (= (rt/runtime-name (.-runtime profile)) "WAMR (Intel Micro Runtime)") "Android runtime must be WAMR")
    true))

(df test-platform-windows [] -> Bool
  :d "Verifies Windows platform target adds .exe and generates PC triple."
  (let [(p (plat/make-platform (plat/os-windows) (plat/arch-x64)))
        (bin-name (plat/format-binary-name "asl" p))]
    (assert (plat/is-windows? p) "Platform must be Windows")
    (assert (= (.-executable-extension p) ".exe") "Extension must be .exe")
    (assert (= (.-shared-lib-extension p) ".dll") "Shared lib extension must be .dll")
    (assert (string-ends-with? bin-name "x86_64-pc-windows-msvc.exe") "Binary name must end with triple exe")
    true))

(df test-platform-macos-arm64 [] -> Bool
  :d "Verifies macOS Apple Silicon target configuration."
  (let [(p (plat/make-platform (plat/os-macos) (plat/arch-arm64)))]
    (assert (plat/is-macos? p) "Platform must be macOS")
    (assert (= (.-triple p) "aarch64-apple-darwin") "Triple must be aarch64-apple-darwin")
    (assert (= (.-executable-extension p) "") "Executable extension must be empty")
    (assert (= (.-shared-lib-extension p) ".dylib") "Shared lib extension must be .dylib")
    true))

(df test-plan-package [] -> Bool
  :d "Verifies end-to-end packaging plan generation and ASN manifest serialization."
  (let [(p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (spec (pk/BuildSpec
                :app-name "asl"
                :version "0.1.0"
                :entry-module "src/cli.asl"
                :target-platform p-mac
                :environment (rt/env-cli)
                :strict-no-jit false
                :embed-wasm true))
        (artifact (pk/plan-package spec))
        (manifest (pk/generate-packaging-manifest artifact))]
    (assert (= (.-target-triple artifact) "aarch64-apple-darwin") "Artifact triple must match")
    (assert (string-contains? (.-binary-name artifact) "asl-aarch64-apple-darwin") "Binary name must match")
    (assert (string-contains? manifest "@pack:{asl-aarch64-apple-darwin") "Manifest must contain pack header")
    (assert (string-contains? manifest "|Wasmtime (Cranelift)|") "Manifest must contain runtime name")
    true))

(df run-tests [] -> Bool
  :d "Executes all packaging and runtime test suites."
  (do
    (assert (test-runtime-recommendation-cli) "test-runtime-recommendation-cli must pass")
    (assert (test-runtime-recommendation-ios) "test-runtime-recommendation-ios must pass")
    (assert (test-runtime-recommendation-android) "test-runtime-recommendation-android must pass")
    (assert (test-platform-windows) "test-platform-windows must pass")
    (assert (test-platform-macos-arm64) "test-platform-macos-arm64 must pass")
    (assert (test-plan-package) "test-plan-package must pass")
    true))
