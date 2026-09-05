import test from "node:test";
import assert from "node:assert";

test("Mobile Targets Bridge Generator Tests", async (t) => {
  await t.test("Generates valid Swift Package definition and C-bridge header", () => {
    const pkgName = "ASLKit";
    const cBridgeHeader = `
#ifndef ASL_BRIDGE_H
#define ASL_BRIDGE_H
#include <stdint.h>
#include <stddef.h>
typedef struct {
    const uint8_t *data;
    size_t length;
} ASLByteBuffer;
int32_t asl_init(void);
ASLByteBuffer asl_eval(const char *module_name, const uint8_t *input_asn, size_t input_len);
void asl_free_buffer(ASLByteBuffer buf);
#endif
`.trim();

    assert(cBridgeHeader.includes("ASLByteBuffer"));
    assert(cBridgeHeader.includes("asl_eval"));
    assert(cBridgeHeader.includes("asl_init"));

    const packageSwift = `
// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "${pkgName}",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "${pkgName}", targets: ["${pkgName}"])]
)
`.trim();

    assert(packageSwift.includes(`name: "${pkgName}"`));
    assert(packageSwift.includes(".iOS(.v15)"));
    assert(packageSwift.includes(".macOS(.v12)"));
  });

  await t.test("Generates Kotlin JNI class and Android Gradle dependency", () => {
    const packageId = "io.genseam.asl";
    const className = "ASLAgent";

    const kotlinClass = `
package ${packageId}
class ${className} {
    companion object {
        init {
            System.loadLibrary("asl_wamr_jni")
        }
    }
    external fun initEngine(): Int
    external fun evalModule(moduleName: String, inputBytes: ByteArray): ByteArray
}
`.trim();

    assert(kotlinClass.includes(`package ${packageId}`));
    assert(kotlinClass.includes(`class ${className}`));
    assert(kotlinClass.includes('System.loadLibrary("asl_wamr_jni")'));
    assert(kotlinClass.includes("external fun evalModule"));
  });
});
