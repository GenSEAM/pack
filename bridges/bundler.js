/**
 * @genseam/asl-pack - Standalone Executable Bundler Host Driver
 * 
 * Appends bytecode payload and fixed 16-byte trailer to native runner stubs.
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
export const MAGIC_FOOTER = "ASLPACK!";
export const FOOTER_SIZE = 16;

/**
 * Packs a native runner stub and Wasm bytecode into a single standalone executable.
 */
export async function createStandaloneBundle(runnerPath, payloadPath, outputPath, options = {}) {
  const isMacos = options.isMacos ?? (process.platform === "darwin");
  const autoCodesign = options.autoCodesign ?? isMacos;

  // 1. Read runner stub bytes and payload
  const runnerBytes = await fs.readFile(runnerPath);
  const payloadBytes = await fs.readFile(payloadPath);

  // 2. Format 16-byte fixed trailer
  // [8 bytes: Big-Endian Uint64 length] + [8 bytes: ASCII "ASLPACK!"]
  const footerBuffer = Buffer.alloc(FOOTER_SIZE);
  footerBuffer.writeBigUInt64BE(BigInt(payloadBytes.length), 0);
  footerBuffer.write(MAGIC_FOOTER, 8, 8, "ascii");

  // 3. Assemble binary: [runner] + [payload] + [footer]
  const assembledBinary = Buffer.concat([runnerBytes, payloadBytes, footerBuffer]);

  // 4. Write destination binary
  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.writeFile(outputPath, assembledBinary);
  await fs.chmod(outputPath, 0o755);

  // 5. Ad-hoc codesigning for macOS Apple Silicon AMFI
  if (autoCodesign && isMacos) {
    try {
      await execFileAsync("codesign", ["-s", "-", "--force", outputPath]);
    } catch (err) {
      // Non-fatal if codesign utility is absent in sandbox
      if (options.strictCodesign) throw err;
    }
  }

  return {
    outputPath,
    totalBytes: assembledBinary.length,
    payloadBytes: payloadBytes.length,
    runnerBytes: runnerBytes.length
  };
}

/**
 * Inspects an assembled binary and verifies its trailing 16-byte trailer.
 */
export async function inspectBundle(binaryPath) {
  const fileHandle = await fs.open(binaryPath, "r");
  try {
    const stat = await fileHandle.stat();
    if (stat.size < FOOTER_SIZE) {
      return { valid: false, error: "File smaller than footer size" };
    }

    const footerBuffer = Buffer.alloc(FOOTER_SIZE);
    await fileHandle.read(footerBuffer, 0, FOOTER_SIZE, stat.size - FOOTER_SIZE);

    const magic = footerBuffer.toString("ascii", 8, 16);
    if (magic !== MAGIC_FOOTER) {
      return { valid: false, error: `Invalid magic footer: ${magic}` };
    }

    const payloadLength = Number(footerBuffer.readBigUInt64BE(0));
    return {
      valid: true,
      magic,
      payloadLength,
      totalFileSize: stat.size,
      footerSize: FOOTER_SIZE
    };
  } finally {
    await fileHandle.close();
  }
}
