(module asl-pack/tests/standalone_test
  :d "Unit test suite for standalone executable packaging, magic footer, and AMFI codesigning."
  :x [test-footer-specs
      test-codesign-detection]
  :i [(standalone :a st)
      (platform :a plat)])

(df test-footer-specs [] -> Bool
  :d "Verifies canonical 8-byte magic footer and 16-byte fixed trailer footprint."
  (and
    (string-equals? (st/magic-footer) "ASLPACK!")
    (== (st/footer-size-bytes) 16)))

(df test-codesign-detection [] -> Bool
  :d "Verifies that macOS target platform activates mandatory ad-hoc codesigning."
  (let [(macos-p (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (linux-p (plat/make-platform (plat/os-linux) (plat/arch-x64)))]
    (and
      (st/requires-codesign? macos-p)
      (not (st/requires-codesign? linux-p)))))
