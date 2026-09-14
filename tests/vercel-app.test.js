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

test("extracts a structured order price from existing catalog labels", () => {
  assert.equal(helpers.parsePriceAmount("Rs. 1,250 / 500 pcs"), 1250);
  assert.equal(helpers.parsePriceAmount("₹95.50 per pack"), 95.5);
  assert.equal(helpers.parsePriceAmount("Ask for quote"), null);
});

test("normalizes duplicate cart lines without trusting client totals", () => {
  assert.deepEqual(helpers.normalizeOrderItems([
    { productId: 8, quantity: 2 },
    { productId: 8, quantity: 3 },
    { productId: 12, quantity: 1 }
  ]), [{ productId: 8, quantity: 5 }, { productId: 12, quantity: 1 }]);
  assert.throws(() => helpers.normalizeOrderItems([{ productId: 8, quantity: 0 }]), /between 1 and 99/);
});

test("calculates delivery from server-side item prices", () => {
  assert.deepEqual(helpers.calculateOrderTotals([{ unitPrice: 150, quantity: 2 }], "delivery"), { subtotal: 300, deliveryFee: 99, total: 399 });
  assert.deepEqual(helpers.calculateOrderTotals([{ unitPrice: 250, quantity: 4 }], "delivery"), { subtotal: 1000, deliveryFee: 0, total: 1000 });
  assert.deepEqual(helpers.calculateOrderTotals([{ unitPrice: 150, quantity: 2 }], "pickup"), { subtotal: 300, deliveryFee: 0, total: 300 });
});
