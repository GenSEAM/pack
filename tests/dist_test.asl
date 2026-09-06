(module asl-pack/dist-test
  :d "Unit tests for distribution generator: installer scripts, package manifests, and bin launcher."
  :x [run-tests]
  :i [(dist :a d)])

(df test-dist-config [] -> Bool
  :d "Verifies distribution configuration setup."
  (let [(cfg (d/make-dist-config "0.1.0"))]
    (and (= (.-version cfg) "0.1.0")
         (and (= (.-npm-package-name cfg) "@genseam/asl")
              (string-contains? (.-binary-base-url cfg) "v0.1.0")))))

(df test-emit-install-sh [] -> Bool
  :d "Verifies generated install.sh contains binary download and source fallback."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (script (d/emit-install-sh cfg))]
    (and (string-contains? script "asl-${VERSION}-${OS}-${ARCH_TAG}.tar.gz")
         (and (string-contains? script "REPO_URL")
              (string-contains? script "chmod +x")))))

(df test-emit-build-from-source [] -> Bool
  :d "Verifies build-from-source script executes gate and symlinks binary."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (script (d/emit-build-from-source-sh cfg))]
    (and (string-contains? script "Building AgentScript from source")
         (and (string-contains? script "gate")
              (string-contains? script "ln -sf")))))

(df test-emit-npm-files [] -> Bool
  :d "Verifies package.json and bin launcher generation."
  (let [(cfg (d/make-dist-config "0.1.0"))
        (pkg (d/emit-npm-package-json cfg))
        (launcher (d/emit-npm-bin cfg))]
    (and (string-contains? pkg "\"name\": \"@genseam/asl\"")
         (and (string-contains? pkg "\"bin\":")
              (string-contains? launcher "spawn")))))

(df run-tests [] -> Bool
  :d "Executes dist test suite."
  (and (test-dist-config)
       (and (test-emit-install-sh)
            (and (test-emit-build-from-source)
                 (test-emit-npm-files)))))
