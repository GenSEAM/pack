(module asl-pack/ffi-test
  :d "Unit tests for native FFI library resolution across platform descriptors."
  :x [run-tests]
  :i [(ffi-linker :a ffi)
      (platform :a plat)])

(df test-dynamic-lib-resolution [] -> Bool
  :d "Verifies dynamic library naming and flags across macOS, Linux, and Windows."
  (let [(spec (ffi/NativeLibrarySpec
                :name "sqlite3"
                :lib-type (ffi/lib-dynamic)
                :pkg-config-name "sqlite3"
                :header-include "<sqlite3.h>"))
        (p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (p-lin (plat/make-platform (plat/os-linux) (plat/arch-x64)))
        (p-win (plat/make-platform (plat/os-windows) (plat/arch-x64)))
        (res-mac (ffi/resolve-library-target spec p-mac))
        (res-lin (ffi/resolve-library-target spec p-lin))
        (res-win (ffi/resolve-library-target spec p-win))]
    (assert (= (.-shared-lib-name res-mac) "libsqlite3.dylib") "macOS dynamic lib name must match")
    (assert (= (.-shared-lib-name res-lin) "libsqlite3.so") "Linux dynamic lib name must match")
    (assert (= (.-shared-lib-name res-win) "sqlite3.dll") "Windows dynamic lib name must match")
    (assert (= (option-or (list-head (.-lib-flags res-win)) "") "sqlite3.lib") "Windows lib flags must match")
    true))

(df test-apple-framework-resolution [] -> Bool
  :d "Verifies macOS framework linker flag generation."
  (let [(spec (ffi/NativeLibrarySpec
                :name "CoreAudio"
                :lib-type (ffi/lib-framework)
                :pkg-config-name ""
                :header-include "<CoreAudio/CoreAudio.h>"))
        (p-mac (plat/make-platform (plat/os-macos) (plat/arch-arm64)))
        (res-mac (ffi/resolve-library-target spec p-mac))
        (flags (.-lib-flags res-mac))]
    (assert (= (option-or (list-head flags) "") "-framework") "First flag must be -framework")
    (assert (= (option-or (list-head (option-or (list-tail flags) (list))) "") "CoreAudio") "Second flag must be framework name")
    true))

(df run-tests [] -> Bool
  :d "Executes native FFI resolution test suites."
  (do
    (assert (test-dynamic-lib-resolution) "test-dynamic-lib-resolution must pass")
    (assert (test-apple-framework-resolution) "test-apple-framework-resolution must pass")
    true))
