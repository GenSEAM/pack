(module asl-pack/tests/release-test
  :d "Unit test suite for AgentScript production release and self-update pipeline."
  :x [test-release-plan
      test-release-script-generation
      test-upgrade-script-generation
      test-version-asn-generation
      run-tests]
  :i [(release :a rel)])

(df test-release-plan [] -> Bool
  :d "Verifies release plan parameters."
  (let [(plan (rel/make-release-plan "0.1.0"))]
    (assert (= (.-version plan) "0.1.0") "Release version must be 0.1.0")
    (assert (= (.-tag plan) "v0.1.0") "Release tag must be v0.1.0")
    (assert (= (list-length (.-target-platforms plan)) 5) "Must have 5 target platforms")
    true))

(df test-release-script-generation [] -> Bool
  :d "Verifies POSIX release script emission contains verification gates and archive building."
  (let [(plan (rel/make-release-plan "0.1.0"))
        (sh (rel/emit-release-script-sh plan))]
    (assert (string-contains? sh "asl gate") "Release script must run asl gate")
    (assert (string-contains? sh "darwin-arm64") "Release script must contain darwin-arm64")
    (assert (string-contains? sh "SHA256SUMS") "Release script must contain SHA256SUMS")
    true))

(df test-upgrade-script-generation [] -> Bool
  :d "Verifies self-update script contains remote version discovery."
  (let [(sh (rel/emit-upgrade-script-sh))]
    (assert (string-contains? sh "version.asn") "Upgrade script must check version.asn")
    (assert (string-contains? sh "install.sh") "Upgrade script must check install.sh")
    true))

(df test-version-asn-generation [] -> Bool
  :d "Verifies version.asn manifest generation."
  (let [(plan (rel/make-release-plan "0.1.0"))
        (asn (rel/emit-version-asn plan))]
    (assert (string-contains? asn ":version \"0.1.0\"") "Version manifest must specify version")
    (assert (string-contains? asn ":channel :stable") "Version manifest must specify stable channel")
    true))

(df run-tests [] -> Bool
  :d "Executes release test suite."
  (do
    (assert (test-release-plan) "test-release-plan must pass")
    (assert (test-release-script-generation) "test-release-script-generation must pass")
    (assert (test-upgrade-script-generation) "test-upgrade-script-generation must pass")
    (assert (test-version-asn-generation) "test-version-asn-generation must pass")
    true))
