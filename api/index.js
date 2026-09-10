"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const express = require("express");
const mysql = require("mysql2/promise");

const app = express();
const ROOT = path.resolve(__dirname, "..");
const PUBLIC = path.join(ROOT, "public");
const IS_PRODUCTION = process.env.NODE_ENV === "production" || Boolean(process.env.VERCEL);
const ADMIN_USER = process.env.ADMIN_USER || "admin";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "change-this-admin-password";
const SESSION_SECRET = process.env.SESSION_SECRET || process.env.OTP_SECRET || "local-session-secret-change-me";
const OTP_SECRET = process.env.OTP_SECRET || SESSION_SECRET;
const DEV_EXPOSE_OTP = String(process.env.DEV_EXPOSE_OTP ?? "true") === "true";
const rateLimits = new Map();
let schemaPromise;

function productionConfigurationErrors() {
  if (!IS_PRODUCTION) return [];
  const errors = [];
  if (!(process.env.DATABASE_URL || process.env.TIDB_HOST || process.env.MYSQL_HOST)) errors.push("database connection");
  if (!process.env.ADMIN_PASSWORD || process.env.ADMIN_PASSWORD.length < 12) errors.push("ADMIN_PASSWORD");
  if (!process.env.SESSION_SECRET || process.env.SESSION_SECRET.length < 32) errors.push("SESSION_SECRET");
  if (!process.env.OTP_SECRET || process.env.OTP_SECRET.length < 32) errors.push("OTP_SECRET");
  return errors;
}

function poolOptions() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  const host = process.env.TIDB_HOST || process.env.MYSQL_HOST || "localhost";
  const port = Number(process.env.TIDB_PORT || process.env.MYSQL_PORT || 3306);
  const user = process.env.TIDB_USER || process.env.MYSQL_USER || "root";
  const password = process.env.TIDB_PASSWORD || process.env.MYSQL_PASSWORD || "";
  const database = process.env.TIDB_DATABASE || process.env.MYSQL_DATABASE || "shaw_enterprise";
  const cloud = Boolean(process.env.TIDB_HOST) || String(process.env.MYSQL_SSL) === "true";
  return {
    host, port, user, password, database,
    waitForConnections: true,
    connectionLimit: 6,
    maxIdle: 3,
    enableKeepAlive: true,
    decimalNumbers: true,
    ...(cloud ? { ssl: { minVersion: "TLSv1.2", rejectUnauthorized: true } } : {})
  };
}

let dbPoolInstance;
const dbPool = () => (dbPoolInstance ||= mysql.createPool(poolOptions()));
const q = async (sql, params = []) => (await dbPool().query(sql, params))[0];
const one = async (sql, params = []) => (await q(sql, params))[0] || null;
const now = () => new Date();

const catalogBlueprints = [
  ["Cups", ["Ripple Paper Cup", "Plain Paper Cup", "Printed Tea Cup", "Double Wall Coffee Cup", "Cold Drink Paper Cup", "Kulhad Style Cup"], "Hot and cold beverage disposable", "50 pcs, 100 pcs, bulk carton", "Tea stalls, cafes, offices, caterers", "Disposable cups for tea, coffee, juice, events, and counters.", "Food-grade disposable cups with dependable rim strength and practical insulation.", 68],
  ["Plates", ["Round Paper Plate", "Compartment Meal Plate", "Silver Laminated Plate", "Snack Paper Plate", "Heavy Duty Dinner Plate", "Eco Bagasse Plate"], "Meal serving disposable", "100 pcs, 500 pcs, wholesale carton", "Caterers, households, event managers, retailers", "Strong disposable plates for meals, snacks, events, and food counters.", "Sturdy disposable plates designed for easy stacking and reliable food service.", 90],
  ["Containers", ["Round Food Container", "Rectangular Meal Box", "Clear Lid Container", "Sauce Cup Container", "Bakery Clamshell Box", "Microwave Safe Container"], "Takeaway packaging", "25 pcs, 100 pcs, carton packs", "Restaurants, cloud kitchens, bakeries, sweet shops", "Food containers for takeaway, delivery, storage, and display.", "Stackable food containers with secure closure options for daily operations.", 115],
  ["Cutlery", ["Wooden Spoon Pack", "Disposable Fork Pack", "Dessert Spoon Pack", "Ice Cream Spoon Pack", "Knife Pack", "Mixed Cutlery Kit"], "Disposable cutlery", "100 pcs, 500 pcs, mixed carton", "Food counters, event planners, tasting counters", "Clean disposable spoons, forks, knives, and serving cutlery.", "Smooth-finish disposable cutlery for events and takeaway orders.", 42],
  ["Napkins", ["Tissue Napkin Pack", "Printed Napkin", "Dinner Napkin", "Cocktail Napkin", "Soft Table Tissue", "Dispenser Tissue"], "Table hygiene disposable", "100 pcs, 200 pcs, carton packs", "Restaurants, offices, hotels, party suppliers", "Soft napkins and tissues for tables, counters, and events.", "Clean absorbent napkins for food service and retail use.", 38],
  ["Bags", ["Paper Carry Bag", "Kraft Grocery Bag", "Food Delivery Bag", "Bakery Paper Bag", "Gift Paper Bag", "Retail Counter Bag"], "Carry and retail packaging", "25 pcs, 100 pcs, bulk carton", "Retail shops, bakeries, groceries, restaurants", "Paper carry bags for packing, delivery, and retail counters.", "Durable paper bags available in practical sizes for food and retail.", 130],
  ["Straws", ["Paper Straw Pack", "Bendy Straw Pack", "Milkshake Straw", "Wrapped Straw", "Cocktail Straw", "Jumbo Drink Straw"], "Drink service disposable", "100 pcs, 250 pcs, bulk carton", "Juice shops, cafes, restaurants, event counters", "Disposable straws for cold drinks, shakes, and event service.", "Convenient straw packs for drink counters and retail sale.", 35],
  ["Bowls", ["Paper Soup Bowl", "Salad Bowl", "Dessert Bowl", "Rice Bowl", "Noodle Bowl", "Laminated Snack Bowl"], "Bowl serving disposable", "50 pcs, 100 pcs, carton packs", "Caterers, restaurants, food stalls, events", "Disposable bowls for soups, snacks, rice, desserts, and salads.", "Strong bowl options for hot and cold food service.", 70]
];

