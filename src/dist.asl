(module asl-pack/dist
  :d "Multi-channel distribution orchestrator: installers, binary release packaging, NPM/NPX wrappers, and build-from-source generators."
  :x [DistConfig
      make-dist-config
      emit-install-sh
      emit-install-ps1
      emit-build-from-source-sh
      emit-npm-package-json
      emit-npm-bin]
  :i [(platform :a plat)])

(dfs DistConfig
  (:f version Str "Release version semver string")
  (:f repo-url Str "Canonical git source repository URL")
  (:f binary-base-url Str "Download URL prefix for precompiled release archives")
  (:f npm-package-name Str "Published NPM package identifier"))

(df make-dist-config [(version Str)] -> DistConfig
  :d "Constructs standard production distribution configuration."
  (DistConfig
    :version version
    :repo-url "https://github.com/GenSEAM/asl.git"
    :binary-base-url (str "https://github.com/GenSEAM/asl/releases/download/v" version)
    :npm-package-name "asl"))

(df emit-build-from-source-sh [(cfg DistConfig)] -> Str
  :d "Generates standalone POSIX build-from-source shell script."
  (str "#!/usr/bin/env bash\n"
       "# AgentScript (ASL) Build-from-Source Bootstrap\n"
       "# Auto-generated from pure AgentScript module: pack/src/dist.asl\n"
       "set -eo pipefail\n\n"
       "echo \"[DIST] Building AgentScript from source (v" (.-version cfg) ")...\";\n"
       "ROOT_DIR=\"$(cd -P \"$(dirname \"${BASH_SOURCE[0]}\")/..\" && pwd)\"\n"
       "cd \"$ROOT_DIR\"\n\n"
       "# Check prerequisites\n"
       "command -v node >/dev/null 2>&1 || { echo \"[ERROR] Node.js runtime required for memory daemon bootstrap.\"; exit 1; }\n"
       "command -v awk >/dev/null 2>&1 || { echo \"[ERROR] AWK required for single-pass AST checking.\"; exit 1; }\n\n"
       "echo \"--> [1/3] Verifying ASL syntax and forms...\";\n"
       "chmod +x ./asl/asl 2>/dev/null || chmod +x ./asl\n"
       "ASL_BIN=\"./asl/asl\"\n"
       "[ ! -f \"$ASL_BIN\" ] && ASL_BIN=\"./asl\"\n\n"
       "echo \"--> [2/3] Running verification gates...\";\n"
       "\"$ASL_BIN\" gate\n\n"
       "echo \"--> [3/3] Setting up local binary symlinks...\";\n"
       "INSTALL_DIR=\"${HOME}/.local/bin\"\n"
       "mkdir -p \"$INSTALL_DIR\"\n"
       "ln -sf \"$(cd -P \"$(dirname \"$ASL_BIN\")\" && pwd)/$(basename \"$ASL_BIN\")\" \"$INSTALL_DIR/asl\"\n"
       "echo \"[OK] Successfully built and symlinked ASL to $INSTALL_DIR/asl\";\n"
       "echo \"[INFO] Run: asl --version\";\n"))

