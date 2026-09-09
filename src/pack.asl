(module asl-pack/pack
  :d "Universal cross-platform packaging orchestrator for standalone AgentScript executables and libraries."
  :x [BuildSpec
      PackageArtifact
      plan-package
      generate-packaging-manifest]
  :i [(runtime :a rt)
      (platform :a plat)])

(dfs BuildSpec
  (:f app-name Str "Application or toolchain binary name")
  (:f version Str "Semver release version string")
  (:f entry-module Str "Root ASL entrypoint module path")
  (:f target-platform plat/PlatformDescriptor "Target OS and CPU architecture")
  (:f environment rt/TargetEnvironment "Target deployment environment")
  (:f strict-no-jit Bool "Enforces Ahead-of-Time or interpreted execution without dynamic JIT")
  (:f embed-wasm Bool "Embeds compiled WebAssembly bytecode directly into runner payload"))

(dfs PackageArtifact
  (:f binary-name Str "Canonical output executable name")
  (:f target-triple Str "Target LLVM platform triple")
  (:f runtime-name Str "Configured WebAssembly runtime engine")
  (:f execution-mode Str "Selected compilation or interpretation strategy")
  (:f output-path Str "Destination directory or file path"))

(df plan-package [(spec BuildSpec)] -> PackageArtifact
  :d "Resolves runtime profile, platform triple, and produces deterministic packaging plan."
  (let [(p (.-target-platform spec))
        (bin-name (plat/format-binary-name (.-app-name spec) p))
        (profile (rt/recommend-runtime-profile (.-environment spec) true (.-strict-no-jit spec)))
        (rt-str (rt/runtime-name (.-runtime profile)))
        (mode-str (rt/mode-name (.-mode profile)))
        (out-path (str "dist/" bin-name))]
    (PackageArtifact
      :binary-name bin-name
      :target-triple (.-triple p)
      :runtime-name rt-str
      :execution-mode mode-str
      :output-path out-path)))

(df generate-packaging-manifest [(artifact PackageArtifact)] -> Str
  :d "Serializes package artifact plan into standard ASN metadata header."
  (str "pack:{"
       (.-binary-name artifact) "|"
       (.-target-triple artifact) "|"
       (.-runtime-name artifact) "|"
       (.-execution-mode artifact) "|"
       (.-output-path artifact) "}"))
