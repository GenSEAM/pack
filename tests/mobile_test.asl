(module asl-pack/mobile-test
  :d "Unit tests for Swift Package Manager and Kotlin Multiplatform bridge generation."
  :x [run-tests]
  :i [(swift :a sw)
      (kotlin :a kt)])

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

(df run-tests [] -> Bool
  :d "Executes mobile target test suites."
  (do
    (assert (test-swift-package-generation) "test-swift-package-generation must pass")
    (assert (test-kotlin-jni-generation) "test-kotlin-jni-generation must pass")
    true))
