(module asl-pack/standalone-test
  :d "Unit tests for standalone binary packaging, footer layouts, and codesigning invariants."
  :x [run-tests]
  :i [(standalone :a s)
      (platform :a plat)])

(df test-footer-constants [] -> Bool
  :d "Verifies fixed 16-byte footer and magic identifier."
  (and (= (s/magic-footer) "ASLPACK!")
       (= (s/footer-size-bytes) 16)))

(df test-codesign-evaluation [] -> Bool
  :d "Verifies that macOS targets require codesigning while Linux/Windows do not."
  (let [(p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (p-lin (plat/make-platform (plat/os-linux) (plat/arch-x64)))
        (p-win (plat/make-platform (plat/os-windows) (plat/arch-x64)))]
    (and (s/requires-codesign? p-mac)
         (and (not (s/requires-codesign? p-lin))
              (not (s/requires-codesign? p-win))))))

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
    (and (= (.-payload-size manifest) 4096)
         (and (= (.-footer-magic manifest) "ASLPACK!")
              (.-requires-codesign manifest)))))

(df run-tests [] -> Bool
  :d "Executes standalone packaging test suites."
  (fold (fn [(acc Bool) (p Bool)] -> Bool (and acc p))
        true
        (list (test-footer-constants)
              (test-codesign-evaluation)
              (test-bundle-manifest-planning))))
