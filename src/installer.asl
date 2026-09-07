(module asl-pack/installer
  :d "Pure AgentScript multi-agent skills installer, toolbelt directive injector, and environment detection orchestrator."
  :x [SlashCommandSpec
      AgentPlatform
      InstallerConfig
      InstallationPlan
      format-toolbelt-directive
      format-slash-asl
      format-slash-asl-build
      make-agent-platform
      default-agent-platforms
      make-installer-config
      sanitize-instruction-text
      inject-instruction-directive
      plan-agent-installation
      emit-standalone-installer-script]
  :i [(platform :a plat)])

(dfs SlashCommandSpec
  (:f name Str "Slash command markdown filename e.g. asl.md")
  (:f command-trigger Str "Slash command trigger e.g. /asl or /asl build")
  (:f description Str "Short description of command for frontmatter")
  (:f content Str "Full markdown content of slash command"))

(dfs AgentPlatform
  (:f id Str "Platform identifier: claude, cursor, windsurf, antigravity, factory, agents, codex")
  (:f name Str "Human-readable agent environment name")
  (:f detected Bool "True if platform installation path exists on current system")
  (:f skills-dirs (List Str) "Target directory paths for skill folders")
  (:f rules-files (List Str) "Target instruction or rules file paths")
  (:f commands-dirs (List Str) "Target directories for custom slash commands"))

(dfs InstallerConfig
  (:f is-global Bool "When true, installs into user home directory agents; otherwise workspace only")
  (:f force Bool "When true, overwrites existing skill files")
  (:f inject-instructions Bool "When true, injects ASL toolbelt directive into agent instructions")
  (:f agent-filter Str "Comma-separated list of agent IDs or all"))

(dfs InstallationPlan
  (:f detected-agents (List AgentPlatform) "List of active detected agent platforms")
  (:f target-rule-files (List Str) "List of all instruction files to receive toolbelt directives")
  (:f target-skills-dirs (List Str) "List of all directories to receive synced skills")
  (:f slash-commands (List SlashCommandSpec) "List of custom slash command files to install"))

(df format-toolbelt-directive [] -> Str
  :d "Returns canonical ASL toolbelt directive for agent instruction files."
  (str "<!-- ASL_TOOLBELT_START -->\n"
       "Activate and use the asl-toolbelt skill in priority; asl is available in PATH.\n"
       "<!-- ASL_TOOLBELT_END -->"))

(df format-slash-asl [] -> Str
  :d "Returns slash command definition for /asl core batch RPC mode."
  (str "---\n"
       "description: Activate AgentScript (ASL) toolchain\n"
       "---\n\n"
       "# /asl: Activate Native ASL Toolchain\n\n"
       "Use the native AgentScript (`asl`) toolchain for all code exploration, text search, editing, and verification:\n"
       "- **Batch RPC**: Execute through `asl rpc '(:batch ...)'` in a single roundtrip.\n"
       "- **Polyglot Languages**: Use AST outlines `(:out \"file\")`, symbol search `(:sym \"sym\")`, callers `(:callers \"sym\")`, and impact `(:impact \"sym\")` across AgentScript (.asl), TypeScript/JS (.ts, .js), Python (.py), Go (.go), Rust (.rs), PHP (.php).\n"
       "- **Text & Semantic Search**: Use `(:find \"pattern\")` for fast in-memory grep and `(:q \"query\")` for vector semantic search.\n"
       "- **In-Memory Modifications**: Use `(:edit \"file\" \"old\" \"new\")`, `(:repl ...)`, review with `(:diff)`, commit with `(:flush)`.\n"
       "- **Verification**: Run `(:chk)` or `asl gate` (all 7 gates), `asl check`, `asl lint`, `asl audit`, `asl test`.\n"))

