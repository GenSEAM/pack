(module asl-pack/standalone-test
  :d "Unit tests for standalone binary packaging, footer layouts, and codesigning invariants."
  :x [run-tests]
  :i [(standalone :a s)
      (platform :a plat)])

(df test-footer-constants [] -> Bool
  :d "Verifies fixed 16-byte footer and magic identifier."
  (do
    (assert (= (s/magic-footer) "ASLPACK!") "Magic footer must equal ASLPACK!")
    (assert (= (s/footer-size-bytes) 16) "Footer size bytes must equal 16")
    true))

(df test-codesign-evaluation [] -> Bool
  :d "Verifies that macOS targets require codesigning while Linux/Windows do not."
  (let [(p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (p-lin (plat/make-platform (plat/os-linux) (plat/arch-x64)))
        (p-win (plat/make-platform (plat/os-windows) (plat/arch-x64)))]
    (assert (s/requires-codesign? p-mac) "macOS platform must require codesigning")
    (assert (not (s/requires-codesign? p-lin)) "Linux platform must not require codesigning")
    (assert (not (s/requires-codesign? p-win)) "Windows platform must not require codesigning")
    true))

(df test-bundle-manifest-planning [] -> Bool
  :d "Verifies standalone bundle planning across target descriptors."
  (let [(p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (cfg (s/StandaloneBundleConfig
               :runner-stub-path "templates/runner"
               :wasm-payload-path "dist/app.wasm"
               :manifest-header "@pack:{v1}"
               :output-binary-path "dist/app-bin"
               :platform p-mac))
        (manifest (s/plan-standalone-bundle cfg 4096))]
    (assert (= (.-payload-size manifest) 4096) "Payload size must equal 4096")
    (assert (= (.-footer-magic manifest) "ASLPACK!") "Footer magic must equal ASLPACK!")
    (assert (.-requires-codesign manifest) "Manifest must require codesign")
    true))

(df run-tests [] -> Bool
  :d "Executes standalone packaging test suites."
  (do
    (assert (test-footer-constants) "test-footer-constants must pass")
    (assert (test-codesign-evaluation) "test-codesign-evaluation must pass")
    (assert (test-bundle-manifest-planning) "test-bundle-manifest-planning must pass")
    true))
