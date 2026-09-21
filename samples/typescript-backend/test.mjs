import assert from "node:assert/strict";
import { createApp } from "./dist/server.js";

const server = createApp().listen(0);
await new Promise((resolve) => server.once("listening", resolve));

try {
    const address = server.address();
    const response = await fetch(`http://127.0.0.1:${address.port}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ message_text: "hello", private: "removed" })
    });
    assert.equal(response.status, 200);
    assert.equal(await response.text(), '{"message_text":"hello"}');
} finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}
