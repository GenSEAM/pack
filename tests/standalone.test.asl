(module asl-pack/tests/standalone_test
  :d "Unit test suite for standalone executable packaging, magic footer, and AMFI codesigning."
  :x [test-footer-specs
      test-codesign-detection
      run-tests]
  :i [(standalone :a st)
      (platform :a plat)])

(df test-footer-specs [] -> Bool
  :d "Verifies canonical 8-byte magic footer and 16-byte fixed trailer footprint."
  (do
    (assert (string-equals? (st/magic-footer) "ASLPACK!") "Magic footer must equal ASLPACK!")
    (assert (== (st/footer-size-bytes) 16) "Footer size bytes must equal 16")
    true))

(df test-codesign-detection [] -> Bool
  :d "Verifies that macOS target platform activates mandatory ad-hoc codesigning."
  (let [(macos-p (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (linux-p (plat/make-platform (plat/os-linux) (plat/arch-x64)))]
    (assert (st/requires-codesign? macos-p) "macOS must require codesigning")
    (assert (not (st/requires-codesign? linux-p)) "Linux must not require codesigning")
    true))

(df run-tests [] -> Bool
  :d "Executes standalone test specs."
  (do
    (assert (test-footer-specs) "test-footer-specs must pass")
    (assert (test-codesign-detection) "test-codesign-detection must pass")
    true))
