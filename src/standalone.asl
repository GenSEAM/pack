(module asl-pack/standalone
  :d "Standalone single-binary executable packager: footer layout, payload mapping, and platform signing."
  :x [StandaloneBundleConfig
      BundleManifest
      magic-footer
      footer-size-bytes
      requires-codesign?
      format-footer-manifest
      format-codesign-command
      plan-standalone-bundle]
  :i [(platform :a plat)])

(df magic-footer [] -> Str
  :d "Canonical 8-byte magic footer identifying an ASL packed executable payload."
  "ASLPACK!")

(df footer-size-bytes [] -> I64
  :d "Fixed footer footprint in bytes: 8 bytes payload length + 8 bytes magic."
  16)

(dfs StandaloneBundleConfig
  (:f runner-stub-path Str "Path to precompiled native runtime runner stub")
  (:f wasm-payload-path Str "Path to compiled WebAssembly bytecode module")
  (:f manifest-header Str "Embedded ASN metadata manifest")
  (:f output-binary-path Str "Destination path for standalone executable")
  (:f platform plat/PlatformDescriptor "Target OS and architecture descriptor"))

(dfs BundleManifest
  (:f entry-name Str "Application entry point identifier")
  (:f payload-size I64 "Size of attached bytecode payload in bytes")
  (:f footer-magic Str "Integrity verification magic string")
  (:f requires-codesign Bool "Flag indicating whether post-bundle ad-hoc signing is required"))

(df requires-codesign? [(p plat/PlatformDescriptor)] -> Bool
  :d "Returns true on macOS where mutating Mach-O requires ad-hoc code-signing."
  (plat/is-macos? p))

(df format-footer-manifest [(payload-size I64) (magic Str)] -> Str
  :d "Formats metadata descriptor for payload footer."
  (str "pack-foot:{" (string-from-int64 payload-size) "|" magic "}"))

(df format-codesign-command [(target-path Str)] -> Str
  :d "Emits ad-hoc codesigning invocation satisfying macOS AMFI."
  (str "codesign -s - --force \"" target-path "\""))

(df plan-standalone-bundle [(cfg StandaloneBundleConfig) (payload-len I64)] -> BundleManifest
  :d "Evaluates bundle configuration and computes packaging requirements."
  (let [(p (.-platform cfg))
        (needs-sign (requires-codesign? p))]
    (BundleManifest
      :entry-name (.-output-binary-path cfg)
      :payload-size payload-len
      :footer-magic (magic-footer)
      :requires-codesign needs-sign)))
