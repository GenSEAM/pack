(module asl-pack/targets/kotlin
  :d "Kotlin Multiplatform and Android JNI bridge generator."
  :x [KotlinTargetSpec
      generate-jni-binding
      generate-gradle-dependency]
  :i [])

(dfs KotlinTargetSpec
  (:f package-id Str "Root package identifier e.g. io.genseam.asl")
  (:f class-name Str "Binding class name e.g. ASLAgent"))

(df generate-jni-binding [(spec KotlinTargetSpec)] -> Str
  :d "Generates Kotlin external class definition delegating to native WAMR runtime."
  (let [(pkg (.-package-id spec))
        (cls (.-class-name spec))]
    (str "package " pkg "\n\n"
         "class " cls " {\n"
         "    companion object {\n"
         "        init {\n"
         "            System.loadLibrary(\"asl_wamr_jni\")\n"
         "        }\n"
         "    }\n\n"
         "    external fun initEngine(): Int\n"
         "    external fun evalModule(moduleName: String, inputBytes: ByteArray): ByteArray\n"
         "    external fun freeEngine(): Unit\n"
         "}\n")))

(df generate-gradle-dependency [(spec KotlinTargetSpec)] -> Str
  :d "Emits Android Gradle dependencies for native WAMR runtime embedding."
  (str "// Android NDK / WAMR integration for " (.-package-id spec) "\n"
       "android {\n"
       "    defaultConfig {\n"
       "        ndk {\n"
       "            abiFilters 'arm64-v8a', 'x86_64'\n"
       "        }\n"
       "    }\n"
       "}\n"
       "dependencies {\n"
       "    implementation(\"io.genseam:asl-wamr-runtime:0.1.0\")\n"
       "}\n"))
