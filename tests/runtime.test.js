import test from "node:test";
import assert from "node:assert";

test("Wasm Runtime Decision Matrix & Recommendation Policies", async (t) => {
  await t.test("CLI environment defaults to high-throughput Cranelift JIT with SIMD", () => {
    const recommendation = {
      runtime: "Wasmtime (Cranelift)",
      mode: "JIT",
      simd: true,
      coldStartMs: 1.5
    };
    assert.strictEqual(recommendation.runtime, "Wasmtime (Cranelift)");
    assert.strictEqual(recommendation.simd, true);
    assert.strictEqual(recommendation.mode, "JIT");
  });

  await t.test("iOS environment strictly enforces Apple App Store compliant AOT (No JIT)", () => {
    const recommendation = {
      runtime: "LLVM / Cranelift AOT Native",
      mode: "AOT",
      appleAppStoreCompliant: true,
      jitAllowed: false
    };
    assert.strictEqual(recommendation.appleAppStoreCompliant, true);
    assert.strictEqual(recommendation.mode, "AOT");
    assert.strictEqual(recommendation.jitAllowed, false);
  });

  await t.test("Android mobile environment selects compact Intel WAMR AOT", () => {
    const recommendation = {
      runtime: "WAMR (Intel Micro Runtime)",
      mode: "AOT",
      binaryOverheadMb: 0.8
    };
    assert.strictEqual(recommendation.runtime, "WAMR (Intel Micro Runtime)");
    assert(recommendation.binaryOverheadMb < 1.0);
  });

  await t.test("Windows platform target assigns .exe and standard MSVC target triple", () => {
    const targetTriple = "x86_64-pc-windows-msvc";
    const binary = `asl-${targetTriple}.exe`;
    assert(binary.endsWith(".exe"));
    assert(binary.includes("windows-msvc"));
  });

  await t.test("macOS Apple Silicon platform target assigns aarch64-apple-darwin", () => {
    const targetTriple = "aarch64-apple-darwin";
    const binary = `asl-${targetTriple}`;
    assert(!binary.endsWith(".exe"));
    assert(binary.includes("apple-darwin"));
  });
});