(df emit-install-sh [(cfg DistConfig)] -> Str
  :d "Generates universal smart installer supporting pre-built binaries with source build fallback."
  (str "#!/bin/bash\n"
       "# AgentScript Universal Installer (Pre-built Binaries + Source Fallback)\n"
       "# Auto-generated from pure AgentScript module: pack/src/dist.asl\n"
       "set -eo pipefail\n\n"
       "VERSION=\"" (.-version cfg) "\"\n"
       "REPO_URL=\"" (.-repo-url cfg) "\"\n"
       "BINARY_BASE_URL=\"" (.-binary-base-url cfg) "\"\n"
       "INSTALL_DIR=\"${HOME}/.asl/bin\"\n"
       "mkdir -p \"${INSTALL_DIR}\"\n\n"
       "OS=\"$(uname -s | tr '[:upper:]' '[:lower:]')\"\n"
       "ARCH=\"$(uname -m)\"\n\n"
       "case \"$ARCH\" in\n"
       "  x86_64|amd64) ARCH_TAG=\"x64\" ;;\n"
       "  arm64|aarch64) ARCH_TAG=\"arm64\" ;;\n"
       "  *) ARCH_TAG=\"unknown\" ;;\n"
       "esac\n\n"
       "BINARY_INSTALLED=0\n"
       "if [ \"$ARCH_TAG\" != \"unknown\" ] && [ \"$1\" != \"--source\" ]; then\n"
       "  TAR_NAME=\"asl-${VERSION}-${OS}-${ARCH_TAG}.tar.gz\"\n"
       "  DL_URL=\"${BINARY_BASE_URL}/${TAR_NAME}\"\n"
       "  echo \"[DIST] Downloading pre-built ASL binary for ${OS}-${ARCH_TAG}...\";\n"
       "  if curl -fsSL \"${DL_URL}\" -o \"/tmp/${TAR_NAME}\" 2>/dev/null; then\n"
       "    tar -xzf \"/tmp/${TAR_NAME}\" -C \"${INSTALL_DIR}\"\n"
       "    rm -f \"/tmp/${TAR_NAME}\"\n"
       "    chmod +x \"${INSTALL_DIR}/asl\"\n"
       "    BINARY_INSTALLED=1\n"
       "    echo \"[OK] Pre-built binary installed cleanly.\";\n"
       "  fi\n"
       "fi\n\n"
       "if [ \"$BINARY_INSTALLED\" -eq 0 ]; then\n"
       "  echo \"[DIST] Installing ASL from git source repository...\";\n"
       "  CLONE_DIR=\"${HOME}/.asl/repo\"\n"
       "  if [ -d \"${CLONE_DIR}\" ]; then\n"
       "    git -C \"${CLONE_DIR}\" pull --ff-only 2>/dev/null || true\n"
       "  else\n"
       "    git clone \"${REPO_URL}\" \"${CLONE_DIR}\"\n"
       "  fi\n"
       "  ln -sf \"${CLONE_DIR}/asl\" \"${INSTALL_DIR}/asl\"\n"
       "fi\n\n"
       "if [ -d \"${HOME}/.local/bin\" ] && [ -w \"${HOME}/.local/bin\" ]; then\n"
       "  ln -sf \"${INSTALL_DIR}/asl\" \"${HOME}/.local/bin/asl\"\n"
       "fi\n\n"
       "echo \"[OK] ASL successfully installed: ${INSTALL_DIR}/asl\";\n"
       "echo \"[INFO] Run: asl --version\";\n"))

(df emit-install-ps1 [(cfg DistConfig)] -> Str
  :d "Generates Windows PowerShell 1-line installer."
  (str "# AgentScript (ASL) Windows PowerShell Installer\n"
       "# Auto-generated from pure AgentScript module: pack/src/dist.asl\n"
       "$ErrorActionPreference = 'Stop'\n"
       "$Version = '" (.-version cfg) "'\n"
       "$InstallDir = \"$env:LOCALAPPDATA\\asl\\bin\"\n"
       "New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null\n\n"
       "Write-Host \"[INSTALL] Installing AgentScript (ASL) v$Version for Windows...\" -ForegroundColor Cyan\n"
       "$ZipUrl = \"" (.-binary-base-url cfg) "/asl-$Version-windows-x64.zip\"\n"
       "$ZipFile = \"$env:TEMP\\asl-$Version.zip\"\n\n"
       "try {\n"
       "    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile\n"
       "    Expand-Archive -Path $ZipFile -DestinationPath $InstallDir -Force\n"
       "    Remove-Item -Force $ZipFile\n"
       "} catch {\n"
       "    Write-Host \"Falling back to git clone source build...\" -ForegroundColor Yellow\n"
       "    git clone " (.-repo-url cfg) " \"$env:LOCALAPPDATA\\asl\\repo\"\n"
       "    Copy-Item \"$env:LOCALAPPDATA\\asl\\repo\\asl\" \"$InstallDir\\asl.cmd\"\n"
       "}\n\n"
       "$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')\n"
       "if ($UserPath -notlike \"*$InstallDir*\") {\n"
       "    [Environment]::SetEnvironmentVariable('Path', \"$InstallDir;$UserPath\", 'User')\n"
       "    Write-Host \"[OK] Added $InstallDir to User PATH\" -ForegroundColor Green\n"
       "}\n"
       "Write-Host \"[OK] AgentScript successfully installed! Restart your shell and run: asl --version\" -ForegroundColor Green\n"))

