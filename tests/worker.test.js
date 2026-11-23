import test from "node:test";
import assert from "node:assert/strict";
import worker from "../src/index.js";

test("health endpoint returns the FUL454 service status without caching", async () => {
  const response = await worker.fetch(new Request("https://ful454.example/health"), {
    ASSETS: { fetch: async () => { throw new Error("Assets must not be called for health"); } }
  });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    ok: true,
    app: "FUL454",
    service: "cloudflare-worker"
  });
  assert.equal(response.headers.get("cache-control"), "no-store");
});

test("health endpoint includes baseline security headers", async () => {
  const response = await worker.fetch(new Request("https://ful454.example/health"), {
    ASSETS: { fetch: async () => new Response("unused") }
  });
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "DENY");
  assert.equal(response.headers.get("referrer-policy"), "strict-origin-when-cross-origin");
  assert.match(response.headers.get("strict-transport-security") || "", /max-age=31536000/);
  assert.equal(response.headers.get("permissions-policy"), "camera=(), microphone=(), geolocation=()");
});

test("static asset responses preserve body/status and receive security headers", async () => {
  const assetResponse = new Response("FUL454 homepage", {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=60" }
  });
  const response = await worker.fetch(new Request("https://ful454.example/"), {
    ASSETS: { fetch: async () => assetResponse }
  });
  assert.equal(response.status, 200);
  assert.equal(await response.text(), "FUL454 homepage");
  assert.equal(response.headers.get("content-type"), "text/html; charset=utf-8");
  assert.equal(response.headers.get("cache-control"), "public, max-age=60");
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "DENY");
  assert.equal(response.headers.get("x-permitted-cross-domain-policies"), "none");
});

test("asset errors are not disguised as successful responses", async () => {
  const response = await worker.fetch(new Request("https://ful454.example/missing"), {
    ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) }
  });
  assert.equal(response.status, 404);
  assert.equal(await response.text(), "Not found");
});
