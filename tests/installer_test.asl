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
    (assert (string-contains? d "<!-- ASL_TOOLBELT_START -->") "Directive must contain start tag")
    (assert (string-contains? d "asl-toolbelt") "Directive must reference asl-toolbelt")
    (assert (string-contains? d "<!-- ASL_TOOLBELT_END -->") "Directive must contain end tag")
    true))

(df test-slash-commands [] -> Bool
  :d "Verifies /asl and /asl build slash command contents"
  (let [(cmd-asl (inst/format-slash-asl))
        (cmd-build (inst/format-slash-asl-build))]
    (assert (string-contains? cmd-asl "description: Activate AgentScript (ASL) toolchain") "Slash asl must have description")
    (assert (string-contains? cmd-asl "asl rpc '(:batch ...)'") "Slash asl must reference asl rpc")
    (assert (string-contains? cmd-build "asl rpc '(:batch") "Slash asl build must reference batch rpc")
    (assert (string-contains? cmd-build "Full 7 gates: `asl gate`") "Slash asl build must mention full 7 gates")
    true))

(df test-agent-platforms [] -> Bool
  :d "Verifies all 7 agent platforms are configured with correct paths"
  (let [(platforms (inst/default-agent-platforms "/home/user"))]
    (assert (= (list-length platforms) 7) "Must configure 7 agent platforms")
    (assert (string-contains? (inst/format-toolbelt-directive) "toolbelt") "Directive must contain toolbelt")
    true))

(df test-sanitize-and-inject [] -> Bool
  :d "Verifies instruction sanitization and idempotent directive injection"
  (let [(legacy-text "## tokensave\nlegacy configuration\n")
        (sanitized (inst/sanitize-instruction-text legacy-text))
        (empty-injected (inst/inject-instruction-directive ""))
        (already-injected (inst/inject-instruction-directive (inst/format-toolbelt-directive)))]
    (assert (string-contains? sanitized "<!-- ASL_TOOLBELT_START -->") "Sanitized text must contain toolbelt directive")
    (assert (string-contains? empty-injected "<!-- ASL_TOOLBELT_START -->") "Empty injected must contain start tag")
    (assert (string-contains? already-injected "asl-toolbelt") "Already injected must contain toolbelt")
    true))

(df test-plan-installation [] -> Bool
  :d "Verifies installation planning across agents"
  (let [(cfg (inst/make-installer-config true false true "all"))
        (platforms (inst/default-agent-platforms "/Users/test"))
        (plan (inst/plan-agent-installation cfg platforms))]
    (assert (= (list-length (.-detected-agents plan)) 7) "Must detect 7 agents")
    (assert (> (list-length (.-target-rule-files plan)) 0) "Must have target rule files")
    (assert (> (list-length (.-target-skills-dirs plan)) 0) "Must have target skills dirs")
    (assert (= (list-length (.-slash-commands plan)) 2) "Must have 2 slash commands")
    true))

(df test-emit-installer-script [] -> Bool
  :d "Verifies standalone installer shell script generation"
  (let [(cfg (inst/make-installer-config true false true "all"))
        (script (inst/emit-standalone-installer-script cfg))]
    (assert (string-contains? script "#!/bin/bash") "Script must have bash shebang")
    (assert (string-contains? script "Running pure AgentScript Multi-Agent Skills Setup") "Script must announce setup")
    (assert (string-contains? script "AGENTS.md") "Script must reference AGENTS.md")
    (assert (string-contains? script "TOOLBELT_DIRECTIVE") "Script must define TOOLBELT_DIRECTIVE")
    true))

(df run-tests [] -> Bool
  :d "Executes complete installer test suite"
  (do
    (assert (test-toolbelt-directive) "test-toolbelt-directive must pass")
    (assert (test-slash-commands) "test-slash-commands must pass")
    (assert (test-agent-platforms) "test-agent-platforms must pass")
    (assert (test-sanitize-and-inject) "test-sanitize-and-inject must pass")
    (assert (test-plan-installation) "test-plan-installation must pass")
    (assert (test-emit-installer-script) "test-emit-installer-script must pass")
    true))