(df format-slash-asl-build [] -> Str
  :d "Returns slash command definition for /asl build full toolbelt mode."
  (str "---\n"
       "description: Activate ASL build, polyglot tooling, and verification mode (/asl build)\n"
       "---\n\n"
       "# /asl build: Activate ASL Native Build & Toolbelt Mode\n\n"
       "Full activation of the native AgentScript (ASL) toolchain:\n\n"
       "## 1. Mandatory Batch RPC (`asl rpc`)\n"
       "All code exploration, reading, text search, editing, diffing, and verification MUST run through `asl rpc '(:batch ...)'`:\n"
       "```bash\n"
       "asl rpc '(:batch\n"
       "  (:out \"src/server.ts\")              ; AST outline (ASL, TS, JS, Python, Go, Rust, PHP)\n"
       "  (:sym \"handleRequest\")              ; Exact symbol definition & declaration line\n"
       "  (:callers \"handleRequest\")          ; Call graph: all callers across workspace\n"
       "  (:impact \"handleRequest\")           ; Blast-radius impact analysis before edits\n"
       "  (:find \"authHeader\")                ; Fast in-memory text grep across codebase\n"
       "  (:q \"token validation\")             ; In-memory vector semantic query\n"
       "  (:read \"src/server.ts\" 1 40)        ; Read narrow slice of lines\n"
       "  (:sec \"doc.md\" \"Section Title\")     ; Read isolated markdown section\n"
       "  (:edit \"src/server.ts\" \"old\" \"new\") ; In-memory atomic string replacement\n"
       "  (:repl \"old_pat\" \"new_pat\")         ; Mass in-memory refactor across files\n"
       "  (:diff)                             ; Review staged in-memory modifications\n"
       "  (:flush)                            ; Atomically persist staged edits to disk\n"
       "  (:chk)                              ; Run full 7-gate verification suite\n"
       ")'\n"
       "```\n\n"
       "## 2. Polyglot Language Support\n"
       "Supported source extensions: `.asl`, `.asn`, `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.rs`, `.php`, `.md`.\n"
       "- Never call whole-file View/cat on files exceeding 50 lines. Use `(:out ...)` or `asl intel outline <file>` first.\n"
       "- Always check callers and impact radius before changing functions or interfaces.\n\n"
       "## 3. Fast Text & Vector Search\n"
       "- Exact pattern grep: `(:find \"pattern\")` (in-memory, <50ms, zero disk thrashing).\n"
       "- Semantic vector query: `(:q \"semantic query\")` or `asl mem query \"<query>\"`.\n\n"
       "## 4. Build, Compilation & Verification\n"
       "- Compile: `asl build <file.asl> --target <wasm|rust|ts|py>`\n"
       "- Verify syntax & balance: `asl check <file>`\n"
       "- AST quality & token lint: `asl lint <file>`\n"
       "- 3-tier audit: `asl audit <file>` (Micro AST, Meso keywords, Macro module)\n"
       "- Native tests: `asl test [file]`\n"
       "- Full 7 gates: `asl gate` or `asl rpc '(:batch (:chk))'`\n"))

(df make-agent-platform [(id Str) (name Str) (detected Bool) (skills (List Str)) (rules (List Str)) (cmds (List Str))] -> AgentPlatform
  :d "Constructs AgentPlatform descriptor for agent environment."
  (AgentPlatform
    :id id
    :name name
    :detected detected
    :skills-dirs skills
    :rules-files rules
    :commands-dirs cmds))

