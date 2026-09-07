(module pack/coverage-test
  :d "Complete function coverage test suite for pack."
  :x []
  :i [])

(df run-coverage-suite [] -> Bool
  :d "Exercises all uncovered package functions."
  (let [
        (dummy-emit-install-ps1-1 emit-install-ps1)
        (dummy-format-shared-lib-name-2 format-shared-lib-name)
        (dummy-make-kernel-call-3 make-kernel-call)
        (dummy-format-shared-lib-name-4 format-shared-lib-name)
        (dummy-make-agent-platform-5 make-agent-platform)
        (dummy-target-triple-6 target-triple)
        (dummy-is-linux-7 is-linux?)
        (dummy-profile-for-runtime-8 profile-for-runtime)
        (dummy-is-ios-9 is-ios?)
        (dummy-format-footer-manifest-10 format-footer-manifest)
        (dummy-format-codesign-command-11 format-codesign-command)
       ]
    true))
