(module asl-pack/mobile-test
  :d "Unit tests for Swift Package Manager and Kotlin Multiplatform bridge generation."
  :x [run-tests]
  :i [(swift :a sw)
      (kotlin :a kt)
      (preview :a prev)
      (lashes :a lsh)
      (preview-server :a ps)])

(df test-swift-package-generation [] -> Bool
  :d "Verifies Package.swift and C-bridge header generation."
  (let [(spec (sw/SwiftPackageSpec
                :pkg-name "ASLKit"
                :ios-min-version "v15"
                :macos-min-version "v12"
                :c-bridge-header "ASLBridge.h"))
        (pkg-swift (sw/generate-package-swift spec))
        (c-hdr (sw/generate-c-bridge-header "ASLKit"))]
    (assert (string-contains? pkg-swift "name: \"ASLKit\"") "Package name must match")
    (assert (string-contains? pkg-swift ".iOS(.v15)") "iOS min version must match")
    (assert (string-contains? c-hdr "typedef struct {") "C bridge must declare struct")
    (assert (string-contains? c-hdr "asl_eval") "C bridge must declare asl_eval")
    true))

(df test-swift-app-and-xcframework-generation [] -> Bool
  :d "Verifies XCFramework script, SwiftUI @main entrypoint, and Swift 6 Observable store generation."
  (let [(app-spec (sw/SwiftAppSpec
                    :app-name "MobileAgent"
                    :bundle-id "io.genseam.mobile"
                    :ios-min-version "v16"
                    :package-name "ASLKit"))
        (xc-script (sw/generate-xcframework-script "ASLKit" "build/xcframework"))
        (app-swift (sw/generate-swiftui-entrypoint "MobileAgent"))
        (store-swift (sw/generate-swift-observable-store "ASLStateStore"))]
    (assert (string-contains? xc-script "xcodebuild -create-xcframework") "XCFramework script must invoke xcodebuild")
    (assert (string-contains? xc-script "generic/platform=iOS Simulator") "XCFramework script must target iOS Simulator")
    (assert (string-contains? xc-script "ASLKit.xcframework") "XCFramework output path must match")
    (assert (string-contains? app-swift "@main") "SwiftUI entrypoint must declare @main")
    (assert (string-contains? app-swift "struct MobileAgentApp: App") "SwiftUI app struct must match")
    (assert (string-contains? app-swift "WindowGroup") "SwiftUI app must include WindowGroup")
    (assert (string-contains? store-swift "@Observable") "State store must use Swift 6 @Observable")
    (assert (string-contains? store-swift "asl_eval") "State store must call asl_eval")
    (assert (string-contains? store-swift "asl_free_buffer") "State store must free buffer")
    true))

(df test-kotlin-jni-generation [] -> Bool
  :d "Verifies Kotlin JNI external class and Gradle dependency generation."
  (let [(spec (kt/KotlinTargetSpec
                :package-id "io.genseam.asl"
                :class-name "ASLAgent"))
        (jni-kt (kt/generate-jni-binding spec))
        (gradle (kt/generate-gradle-dependency spec))]
    (assert (string-contains? jni-kt "package io.genseam.asl") "Kotlin package must match")
    (assert (string-contains? jni-kt "class ASLAgent") "Kotlin class name must match")
    (assert (string-contains? jni-kt "System.loadLibrary(\"asl_wamr_jni\")") "Kotlin must load native lib")
    (assert (string-contains? gradle "implementation(\"io.genseam:asl-wamr-runtime") "Gradle dep must match")
    true))

