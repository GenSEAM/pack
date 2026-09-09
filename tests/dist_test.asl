(module asl-pack/dist-test
  :d "Unit tests for distribution generator: installer scripts, package manifests, and bin launcher."
  :x [run-tests]
  :i [(dist :a d)])

(df test-dist-config [] -> Bool
  :d "Verifies distribution configuration setup."
  (let [(cfg (d/make-dist-config "0.1.0"))]
    (assert (= (.-version cfg) "0.1.0") "Version must be 0.1.0")
    (assert (= (.-npm-package-name cfg) "asl") "Package name must match")
    (assert (string-contains? (.-binary-base-url cfg) "v0.1.0") "Binary URL must contain version")
    true))

(df test-emit-install-sh [] -> Bool
  :d "Verifies generated install.sh contains binary download and source fallback."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (script (d/emit-install-sh cfg))]
    (assert (string-contains? script "asl-${VERSION}-${OS}-${ARCH_TAG}.tar.gz") "Script must have tarball name")
    (assert (string-contains? script "REPO_URL") "Script must have REPO_URL")
    (assert (string-contains? script "chmod +x") "Script must have chmod +x")
    true))

(df test-emit-build-from-source [] -> Bool
  :d "Verifies build-from-source script executes gate and symlinks binary."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (script (d/emit-build-from-source-sh cfg))]
    (assert (string-contains? script "Building AgentScript from source") "Script must announce build")
    (assert (string-contains? script "gate") "Script must invoke gate")
    (assert (string-contains? script "ln -sf") "Script must create symlink")
    true))

(df test-emit-npm-files [] -> Bool
  :d "Verifies package.json and bin launcher generation."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (pkg (d/emit-npm-package-json cfg))
        (launcher (d/emit-npm-bin cfg))]
    (assert (string-contains? pkg "\"name\": \"asl\"") "Package name must be serialized")
    (assert (string-contains? pkg "\"bin\":") "Package bin field must exist")
    (assert (string-contains? launcher "spawn") "Launcher must invoke spawn")
    true))

(df run-tests [] -> Bool
  :d "Executes dist test suite."
  (do
    (assert (test-dist-config) "test-dist-config must pass")
    (assert (test-emit-install-sh) "test-emit-install-sh must pass")
    (assert (test-emit-build-from-source) "test-emit-build-from-source must pass")
    (assert (test-emit-npm-files) "test-emit-npm-files must pass")
    true))
