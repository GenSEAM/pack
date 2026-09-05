(module asl-pack/runtime
  :d "WebAssembly runtime decision matrix: profiling JIT, AOT, and Interpreted engines for CLI, Mobile, Server, and Embedded."
  :x [WasmRuntimeKind
      TargetEnvironment
      ExecutionMode
      RuntimeProfile
      runtime-name
      mode-name
      profile-for-runtime
      recommend-runtime-profile]
  :i [])

(dfe WasmRuntimeKind
  (:c rt-wasmtime [] "Bytecode Alliance Cranelift JIT / WASI p1-p2, SIMD-128, threads")
  (:c rt-wamr [] "WebAssembly Micro Runtime (Intel): small footprint, interpreter/AOT/JIT")
  (:c rt-wasm3 [] "Pure C interpreter: zero JIT allocation, instant boot, strict sandboxing")
  (:c rt-v8-node [] "Embedded V8 / Node.js / Bun runtime with full JS host environment")
  (:c rt-browser-native [] "Standard browser WebAssembly engine")
  (:c rt-aot-native [] "Direct Ahead-of-Time native machine code compilation via LLVM/Cranelift"))

(dfe TargetEnvironment
  (:c env-cli [] "Developer terminal tools and single-executable CLIs")
  (:c env-server [] "Cloud servers, container microVMs, high-throughput daemons")
  (:c env-mobile-ios [] "iOS native applications (strict Apple App Store no-JIT policy)")
  (:c env-mobile-android [] "Android native applications (JNI / NDK)")
  (:c env-browser [] "Web client applications and browser copilot extensions")
  (:c env-embedded [] "Microcontrollers, IoT devices, severe RAM limits < 1MB"))

(dfe ExecutionMode
  (:c mode-jit [] "Dynamic Just-in-Time compilation to native machine code")
  (:c mode-aot [] "Ahead-of-Time compiled static native object code")
  (:c mode-interpreted [] "Pure bytecode interpreter without dynamic executable memory"))

(dfs RuntimeProfile
  (:f runtime WasmRuntimeKind "Selected WebAssembly runtime engine")
  (:f mode ExecutionMode "Execution compilation strategy")
  (:f supports-simd Bool "Hardware SIMD-128 vector instruction support")
  (:f apple-appstore-compliant Bool "Complies with Apple App Store executable memory restrictions")
  (:f cold-start-ms F64 "Estimated runtime bootstrap latency in milliseconds")
  (:f binary-overhead-mb F64 "Static engine footprint added to bundle in megabytes")
  (:f recommendation-notes Str "Rationale for selection in target deployment environment"))

(df runtime-name [(rt WasmRuntimeKind)] -> Str
  :d "Returns human-readable moniker for Wasm runtime engine."
  (mt rt
    ((rt-wasmtime) "Wasmtime (Cranelift)")
    ((rt-wamr) "WAMR (Intel Micro Runtime)")
    ((rt-wasm3) "Wasm3 (Fast C Interpreter)")
    ((rt-v8-node) "V8 / Node Embed")
    ((rt-browser-native) "Browser Native Engine")
    ((rt-aot-native) "LLVM / Cranelift AOT Native")))

(df mode-name [(m ExecutionMode)] -> Str
  :d "Returns human-readable moniker for execution strategy."
  (mt m
    ((mode-jit) "JIT (Just-In-Time)")
    ((mode-aot) "AOT (Ahead-Of-Time)")
    ((mode-interpreted) "Interpreted (Zero-JIT)")))

(df profile-for-runtime [(rt WasmRuntimeKind) (mode ExecutionMode)] -> RuntimeProfile
  :d "Calculates operational profile characteristics for a given runtime and mode combination."
  (mt rt
    ((rt-wasmtime)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd true
       :apple-appstore-compliant false
       :cold-start-ms 1.5
       :binary-overhead-mb 12.0
       :recommendation-notes "Best-in-class performance for CLI and server. High throughput, SIMD-128, and robust WASI preview2."))
    ((rt-wamr)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd true
       :apple-appstore-compliant true
       :cold-start-ms 0.2
       :binary-overhead-mb 0.8
       :recommendation-notes "Intel WAMR: ultra-compact footprint (<1MB), multi-tier AOT/interpreter, optimal for Android and mobile."))
    ((rt-wasm3)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd false
       :apple-appstore-compliant true
       :cold-start-ms 0.05
       :binary-overhead-mb 0.15
       :recommendation-notes "Wasm3: instant cold start (<0.05ms), tiny 150KB footprint, zero JIT allocation. Ideal for strict sandbox/iOS."))
    ((rt-v8-node)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd true
       :apple-appstore-compliant false
       :cold-start-ms 15.0
       :binary-overhead-mb 35.0
       :recommendation-notes "V8 / Node: rich JS ecosystem integration, fast JIT, higher binary footprint."))
    ((rt-browser-native)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd true
       :apple-appstore-compliant true
       :cold-start-ms 0.01
       :binary-overhead-mb 0.0
       :recommendation-notes "Zero-bundle overhead; leverages browser-resident WebAssembly JIT engine directly."))
    ((rt-aot-native)
     (RuntimeProfile
       :runtime rt
       :mode mode
       :supports-simd true
       :apple-appstore-compliant true
       :cold-start-ms 0.001
       :binary-overhead-mb 1.5
       :recommendation-notes "Direct native machine code emission. 100% Apple App Store compliant, zero runtime compilation overhead."))))

(df is-ios? [(env TargetEnvironment)] -> Bool
  :d "Checks if environment is iOS."
  (mt env
    ((env-mobile-ios) true)
    ((env-cli) false)
    ((env-server) false)
    ((env-mobile-android) false)
    ((env-browser) false)
    ((env-embedded) false)))

(df recommend-runtime-profile [(env TargetEnvironment) (needs-simd Bool) (strict-no-jit Bool)] -> RuntimeProfile
  :d "Applies deterministic heuristics to select the optimal Wasm runtime engine and execution strategy."
  (if (or strict-no-jit (is-ios? env))
    (if needs-simd
      (profile-for-runtime (rt-aot-native) (mode-aot))
      (profile-for-runtime (rt-wasm3) (mode-interpreted)))
    (mt env
      ((env-cli)
       (profile-for-runtime (rt-wasmtime) (mode-jit)))
      ((env-server)
       (profile-for-runtime (rt-wasmtime) (mode-jit)))
      ((env-mobile-ios)
       (profile-for-runtime (rt-aot-native) (mode-aot)))
      ((env-mobile-android)
       (profile-for-runtime (rt-wamr) (mode-aot)))
      ((env-browser)
       (profile-for-runtime (rt-browser-native) (mode-jit)))
      ((env-embedded)
       (profile-for-runtime (rt-wasm3) (mode-interpreted))))))