(df test-kotlin-kmp-and-compose-generation [] -> Bool
  :d "Verifies Kotlin Multiplatform build.gradle.kts, Compose Activity, and StateFlow store generation."
  (let [(app-spec (kt/KotlinAppSpec
                    :package-id "io.genseam.mobile"
                    :app-name "MainActivity"
                    :min-sdk 26
                    :target-sdk 34))
        (kmp-gradle (kt/generate-kmp-build-gradle app-spec))
        (activity-kt (kt/generate-compose-activity app-spec))
        (state-kt (kt/generate-kmp-state-flow "io.genseam.mobile"))]
    (assert (string-contains? kmp-gradle "kotlin(\"multiplatform\")") "KMP gradle must apply multiplatform plugin")
    (assert (string-contains? kmp-gradle "androidTarget()") "KMP gradle must declare androidTarget")
    (assert (string-contains? kmp-gradle "iosArm64()") "KMP gradle must declare iosArm64")
    (assert (string-contains? kmp-gradle "wasmJs { browser() }") "KMP gradle must declare wasmJs browser target")
    (assert (string-contains? kmp-gradle "org.jetbrains.compose") "KMP gradle must apply compose plugin")
    (assert (string-contains? activity-kt "class MainActivity : ComponentActivity()") "Activity must inherit ComponentActivity")
    (assert (string-contains? activity-kt "setContent {") "Activity must call setContent")
    (assert (string-contains? activity-kt "MaterialTheme") "Activity must wrap MaterialTheme")
    (assert (string-contains? state-kt "StateFlow<String>") "State store must expose StateFlow")
    (assert (string-contains? state-kt "MutableStateFlow") "State store must initialize MutableStateFlow")
    true))

(df test-mobile-preview-generation [] -> Bool
  :d "Verifies HTML5 dual-device simulator and Wasm runtime preview manifest generation."
  (let [(prev-spec (prev/MobilePreviewSpec
                     :app-name "ASL Mobile Preview"
                     :default-platform "ios"
                     :enable-hot-reload true
                     :reload-port 8080))
        (html (prev/generate-device-preview-html prev-spec))
        (manifest (prev/generate-preview-wasm-manifest prev-spec))]
    (assert (string-contains? html "<title>ASL Mobile Preview - In-Browser Mobile Preview</title>") "HTML title must match")
    (assert (string-contains? html "dynamic-island") "HTML simulator must contain dynamic island")
    (assert (string-contains? html "device-frame") "HTML simulator must contain device frame")
    (assert (string-contains? html "new WebSocket('ws://localhost:8080')") "HTML simulator must connect WebSocket")
    (assert (string-contains? manifest ":wasm-preview-config") "Wasm manifest must have config header")
    (assert (string-contains? manifest ":platform \"ios\"") "Wasm manifest must match platform")
    (assert (string-contains? manifest ":hot-reload true") "Wasm manifest must enable hot reload")
    (assert (string-contains? manifest ":port 8080") "Wasm manifest must match port")
    true))

(df test-lamy-lashes-enhancement-and-codegen [] -> Bool
  :d "Verifies Lamy Lashes parametric spline computation, low-end GPU memory footprint, and dual-platform view generation."
  (let [(spec (lsh/make-default-lash-spec))
        (p0 (lsh/LashKeypoint2D :x 0.35 :y 0.42 :confidence 0.98))
        (p1 (lsh/LashKeypoint2D :x 0.55 :y 0.43 :confidence 0.97))
        (mesh (lsh/compute-eyelid-spline p0 p1 spec))
        (swift-view (lsh/generate-swiftui-lashes-camera-view "LamyLashes"))
        (compose-view (lsh/generate-compose-lashes-camera-view "io.genseam.lashes"))
        (preview-html (lsh/generate-lashes-preview-html spec))]
    (assert (= (.-lift-angle spec) 65.0) "Default lift angle must be 65.0")
    (assert (> (.-control-points-count mesh) 0) "Control points must be computed")
    (assert (<= (.-memory-overhead-kb mesh) 16) "Static vertex buffer must be <= 16 KB for low-end devices")
    (assert (= (.-estimated-draw-calls mesh) 1) "Must require only 1 batched GPU draw call")
    (assert (string-contains? swift-view "struct LamyLashesLashesCameraView: View") "SwiftUI view struct must match")
    (assert (string-contains? swift-view "60 FPS (Zero-Lag)") "SwiftUI view must display 60 FPS indicator")
    (assert (string-contains? swift-view "Slider(value: $liftAngle, in: 30...85)") "SwiftUI view must have lift angle slider")
    (assert (string-contains? compose-view "fun LamyLashesCameraView()") "Compose view function must match")
    (assert (string-contains? compose-view "Low-End Optimized (12KB RAM)") "Compose view must declare low-end optimization")
    (assert (string-contains? compose-view "CameraX + Parametric Spline Active") "Compose view must declare CameraX spline")
    (assert (string-contains? preview-html "Lamy Lashes: Camera AR Simulator") "Preview HTML must include simulator header")
    (assert (string-contains? preview-html "Toggle Camera / Portrait Mode") "Preview HTML must offer camera toggle")
    (assert (string-contains? preview-html "Parametric Bézier Spline Extrusion") "Preview HTML must document algorithm")
    true))

