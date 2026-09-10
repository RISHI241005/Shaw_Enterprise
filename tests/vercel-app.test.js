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