async function ensureSchema() {
  if (schemaPromise) return schemaPromise;
  schemaPromise = (async () => {
    const statements = [
      `CREATE TABLE IF NOT EXISTS product_categories (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL UNIQUE, description TEXT, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)`,
      `CREATE TABLE IF NOT EXISTS products (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, category_id BIGINT UNSIGNED NOT NULL, name VARCHAR(180) NOT NULL, sku VARCHAR(60) NOT NULL UNIQUE, price_label VARCHAR(80) NOT NULL, product_type VARCHAR(160) NOT NULL, summary TEXT NOT NULL, details TEXT NOT NULL, pack_size VARCHAR(160) NOT NULL, audience VARCHAR(180) NOT NULL, featured BOOLEAN NOT NULL DEFAULT FALSE, status VARCHAR(20) NOT NULL DEFAULT 'active', created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_products_category(category_id), INDEX idx_products_featured(featured))`,
      `CREATE TABLE IF NOT EXISTS product_images (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, product_id BIGINT UNSIGNED NOT NULL, image_data LONGTEXT NOT NULL, alt_text VARCHAR(220) NOT NULL, sort_order INT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_product_images_product(product_id))`,
      `CREATE TABLE IF NOT EXISTS inquiries (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(160) NOT NULL, email VARCHAR(180) NOT NULL, phone VARCHAR(60) NOT NULL, message TEXT NOT NULL, status VARCHAR(20) NOT NULL DEFAULT 'new', created_at DATETIME NOT NULL, INDEX idx_inquiries_status_created(status, created_at))`,
      `CREATE TABLE IF NOT EXISTS feedback_identities (visitor_id VARCHAR(80) PRIMARY KEY, email VARCHAR(180) NOT NULL, verified BOOLEAN NOT NULL DEFAULT FALSE, created_at DATETIME NOT NULL, updated_at DATETIME NOT NULL, INDEX idx_feedback_identity_email(email))`,
      `CREATE TABLE IF NOT EXISTS feedback_identity_otps (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, visitor_id VARCHAR(80) NOT NULL, email VARCHAR(180) NOT NULL, otp_hash VARCHAR(255) NOT NULL, expires_at DATETIME NOT NULL, used_at DATETIME NULL, created_at DATETIME NOT NULL, INDEX idx_feedback_otps_visitor(visitor_id, created_at))`,
      `CREATE TABLE IF NOT EXISTS feedback_comments (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, visitor_id VARCHAR(80) NOT NULL, author_email VARCHAR(180) NOT NULL, message TEXT NOT NULL, parent_id BIGINT UNSIGNED NULL, product_id BIGINT UNSIGNED NULL, status VARCHAR(20) NOT NULL DEFAULT 'visible', created_at DATETIME NOT NULL, INDEX idx_feedback_parent(parent_id), INDEX idx_feedback_product(product_id))`,
      `CREATE TABLE IF NOT EXISTS feedback_reactions (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, feedback_id BIGINT UNSIGNED NOT NULL, visitor_id VARCHAR(80) NOT NULL, reaction VARCHAR(20) NOT NULL, created_at DATETIME NOT NULL, UNIQUE KEY uq_feedback_reaction_visitor(feedback_id, visitor_id))`,
      `CREATE TABLE IF NOT EXISTS admin_audit_logs (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, action_type VARCHAR(80) NOT NULL, target_type VARCHAR(80) NOT NULL, target_id VARCHAR(80), details TEXT NOT NULL, ip_address VARCHAR(80) NOT NULL, created_at DATETIME NOT NULL, INDEX idx_audit_created(created_at))`,
      `CREATE TABLE IF NOT EXISTS business_settings (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, setting_key VARCHAR(120) NOT NULL UNIQUE, setting_value TEXT NOT NULL, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)`,
      `CREATE TABLE IF NOT EXISTS sync_state (topic VARCHAR(40) PRIMARY KEY, version BIGINT NOT NULL DEFAULT 0, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)`
    ];
    for (const sql of statements) await q(sql);
    await q(`INSERT IGNORE INTO business_settings(setting_key,setting_value) VALUES
      ('business_name','Shaw Enterprise'),('phone','+91 00000 00000'),('email','sales@shawenterprise.example'),
      ('address','Kolkata, West Bengal, India'),('whatsapp','910000000000'),('hours','Monday to Saturday, 10:00 AM–7:00 PM')`);
    await q("INSERT IGNORE INTO sync_state(topic,version) VALUES ('products',0),('feedback',0),('inquiries',0),('settings',0)");
    const count = Number((await one("SELECT COUNT(*) count FROM products"))?.count || 0);
    if (count === 0) await seedCatalog();
  })().catch((error) => { schemaPromise = null; throw error; });
  return schemaPromise;
}

async function seedCatalog() {
  const created = now();
  for (const [category] of catalogBlueprints) {
    await q("INSERT IGNORE INTO product_categories(name,description) VALUES (?,?)", [category, `${category} products for Shaw Enterprise`]);
  }
  const categories = Object.fromEntries((await q("SELECT id,name FROM product_categories")).map((row) => [row.name, row.id]));
  const products = [];
  for (let index = 0; index < 300; index += 1) {
    const [category, names, type, pack, audience, summary, details, basePrice] = catalogBlueprints[index % catalogBlueprints.length];
    const size = ["Small", "Medium", "Large", "Premium", "Economy"][index % 5];
    const packCount = [25, 50, 100, 200, 500][index % 5];
    const itemName = `${size} ${names[Math.floor(index / catalogBlueprints.length) % names.length]} ${String(index + 1).padStart(3, "0")}`;
    const price = basePrice + (index % 17) * 7 + Math.floor(index / 20) * 3;
    products.push([categories[category], itemName, `SE-${String(index + 1).padStart(4, "0")}`, `Rs. ${price} / ${packCount} pcs`, type, summary, `${details} Item code SE-${String(index + 1).padStart(4, "0")} is suited for regular replenishment.`, pack, audience, index < 12, "active", created, created]);
  }
  await q("INSERT INTO products(category_id,name,sku,price_label,product_type,summary,details,pack_size,audience,featured,status,created_at,updated_at) VALUES ?", [products]);
  const ids = await q("SELECT id,name,category_id FROM products ORDER BY id");
  const categoryNames = Object.fromEntries(Object.entries(categories).map(([name, id]) => [String(id), name.toLowerCase()]));
  const images = [];
  for (const row of ids) for (let variant = 1; variant <= 3; variant += 1) images.push([row.id, `/images/generated-${categoryNames[String(row.category_id)]}-${row.id}-${variant}.svg`, row.name, variant - 1]);
  await q("INSERT INTO product_images(product_id,image_data,alt_text,sort_order) VALUES ?", [images]);
}

