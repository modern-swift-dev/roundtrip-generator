import assert from "node:assert/strict";
import { createApp } from "./dist/server.js";

const server = createApp().listen(0);
await new Promise((resolve) => server.once("listening", resolve));

try {
    const address = server.address();
    const base = `http://127.0.0.1:${address.port}`;
    const profileId = "550E8400-E29B-41D4-A716-446655440000";
    const authorization = { authorization: "Bearer future-user" };

    const unauthorized = await fetch(`${base}/profiles/${profileId}`);
    assert.equal(unauthorized.status, 401);
    assert.deepEqual(await unauthorized.json(), { code: "AUTH_REQUIRED" });

    const profile = await fetch(`${base}/profiles/${profileId}?fields=biography`, { headers: authorization });
    assert.equal(profile.status, 200);
    assert.equal(profile.headers.get("x-profile-owner"), "future-user");
    assert.equal(
        await profile.text(),
        `{"id":"${profileId}","first_name":"Ada","biography":null,"created_at":"2026-09-21T12:34:56.000Z"}`
    );

    const omitted = await fetch(`${base}/profiles/${profileId}?fields=omit-biography`, { headers: authorization });
    assert.equal(omitted.status, 200);
    assert.equal(
        await omitted.text(),
        `{"id":"${profileId}","first_name":"Ada","created_at":"2026-09-21T12:34:56.000Z"}`
    );

    const invalidUUID = await fetch(`${base}/profiles/not-a-uuid`, { headers: authorization });
    assert.equal(invalidUUID.status, 400);
    assert.deepEqual(await invalidUUID.json(), { code: "GENERATED_INPUT" });

    const invalidRule = await fetch(`${base}/profiles/${profileId}?fields=private-payment`, { headers: authorization });
    assert.equal(invalidRule.status, 400);
    assert.deepEqual(await invalidRule.json(), { code: "GENERATED_INPUT" });

    const missing = await fetch(`${base}/profiles/${profileId}?fields=missing`, { headers: authorization });
    assert.equal(missing.status, 404);
    assert.deepEqual(await missing.json(), { code: "PROFILE_NOT_FOUND" });

    const invalidOutput = await fetch(`${base}/profiles/${profileId}?fields=invalid-output`, { headers: authorization });
    assert.equal(invalidOutput.status, 500);
    assert.equal(invalidOutput.headers.get("x-profile-owner"), null);
    assert.deepEqual(await invalidOutput.json(), { code: "GENERATED_OUTPUT" });

    const patch = await fetch(`${base}/profiles/${profileId}`, {
        method: "PATCH",
        headers: { ...authorization, "content-type": "application/json" },
        body: '{"first_name":"Grace","biography":null}'
    });
    assert.equal(patch.status, 200);
    assert.equal(await patch.text(), '{"first_name":"Grace","biography":null}');

    const ledgerBody = `{"entries":[{"entry_name":"charge","amount":9223372036854775807,"captured_at":"2026-09-21T12:34:56Z","evidence":"AQID"}],"totals":{"gross":18446744073709551615}}`;
    const ledger = await fetch(`${base}/profiles/${profileId}/ledger`, {
        method: "POST",
        headers: { ...authorization, "content-type": "application/json" },
        body: ledgerBody
    });
    assert.equal(ledger.status, 200, await ledger.clone().text());
    assert.equal(
        await ledger.text(),
        '{"entries":[{"entry_name":"charge","amount":9223372036854775807,"captured_at":"2026-09-21T12:34:56.000Z","evidence":"AQID"}],"totals":{"gross":18446744073709551615}}'
    );

    const photo = new FormData();
    photo.append("file", new Blob([new Uint8Array([0, 255, 1])], { type: "image/png" }), "profile.png");
    photo.append("metadata", new Blob(["profile"], { type: "application/json" }));
    const uploaded = await fetch(`${base}/profiles/${profileId}/photo`, {
        method: "POST",
        headers: authorization,
        body: photo
    });
    assert.equal(uploaded.status, 201);
    assert.equal(uploaded.headers.get("x-profile-owner"), "future-user");
    assert.equal(uploaded.headers.get("x-middleware-order"), "auth,context,upload,handler");
    assert.deepEqual(await uploaded.json(), { profile_id: profileId, byte_count: 3 });

    const incompletePhoto = new FormData();
    incompletePhoto.append("file", new Blob([new Uint8Array([1])], { type: "image/png" }), "profile.png");
    const incompleteUpload = await fetch(`${base}/profiles/${profileId}/photo`, {
        method: "POST",
        headers: authorization,
        body: incompletePhoto
    });
    assert.equal(incompleteUpload.status, 400);
    assert.deepEqual(await incompleteUpload.json(), { code: "GENERATED_INPUT" });

    const invalidPhoto = new FormData();
    invalidPhoto.append("file", new Blob(["not-an-image"], { type: "text/plain" }), "profile.txt");
    invalidPhoto.append("metadata", "profile");
    const rejectedUpload = await fetch(`${base}/profiles/${profileId}/photo`, {
        method: "POST",
        headers: authorization,
        body: invalidPhoto
    });
    assert.equal(rejectedUpload.status, 415);
    assert.deepEqual(await rejectedUpload.json(), { code: "UPLOAD_REJECTED" });

    const boundary = "future-receipt-boundary";
    const receiptText = `--${boundary}\r\nContent-Disposition: form-data; name="receipt"\r\n\r\nfirst\r\n--${boundary}\r\nContent-Disposition: form-data; name="receipt"\r\n\r\nsecond\r\n--${boundary}--\r\n`;
    const receiptBytes = new TextEncoder().encode(receiptText);
    const receipts = await fetch(`${base}/receipts/raw`, {
        method: "POST",
        headers: { "content-type": `multipart/form-data; boundary=${boundary}` },
        body: receiptBytes
    });
    assert.equal(receipts.status, 200);
    assert.deepEqual(new Uint8Array(await receipts.arrayBuffer()), receiptBytes);
} finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}