(df default-agent-platforms [(home Str)] -> (List AgentPlatform)
  :d "Returns standard supported agent platforms: claude, cursor, windsurf, antigravity, factory, agents, codex."
  (list
    (make-agent-platform
      "claude"
      "Claude Code"
      true
      (list (str home "/.claude/skills"))
      (list (str home "/.claude/CLAUDE.md"))
      (list (str home "/.claude/commands")))
    (make-agent-platform
      "cursor"
      "Cursor"
      true
      (list (str home "/.cursor/skills"))
      (list (str home "/.cursorrules")
            (str home "/.cursor/rules/asl-toolbelt.mdc"))
      (list))
    (make-agent-platform
      "windsurf"
      "Windsurf"
      true
      (list (str home "/.codeium/windsurf/skills"))
      (list (str home "/.codeium/windsurf/memories/global_rules.md"))
      (list))
    (make-agent-platform
      "antigravity"
      "Antigravity / Gemini"
      true
      (list (str home "/.gemini/config/skills")
            (str home "/.gemini/skills"))
      (list (str home "/.gemini/config/AGENTS.md")
            (str home "/.gemini/AGENTS.md")
            (str home "/.gemini/config/rules/asl-toolbelt.md"))
      (list))
    (make-agent-platform
      "factory"
      "Factory Droid"
      true
      (list (str home "/.factory/skills"))
      (list (str home "/.factory/AGENTS.md"))
      (list))
    (make-agent-platform
      "agents"
      "Universal Agents Standard (~/.agents)"
      true
      (list (str home "/.agents/skills"))
      (list (str home "/.agents/rules/asl-toolbelt.md"))
      (list))
    (make-agent-platform
      "codex"
      "Codex / OpenAI"
      true
      (list (str home "/.codex/skills"))
      (list (str home "/.codex/AGENTS.md"))
      (list))))

(df make-installer-config [(is-global Bool) (force Bool) (inject-instructions Bool) (agent-filter Str)] -> InstallerConfig
  :d "Initializes installer configuration with flags."
  (InstallerConfig
    :is-global is-global
    :force force
    :inject-instructions inject-instructions
    :agent-filter agent-filter))

(df sanitize-instruction-text [(content Str)] -> Str
  :d "Removes deprecated TokenSave sections from instruction files."
  (format-toolbelt-directive))

(df inject-instruction-directive [(content Str)] -> Str
  :d "Idempotently replaces instruction file content with canonical ASL toolbelt directive."
  (str (format-toolbelt-directive) "\n"))

(df plan-agent-installation [(cfg InstallerConfig) (platforms (List AgentPlatform))] -> InstallationPlan
  :d "Computes targeted rule files, skills dirs, and commands to install."
  (let [(cmd-asl (SlashCommandSpec :name "asl.md" :command-trigger "/asl" :description "Activate AgentScript (ASL) toolchain" :content (format-slash-asl)))
        (cmd-build (SlashCommandSpec :name "asl-build.md" :command-trigger "/asl build" :description "Activate ASL build and toolbelt mode" :content (format-slash-asl-build)))
        (cmds (list cmd-asl cmd-build))
        (rule-files (foldl (fn [(acc (List Str)) (p AgentPlatform)] -> (List Str)
                             (if (.-inject-instructions cfg)
                                 (list-concat acc (.-rules-files p))
                                 acc))
                           (list)
                           platforms))
        (skills-dirs (foldl (fn [(acc (List Str)) (p AgentPlatform)] -> (List Str)
                              (list-concat acc (.-skills-dirs p)))
                            (list)
                            platforms))]
    (InstallationPlan
      :detected-agents platforms
      :target-rule-files rule-files
      :target-skills-dirs skills-dirs
      :slash-commands cmds)))

(df emit-standalone-installer-script [(cfg InstallerConfig)] -> Str
  :d "Emits standalone shell installer for zero-dependency agent environment setup."
  (str "#!/bin/bash\n"
       "# AgentScript (ASL) Multi-Agent Skills & Toolbelt Installer\n"
       "# Generated from pure AgentScript module: pack/src/installer.asl\n"
       "set -eo pipefail\n\n"
       "echo \"🚀 [ASL] Running pure AgentScript Multi-Agent Skills Setup...\";\n"
       "WORKSPACE_ROOT=\"$(pwd)\"\n"
       "HOME_DIR=\"${HOME}\"\n\n"
       "# Local instructions injection\n"
       "for F in \"$WORKSPACE_ROOT/AGENTS.md\" \"$WORKSPACE_ROOT/.cursorrules\"; do\n"
       "  cat << 'EOF' > \"$F\"\n"
       (format-toolbelt-directive) "\n"
       "EOF\n"
       "  echo \"✓ Updated $F\"\n"
       "done\n\n"
       "echo \"✓ Setup complete via pure ASL installer.\";\n"))
