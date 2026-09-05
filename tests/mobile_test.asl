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
    (and (string-contains? pkg-swift "name: \"ASLKit\"")
         (and (string-contains? pkg-swift ".iOS(.v15)")
              (and (string-contains? c-hdr "typedef struct {")
                   (string-contains? c-hdr "asl_eval"))))))

(df test-kotlin-jni-generation [] -> Bool
  :d "Verifies Kotlin JNI external class and Gradle dependency generation."
  (let [(spec (kt/KotlinTargetSpec
                :package-id "io.genseam.asl"
                :class-name "ASLAgent"))
        (jni-kt (kt/generate-jni-binding spec))
        (gradle (kt/generate-gradle-dependency spec))]
    (and (string-contains? jni-kt "package io.genseam.asl")
         (and (string-contains? jni-kt "class ASLAgent")
              (and (string-contains? jni-kt "System.loadLibrary(\"asl_wamr_jni\")")
                   (string-contains? gradle "implementation(\"io.genseam:asl-wamr-runtime"))))))

(df run-tests [] -> Bool
  :d "Executes mobile target test suites."
  (fold (fn [(acc Bool) (p Bool)] -> Bool (and acc p))
        true
        (list (test-swift-package-generation)
              (test-kotlin-jni-generation))))