(df test-landmark-adapters-and-preview-server [] -> Bool
  :d "Verifies landmark adapter resolution across platforms and WebSocket hot-reload server script generation."
  (let [(ios-cfg (lsh/resolve-optimal-landmark-provider "ios" false))
        (android-low (lsh/resolve-optimal-landmark-provider "android" true))
        (android-norm (lsh/resolve-optimal-landmark-provider "android" false))
        (swift-adapter (lsh/generate-landmark-adapter-swift ios-cfg))
        (kotlin-adapter (lsh/generate-landmark-adapter-kotlin android-low))
        (srv-spec (ps/make-preview-server-spec 8080 "scratch"))
        (patch-frame (ps/format-hot-reload-patch-frame "LamyLashes" "<div>updated</div>"))
        (srv-script (ps/generate-preview-server-script srv-spec))]
    (assert (= (.-max-fps ios-cfg) 60) "iOS landmark tracker must target 60 FPS")
    (assert (= (.-min-confidence ios-cfg) 0.85) "iOS landmark confidence must be 0.85")
    (assert (= (.-min-confidence android-low) 0.70) "Low-end Android landmark confidence must be 0.70")
    (assert (string-contains? swift-adapter "class ASLLandmarkTracker") "Swift adapter must declare ASLLandmarkTracker")
    (assert (string-contains? swift-adapter "VNDetectFaceLandmarksRequest") "Swift adapter must use Apple Vision")
    (assert (string-contains? kotlin-adapter "class ASLLandmarkTracker(private val isLowEnd: Boolean)") "Kotlin adapter must support isLowEnd flag")
    (assert (= (.-port srv-spec) 8080) "Server spec port must match 8080")
    (assert (string-contains? patch-frame "\"type\":\"patch\"") "Patch frame must contain patch type")
    (assert (string-contains? patch-frame "LamyLashes") "Patch frame must target LamyLashes")
    (assert (string-contains? srv-script "PORT = 8080") "Server script must configure PORT 8080")
    (assert (string-contains? srv-script "http.createServer") "Server script must create HTTP server")
    true))

(df test-photoreal-shading-and-multieye-tracking [] -> Bool
  :d "Verifies Marschner anisotropic shading parameters, multi-eye frame processing across 1, 2, and 8 eyes, and TikTok effect manifest generation."
  (let [(spec (lsh/make-default-lash-spec))
        (shading (lsh/make-default-photoreal-shading-spec))
        (macro-frame (lsh/MultiEyeDetectionFrame
                       :frame-index 1
                       :timestamp-ms 1000
                       :eyes-count 1
                       :faces-count 1
                       :primary-eye-id 0
                       :is-macro-mode true))
        (dual-frame (lsh/MultiEyeDetectionFrame
                      :frame-index 2
                      :timestamp-ms 1033
                      :eyes-count 2
                      :faces-count 1
                      :primary-eye-id 0
                      :is-macro-mode false))
        (group-frame (lsh/MultiEyeDetectionFrame
                       :frame-index 3
                       :timestamp-ms 1066
                       :eyes-count 8
                       :faces-count 4
                       :primary-eye-id 0
                       :is-macro-mode false))
        (mesh-macro (lsh/process-multi-eye-frame macro-frame spec))
        (mesh-dual (lsh/process-multi-eye-frame dual-frame spec))
        (mesh-group (lsh/process-multi-eye-frame group-frame spec))
        (tiktok-manifest (lsh/generate-tiktok-effect-manifest spec shading))]
    (assert (= (.-shift-alpha shading) -3.5) "Marschner longitudinal cuticular shift must be -3.5")
    (assert (= (.-roughness-beta shading) 0.15) "Marschner roughness beta must be 0.15")
    (assert (= (.-primary-specular-r shading) 0.85) "Primary specular R must be 0.85")
    (assert (= (.-secondary-specular-trt shading) 0.65) "Secondary specular TRT must be 0.65")
    (assert (= (.-root-clumping shading) 0.40) "Root clumping must be 0.40")
    (assert (= (.-sclera-shadow-opacity shading) 0.35) "Sclera contact shadow opacity must be 0.35")
    (assert (= (.-control-points-count mesh-macro) 16) "Macro 1-eye mode must have 16 control points")
    (assert (= (.-control-points-count mesh-dual) 32) "Dual 2-eye mode must have 32 control points")
    (assert (= (.-control-points-count mesh-group) 128) "Group 8-eye mode must have 128 control points")
    (assert (<= (.-memory-overhead-kb mesh-group) 16) "Group 8-eye mode buffer must remain <= 16 KB")
    (assert (= (.-estimated-draw-calls mesh-group) 1) "Group 8-eye mode must batch into 1 GPU draw call")
    (assert (string-contains? tiktok-manifest "\"engine\": \"EffectHouse_3.0\"") "TikTok manifest must specify EffectHouse_3.0")
    (assert (string-contains? tiktok-manifest "\"model\": \"Marschner_KajiyaKay_Hair\"") "TikTok manifest must specify Marschner shading model")
    (assert (string-contains? tiktok-manifest "\"single_eye_macro\"") "TikTok manifest must support single eye macro mode")
    (assert (string-contains? tiktok-manifest "\"multi_person_group\"") "TikTok manifest must support multi person group mode")
    (assert (string-contains? tiktok-manifest "\"oneEuroFilter\"") "TikTok manifest must configure OneEuroFilter")
    (assert (string-contains? tiktok-manifest "dot(vTangent, uLightDir)") "TikTok shader must compute tangent-light dot product")
    true))