function cookies(req) {
  return Object.fromEntries(String(req.headers.cookie || "").split(";").filter(Boolean).map((part) => {
    const split = part.indexOf("=");
    return [part.slice(0, split).trim(), decodeURIComponent(part.slice(split + 1))];
  }));
}

function signed(value) { return `${value}.${crypto.createHmac("sha256", SESSION_SECRET).update(value).digest("hex")}`; }
function validSigned(token) {
  if (!token) return false;
  const split = token.lastIndexOf(".");
  if (split < 0) return false;
  const value = token.slice(0, split), signature = token.slice(split + 1), expected = signed(value).slice(split + 1);
  return signature.length === expected.length && crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected)) ? value : false;
}
function isAdmin(req) {
  const payload = validSigned(cookies(req).shaw_admin);
  if (!payload) return false;
  const [, issued] = payload.split(":");
  return Date.now() - Number(issued) < 8 * 60 * 60 * 1000;
}
function clientIp(req) { return String(req.headers["x-forwarded-for"] || req.socket?.remoteAddress || "").split(",")[0].trim().slice(0, 80); }
function rateLimit(req, bucket, limit = 30, windowMs = 60000) {
  const key = `${bucket}:${clientIp(req)}`;
  const moment = Date.now();
  let state = rateLimits.get(key) || { count: 0, until: moment + windowMs };
  if (state.until < moment) state = { count: 0, until: moment + windowMs };
  state.count += 1; rateLimits.set(key, state); return state.count <= limit;
}
function escapeHtml(value = "") { return String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]); }
function safeEmail(email = "") { const [name, domain] = String(email).split("@"); return name && domain ? `${name.slice(0, 2)}***@${domain}` : "Verified customer"; }
function otpHash(code) { return crypto.createHmac("sha256", OTP_SECRET).update(code).digest("hex"); }
function asyncRoute(handler) { return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next); }

async function products() {
  const rows = await q(`SELECT p.*, c.name category FROM products p JOIN product_categories c ON c.id=p.category_id WHERE p.status='active' ORDER BY p.featured DESC,p.id`);
  const images = await q("SELECT product_id,image_data FROM product_images ORDER BY product_id,sort_order");
  const grouped = new Map();
  for (const image of images) { if (!grouped.has(String(image.product_id))) grouped.set(String(image.product_id), []); grouped.get(String(image.product_id)).push(image.image_data); }
  return rows.map((row) => ({ id: Number(row.id), sku: row.sku, name: row.name, category: row.category, price: row.price_label, productType: row.product_type, summary: row.summary, details: row.details, packSize: row.pack_size, audience: row.audience, images: grouped.get(String(row.id)) || [], featured: Boolean(row.featured), createdAt: row.created_at, updatedAt: row.updated_at }));
}
async function product(id) { return (await products()).find((item) => item.id === Number(id)) || null; }
async function business() {
  const values = Object.fromEntries((await q("SELECT setting_key,setting_value FROM business_settings")).map((row) => [row.setting_key, row.setting_value]));
  const destination = encodeURIComponent(values.address || "Kolkata, West Bengal, India");
  return { business_name: values.business_name || "Shaw Enterprise", phone: values.phone || "", email: values.email || "", address: values.address || "", whatsapp: String(values.whatsapp || "").replace(/\D/g, ""), hours: values.hours || "", mapEmbedUrl: `https://maps.google.com/maps?q=${destination}&z=16&output=embed`, mapDirectionsUrl: `https://www.google.com/maps/dir/?api=1&destination=${destination}&dir_action=navigate`, mapSearchUrl: `https://www.google.com/maps/search/?api=1&query=${destination}` };
}
async function metrics() {
  const [p, f, inquiryRows] = await Promise.all([one("SELECT COUNT(*) count,SUM(featured) featured FROM products WHERE status='active'"), one("SELECT COUNT(*) count FROM feedback_comments WHERE status='visible'"), q("SELECT status,COUNT(*) count FROM inquiries GROUP BY status")]);
  const statuses = Object.fromEntries(inquiryRows.map((row) => [row.status, Number(row.count)]));
  return { totalProducts: Number(p?.count || 0), featured: Number(p?.featured || 0), feedback: Number(f?.count || 0), inquiries: { new: statuses.new || 0, contacted: statuses.contacted || 0, closed: statuses.closed || 0, total: inquiryRows.reduce((sum, row) => sum + Number(row.count), 0) } };
}
async function bump(topic) { await q("INSERT INTO sync_state(topic,version) VALUES (?,1) ON DUPLICATE KEY UPDATE version=version+1", [topic]); }
async function audit(req, action, target, id, details = "") { await q("INSERT INTO admin_audit_logs(action_type,target_type,target_id,details,ip_address,created_at) VALUES (?,?,?,?,?,?)", [action, target, String(id || ""), details, clientIp(req), now()]); }

async function feedbackThreads(visitorId, options = {}) {
  const where = [options.includeHidden ? "1=1" : "fc.status='visible'"];
  const params = [];
  if (options.productId === null) where.push("fc.product_id IS NULL");
  else if (options.productId) { where.push("fc.product_id=?"); params.push(options.productId); }
  const rows = await q(`SELECT fc.* FROM feedback_comments fc WHERE ${where.join(" AND ")} ORDER BY fc.created_at DESC`, params);
  const ids = rows.map((row) => Number(row.id));
  const reactionRows = ids.length ? await q(`SELECT feedback_id,visitor_id,reaction FROM feedback_reactions WHERE feedback_id IN (${ids.map(() => "?").join(",")})`, ids) : [];
  const items = new Map(rows.map((row) => {
    const reactions = reactionRows.filter((reaction) => Number(reaction.feedback_id) === Number(row.id));
    return [Number(row.id), { id: Number(row.id), authorEmail: row.author_email, displayLabel: safeEmail(row.author_email), message: row.message, parentId: row.parent_id ? Number(row.parent_id) : null, productId: row.product_id ? Number(row.product_id) : null, status: row.status, createdAt: row.created_at, reactions: { like: reactions.filter((r) => r.reaction === "like").length, heart: reactions.filter((r) => r.reaction === "heart").length }, myReaction: reactions.find((r) => r.visitor_id === visitorId)?.reaction || null, replies: [] }];
  }));
  const roots = [];
  for (const item of items.values()) { if (item.parentId && items.has(item.parentId)) items.get(item.parentId).replies.unshift(item); else roots.push(item); }
  return roots.sort((a, b) => options.sort === "top" ? (b.reactions.like + b.reactions.heart * 2 + b.replies.length) - (a.reactions.like + a.reactions.heart * 2 + a.replies.length) : new Date(b.createdAt) - new Date(a.createdAt));
}

