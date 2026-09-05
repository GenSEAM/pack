(module asl-pack/test
  :d "Unit tests for runtime matrix recommendations, platform descriptors, and packaging plans."
  :x [run-tests]
  :i [(runtime :a rt)
      (platform :a plat)
      (pack :a pk)])

(df test-runtime-recommendation-cli [] -> Bool
  :d "Verifies CLI environment selects Wasmtime JIT for high throughput and SIMD."
  (let [(profile (rt/recommend-runtime-profile (rt/env-cli) true false))]
    (and (.-supports-simd profile)
         (and (= (rt/runtime-name (.-runtime profile)) "Wasmtime (Cranelift)")
              (= (rt/mode-name (.-mode profile)) "JIT (Just-In-Time)")))))

(df test-runtime-recommendation-ios [] -> Bool
  :d "Verifies iOS environment enforces Apple App Store compliant AOT without JIT."
  (let [(profile (rt/recommend-runtime-profile (rt/env-mobile-ios) true false))]
    (and (.-apple-appstore-compliant profile)
         (and (= (rt/runtime-name (.-runtime profile)) "LLVM / Cranelift AOT Native")
              (= (rt/mode-name (.-mode profile)) "AOT (Ahead-Of-Time)")))))

(df test-runtime-recommendation-android [] -> Bool
  :d "Verifies Android environment selects compact WAMR AOT engine."
  (let [(profile (rt/recommend-runtime-profile (rt/env-mobile-android) true false))]
    (and (.-apple-appstore-compliant profile)
         (= (rt/runtime-name (.-runtime profile)) "WAMR (Intel Micro Runtime)"))))

(df test-platform-windows [] -> Bool
  :d "Verifies Windows platform target adds .exe and generates PC triple."
  (let [(p (plat/make-platform (plat/os-windows) (plat/arch-x64)))
        (bin-name (plat/format-binary-name "asl" p))]
    (and (plat/is-windows? p)
         (and (= (.-executable-extension p) ".exe")
              (and (= (.-shared-lib-extension p) ".dll")
                   (string-ends-with? bin-name "x86_64-pc-windows-msvc.exe"))))))

(df test-platform-macos-arm64 [] -> Bool
  :d "Verifies macOS Apple Silicon target configuration."
  (let [(p (plat/make-platform (plat/os-macos) (plat/arch-arm64)))]
    (and (plat/is-macos? p)
         (and (= (.-triple p) "aarch64-apple-darwin")
              (and (= (.-executable-extension p) "")
                   (= (.-shared-lib-extension p) ".dylib"))))))

(df test-plan-package [] -> Bool
  :d "Verifies end-to-end packaging plan generation and ASN manifest serialization."
  (let [(p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (spec (pk/BuildSpec
                :app-name "asl"
                :version "0.3.0"
                :entry-module "src/cli.asl"
                :target-platform p-mac
                :environment (rt/env-cli)
                :strict-no-jit false
                :embed-wasm true))
        (artifact (pk/plan-package spec))
        (manifest (pk/generate-packaging-manifest artifact))]
    (and (= (.-target-triple artifact) "aarch64-apple-darwin")
         (and (string-contains? (.-binary-name artifact) "asl-aarch64-apple-darwin")
              (and (string-contains? manifest "@pack:{asl-aarch64-apple-darwin")
                   (string-contains? manifest "|Wasmtime (Cranelift)|"))))))

(df run-tests [] -> Bool
  :d "Executes all packaging and runtime test suites."
  (fold (fn [(acc Bool) (p Bool)] -> Bool (and acc p))
        true
        (list (test-runtime-recommendation-cli)
              (test-runtime-recommendation-ios)
              (test-runtime-recommendation-android)
              (test-platform-windows)
              (test-platform-macos-arm64)
              (test-plan-package))))
