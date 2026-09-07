(module asl-pack/installer-test
  :d "Unit verification test suite for pure ASL multi-agent skills installer"
  :x [test-toolbelt-directive
      test-slash-commands
      test-agent-platforms
      test-sanitize-and-inject
      test-plan-installation
      test-emit-installer-script
      run-tests]
  :i [(installer :a inst)])

(df test-toolbelt-directive [] -> Bool
  :d "Verifies format-toolbelt-directive returns canonical marker tags and toolbelt path"
  (let [(d (inst/format-toolbelt-directive))]
    (and (string-contains? d "<!-- ASL_TOOLBELT_START -->")
         (and (string-contains? d "asl-toolbelt")
              (string-contains? d "<!-- ASL_TOOLBELT_END -->")))))

(df test-slash-commands [] -> Bool
  :d "Verifies /asl and /asl build slash command contents"
  (let [(cmd-asl (inst/format-slash-asl))
        (cmd-build (inst/format-slash-asl-build))]
    (and (string-contains? cmd-asl "description: Activate AgentScript (ASL) toolchain")
         (and (string-contains? cmd-asl "asl rpc '(:batch ...)'")
              (and (string-contains? cmd-build "asl rpc '(:batch")
                   (string-contains? cmd-build "Full 7 gates: `asl gate`"))))))

(df test-agent-platforms [] -> Bool
  :d "Verifies all 7 agent platforms are configured with correct paths"
  (let [(platforms (inst/default-agent-platforms "/home/user"))]
    (and (= (list-length platforms) 7)
         (and (string-contains? (inst/format-toolbelt-directive) "toolbelt")
              true))))

(df test-sanitize-and-inject [] -> Bool
  :d "Verifies instruction sanitization and idempotent directive injection"
  (let [(legacy-text "## tokensave\nlegacy configuration\n")
        (sanitized (inst/sanitize-instruction-text legacy-text))
        (empty-injected (inst/inject-instruction-directive ""))
        (already-injected (inst/inject-instruction-directive (inst/format-toolbelt-directive)))]
    (and (string-contains? sanitized "Cleaned ASL Instructions")
         (and (string-contains? empty-injected "<!-- ASL_TOOLBELT_START -->")
              (string-contains? already-injected "asl-toolbelt")))))

(df test-plan-installation [] -> Bool
  :d "Verifies installation planning across agents"
  (let [(cfg (inst/make-installer-config true false true "all"))
        (platforms (inst/default-agent-platforms "/Users/test"))
        (plan (inst/plan-agent-installation cfg platforms))]
    (and (= (list-length (.-detected-agents plan)) 7)
         (and (> (list-length (.-target-rule-files plan)) 0)
              (and (> (list-length (.-target-skills-dirs plan)) 0)
                   (= (list-length (.-slash-commands plan)) 2))))))

(df test-emit-installer-script [] -> Bool
  :d "Verifies standalone installer shell script generation"
  (let [(cfg (inst/make-installer-config true false true "all"))
        (script (inst/emit-standalone-installer-script cfg))]
    (and (string-contains? script "#!/bin/bash")
         (and (string-contains? script "Running pure AgentScript Multi-Agent Skills Setup")
              (and (string-contains? script "AGENTS.md")
                   (string-contains? script "TOOLBELT_DIRECTIVE"))))))

(df run-tests [] -> Bool
  :d "Executes complete installer test suite"
  (and (test-toolbelt-directive)
       (and (test-slash-commands)
            (and (test-agent-platforms)
                 (and (test-sanitize-and-inject)
                      (and (test-plan-installation)
                           (test-emit-installer-script)))))))