function productCard(item) {
  return `<article class="product-card" data-product-id="${item.id}" data-name="${escapeHtml(`${item.name} ${item.category} ${item.summary}`.toLowerCase())}" data-category="${escapeHtml(item.category.toLowerCase())}" data-summary="${escapeHtml(item.summary.toLowerCase())}" data-details="${escapeHtml(item.details.toLowerCase())}" data-pack="${escapeHtml(item.packSize.toLowerCase())}" data-audience="${escapeHtml(item.audience.toLowerCase())}"><img src="${escapeHtml(item.images[0] || "/images/product.svg")}" alt="${escapeHtml(item.name)}"><div class="product-card-body"><p class="tag">${escapeHtml(item.category)}</p><h3>${escapeHtml(item.name)}</h3><p>${escapeHtml(item.summary)}</p><div class="product-meta"><strong>${escapeHtml(item.price)}</strong><span>${escapeHtml(item.packSize)}</span></div><button class="button small view-product" type="button" data-product-id="${item.id}">View Product</button></div></article>`;
}
function layout(title, content, req, info) {
  const nav = [["/", "Home"], ["/products", "Products"], ["/feedback", "Feedback"], ["/contact", "Contact"], [isAdmin(req) ? "/admin" : "/login", "Admin"]];
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)} | Shaw Enterprise</title><meta name="csrf-token" content="${escapeHtml(req.csrfToken)}"><link rel="stylesheet" href="/styles.css"><script defer src="/client.js"></script></head><body><div class="launch-screen" aria-hidden="true"><div class="launch-mark">SE</div><p>STOCK IN MOTION</p><i></i></div><div class="page-atmosphere" aria-hidden="true"></div><header class="site-header"><a class="brand" href="/"><img src="/logo.svg" alt="Shaw Enterprise"></a><button class="nav-toggle" type="button">Menu</button><nav class="site-nav">${nav.map(([url, label]) => `<a href="${url}">${label}</a>`).join("")}</nav></header><main>${content}</main><footer class="site-footer"><div><strong>${escapeHtml(info.business_name)}</strong><span>Wholesale and retail disposable products.</span></div><div>${escapeHtml(info.phone)} | ${escapeHtml(info.email)}</div></footer></body></html>`;
}

app.disable("x-powered-by");
app.use(express.json({ limit: "4mb" }));
app.use(express.urlencoded({ extended: false, limit: "1mb" }));
app.use((req, res, next) => {
  res.set({ "X-Content-Type-Options": "nosniff", "X-Frame-Options": "SAMEORIGIN", "Referrer-Policy": "strict-origin-when-cross-origin", "Permissions-Policy": "camera=(), microphone=(), geolocation=()", "Content-Security-Policy": "default-src 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self'; frame-src https://maps.google.com https://www.google.com; connect-src 'self'; base-uri 'self'; form-action 'self'" });
  const jar = cookies(req);
  let visitor = jar.visitor_id;
  if (!/^[a-f0-9]{24}$/.test(visitor || "")) { visitor = crypto.randomBytes(12).toString("hex"); res.cookie("visitor_id", visitor, { httpOnly: true, sameSite: "lax", secure: IS_PRODUCTION, maxAge: 365 * 86400000 }); }
  let csrf = jar.csrf_token;
  if (!/^[a-f0-9]{48}$/.test(csrf || "")) { csrf = crypto.randomBytes(24).toString("hex"); res.cookie("csrf_token", csrf, { sameSite: "strict", secure: IS_PRODUCTION, maxAge: 3600000 }); }
  req.visitorId = visitor; req.csrfToken = csrf; next();
});

function validCsrf(req) { return ["GET", "HEAD", "OPTIONS"].includes(req.method) || (cookies(req).csrf_token && (req.get("x-csrf-token") || req.body?._csrf) === cookies(req).csrf_token); }
function requireCsrf(req, res, next) { if (!validCsrf(req)) return res.status(403).json({ error: "Security token expired. Reload and try again." }); next(); }
function requireAdmin(req, res, next) { if (!isAdmin(req)) return res.status(401).json({ error: "Admin login required" }); next(); }

app.get(["/styles.css", "/client.js", "/logo.svg"], (req, res) => res.sendFile(path.join(PUBLIC, req.path.slice(1))));
app.get("/images/:name", (req, res) => {
  const local = path.join(PUBLIC, "images", path.basename(req.params.name));
  if (fs.existsSync(local)) return res.sendFile(local);
  const label = req.params.name.split("-")[1] || "Products";
  res.type("image/svg+xml").send(`<svg width="900" height="620" viewBox="0 0 900 620" xmlns="http://www.w3.org/2000/svg"><rect width="900" height="620" fill="#f4e9d2"/><rect x="70" y="70" width="760" height="480" rx="38" fill="#fff" opacity=".78"/><circle cx="450" cy="260" r="128" fill="#0f2f2e" opacity=".12"/><text x="450" y="292" text-anchor="middle" fill="#0f2f2e" font-family="Georgia" font-size="54" font-weight="700">${escapeHtml(label)}</text><text x="450" y="365" text-anchor="middle" fill="#304b49" font-family="Verdana" font-size="22">Shaw Enterprise</text></svg>`);
});

app.use((req, res, next) => {
  const errors = productionConfigurationErrors();
  if (!errors.length) return next();
  const payload = { ok: false, error: "Production configuration is incomplete", missing: errors };
  if (req.path === "/healthz" || req.path.startsWith("/api/")) return res.status(503).json(payload);
  return res.status(503).send(`<h1>Service setup in progress</h1><p>The production database and security configuration must be completed before launch.</p>`);
});
app.use(asyncRoute(async (req, res, next) => { await ensureSchema(); next(); }));

app.get("/healthz", asyncRoute(async (_req, res) => { const count = await one("SELECT COUNT(*) count FROM products"); res.json({ ok: true, service: "shaw-enterprise-vercel", runtime: "node", database: process.env.TIDB_HOST ? "tidb-mysql" : "mysql", products: Number(count.count), liveSync: true }); }));
app.get("/", asyncRoute(async (req, res) => {
  const [items, info, stats] = await Promise.all([products(), business(), metrics()]);
  const featured = items.filter((item) => item.featured).slice(0, 3);
  res.send(layout("Home", `<section class="hero"><div class="hero-media"></div><div class="hero-content"><div class="hero-topline"><span>INDIA / WHOLESALE SUPPLY</span><span>EST. 2012</span></div><p class="eyebrow">Wholesale and retail disposable products</p><h1><span>Shaw</span> <span class="outline-word">Enterprise</span></h1><p>Reliable cups, plates, containers, cutlery, and packaging supplies for shops, caterers, offices, and events.</p><div class="hero-metrics"><span><strong>${stats.totalProducts}</strong> active SKUs</span><span><strong>${new Set(items.map((i) => i.category)).size}</strong> product types</span><span><strong>${stats.featured}</strong> featured items</span></div><div class="hero-actions"><a class="button primary" href="/products">View Products</a><a class="button ghost" href="https://wa.me/${info.whatsapp}">WhatsApp Enquiry</a></div></div></section><section class="band"><div class="section-head"><p class="eyebrow">About the business</p><h2>Professional supply for everyday food service.</h2></div><div class="feature-grid"><article><span class="feature-icon">01</span><h3>Wholesale Ready</h3><p>Bulk carton supply and consistent repeat-order handling.</p></article><article><span class="feature-icon">02</span><h3>Retail Friendly</h3><p>Practical pack sizes for homes, shops, and event buyers.</p></article><article><span class="feature-icon">03</span><h3>Fast Enquiries</h3><p>Contact through the website, phone, or WhatsApp.</p></article></div></section><section class="band tint"><div class="section-head"><p class="eyebrow">Featured stock</p><h2>Popular disposable items</h2></div><div class="product-grid">${featured.map(productCard).join("")}</div></section><aside class="product-panel" id="productPanel" aria-hidden="true"></aside>`, req, info));
}));
app.get("/products", asyncRoute(async (req, res) => {
  const [items, info] = await Promise.all([products(), business()]); const categories = [...new Set(items.map((item) => item.category))];
  res.send(layout("Products", `<section class="page-title catalog-title"><p class="eyebrow">Curated product catalog</p><h1>Everything your business needs, in one place.</h1><p>Browse dependable everyday disposables for shops, events, delivery, and food service.</p></section><section class="band"><div class="catalog-toolbar"><div class="catalog-toolbar-top"><label class="catalog-search-field"><span>⌕</span><input id="productSearch" type="search" placeholder="Search products, categories or uses"></label><label class="catalog-sort-field"><span>Sort</span><select id="productSort"><option value="featured">Featured first</option><option value="name-asc">Name: A–Z</option><option value="name-desc">Name: Z–A</option></select></label></div><div class="catalog-filter-row"><button class="filter-chip active" type="button" data-category="all">All <span>${items.length}</span></button>${categories.map((category) => `<button class="filter-chip" type="button" data-category="${escapeHtml(category.toLowerCase())}">${escapeHtml(category)}</button>`).join("")}</div><div class="catalog-status"><p id="catalogCount">Showing all ${items.length} products</p><p class="catalog-empty" hidden>No products found.</p></div></div><div class="product-grid" id="productGrid">${items.map(productCard).join("")}</div></section><aside class="product-panel" id="productPanel" aria-hidden="true"></aside>`, req, info));
}));
app.get("/feedback", asyncRoute(async (req, res) => { const [identity, info] = await Promise.all([one("SELECT email,verified FROM feedback_identities WHERE visitor_id=?", [req.visitorId]), business()]); const publicIdentity = identity ? { email: safeEmail(identity.email), verified: Boolean(identity.verified) } : null; res.send(layout("Feedback", `<section class="page-title compact"><p class="eyebrow">Community feedback</p><h1>Customer feedback and product reviews.</h1></section><section class="feedback-shell" data-identity='${escapeHtml(JSON.stringify(publicIdentity))}'><form class="feedback-form" id="feedbackForm"><div id="feedbackIdentity"></div><label>Feedback<textarea name="message" rows="4" placeholder="Share your experience" required maxlength="5000"></textarea></label><button class="button primary" type="submit">Post Feedback</button><p class="form-note" id="otpNote"></p></form><div class="feedback-toolbar"><strong>Comments</strong><select id="feedbackSort"><option value="top">Top</option><option value="newest">Newest</option></select></div><div id="feedbackList" class="feedback-list"></div><button class="button ghost" id="loadMoreFeedback" type="button">Load More</button></section>`, req, info)); }));
app.get("/contact", asyncRoute(async (req, res) => { const info = await business(); res.send(layout("Contact", `<section class="page-title compact"><p class="eyebrow">Contact & directions</p><h1>Send an enquiry or plan your visit.</h1></section><section class="contact-layout"><form class="contact-form"><label>Name<input name="name" required maxlength="160"></label><label>Email<input name="email" type="email" required maxlength="180"></label><label>Phone<input name="phone" required maxlength="60"></label><label>Message<textarea name="message" rows="5" required maxlength="5000"></textarea></label><button class="button primary" type="submit">Send Enquiry</button><p class="form-note contact-note"></p></form><aside class="contact-card"><p class="eyebrow">Business details</p><h2>${escapeHtml(info.business_name)}</h2><a class="contact-detail" href="tel:${escapeHtml(info.phone)}">${escapeHtml(info.phone)}</a><a class="contact-detail" href="mailto:${escapeHtml(info.email)}">${escapeHtml(info.email)}</a><p>${escapeHtml(info.address)}</p><p>${escapeHtml(info.hours)}</p><div class="contact-actions"><a class="button primary" href="${info.mapDirectionsUrl}" target="_blank" rel="noopener">Get directions</a><a class="button ghost" href="https://wa.me/${info.whatsapp}" target="_blank" rel="noopener">Open WhatsApp</a></div></aside><div class="map-card"><iframe src="${info.mapEmbedUrl}" title="Shaw Enterprise location" loading="lazy" allowfullscreen></iframe><div><strong>Open on your phone</strong><p>Google Maps will guide you to the enterprise.</p><a class="button ghost" href="${info.mapDirectionsUrl}" target="_blank" rel="noopener">Navigate with Google Maps</a></div></div></section>`, req, info)); }));

app.get("/login", asyncRoute(async (req, res) => { const info = await business(); res.send(layout("Admin Login", `<section class="auth-wrap"><div class="auth-shell"><aside class="auth-intro"><img src="/logo.svg" alt="Shaw Enterprise"><p class="eyebrow">Secure workspace</p><h1>Manage the business with confidence.</h1><p>Protected access and one control centre for your team.</p></aside><div class="auth-card"><div class="auth-card-head"><p class="eyebrow">Administrator portal</p><h2>Welcome back</h2></div><p class="auth-status" id="authStatus"></p><form id="loginForm" class="auth-form"><label>Username<input name="username" autocomplete="username" required></label><label>Password<span class="password-field"><input name="password" type="password" autocomplete="current-password" required><button class="password-toggle" type="button">Show</button></span></label><button class="button primary auth-submit" type="submit">Sign in securely <span>→</span></button></form></div></div></section>`, req, info)); }));
app.get("/logout", (req, res) => { res.clearCookie("shaw_admin"); res.redirect("/login"); });

function adminTabs(active) { return `<nav class="admin-tabs">${[["products","Products"],["inquiries","Inquiries"],["feedback","Feedback"],["audits","Audits"],["settings","Business & Map"]].map(([key,label]) => `<a class="${active === key ? "active" : ""}" href="/admin/${key}">${label}</a>`).join("")}</nav>`; }
app.get(["/admin", "/admin/:tab"], asyncRoute(async (req, res) => {
  if (!isAdmin(req)) return res.redirect("/login"); const active = req.params.tab || "products"; const [stats, info] = await Promise.all([metrics(), business()]);
  const sections = {
    products: `<section class="admin-section"><h2>Product Management</h2><form id="productForm" class="admin-form"><input type="hidden" name="id"><label>Name<input name="name" required></label><label>Category<input name="category" required></label><label>Price<input name="price" required></label><label>Type<input name="productType" required></label><label>Pack Size<input name="packSize" required></label><label>Audience<input name="audience" required></label><label>Summary<textarea name="summary" rows="2" required></textarea></label><label>Details<textarea name="details" rows="4" required></textarea></label><label>Product Images<input name="imageFiles" type="file" accept="image/*" multiple></label><input name="images" type="hidden"><div class="image-preview-grid" id="imagePreviewGrid"></div><label class="check"><input name="featured" type="checkbox"> Featured product</label><div class="admin-actions"><button class="button primary" type="submit">Save Product</button><button class="button ghost" id="resetProductForm" type="button">Clear</button></div></form><div id="adminProducts" class="admin-list"></div></section>`,
    inquiries: `<section class="admin-section"><h2>Inquiries</h2><div id="adminInquiries" class="admin-list"></div></section>`,
    feedback: `<section class="admin-section"><h2>Feedback Moderation</h2><div id="adminFeedback" class="admin-list"></div></section>`,
    audits: `<section class="admin-section"><h2>Audit Log</h2><div id="auditLog" class="audit-list"></div></section>`,
    settings: `<section class="admin-section"><div class="section-head"><p class="eyebrow">Single source of truth</p><h2>Business details & map location</h2><p>These values update the public map, footer, phone, email, and WhatsApp links together.</p></div><form id="businessSettingsForm" class="admin-form settings-form"><label>Business name<input name="business_name" value="${escapeHtml(info.business_name)}" required></label><label>Phone<input name="phone" value="${escapeHtml(info.phone)}" required></label><label>Email<input name="email" type="email" value="${escapeHtml(info.email)}" required></label><label>WhatsApp number<input name="whatsapp" value="${escapeHtml(info.whatsapp)}" required></label><label class="wide">Exact enterprise address<input name="address" value="${escapeHtml(info.address)}" required></label><label class="wide">Opening hours<input name="hours" value="${escapeHtml(info.hours)}" required></label><div class="admin-actions wide"><button class="button primary" type="submit">Save & sync everywhere</button><a class="button ghost" href="${info.mapSearchUrl}" target="_blank">Check current map</a></div><p id="settingsStatus" class="form-note wide"></p></form></section>`
  };
  res.send(layout("Admin", `<section class="admin-shell"><div class="admin-head"><div><p class="eyebrow">Control room</p><h1>Admin Dashboard</h1></div><a class="button ghost" href="/logout">Logout</a></div><section class="admin-command-center"><article><span>${stats.totalProducts}</span><strong>Products</strong><small>${stats.featured} featured SKUs</small></article><article><span>${stats.inquiries.new}</span><strong>New Enquiries</strong><small>${stats.inquiries.total} total</small></article><article><span>${stats.feedback}</span><strong>Visible Feedback</strong><small>Reviews and comments</small></article><article><span>Live</span><strong>MySQL-compatible DB</strong><small>Vercel serverless connection</small></article></section>${adminTabs(active)}${sections[active] || sections.products}</section>`, req, info));
}));

app.get("/api/products", asyncRoute(async (_req, res) => res.json({ products: await products() })));
app.get("/api/products/:id", asyncRoute(async (req, res) => { const item = await product(req.params.id); if (!item) return res.status(404).json({ error: "Product not found" }); res.json({ product: item, reviews: await feedbackThreads(req.visitorId, { productId: item.id, sort: "top" }) }); }));
app.post("/api/inquiries", requireCsrf, asyncRoute(async (req, res) => { if (!rateLimit(req, "inquiry", 8, 600000)) return res.status(429).json({ error: "Too many enquiries" }); const { name, email, phone, message } = req.body; if (![name,email,phone,message].every((value) => String(value || "").trim())) return res.status(400).json({ error: "All enquiry fields are required" }); const result = await q("INSERT INTO inquiries(name,email,phone,message,status,created_at) VALUES (?,?,?,?, 'new',?)", [String(name).trim(),String(email).trim(),String(phone).trim(),String(message).trim(),now()]); await bump("inquiries"); res.status(201).json({ inquiry: { id: result.insertId, name: String(name).trim() }, message: "Enquiry saved" }); }));

async function deliverOtp(email, code) {
  if (process.env.RESEND_API_KEY && process.env.EMAIL_FROM) {
    const response = await fetch("https://api.resend.com/emails", { method: "POST", headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, "Content-Type": "application/json" }, body: JSON.stringify({ from: process.env.EMAIL_FROM, to: [email], subject: "Your Shaw Enterprise verification code", text: `Your verification code is ${code}. It expires in 10 minutes.` }) });
    if (!response.ok) throw new Error("Verification email could not be delivered"); return {};
  }
  if (DEV_EXPOSE_OTP && !IS_PRODUCTION) return { devOtp: code };
  throw new Error("Email verification is not configured");
}
app.post("/api/feedback/request-otp", requireCsrf, asyncRoute(async (req, res) => { if (!rateLimit(req, "otp", 5, 600000)) return res.status(429).json({ error: "Too many OTP requests" }); const email = String(req.body.email || "").trim().toLowerCase(); if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({ error: "Valid email is required" }); const code = String(Math.floor(100000 + Math.random() * 900000)); await q("INSERT INTO feedback_identity_otps(visitor_id,email,otp_hash,expires_at,created_at) VALUES (?,?,?,?,?)", [req.visitorId,email,otpHash(code),new Date(Date.now()+600000),now()]); const delivery = await deliverOtp(email, code); res.json({ message: "OTP sent", ...delivery }); }));
app.post("/api/feedback/verify-otp", requireCsrf, asyncRoute(async (req, res) => { const email = String(req.body.email || "").trim().toLowerCase(), code = String(req.body.otp || "").trim(); const row = await one("SELECT * FROM feedback_identity_otps WHERE visitor_id=? AND email=? AND used_at IS NULL ORDER BY id DESC LIMIT 1", [req.visitorId,email]); if (!row || new Date(row.expires_at) < now() || row.otp_hash !== otpHash(code)) return res.status(400).json({ error: "Invalid or expired OTP" }); await q("UPDATE feedback_identity_otps SET used_at=? WHERE id=?", [now(),row.id]); await q("INSERT INTO feedback_identities(visitor_id,email,verified,created_at,updated_at) VALUES (?,?,1,?,?) ON DUPLICATE KEY UPDATE email=VALUES(email),verified=1,updated_at=VALUES(updated_at)", [req.visitorId,email,now(),now()]); res.json({ identity: { email: safeEmail(email), verified: true } }); }));
app.get("/api/feedback", asyncRoute(async (req, res) => { const identity = await one("SELECT email,verified FROM feedback_identities WHERE visitor_id=?", [req.visitorId]); res.json({ identity: identity ? { email: safeEmail(identity.email), verified: Boolean(identity.verified) } : null, threads: await feedbackThreads(req.visitorId, { sort: req.query.sort || "top", productId: null }) }); }));
app.post("/api/feedback", requireCsrf, asyncRoute(async (req, res) => { const identity = await one("SELECT email,verified FROM feedback_identities WHERE visitor_id=?", [req.visitorId]); if (!identity?.verified) return res.status(403).json({ error: "Please verify your email before posting" }); const message = String(req.body.message || "").trim(); if (message.length < 3) return res.status(400).json({ error: "Feedback is too short" }); await q("INSERT INTO feedback_comments(visitor_id,author_email,message,parent_id,product_id,status,created_at) VALUES (?,?,?,?,?,'visible',?)", [req.visitorId,identity.email,message,req.body.parentId ? Number(req.body.parentId) : null,req.body.productId ? Number(req.body.productId) : null,now()]); await bump("feedback"); res.status(201).json({ ok: true }); }));
app.post("/api/feedback/:id/react", requireCsrf, asyncRoute(async (req, res) => { const id = Number(req.params.id), reaction = req.body.reaction === "heart" ? "heart" : "like"; const existing = await one("SELECT id,reaction FROM feedback_reactions WHERE feedback_id=? AND visitor_id=?", [id,req.visitorId]); if (existing?.reaction === reaction) await q("DELETE FROM feedback_reactions WHERE id=?", [existing.id]); else await q("INSERT INTO feedback_reactions(feedback_id,visitor_id,reaction,created_at) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE reaction=VALUES(reaction),created_at=VALUES(created_at)", [id,req.visitorId,reaction,now()]); await bump("feedback"); res.json({ message: "Reaction saved" }); }));

app.post("/api/auth/login", requireCsrf, asyncRoute(async (req, res) => { if (!rateLimit(req, "login", 10, 600000)) return res.status(429).json({ error: "Too many login attempts" }); const username = String(req.body.username || ""), password = String(req.body.password || ""); const userMatch = username === ADMIN_USER, passA = Buffer.from(password), passB = Buffer.from(ADMIN_PASSWORD); const passMatch = passA.length === passB.length && crypto.timingSafeEqual(passA, passB); if (!userMatch || !passMatch) { await audit(req,"login_failed","admin",username,"Invalid login attempt"); return res.status(401).json({ error: "Invalid username or password" }); } res.cookie("shaw_admin", signed(`admin:${Date.now()}`), { httpOnly: true, sameSite: "lax", secure: IS_PRODUCTION, maxAge: 8*3600000 }); await audit(req,"login","admin",username,"Admin login successful"); res.json({ redirect: "/admin" }); }));

app.use("/api/admin", requireAdmin);
app.get("/api/admin/products", asyncRoute(async (_req,res) => res.json({ products: await products() })));
app.post("/api/admin/products", requireCsrf, asyncRoute(async (req,res) => { const p=req.body; for (const key of ["name","category","price","productType","summary","details","packSize","audience"]) if (!String(p[key]||"").trim()) return res.status(400).json({error:`${key} is required`}); await q("INSERT IGNORE INTO product_categories(name,description) VALUES (?,?)",[p.category,`${p.category} products`]); const category=await one("SELECT id FROM product_categories WHERE name=?",[p.category]); const result=await q("INSERT INTO products(category_id,name,sku,price_label,product_type,summary,details,pack_size,audience,featured,status,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?, 'active',?,?)",[category.id,p.name,`SE-${Date.now()}`,p.price,p.productType,p.summary,p.details,p.packSize,p.audience,Boolean(p.featured),now(),now()]); for (const [index,image] of (p.images||[]).entries()) await q("INSERT INTO product_images(product_id,image_data,alt_text,sort_order) VALUES (?,?,?,?)",[result.insertId,image,p.name,index]); await audit(req,"create","product",result.insertId,p.name); await bump("products"); res.status(201).json({products:await products(),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.put("/api/admin/products/:id", requireCsrf, asyncRoute(async (req,res) => { const id=Number(req.params.id),p=req.body; await q("INSERT IGNORE INTO product_categories(name,description) VALUES (?,?)",[p.category,`${p.category} products`]); const category=await one("SELECT id FROM product_categories WHERE name=?",[p.category]); await q("UPDATE products SET category_id=?,name=?,price_label=?,product_type=?,summary=?,details=?,pack_size=?,audience=?,featured=?,updated_at=? WHERE id=?",[category.id,p.name,p.price,p.productType,p.summary,p.details,p.packSize,p.audience,Boolean(p.featured),now(),id]); await q("DELETE FROM product_images WHERE product_id=?",[id]); for (const [index,image] of (p.images||[]).entries()) await q("INSERT INTO product_images(product_id,image_data,alt_text,sort_order) VALUES (?,?,?,?)",[id,image,p.name,index]); await audit(req,"update","product",id,p.name); await bump("products"); res.json({products:await products(),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.delete("/api/admin/products/:id", requireCsrf, asyncRoute(async (req,res) => { const id=Number(req.params.id); await q("DELETE FROM product_images WHERE product_id=?",[id]); await q("DELETE FROM products WHERE id=?",[id]); await audit(req,"delete","product",id,"Product deleted"); await bump("products"); res.json({products:await products(),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.get("/api/admin/inquiries", asyncRoute(async (_req,res) => res.json({inquiries:await q("SELECT * FROM inquiries ORDER BY id DESC LIMIT 100"),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")})));
app.post("/api/admin/inquiries/:id/status", requireCsrf, asyncRoute(async (req,res) => { const status=["new","contacted","closed"].includes(req.body.status)?req.body.status:null; if(!status)return res.status(400).json({error:"Invalid status"}); await q("UPDATE inquiries SET status=? WHERE id=?",[status,Number(req.params.id)]); await audit(req,"status","inquiry",req.params.id,status); await bump("inquiries"); res.json({inquiries:await q("SELECT * FROM inquiries ORDER BY id DESC LIMIT 100"),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.get("/api/admin/feedback", asyncRoute(async (_req,res) => { const rows=await q("SELECT fc.*,p.name product_name FROM feedback_comments fc LEFT JOIN products p ON p.id=fc.product_id ORDER BY fc.created_at DESC LIMIT 100"); res.json({feedback:rows.map((row)=>({id:Number(row.id),displayLabel:safeEmail(row.author_email),message:row.message,status:row.status,productName:row.product_name||"General feedback",createdAt:row.created_at})),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.post("/api/admin/feedback/:id/hide", requireCsrf, asyncRoute(async (req,res) => { const row=await one("SELECT status FROM feedback_comments WHERE id=?",[Number(req.params.id)]); const status=row?.status==="hidden"?"visible":"hidden"; await q("UPDATE feedback_comments SET status=? WHERE id=?",[status,Number(req.params.id)]); await audit(req,status==="hidden"?"hide":"restore","feedback",req.params.id,`Feedback ${status}`); await bump("feedback"); const rows=await q("SELECT fc.*,p.name product_name FROM feedback_comments fc LEFT JOIN products p ON p.id=fc.product_id ORDER BY fc.created_at DESC LIMIT 100"); res.json({feedback:rows.map((item)=>({id:Number(item.id),displayLabel:safeEmail(item.author_email),message:item.message,status:item.status,productName:item.product_name||"General feedback",createdAt:item.created_at})),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.delete("/api/admin/feedback/:id", requireCsrf, asyncRoute(async (req,res) => { const id=Number(req.params.id); await q("DELETE FROM feedback_reactions WHERE feedback_id=?",[id]); await q("DELETE FROM feedback_comments WHERE parent_id=?",[id]); await q("DELETE FROM feedback_comments WHERE id=?",[id]); await audit(req,"delete","feedback",id,"Feedback deleted"); await bump("feedback"); const rows=await q("SELECT fc.*,p.name product_name FROM feedback_comments fc LEFT JOIN products p ON p.id=fc.product_id ORDER BY fc.created_at DESC LIMIT 100"); res.json({feedback:rows.map((item)=>({id:Number(item.id),displayLabel:safeEmail(item.author_email),message:item.message,status:item.status,productName:item.product_name||"General feedback",createdAt:item.created_at})),auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")}); }));
app.get("/api/admin/audits", asyncRoute(async (_req,res) => res.json({auditLogs:await q("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80")})));
app.get("/api/admin/settings", asyncRoute(async (_req,res) => res.json({settings:await business()})));
app.put("/api/admin/settings", requireCsrf, asyncRoute(async (req,res) => { for(const key of ["business_name","phone","email","whatsapp","address","hours"]){ const value=String(req.body[key]||"").trim(); if(!value)return res.status(400).json({error:`${key} is required`}); await q("INSERT INTO business_settings(setting_key,setting_value) VALUES (?,?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)",[key,key==="whatsapp"?value.replace(/\D/g,""):value]); } await audit(req,"update","settings","business","Business and map settings updated"); await bump("settings"); res.json({settings:await business()}); }));

app.get("/api/live", asyncRoute(async (_req,res) => { res.set({"Content-Type":"text/event-stream","Cache-Control":"no-cache, no-transform","Connection":"keep-alive"}); res.flushHeaders?.(); let versions=Object.fromEntries((await q("SELECT topic,version FROM sync_state")).map((row)=>[row.topic,Number(row.version)])); res.write("retry: 2000\nevent: ready\ndata: connected\n\n"); for(let tick=0;tick<25;tick+=1){ await new Promise((resolve)=>setTimeout(resolve,1000)); const rows=await q("SELECT topic,version FROM sync_state"); for(const row of rows){ const version=Number(row.version); if(version!==versions[row.topic]){ versions[row.topic]=version; res.write(`event: sync\ndata: ${row.topic}\n\n`); } } res.write(": heartbeat\n\n"); } res.end(); }));

app.use((req,res) => res.status(404).send(`<h1>Page not found</h1><p><a href="/">Return home</a></p>`));
app.use((error, _req, res, _next) => { console.error(error); res.status(500).json({ error: IS_PRODUCTION ? "Server error" : error.message }); });

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, "0.0.0.0", () => console.log(`Shaw Enterprise Vercel runtime at http://localhost:${port}`));
}

module.exports = app;
module.exports._test = { escapeHtml, safeEmail, signed, validSigned, poolOptions };
