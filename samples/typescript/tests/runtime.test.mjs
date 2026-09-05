import assert from "node:assert/strict";
import test from "node:test";
import { arrayBufferToBase64, base64ToArrayBuffer } from "../dist/generated/runtime.js";

test("base64 encoding preserves padding and bytes across chunk boundaries", () => {
    for (const length of [0, 1, 2, 3, 255, 24_575, 24_576, 24_577, 49_153, 1_048_576]) {
        const bytes = Uint8Array.from({ length }, (_, index) => index % 256);
        const encoded = arrayBufferToBase64(bytes.buffer);
        assert.equal(encoded, Buffer.from(bytes).toString("base64"), `length ${length}`);
        assert.deepEqual(new Uint8Array(base64ToArrayBuffer(encoded)), bytes);
    }
});

const { decodeStructureType, decodeSampleVisibility, decodeSampleScore } = await import("../dist/generated/models.js");

test("enum decoding preserves coercion, unknown fallback, and rejection", () => {
    for (const value of ["plant", "production_line", "workstation", "equipment"]) {
        assert.equal(decodeStructureType(value), value);
    }
    assert.equal(decodeStructureType({ toString: () => "plant" }), "plant");
    assert.throws(() => decodeStructureType("unknown"), /Unknown StructureType value/);
    for (const value of ["public", "internal", "private"]) {
        assert.equal(decodeSampleVisibility(value), value);
    }
    assert.equal(decodeSampleVisibility("unknown"), "__garbage__");
    for (const value of [10, 50, 100]) {
        assert.equal(decodeSampleScore(value), value);
        assert.equal(decodeSampleScore(String(value)), value);
    }
    for (const value of [0, 42, Number.NaN, null, undefined]) {
        assert.throws(() => decodeSampleScore(value), /Unknown SampleScore value/);
    }
});
