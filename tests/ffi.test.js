import test from "node:test";
import assert from "node:assert";

test("Native FFI & PC-Library Linker Tests", async (t) => {
  await t.test("Resolves dynamic library names across platforms", () => {
    const resolveLibName = (name, os) => {
      if (os === "windows") return `${name}.dll`;
      if (os === "macos") return `lib${name}.dylib`;
      return `lib${name}.so`;
    };

    assert.strictEqual(resolveLibName("sqlite3", "macos"), "libsqlite3.dylib");
    assert.strictEqual(resolveLibName("sqlite3", "linux"), "libsqlite3.so");
    assert.strictEqual(resolveLibName("sqlite3", "windows"), "sqlite3.dll");
  });

  await t.test("Resolves linker argument flags across platforms", () => {
    const resolveLinkerFlags = (name, type, os) => {
      if (type === "framework" && os === "macos") return ["-framework", name];
      if (os === "windows") return [`${name}.lib`];
      return [`-l${name}`];
    };

    assert.deepStrictEqual(resolveLinkerFlags("sqlite3", "dynamic", "macos"), ["-lsqlite3"]);
    assert.deepStrictEqual(resolveLinkerFlags("sqlite3", "dynamic", "linux"), ["-lsqlite3"]);
    assert.deepStrictEqual(resolveLinkerFlags("sqlite3", "dynamic", "windows"), ["sqlite3.lib"]);
    assert.deepStrictEqual(resolveLinkerFlags("CoreAudio", "framework", "macos"), ["-framework", "CoreAudio"]);
  });
});
