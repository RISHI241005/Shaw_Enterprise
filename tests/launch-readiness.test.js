const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const http = require("node:http");
const net = require("node:net");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const root = path.join(__dirname, "..");

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
    server.on("error", reject);
  });
}

function cookieHeader(jar) {
  return Object.entries(jar).map(([key, value]) => `${key}=${value}`).join("; ");
}

function storeCookies(jar, headers) {
  for (let index = 0; index < headers.length; index += 2) {
    if (headers[index].toLowerCase() !== "set-cookie") continue;
    const cookie = headers[index + 1].split(";")[0];
    const splitAt = cookie.indexOf("=");
    jar[cookie.slice(0, splitAt)] = cookie.slice(splitAt + 1);
  }
}

function request(port, jar, method, pathname, body, headers = {}) {
  const payload = body === undefined ? null : typeof body === "string" ? body : JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: "localhost",
      port,
      path: pathname,
      method,
      headers: {
        ...(payload ? { "Content-Length": Buffer.byteLength(payload), "Content-Type": "application/json" } : {}),
        ...(Object.keys(jar).length ? { Cookie: cookieHeader(jar) } : {}),
        ...headers
      }
    }, (res) => {
      let text = "";
      res.setEncoding("utf8");
      res.on("data", (chunk) => { text += chunk; });
      res.on("end", () => {
        storeCookies(jar, res.rawHeaders);
        const json = (() => {
          try {
            return JSON.parse(text);
          } catch {
            return null;
          }
        })();
        resolve({ status: res.statusCode, headers: res.headers, text, json });
      });
    });
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function startServer(extraEnv = {}) {
  const port = await freePort();
  const dataDir = path.join(os.tmpdir(), `shaw-test-${Date.now()}-${Math.random().toString(16).slice(2)}`);
  const child = spawn(process.execPath, ["--experimental-sqlite", "server.js"], {
    cwd: root,
    env: {
      ...process.env,
      PORT: String(port),
      DATA_DIR: dataDir,
      NODE_ENV: "test",
      MYSQL_SYNC_ENABLED: "false",
      ...extraEnv
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += chunk; });
  child.stderr.on("data", (chunk) => { output += chunk; });
  for (let attempt = 0; attempt < 80; attempt += 1) {
    if (child.exitCode !== null) throw new Error(output);
    try {
      const health = await request(port, {}, "GET", "/healthz");
      if (health.status === 200) return { port, dataDir, child };
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  child.kill();
  throw new Error(`Server did not start: ${output}`);
}

function stopServer(child) {
  if (child.exitCode === null) child.kill();
}

function csrfFrom(html) {
  return html.match(/<meta name="csrf-token" content="([^"]+)"/)?.[1] || "";
}

test("public routes, enquiries, admin inquiry status, feedback, moderation, and product CRUD work", async () => {
  const { port, child } = await startServer();
  try {
    const jar = {};
    for (const pathname of ["/", "/products", "/contact", "/feedback", "/login", "/styles.css", "/client.js", "/logo.svg"]) {
      const response = await request(port, jar, "GET", pathname);
      assert.equal(response.status, 200, pathname);
    }

    const contact = await request(port, jar, "GET", "/contact");
    const csrf = csrfFrom(contact.text);
    assert.match(csrf, /^[a-f0-9]{48}$/);

    const inquiry = await request(port, jar, "POST", "/api/inquiries", {
      name: "Launch Test",
      email: "launch@example.com",
      phone: "9999999999",
      message: "Need bulk pricing"
    }, { "X-CSRF-Token": csrf });
    assert.equal(inquiry.status, 201);
    assert.equal(inquiry.json.inquiry.status, "new");

    const login = await request(port, jar, "POST", "/login", "_csrf=" + csrf + "&username=admin&password=change-me-now", {
      "Content-Type": "application/x-www-form-urlencoded"
    });
    assert.equal(login.status, 302);
    assert.ok(jar.shaw_admin);

    const admin = await request(port, jar, "GET", "/admin");
    assert.equal(admin.status, 200);

    const inquiries = await request(port, jar, "GET", "/api/admin/inquiries");
    assert.equal(inquiries.status, 200);
    assert.equal(inquiries.json.inquiries[0].status, "new");

    const status = await request(port, jar, "POST", `/api/admin/inquiries/${inquiries.json.inquiries[0].id}/status`, {
      status: "contacted"
    }, { "X-CSRF-Token": csrf });
    assert.equal(status.status, 200);
    assert.equal(status.json.inquiries[0].status, "contacted");

    const otp = await request(port, jar, "POST", "/api/feedback/request-otp", { email: "review@example.com" }, { "X-CSRF-Token": csrf });
    assert.equal(otp.status, 200);
    assert.match(otp.json.devOtp, /^\d{6}$/);

    const verified = await request(port, jar, "POST", "/api/feedback/verify-otp", { email: "review@example.com", otp: otp.json.devOtp }, { "X-CSRF-Token": csrf });
    assert.equal(verified.status, 200);
    assert.equal(verified.json.identity.verified, true);

    const feedback = await request(port, jar, "POST", "/api/feedback", { message: "Great service" }, { "X-CSRF-Token": csrf });
    assert.equal(feedback.status, 201);

    const threadList = await request(port, jar, "GET", "/api/feedback");
    assert.equal(threadList.status, 200);
    const feedbackId = threadList.json.threads[0].id;

    const reaction = await request(port, jar, "POST", `/api/feedback/${feedbackId}/react`, { reaction: "heart" }, { "X-CSRF-Token": csrf });
    assert.equal(reaction.status, 200);

    const hidden = await request(port, jar, "POST", `/api/admin/feedback/${feedbackId}/hide`, undefined, { "X-CSRF-Token": csrf });
    assert.equal(hidden.status, 200);
    assert.equal(hidden.json.feedback[0].status, "hidden");

    const createProduct = await request(port, jar, "POST", "/api/admin/products", {
      name: "Launch Test Cups",
      category: "Cups",
      price: "Rs. 10 / 1 pc",
      productType: "Test disposable",
      summary: "Test summary",
      details: "Test details",
      packSize: "1 pc",
      audience: "Test buyers",
      images: [],
      featured: false
    }, { "X-CSRF-Token": csrf });
    assert.equal(createProduct.status, 201);
    const product = createProduct.json.products.find((item) => item.name === "Launch Test Cups");
    assert.ok(product);

    const updateProduct = await request(port, jar, "PUT", `/api/admin/products/${product.id}`, {
      ...product,
      productType: product.productType,
      packSize: product.packSize,
      name: "Launch Test Cups Updated"
    }, { "X-CSRF-Token": csrf });
    assert.equal(updateProduct.status, 200);

    const deleteProduct = await request(port, jar, "DELETE", `/api/admin/products/${product.id}`, undefined, { "X-CSRF-Token": csrf });
    assert.equal(deleteProduct.status, 200);
  } finally {
    stopServer(child);
  }
});

test("production config rejects unsafe defaults", async () => {
  const port = await freePort();
  const child = spawn(process.execPath, ["--experimental-sqlite", "server.js"], {
    cwd: root,
    env: {
      ...process.env,
      PORT: String(port),
      DATA_DIR: path.join(os.tmpdir(), `shaw-prod-bad-${Date.now()}`),
      NODE_ENV: "production",
      ADMIN_USER: "admin",
      ADMIN_PASSWORD: "change-me-now",
      SESSION_SECRET: "short",
      MYSQL_SYNC_ENABLED: "false",
      EMAIL_PROVIDER: "dev"
    },
    stdio: ["ignore", "ignore", "pipe"]
  });
  const exitCode = await new Promise((resolve) => child.on("exit", resolve));
  assert.notEqual(exitCode, 0);
});

test("production OTP response does not expose devOtp", async () => {
  const { port, child } = await startServer({
    NODE_ENV: "production",
    ADMIN_USER: "owner",
    ADMIN_PASSWORD: "super-secure-password",
    SESSION_SECRET: "0123456789abcdef0123456789abcdef",
    EMAIL_PROVIDER: "console"
  });
  try {
    const jar = {};
    const contact = await request(port, jar, "GET", "/contact");
    const csrf = csrfFrom(contact.text);
    const otp = await request(port, jar, "POST", "/api/feedback/request-otp", { email: "prod@example.com" }, { "X-CSRF-Token": csrf });
    assert.equal(otp.status, 200);
    assert.equal(Object.hasOwn(otp.json, "devOtp"), false);
  } finally {
    stopServer(child);
  }
});
