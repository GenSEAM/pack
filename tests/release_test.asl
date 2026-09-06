(module asl-pack/tests/release-test
  :d "Unit test suite for AgentScript production release and self-update pipeline."
  :x [test-release-plan
      test-release-script-generation
      test-upgrade-script-generation
      test-version-asn-generation]
  :i [(release :a rel)])

(df test-release-plan [] -> Bool
  :d "Verifies release plan parameters."
  (let [(plan (rel/make-release-plan "0.1.0"))]
    (and (= (.-version plan) "0.1.0")
         (and (= (.-tag plan) "v0.1.0")
              (= (list-length (.-target-platforms plan)) 5)))))

(df test-release-script-generation [] -> Bool
  :d "Verifies POSIX release script emission contains verification gates and archive building."
  (let [(plan (rel/make-release-plan "0.1.0"))
        (sh (rel/emit-release-script-sh plan))]
    (and (string-contains? sh "asl gate")
         (and (string-contains? sh "darwin-arm64")
              (string-contains? sh "SHA256SUMS")))))

(df test-upgrade-script-generation [] -> Bool
  :d "Verifies self-update script contains remote version discovery."
  (let [(sh (rel/emit-upgrade-script-sh))]
    (and (string-contains? sh "version.asn")
         (string-contains? sh "install.sh"))))

(df test-version-asn-generation [] -> Bool
  :d "Verifies version.asn manifest generation."
  (let [(plan (rel/make-release-plan "0.1.0"))
        (asn (rel/emit-version-asn plan))]
    (and (string-contains? asn ":version \"0.1.0\"")
         (string-contains? asn ":channel :stable"))))