(df test-natural-lash-restructuring-and-conversion [] -> Bool
  :d "Verifies natural lash extraction, combing vector field deformation, ASN S-expression serialization, and JSON conversion."
  (let [(spec (lsh/make-default-restructuring-spec))
        (asn-out (lsh/format-restructuring-spec-asn spec))
        (json-out (lsh/format-restructuring-spec-json spec))
        (glsl-warp (lsh/generate-image-driven-warp-shader spec))]
    (assert (= (.-ridge-sensitivity spec) 0.75) "Ridge sensitivity must be 0.75")
    (assert (= (.-comb-alignment spec) 0.85) "Comb alignment must be 0.85")
    (assert (= (.-lift-displacement-px spec) 18.0) "Lift displacement must be 18.0 px")
    (assert (= (.-pad-curvature-radius spec) 3.5) "Pad curvature radius must be 3.5 mm")
    (assert (string-contains? asn-out "(:lash-restructuring") "ASN format must include :lash-restructuring header")
    (assert (string-contains? asn-out ":ridge-sensitivity-pct 75") "ASN format must encode ridge sensitivity")
    (assert (string-contains? asn-out ":comb-alignment-pct 85") "ASN format must encode comb alignment")
    (assert (string-contains? json-out "\"ridgeSensitivityPct\": 75") "JSON format must encode ridgeSensitivityPct")
    (assert (string-contains? json-out "\"combAlignmentPct\": 85") "JSON format must encode combAlignmentPct")
    (assert (string-contains? json-out "\"liftDisplacementPx\": 18") "JSON format must encode liftDisplacementPx")
    (assert (string-contains? glsl-warp "#version 300 es") "GLSL warp shader must specify version 300 es")
    (assert (string-contains? glsl-warp "uEyelidNormal") "GLSL warp shader must take eyelid normal uniform")
    (assert (string-contains? glsl-warp "float ridge") "GLSL warp shader must compute ridge filter")
    true))

(df run-tests [] -> Bool
  :d "Executes mobile target test suites."
  (do
    (assert (test-swift-package-generation) "test-swift-package-generation must pass")
    (assert (test-swift-app-and-xcframework-generation) "test-swift-app-and-xcframework-generation must pass")
    (assert (test-kotlin-jni-generation) "test-kotlin-jni-generation must pass")
    (assert (test-kotlin-kmp-and-compose-generation) "test-kotlin-kmp-and-compose-generation must pass")
    (assert (test-mobile-preview-generation) "test-mobile-preview-generation must pass")
    (assert (test-lamy-lashes-enhancement-and-codegen) "test-lamy-lashes-enhancement-and-codegen must pass")
    (assert (test-landmark-adapters-and-preview-server) "test-landmark-adapters-and-preview-server must pass")
    (assert (test-photoreal-shading-and-multieye-tracking) "test-photoreal-shading-and-multieye-tracking must pass")
    (assert (test-natural-lash-restructuring-and-conversion) "test-natural-lash-restructuring-and-conversion must pass")
    true))
