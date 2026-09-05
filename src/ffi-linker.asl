(module asl-pack/ffi-linker
  :d "Native foreign function interface (FFI) and platform library resolution across macOS, Linux, and Windows."
  :x [LibraryType
      NativeLibrarySpec
      ResolvedLinkerFlags
      format-shared-lib-name
      resolve-library-target]
  :i [(platform :a plat)])

(dfe LibraryType
  (:c lib-dynamic [] "Dynamically linked shared object (.dylib, .so, .dll)")
  (:c lib-static [] "Statically linked object archive (.a, .lib)")
  (:c lib-framework [] "Apple macOS/iOS system framework"))

(dfs NativeLibrarySpec
  (:f name Str "Base canonical library name without prefixes or extensions")
  (:f lib-type LibraryType "Linkage kind")
  (:f pkg-config-name Str "Package config lookup token")
  (:f header-include Str "C header include statement e.g. <sqlite3.h>"))

(dfs ResolvedLinkerFlags
  (:f lib-flags (List Str) "Compiler/linker arguments e.g. -lsqlite3")
  (:f include-flags (List Str) "Header search path flags")
  (:f shared-lib-name Str "Physical runtime shared library file name"))

(df format-shared-lib-name [(name Str) (plat plat/PlatformDescriptor)] -> Str
  :d "Calculates the exact runtime library file name according to OS naming conventions."
  (if (plat/is-windows? plat)
    (str name ".dll")
    (if (plat/is-macos? plat)
      (str "lib" name ".dylib")
      (str "lib" name ".so"))))

(df resolve-library-target [(spec NativeLibrarySpec) (plat plat/PlatformDescriptor)] -> ResolvedLinkerFlags
  :d "Translates abstract library specification into platform-specific linker flags."
  (let [(sh-name (format-shared-lib-name (.-name spec) plat))
        (flags (mt (.-lib-type spec)
                 ((lib-framework)
                  (if (plat/is-macos? plat)
                    (list "-framework" (.-name spec))
                    (list (str "-l" (.-name spec)))))
                 ((lib-static)
                  (if (plat/is-windows? plat)
                    (list (str (.-name spec) ".lib"))
                    (list (str "lib" (.-name spec) ".a"))))
                 ((lib-dynamic)
                  (if (plat/is-windows? plat)
                    (list (str (.-name spec) ".lib"))
                    (list (str "-l" (.-name spec)))))))]
    (ResolvedLinkerFlags
      :lib-flags flags
      :include-flags (list (str "-I/usr/include/" (.-name spec)))
      :shared-lib-name sh-name)))