(df emit-npm-package-json [(cfg DistConfig)] -> Str
  :d "Generates package.json manifest for NPM/NPX distribution."
  (str "{\n"
       "  \"name\": \"" (.-npm-package-name cfg) "\",\n"
       "  \"version\": \"" (.-version cfg) "\",\n"
       "  \"description\": \"AgentScript (ASL) - The Autonomous AI Coding Agent Language & Toolbelt\",\n"
       "  \"main\": \"bin/asl.mjs\",\n"
       "  \"type\": \"module\",\n"
       "  \"bin\": {\n"
       "    \"asl\": \"bin/asl.mjs\",\n"
       "    \"agentscript\": \"bin/asl.mjs\"\n"
       "  },\n"
       "  \"keywords\": [\"agentscript\", \"asl\", \"ai-agent\", \"compiler\", \"toolbelt\", \"wasm\", \"rag\", \"webgpu\"],\n"
       "  \"license\": \"MIT\",\n"
       "  \"repository\": {\n"
       "    \"type\": \"git\",\n"
       "    \"url\": \"" (.-repo-url cfg) "\"\n"
       "  },\n"
       "  \"engines\": {\n"
       "    \"node\": \">=18.0.0\"\n"
       "  }\n"
       "}\n"))

(df emit-npm-bin [(cfg DistConfig)] -> Str
  :d "Generates bin/asl.mjs executable wrapper for NPM global install and npx execution."
  (str "#!/usr/bin/env node\n"
       "/**\n"
       " * AgentScript (ASL) CLI Runner for NPM and NPX\n"
       " * Auto-generated from pure AgentScript module: pack/src/dist.asl\n"
       " */\n"
       "import { spawn } from 'node:child_process';\n"
       "import path from 'node:path';\n"
       "import fs from 'node:fs';\n"
       "import { fileURLToPath } from 'node:url';\n\n"
       "const __dirname = path.dirname(fileURLToPath(import.meta.url));\n"
       "const rootDir = path.resolve(__dirname, '..');\n\n"
       "const candidateBins = [\n"
       "  path.join(rootDir, 'asl'),\n"
       "  path.join(rootDir, 'asl.cmd'),\n"
       "  path.join(rootDir, 'bin', 'asl')\n"
       "];\n\n"
       "let targetBin = candidateBins.find(p => fs.existsSync(p));\n"
       "const args = process.argv.slice(2);\n\n"
       "if (!targetBin) {\n"
       "  const daemonCandidate = path.join(rootDir, 'asl', 'bridges', 'node', 'asl-mem-daemon.mjs');\n"
       "  const daemonFallback = path.join(rootDir, 'tools', 'asl-mem-daemon.mjs');\n"
       "  const daemonPath = fs.existsSync(daemonCandidate) ? daemonCandidate : daemonFallback;\n"
       "  if (fs.existsSync(daemonPath)) {\n"
       "    const child = spawn(process.execPath, [daemonPath, ...args], { stdio: 'inherit' });\n"
       "    child.on('exit', code => process.exit(code || 0));\n"
       "  } else {\n"
       "    console.error('asl: binary not found in package');\n"
       "    process.exit(1);\n"
       "  }\n"
       "} else {\n"
       "  const child = spawn(targetBin, args, { stdio: 'inherit' });\n"
       "  child.on('exit', code => process.exit(code || 0));\n"
       "}\n"))
