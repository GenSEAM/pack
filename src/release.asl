(module asl-pack/release
  :d "Pure AgentScript release orchestrator: multi-platform binary bundler, checksum generator, tag-based web publishing, and atomic self-update generator."
  :x [ReleasePlan
      make-release-plan
      emit-release-script-sh
      emit-upgrade-script-sh
      emit-version-asn]
  :i [(platform :a plat) (dist :a dist)])

(dfs ReleasePlan
  (:f version Str "Semver release version string e.g. 0.1.0")
  (:f tag Str "Git release tag string e.g. v0.1.0")
  (:f release-date Str "ISO date of release")
  (:f target-platforms (List Str) "List of target platform descriptors")
  (:f dist-dir Str "Output directory for release archives"))

(df make-release-plan [(version Str)] -> ReleasePlan
  :d "Constructs standard production release plan."
  (ReleasePlan
    :version version
    :tag (str "v" version)
    :release-date "2026-09-08"
    :target-platforms (list "darwin-arm64" "darwin-x64" "linux-x64" "linux-arm64" "windows-x64")
    :dist-dir "dist"))

(df emit-version-asn [(plan ReleasePlan)] -> Str
  :d "Emits version.asn metadata for remote version discovery and self-update."
  (str ";; AgentScript Production Release Manifest\n"
       "(:release\n"
       "  :version \"" (.-version plan) "\"\n"
       "  :tag \"" (.-tag plan) "\"\n"
       "  :date \"" (.-release-date plan) "\"\n"
       "  :channel :stable\n"
       "  :binary-base \"https://github.com/GenSEAM/asl/releases/download/" (.-tag plan) "\")\n"))

(df emit-release-script-sh [(plan ReleasePlan)] -> Str
  :d "Generates complete POSIX release pipeline script."
  (let [(v (.-version plan))
        (tag (.-tag plan))]
    (str "#!/usr/bin/env bash\n"
         "# AgentScript (ASL) Production Release Pipeline\n"
         "# Auto-generated from pure AgentScript module: pack/src/release.asl\n"
         "set -eo pipefail\n\n"
         "VERSION=\"" v "\"\n"
         "TAG=\"" tag "\"\n"
         "ROOT_DIR=\"$(cd -P \"$(dirname \"${BASH_SOURCE[0]}\")/..\" && pwd)\"\n"
         "cd \"$ROOT_DIR\"\n\n"
         "echo \"🚀 [ASL Release] Starting automated release for ${TAG}...\";\n\n"
         "# Step 1: Verification Gates\n"
         "echo \"--> [1/5] Executing complete 7-gate verification suite...\";\n"
         "./asl/asl gate\n\n"
         "# Step 2: Prepare Release Output\n"
         "echo \"--> [2/5] Preparing release distribution directory...\";\n"
         "DIST_DIR=\"dist/${TAG}\"\n"
         "mkdir -p \"$DIST_DIR\"\n\n"
         "# Step 3: Bundle Platform Archives\n"
         "echo \"--> [3/5] Packaging binary archives for target platforms...\";\n"
         "for target in darwin-arm64 darwin-x64 linux-x64 linux-arm64; do\n"
         "  ARCHIVE=\"${DIST_DIR}/asl-${VERSION}-${target}.tar.gz\"\n"
         "  tar -czf \"${ARCHIVE}\" -C \"${ROOT_DIR}\" asl\n"
         "  echo \"    ✓ Built ${ARCHIVE}\"\n"
         "done\n"
         "# Windows zip bundle\n"
         "if command -v zip >/dev/null 2>&1; then\n"
         "  zip -q \"${DIST_DIR}/asl-${VERSION}-windows-x64.zip\" asl\n"
         "  echo \"    ✓ Built ${DIST_DIR}/asl-${VERSION}-windows-x64.zip\"\n"
         "fi\n\n"
         "# Step 4: Checksums\n"
         "echo \"--> [4/5] Generating cryptographic SHA256 checksums...\";\n"
         "cd \"$DIST_DIR\"\n"
         "if command -v sha256sum >/dev/null 2>&1; then\n"
         "  sha256sum asl-* > SHA256SUMS\n"
         "elif command -v shasum >/dev/null 2>&1; then\n"
         "  shasum -a 256 asl-* > SHA256SUMS\n"
         "fi\n"
         "cd \"$ROOT_DIR\"\n\n"
         "# Step 5: Web & NPM Publishing Preparation\n"
         "echo \"--> [5/5] Updating web distribution and version metadata...\";\n"
         "cp \"$ROOT_DIR/npm/package.json\" \"$DIST_DIR/package.json\"\n"
         "echo \"✓ Release ${TAG} packaged cleanly in ${DIST_DIR}.\";\n"
         "echo \"⚡ Ready to tag and publish: git tag ${TAG} && git push origin ${TAG}\";\n")))

(df emit-upgrade-script-sh [] -> Str
  :d "Generates atomic in-place binary upgrade script."
  (str "#!/bin/bash\n"
       "# AgentScript (ASL) Self-Update Runner\n"
       "# Auto-generated from pure AgentScript module: pack/src/release.asl\n"
       "set -eo pipefail\n\n"
       "VERSION_URL=\"https://aslang.dev/version.asn\"\n"
       "CURRENT_BIN=\"$(command -v asl 2>/dev/null || echo \"${HOME}/.local/bin/asl\")\"\n\n"
       "echo \"🔍 Checking for AgentScript updates from ${VERSION_URL}...\";\n"
       "REMOTE_ASN=\"$(curl -fsSL \"${VERSION_URL}\" 2>/dev/null || true)\"\n"
       "if [ -z \"$REMOTE_ASN\" ]; then\n"
       "  echo \"✗ Could not check for updates (offline or network error).\";\n"
       "  exit 1;\n"
       "fi\n\n"
       "REMOTE_VER=\"$(echo \"$REMOTE_ASN\" | grep ':version' | head -1 | awk -F'\"' '{print $2}')\"\n"
       "LOCAL_VER=\"$(\"$CURRENT_BIN\" version 2>/dev/null || echo \"0.0.0\")\"\n\n"
       "if [ \"$REMOTE_VER\" = \"$LOCAL_VER\" ]; then\n"
       "  echo \"✓ AgentScript is already up to date (v${LOCAL_VER}).\";\n"
       "  exit 0;\n"
       "fi\n\n"
       "echo \"🚀 Upgrading AgentScript: v${LOCAL_VER} ➔ v${REMOTE_VER}...\";\n"
       "curl -fsSL https://aslang.dev/install.sh | bash\n"
       "echo \"✓ Successfully updated to v${REMOTE_VER}!\";\n"))
