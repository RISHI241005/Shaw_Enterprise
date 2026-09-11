"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

process.env.SESSION_SECRET = "test-session-secret-with-more-than-thirty-two-characters";
const helpers = require("../api/index")._test;

test("escapes untrusted HTML", () => {
  assert.equal(helpers.escapeHtml('<script>"x"</script>'), "&lt;script&gt;&quot;x&quot;&lt;/script&gt;");
});

test("signs and verifies session values", () => {
  const token = helpers.signed("admin:123");
  assert.equal(helpers.validSigned(token), "admin:123");
  assert.equal(helpers.validSigned(`${token}x`), false);
});

test("masks customer email", () => {
  assert.equal(helpers.safeEmail("buyer@example.com"), "bu***@example.com");
});

test("normalizes Indian and international phone numbers", () => {
  assert.equal(helpers.normalizePhone("98765 43210"), "+919876543210");
  assert.equal(helpers.normalizePhone("+1 (415) 555-2671"), "+14155552671");
  assert.equal(helpers.normalizePhone("123"), null);
});

test("masks verified phone numbers", () => {
  assert.equal(helpers.safeContact("+919876543210"), "+91*****3210");
});

test("publishes a masked identity without exposing its destination", () => {
  assert.deepEqual(helpers.publicIdentity({ email: "+919876543210", verification_channel: "phone", verified: 1 }), {
    channel: "phone",
    contact: "+91*****3210",
    email: "+91*****3210",
    verified: true
  });
});

test("generates a six-digit dummy OTP", () => {
  assert.match(helpers.generateDummyOtp(), /^\d{6}$/);
});
