import test from "node:test";
import assert from "node:assert";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { createStandaloneBundle, inspectBundle, MAGIC_FOOTER, FOOTER_SIZE } from "../bridges/bundler.js";

test("Standalone Executable Packaging Driver", async (t) => {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "asl-pack-test-"));
  const runnerPath = path.join(tmpDir, "stub-runner");
  const payloadPath = path.join(tmpDir, "sample.wasm");
  const outputPath = path.join(tmpDir, "app-standalone");

  try {
    // 1. Create mock runner binary (e.g. 1024 bytes) and mock payload (e.g. 256 bytes)
    const mockRunner = Buffer.alloc(1024, 0x90); // NOP sled
    const mockPayload = Buffer.from("\x00asm\x01\x00\x00\x00(module (func $main))");
    await fs.writeFile(runnerPath, mockRunner);
    await fs.writeFile(payloadPath, mockPayload);

    await t.test("Packages binary with 16-byte fixed trailer", async () => {
      const res = await createStandaloneBundle(runnerPath, payloadPath, outputPath, {
        autoCodesign: false
      });

      assert.strictEqual(res.runnerBytes, 1024);
      assert.strictEqual(res.payloadBytes, mockPayload.length);
      assert.strictEqual(res.totalBytes, 1024 + mockPayload.length + FOOTER_SIZE);
    });

    await t.test("Inspects bundle and extracts exact payload length and magic", async () => {
      const inspection = await inspectBundle(outputPath);
      assert.strictEqual(inspection.valid, true);
      assert.strictEqual(inspection.magic, MAGIC_FOOTER);
      assert.strictEqual(inspection.payloadLength, mockPayload.length);
      assert.strictEqual(inspection.totalFileSize, 1024 + mockPayload.length + FOOTER_SIZE);
    });

    await t.test("Rejects corrupted or truncated binary", async () => {
      const corruptPath = path.join(tmpDir, "corrupted");
      await fs.writeFile(corruptPath, Buffer.from("short"));
      const inspection = await inspectBundle(corruptPath);
      assert.strictEqual(inspection.valid, false);
    });
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true });
  }
});
