(module asl-pack/mobile-test
  :d "Unit tests for Swift Package Manager and Kotlin Multiplatform bridge generation."
  :x [run-tests]
  :i [(targets/swift :a sw)
      (targets/kotlin :a kt)
      (targets/preview :a prev)
      (targets/preview_server :a ps)])

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

(df test-preview-server [] -> Bool
  :d "Verifies WebSocket hot-reload server script generation and patch frame formatting."
  (let [(srv-spec (ps/make-preview-server-spec 8080 "scratch"))
        (patch-frame (ps/format-hot-reload-patch-frame "MobilePreview" "<div>updated</div>"))
        (srv-script (ps/generate-preview-server-script srv-spec))]
    (assert (= (.-port srv-spec) 8080) "Server spec port must match 8080")
    (assert (string-contains? patch-frame "patch") "Patch frame must contain patch type")
    (assert (string-contains? patch-frame "MobilePreview") "Patch frame must target MobilePreview")
    (assert (string-contains? srv-script "PORT = 8080") "Server script must configure PORT 8080")
    (assert (string-contains? srv-script "http.createServer") "Server script must create HTTP server")
    true))

(df run-tests [] -> Bool
  :d "Executes mobile target test suites."
  (do
    (assert (test-swift-package-generation) "test-swift-package-generation must pass")
    (assert (test-swift-app-and-xcframework-generation) "test-swift-app-and-xcframework-generation must pass")
    (assert (test-kotlin-jni-generation) "test-kotlin-jni-generation must pass")
    (assert (test-kotlin-kmp-and-compose-generation) "test-kotlin-kmp-and-compose-generation must pass")
    (assert (test-mobile-preview-generation) "test-mobile-preview-generation must pass")
    (assert (test-preview-server) "test-preview-server must pass")
    true))
