(module asl-pack/platform
  :d "Cross-platform operating system, architecture, and executable target descriptor registry."
  :x [TargetOs
      TargetArch
      PlatformDescriptor
      make-platform
      target-triple
      format-binary-name
      is-windows?
      is-macos?
      is-linux?]
  :i [])

(dfe TargetOs
  (:c os-macos [] "Apple Darwin / macOS")
  (:c os-linux [] "Linux (GNU / musl)")
  (:c os-windows [] "Microsoft Windows"))

(dfe TargetArch
  (:c arch-arm64 [] "ARM64 / AArch64 (Apple Silicon, AWS Graviton)")
  (:c arch-x64 [] "x86_64 / AMD64"))

(dfs PlatformDescriptor
  (:f os TargetOs "Target operating system family")
  (:f arch TargetArch "Target CPU instruction set architecture")
  (:f triple Str "Standard LLVM target triple")
  (:f executable-extension Str "Executable file suffix")
  (:f shared-lib-extension Str "Dynamic shared library suffix"))

(df target-triple [(os TargetOs) (arch TargetArch)] -> Str
  :d "Computes standard LLVM target triple for OS and architecture pair."
  (mt os
    ((os-macos)
     (mt arch
       ((arch-arm64) "aarch64-apple-darwin")
       ((arch-x64) "x86_64-apple-darwin")))
    ((os-linux)
     (mt arch
       ((arch-arm64) "aarch64-unknown-linux-gnu")
       ((arch-x64) "x86_64-unknown-linux-gnu")))
    ((os-windows)
     (mt arch
       ((arch-arm64) "aarch64-pc-windows-msvc")
       ((arch-x64) "x86_64-pc-windows-msvc")))))

(df make-platform [(os TargetOs) (arch TargetArch)] -> PlatformDescriptor
  :d "Constructs platform specification record with canonical file extensions."
  (let [(triple (target-triple os arch))
        (exe-ext (mt os
                   ((os-windows) ".exe")
                   ((os-macos) "")
                   ((os-linux) "")))
        (lib-ext (mt os
                   ((os-macos) ".dylib")
                   ((os-linux) ".so")
                   ((os-windows) ".dll")))]
    (PlatformDescriptor
      :os os
      :arch arch
      :triple triple
      :executable-extension exe-ext
      :shared-lib-extension lib-ext)))

(df format-binary-name [(pkg-name Str) (plat PlatformDescriptor)] -> Str
  :d "Formats artifact executable filename with platform suffix and extension."
  (str pkg-name "-" (.-triple plat) (.-executable-extension plat)))

(df is-windows? [(plat PlatformDescriptor)] -> Bool
  :d "Returns true if platform target is Microsoft Windows."
  (mt (.-os plat)
    ((os-windows) true)
    ((os-macos) false)
    ((os-linux) false)))

(df is-macos? [(plat PlatformDescriptor)] -> Bool
  :d "Returns true if platform target is Apple macOS."
  (mt (.-os plat)
    ((os-macos) true)
    ((os-windows) false)
    ((os-linux) false)))

(df is-linux? [(plat PlatformDescriptor)] -> Bool
  :d "Returns true if platform target is Linux."
  (mt (.-os plat)
    ((os-linux) true)
    ((os-macos) false)
    ((os-windows) false)))
