const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const { DatabaseSync } = require("node:sqlite");

const PORT = Number(process.env.PORT || 3000);
const ROOT = __dirname;
const PUBLIC_DIR = path.join(ROOT, "public");
const DATA_DIR = path.join(ROOT, "data");
const DB_PATH = path.join(DATA_DIR, "shaw-enterprise.db");
const MYSQL_SYNC_PATH = path.join(DATA_DIR, "mysql-live-sync.sql");

const ADMIN_USER = process.env.ADMIN_USER || "admin";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "change-me-now";
const SESSION_SECRET = process.env.SESSION_SECRET || "local-dev-secret-change-before-production";
const MYSQL_HOST = process.env.MYSQL_HOST || "localhost";
const MYSQL_USER = process.env.MYSQL_USER || "root";
const MYSQL_PASSWORD = process.env.MYSQL_PASSWORD || "Rishi@042405";
const MYSQL_DATABASE = process.env.MYSQL_DATABASE || "shaw_enterprise";

const settings = {
  phone: process.env.BUSINESS_PHONE || "+91 00000 00000",
  email: process.env.BUSINESS_EMAIL || "sales@shawenterprise.example",
  address: process.env.BUSINESS_ADDRESS || "Your shop address, city, state",
  whatsapp: process.env.WHATSAPP_NUMBER || "910000000000"
};

fs.mkdirSync(DATA_DIR, { recursive: true });
const db = new DatabaseSync(DB_PATH);
db.exec("PRAGMA foreign_keys = ON");

const nowSql = () => new Date().toISOString();
const randomId = () => crypto.randomBytes(12).toString("hex");
const parseJson = (value, fallback = []) => {
  try {
    return value ? JSON.parse(value) : fallback;
  } catch {
    return fallback;
  }
};

function mysqlDate(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value).replace("T", " ").replace("Z", "").slice(0, 19);
  return date.toISOString().slice(0, 19).replace("T", " ");
}

function mysqlEscape(value) {
  if (value === null || value === undefined || value === "") return "NULL";
  return `'${String(value).replace(/\\/g, "\\\\").replace(/'/g, "''")}'`;
}

function mysqlBool(value) {
  return value ? 1 : 0;
}

function mysqlRun(sql) {
  const wrapped = `USE \`${MYSQL_DATABASE}\`;\nSET FOREIGN_KEY_CHECKS = 1;\n${sql}\n`;
  fs.writeFileSync(MYSQL_SYNC_PATH, wrapped, "utf8");
  const result = spawnSync("mysql", ["-h", MYSQL_HOST, "-u", MYSQL_USER, `--database=${MYSQL_DATABASE}`], {
    cwd: ROOT,
    env: { ...process.env, MYSQL_PWD: MYSQL_PASSWORD },
    input: wrapped,
    encoding: "utf8"
  });
  if (result.status !== 0) {
    console.error("MySQL live sync failed:", result.stderr || result.stdout);
  }
  return result.status === 0;
}

function mysqlEnsureCategory(category) {
  mysqlRun(`
    INSERT INTO product_categories (name, description)
    VALUES (${mysqlEscape(category)}, ${mysqlEscape(`${category} products for Shaw Enterprise catalog`)})
    ON DUPLICATE KEY UPDATE description = VALUES(description);
  `);
}

function mysqlSyncProduct(product) {
  if (!product) return;
  mysqlEnsureCategory(product.category);
  const images = parseJson(product.images_json, []);
  mysqlRun(`
    INSERT INTO products
      (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
    SELECT ${product.id}, id, ${mysqlEscape(product.name)}, ${mysqlEscape(`SE-${String(product.id).padStart(4, "0")}`)}, ${mysqlEscape(product.price)}, ${mysqlEscape(product.product_type)}, ${mysqlEscape(product.summary)}, ${mysqlEscape(product.details)}, ${mysqlEscape(product.pack_size)}, ${mysqlEscape(product.audience)}, ${mysqlBool(product.featured)}, 'active', ${mysqlEscape(mysqlDate(product.created_at))}, ${mysqlEscape(mysqlDate(product.updated_at))}
    FROM product_categories WHERE name = ${mysqlEscape(product.category)}
    ON DUPLICATE KEY UPDATE
      category_id = VALUES(category_id),
      name = VALUES(name),
      sku = VALUES(sku),
      price_label = VALUES(price_label),
      product_type = VALUES(product_type),
      summary = VALUES(summary),
      details = VALUES(details),
      pack_size = VALUES(pack_size),
      audience = VALUES(audience),
      featured = VALUES(featured),
      status = 'active',
      updated_at = VALUES(updated_at);
    DELETE FROM product_images WHERE product_id = ${product.id};
    ${images.map((image, index) => `INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (${product.id}, ${mysqlEscape(image)}, ${mysqlEscape(product.name)}, ${index});`).join("\n")}
  `);
}

function mysqlDeleteProduct(id) {
  mysqlRun(`DELETE FROM products WHERE id = ${Number(id)};`);
}

function mysqlSyncInquiry(row) {
  mysqlRun(`
    INSERT INTO inquiries (id, name, email, phone, message, status, created_at)
    VALUES (${row.id}, ${mysqlEscape(row.name)}, ${mysqlEscape(row.email)}, ${mysqlEscape(row.phone)}, ${mysqlEscape(row.message)}, 'new', ${mysqlEscape(mysqlDate(row.created_at))})
    ON DUPLICATE KEY UPDATE name = VALUES(name), email = VALUES(email), phone = VALUES(phone), message = VALUES(message), created_at = VALUES(created_at);
  `);
}

function saveInquiry(data) {
  const name = String(data.name || "").trim();
  const email = String(data.email || "").trim();
  const phone = String(data.phone || "").trim();
  const message = String(data.message || "").trim();
  if (!name || !email || !phone || !message) return { error: "All inquiry fields are required" };
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return { error: "Valid email is required" };
  const result = db.prepare("INSERT INTO inquiries (name, email, phone, message, created_at) VALUES (?, ?, ?, ?, ?)").run(name, email, phone, message, nowSql());
  const inquiry = db.prepare("SELECT * FROM inquiries WHERE id = ?").get(result.lastInsertRowid);
  mysqlSyncInquiry(inquiry);
  return { inquiry };
}

function mysqlSyncOtp(row) {
  mysqlRun(`
    INSERT INTO feedback_identity_otps (id, visitor_id, email, otp_hash, expires_at, used_at, created_at)
    VALUES (${row.id}, ${mysqlEscape(row.visitor_id)}, ${mysqlEscape(row.email)}, ${mysqlEscape(row.otp_hash)}, ${mysqlEscape(mysqlDate(row.expires_at))}, ${mysqlEscape(mysqlDate(row.used_at))}, ${mysqlEscape(mysqlDate(row.created_at))})
    ON DUPLICATE KEY UPDATE used_at = VALUES(used_at), expires_at = VALUES(expires_at);
  `);
}

function mysqlSyncIdentity(row) {
  mysqlRun(`
    INSERT INTO feedback_identities (visitor_id, email, verified, created_at, updated_at)
    VALUES (${mysqlEscape(row.visitor_id)}, ${mysqlEscape(row.email)}, ${mysqlBool(row.verified)}, ${mysqlEscape(mysqlDate(row.created_at))}, ${mysqlEscape(mysqlDate(row.updated_at))})
    ON DUPLICATE KEY UPDATE email = VALUES(email), verified = VALUES(verified), updated_at = VALUES(updated_at);
  `);
}

function mysqlSyncFeedback(row) {
  mysqlRun(`
    INSERT INTO feedback_comments (id, visitor_id, author_email, message, parent_id, product_id, status, created_at)
    VALUES (${row.id}, ${mysqlEscape(row.visitor_id)}, ${mysqlEscape(row.author_email)}, ${mysqlEscape(row.message)}, ${row.parent_id || "NULL"}, ${row.product_id || "NULL"}, ${mysqlEscape(row.status)}, ${mysqlEscape(mysqlDate(row.created_at))})
    ON DUPLICATE KEY UPDATE message = VALUES(message), status = VALUES(status), product_id = VALUES(product_id);
  `);
}

function mysqlDeleteFeedback(id) {
  mysqlRun(`DELETE FROM feedback_comments WHERE id = ${Number(id)};`);
}

function mysqlSyncReaction(row) {
  mysqlRun(`
    INSERT INTO feedback_reactions (id, feedback_id, visitor_id, reaction, created_at)
    VALUES (${row.id}, ${row.feedback_id}, ${mysqlEscape(row.visitor_id)}, ${mysqlEscape(row.reaction)}, ${mysqlEscape(mysqlDate(row.created_at))})
    ON DUPLICATE KEY UPDATE reaction = VALUES(reaction), created_at = VALUES(created_at);
  `);
}

function mysqlDeleteReaction(id) {
  mysqlRun(`DELETE FROM feedback_reactions WHERE id = ${Number(id)};`);
}

function mysqlSyncAudit(row) {
  mysqlRun(`
    INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at)
    VALUES (${row.id}, ${mysqlEscape(row.action_type)}, ${mysqlEscape(row.target_type)}, ${mysqlEscape(row.target_id)}, ${mysqlEscape(row.details)}, ${mysqlEscape(row.ip_address)}, ${mysqlEscape(mysqlDate(row.created_at))})
    ON DUPLICATE KEY UPDATE details = VALUES(details), created_at = VALUES(created_at);
  `);
}

const catalogBlueprints = [
  {
    category: "Cups",
    names: ["Ripple Paper Cup", "Plain Paper Cup", "Printed Tea Cup", "Double Wall Coffee Cup", "Cold Drink Paper Cup", "Kulhad Style Cup"],
    type: "Hot and cold beverage disposable",
    pack: "50 pcs, 100 pcs, bulk carton",
    audience: "Tea stalls, cafes, offices, caterers",
    summary: "Disposable cups for tea, coffee, juice, events, and counters.",
    details: "Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons.",
    basePrice: 68
  },
  {
    category: "Plates",
    names: ["Round Paper Plate", "Compartment Meal Plate", "Silver Laminated Plate", "Snack Paper Plate", "Heavy Duty Dinner Plate", "Eco Bagasse Plate"],
    type: "Meal serving disposable",
    pack: "100 pcs, 500 pcs, wholesale carton",
    audience: "Caterers, households, event managers, retailers",
    summary: "Strong disposable plates for meals, snacks, events, and food counters.",
    details: "Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale.",
    basePrice: 90
  },
  {
    category: "Containers",
    names: ["Round Food Container", "Rectangular Meal Box", "Clear Lid Container", "Sauce Cup Container", "Bakery Clamshell Box", "Microwave Safe Container"],
    type: "Takeaway packaging",
    pack: "25 pcs, 100 pcs, carton packs",
    audience: "Restaurants, cloud kitchens, bakeries, sweet shops",
    summary: "Food containers for takeaway, delivery, storage, and display.",
    details: "Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations.",
    basePrice: 115
  },
  {
    category: "Cutlery",
    names: ["Wooden Spoon Pack", "Disposable Fork Pack", "Dessert Spoon Pack", "Ice Cream Spoon Pack", "Knife Pack", "Mixed Cutlery Kit"],
    type: "Disposable cutlery",
    pack: "100 pcs, 500 pcs, mixed carton",
    audience: "Food counters, event planners, tasting counters",
    summary: "Clean disposable spoons, forks, knives, and serving cutlery.",
    details: "Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters.",
    basePrice: 42
  },
  {
    category: "Napkins",
    names: ["Tissue Napkin Pack", "Printed Napkin", "Dinner Napkin", "Cocktail Napkin", "Soft Table Tissue", "Dispenser Tissue"],
    type: "Table hygiene disposable",
    pack: "100 pcs, 200 pcs, carton packs",
    audience: "Restaurants, offices, hotels, party suppliers",
    summary: "Soft napkins and tissues for tables, counters, and events.",
    details: "Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers.",
    basePrice: 38
  },
  {
    category: "Bags",
    names: ["Paper Carry Bag", "Kraft Grocery Bag", "Food Delivery Bag", "Bakery Paper Bag", "Gift Paper Bag", "Retail Counter Bag"],
    type: "Carry and retail packaging",
    pack: "25 pcs, 100 pcs, bulk carton",
    audience: "Retail shops, bakeries, groceries, restaurants",
    summary: "Paper carry bags for packing, delivery, and retail counters.",
    details: "Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting.",
    basePrice: 130
  },
  {
    category: "Straws",
    names: ["Paper Straw Pack", "Bendy Straw Pack", "Milkshake Straw", "Wrapped Straw", "Cocktail Straw", "Jumbo Drink Straw"],
    type: "Drink service disposable",
    pack: "100 pcs, 250 pcs, bulk carton",
    audience: "Juice shops, cafes, restaurants, event counters",
    summary: "Disposable straws for cold drinks, shakes, and event service.",
    details: "Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale.",
    basePrice: 35
  },
  {
    category: "Bowls",
    names: ["Paper Soup Bowl", "Salad Bowl", "Dessert Bowl", "Rice Bowl", "Noodle Bowl", "Laminated Snack Bowl"],
    type: "Bowl serving disposable",
    pack: "50 pcs, 100 pcs, carton packs",
    audience: "Caterers, restaurants, food stalls, events",
    summary: "Disposable bowls for soups, snacks, rice, desserts, and salads.",
    details: "Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply.",
    basePrice: 70
  }
];

function generatedProductImage(category, index, variant = 1) {
  return `/images/generated-${category.toLowerCase()}-${index}-${variant}.svg`;
}

function buildCatalogProduct(index) {
  const blueprint = catalogBlueprints[index % catalogBlueprints.length];
  const name = blueprint.names[Math.floor(index / catalogBlueprints.length) % blueprint.names.length];
  const size = ["Small", "Medium", "Large", "Premium", "Economy"][index % 5];
  const packCount = [25, 50, 100, 200, 500][index % 5];
  const price = blueprint.basePrice + (index % 17) * 7 + Math.floor(index / 20) * 3;
  const productName = `${size} ${name} ${String(index + 1).padStart(3, "0")}`;
  return [
    productName,
    blueprint.category,
    `Rs. ${price} / ${packCount} pcs`,
    blueprint.type,
    blueprint.summary,
    `${blueprint.details} Item code SE-${String(index + 1).padStart(4, "0")} is suited for regular replenishment and counter-ready presentation.`,
    blueprint.pack,
    blueprint.audience,
    JSON.stringify([generatedProductImage(blueprint.category, index + 1, 1), generatedProductImage(blueprint.category, index + 1, 2), generatedProductImage(blueprint.category, index + 1, 3)]),
    index < 12 ? 1 : 0,
    nowSql(),
    nowSql()
  ];
}

function initDb() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      price TEXT NOT NULL,
      product_type TEXT NOT NULL DEFAULT 'Retail and wholesale',
      summary TEXT NOT NULL,
      details TEXT NOT NULL,
      pack_size TEXT NOT NULL,
      audience TEXT NOT NULL,
      images_json TEXT NOT NULL DEFAULT '[]',
      featured INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS inquiries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT NOT NULL,
      message TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS feedback_identities (
      visitor_id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      verified INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS feedback_identity_otps (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      visitor_id TEXT NOT NULL,
      email TEXT NOT NULL,
      otp_hash TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      used_at TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS feedback_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      visitor_id TEXT NOT NULL,
      author_email TEXT NOT NULL,
      message TEXT NOT NULL,
      parent_id INTEGER,
      product_id INTEGER,
      status TEXT NOT NULL DEFAULT 'visible',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(parent_id) REFERENCES feedback_comments(id) ON DELETE CASCADE,
      FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS feedback_reactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      feedback_id INTEGER NOT NULL,
      visitor_id TEXT NOT NULL,
      reaction TEXT NOT NULL CHECK(reaction IN ('like', 'heart')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(feedback_id, visitor_id),
      FOREIGN KEY(feedback_id) REFERENCES feedback_comments(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS admin_audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action_type TEXT NOT NULL,
      target_type TEXT NOT NULL,
      target_id TEXT,
      details TEXT NOT NULL DEFAULT '',
      ip_address TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `);

  const productCount = db.prepare("SELECT COUNT(*) AS count FROM products").get().count;
  const seed = db.prepare(`
      INSERT INTO products
      (name, category, price, product_type, summary, details, pack_size, audience, images_json, featured, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

  if (productCount === 0) {

    const products = [
      ["Ripple Paper Cups", "Cups", "Rs. 95 / 50 pcs", "Hot beverage disposable", "Insulated cups for tea, coffee, and catering counters.", "Triple-layer ripple cups with firm grip, strong rim, and dependable heat resistance for events, offices, food stalls, and cafes.", "50 pcs, 100 pcs, carton packs", "Tea stalls, offices, cafes, events", ["/images/cup-1.svg", "/images/cup-2.svg", "/images/cup-3.svg"], 1],
      ["Premium Paper Plates", "Plates", "Rs. 120 / 100 pcs", "Meal serving disposable", "Strong round plates for parties and daily food service.", "Leak-resistant disposable plates designed for snacks, meals, religious events, catering, and retail resale counters.", "100 pcs, 500 pcs, bulk carton", "Caterers, households, wholesalers", ["/images/plate-1.svg", "/images/plate-2.svg", "/images/plate-3.svg"], 1],
      ["Food Container Set", "Containers", "Rs. 180 / 25 pcs", "Takeaway packaging", "Secure containers for restaurant packing and delivery.", "Stackable food containers with fitted lids, suited for rice, curry, snacks, bakery, sweets, and takeaway operations.", "25 pcs, 100 pcs, carton packs", "Restaurants, cloud kitchens, sweet shops", ["/images/container-1.svg", "/images/container-2.svg"], 1],
      ["Wooden Cutlery Pack", "Cutlery", "Rs. 75 / 100 pcs", "Eco-friendly disposable", "Clean disposable spoons and forks for professional service.", "Smooth finish disposable cutlery for events, takeaway counters, office pantry supply, and food sampling counters.", "100 pcs, 500 pcs, mixed carton", "Event managers, food counters, retailers", ["/images/cutlery-1.svg", "/images/cutlery-2.svg"], 0]
    ];

    for (const item of products) {
      seed.run(item[0], item[1], item[2], item[3], item[4], item[5], item[6], item[7], JSON.stringify(item[8]), item[9], nowSql(), nowSql());
    }
  }

  const updatedCount = db.prepare("SELECT COUNT(*) AS count FROM products").get().count;
  for (let index = updatedCount; index < 300; index += 1) {
    seed.run(...buildCatalogProduct(index));
  }
}

function safeEmail(email = "") {
  const [name, domain] = String(email).split("@");
  if (!name || !domain) return "Verified customer";
  return `${name.slice(0, 2)}***@${domain}`;
}

function productRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    price: row.price,
    productType: row.product_type,
    summary: row.summary,
    details: row.details,
    packSize: row.pack_size,
    audience: row.audience,
    images: parseJson(row.images_json, []),
    featured: Boolean(row.featured),
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

function getProducts() {
  return db.prepare("SELECT * FROM products ORDER BY featured DESC, id ASC").all().map(productRow);
}

function getProduct(id) {
  return productRow(db.prepare("SELECT * FROM products WHERE id = ?").get(id));
}

function getIdentity(visitorId) {
  return db.prepare("SELECT * FROM feedback_identities WHERE visitor_id = ?").get(visitorId) || null;
}

function getVisitor(req, res) {
  const cookies = parseCookies(req);
  let id = cookies.visitor_id;
  if (!id || !/^[a-f0-9]{24}$/.test(id)) {
    id = randomId();
    setCookie(res, "visitor_id", id, { maxAge: 60 * 60 * 24 * 365, httpOnly: true, sameSite: "Lax" });
  }
  return { id };
}

function reactionCounts(id) {
  const rows = db.prepare("SELECT reaction, COUNT(*) AS count FROM feedback_reactions WHERE feedback_id = ? GROUP BY reaction").all(id);
  return {
    like: rows.find((row) => row.reaction === "like")?.count || 0,
    heart: rows.find((row) => row.reaction === "heart")?.count || 0
  };
}

function commentDto(row, visitorId) {
  const reaction = db.prepare("SELECT reaction FROM feedback_reactions WHERE feedback_id = ? AND visitor_id = ?").get(row.id, visitorId);
  return {
    id: row.id,
    visitorId: row.visitor_id,
    authorEmail: row.author_email,
    displayLabel: safeEmail(row.author_email),
    message: row.message,
    parentId: row.parent_id,
    productId: row.product_id,
    status: row.status,
    createdAt: row.created_at,
    reactions: reactionCounts(row.id),
    myReaction: reaction?.reaction || null,
    replies: []
  };
}

function getFeedbackThreads(visitorId, options = {}) {
  const params = [];
  const filters = [];
  if (!options.includeHidden) filters.push("status = 'visible'");
  if (options.productId === null) {
    filters.push("product_id IS NULL");
  } else if (options.productId) {
    filters.push("product_id = ?");
    params.push(options.productId);
  }
  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";
  const rows = db.prepare(`SELECT * FROM feedback_comments ${where} ORDER BY created_at DESC`).all(...params);
  const byId = new Map(rows.map((row) => [row.id, commentDto(row, visitorId)]));
  const threads = [];
  for (const item of byId.values()) {
    if (item.parentId && byId.has(item.parentId)) byId.get(item.parentId).replies.unshift(item);
    else threads.push(item);
  }
  return threads.sort((a, b) => {
    const aScore = a.reactions.like + a.reactions.heart * 2 + a.replies.length;
    const bScore = b.reactions.like + b.reactions.heart * 2 + b.replies.length;
    if (options.sort === "top") return bScore - aScore || new Date(b.createdAt) - new Date(a.createdAt);
    return new Date(b.createdAt) - new Date(a.createdAt);
  });
}

function getAdminFeedback() {
  return db.prepare(`
    SELECT fc.*, p.name AS product_name
    FROM feedback_comments fc
    LEFT JOIN products p ON p.id = fc.product_id
    ORDER BY fc.created_at DESC
    LIMIT 100
  `).all().map((row) => ({
    id: row.id,
    email: row.author_email,
    displayLabel: safeEmail(row.author_email),
    message: row.message,
    status: row.status,
    productName: row.product_name || "General feedback",
    parentId: row.parent_id,
    createdAt: row.created_at
  }));
}

function getAuditLogs() {
  return db.prepare("SELECT * FROM admin_audit_logs ORDER BY id DESC LIMIT 80").all();
}

function logAudit(req, actionType, targetType, targetId, details = "") {
  const result = db.prepare(`
    INSERT INTO admin_audit_logs (action_type, target_type, target_id, details, ip_address, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(actionType, targetType, String(targetId || ""), details, req.socket.remoteAddress || "", nowSql());
  const row = db.prepare("SELECT * FROM admin_audit_logs WHERE id = ?").get(result.lastInsertRowid);
  mysqlSyncAudit(row);
  return row;
}

function parseCookies(req) {
  return Object.fromEntries((req.headers.cookie || "").split(";").filter(Boolean).map((part) => {
    const index = part.indexOf("=");
    return [part.slice(0, index).trim(), decodeURIComponent(part.slice(index + 1))];
  }));
}

function setCookie(res, name, value, options = {}) {
  const parts = [`${name}=${encodeURIComponent(value)}`];
  if (options.maxAge) parts.push(`Max-Age=${options.maxAge}`);
  if (options.httpOnly) parts.push("HttpOnly");
  if (options.sameSite) parts.push(`SameSite=${options.sameSite}`);
  parts.push("Path=/");
  const existing = res.getHeader("Set-Cookie") || [];
  res.setHeader("Set-Cookie", Array.isArray(existing) ? existing.concat(parts.join("; ")) : [existing, parts.join("; ")]);
}

function sessionToken() {
  const payload = `admin:${Date.now()}`;
  const sig = crypto.createHmac("sha256", SESSION_SECRET).update(payload).digest("hex");
  return `${payload}.${sig}`;
}

function isAdmin(req) {
  const token = parseCookies(req).shaw_admin;
  if (!token) return false;
  const [user, issued, sig] = token.split(".");
  if (user !== "admin" || !issued || !sig) return false;
  const expected = crypto.createHmac("sha256", SESSION_SECRET).update(`${user}.${issued}`.replace(".", ":")).digest("hex");
  return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
}

function fixedIsAdmin(req) {
  const token = parseCookies(req).shaw_admin;
  if (!token) return false;
  const splitAt = token.lastIndexOf(".");
  if (splitAt < 0) return false;
  const payload = token.slice(0, splitAt);
  const sig = token.slice(splitAt + 1);
  const expected = crypto.createHmac("sha256", SESSION_SECRET).update(payload).digest("hex");
  return sig.length === expected.length && crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
}

function send(res, status, body, headers = {}) {
  res.writeHead(status, headers);
  res.end(body);
}

function json(res, status, data) {
  send(res, status, JSON.stringify(data), { "Content-Type": "application/json; charset=utf-8" });
}

async function readBody(req) {
  let body = "";
  for await (const chunk of req) body += chunk;
  if (!body) return {};
  const type = req.headers["content-type"] || "";
  if (type.includes("application/json")) return JSON.parse(body);
  return Object.fromEntries(new URLSearchParams(body));
}

function escapeHtml(value = "") {
  return String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
}

function layout(title, content, req) {
  const admin = fixedIsAdmin(req);
  const nav = [
    ["/", "Home"],
    ["/products", "Products"],
    ["/feedback", "Feedback"],
    ["/contact", "Contact"],
    [admin ? "/admin" : "/login", "Admin"]
  ];
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${escapeHtml(title)} | Shaw Enterprise</title>
  <link rel="stylesheet" href="/styles.css" />
  <script defer src="/client.js"></script>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="/"><img src="/logo.svg" alt="Shaw Enterprise" /></a>
    <button class="nav-toggle" type="button" aria-label="Open navigation">Menu</button>
    <nav class="site-nav">${nav.map(([href, label]) => `<a href="${href}">${label}</a>`).join("")}</nav>
  </header>
  <main>${content}</main>
  <footer class="site-footer">
    <div><strong>Shaw Enterprise</strong><span>Wholesale and retail disposable products.</span></div>
    <div>${escapeHtml(settings.phone)} | ${escapeHtml(settings.email)}</div>
  </footer>
</body>
</html>`;
}

function HomePage(req) {
  const products = getProducts().filter((item) => item.featured).slice(0, 3);
  return layout("Home", `
    <section class="hero">
      <div class="hero-media"></div>
      <div class="hero-content">
        <p class="eyebrow">Wholesale and retail disposable products</p>
        <h1>Shaw Enterprise</h1>
        <p>Reliable paper cups, plates, containers, cutlery, and packaging supplies for shops, caterers, offices, and events.</p>
        <div class="hero-actions">
          <a class="button primary" href="/products">View Products</a>
          <a class="button ghost" href="https://wa.me/${escapeHtml(settings.whatsapp)}">WhatsApp Enquiry</a>
        </div>
      </div>
    </section>
    <section class="band">
      <div class="section-head">
        <p class="eyebrow">About the business</p>
        <h2>Professional supply for everyday food service.</h2>
      </div>
      <div class="feature-grid">
        <article><h3>Wholesale Ready</h3><p>Bulk carton supply, category-wise stock planning, and consistent repeat order handling.</p></article>
        <article><h3>Retail Friendly</h3><p>Practical pack sizes for homes, small shops, food stalls, and event buyers.</p></article>
        <article><h3>Fast Enquiries</h3><p>Contact through the website, phone, or WhatsApp for pricing and availability.</p></article>
      </div>
    </section>
    <section class="band tint">
      <div class="section-head"><p class="eyebrow">Featured stock</p><h2>Popular disposable items</h2></div>
      <div class="product-grid">${products.map(ProductCard).join("")}</div>
    </section>
  `, req);
}

function ProductCard(product) {
  return `<article class="product-card" data-product-id="${product.id}">
    <img src="${escapeHtml(product.images[0] || "/images/product.svg")}" alt="${escapeHtml(product.name)}" />
    <div class="product-card-body">
      <p class="tag">${escapeHtml(product.category)}</p>
      <h3>${escapeHtml(product.name)}</h3>
      <p>${escapeHtml(product.summary)}</p>
      <div class="product-meta"><strong>${escapeHtml(product.price)}</strong><span>${escapeHtml(product.packSize)}</span></div>
      <button class="button small view-product" type="button" data-product-id="${product.id}">View</button>
    </div>
  </article>`;
}

function ProductsPage(req) {
  return layout("Products", `
    <section class="page-title">
      <p class="eyebrow">Product catalog</p>
      <h1>Disposable items for shops, events, and food service.</h1>
    </section>
    <section class="band"><div class="product-grid">${getProducts().map(ProductCard).join("")}</div></section>
    <aside class="product-panel" id="productPanel" aria-hidden="true"></aside>
  `, req);
}

function FeedbackPage(req, visitor) {
  const identity = getIdentity(visitor.id);
  return layout("Feedback", `
    <section class="page-title compact">
      <p class="eyebrow">Community feedback</p>
      <h1>Customer feedback and product reviews.</h1>
    </section>
    <section class="feedback-shell" data-identity='${escapeHtml(JSON.stringify(identity ? { email: safeEmail(identity.email), verified: Boolean(identity.verified) } : null))}'>
      <form class="feedback-form" id="feedbackForm">
        <div id="feedbackIdentity"></div>
        <label>Feedback<textarea name="message" rows="4" placeholder="Share your experience with Shaw Enterprise" required></textarea></label>
        <button class="button primary" type="submit">Post Feedback</button>
        <p class="form-note" id="otpNote"></p>
      </form>
      <div class="feedback-toolbar">
        <strong>Comments</strong>
        <select id="feedbackSort"><option value="top">Top</option><option value="newest">Newest</option></select>
      </div>
      <div id="feedbackList" class="feedback-list"></div>
      <button class="button ghost" id="loadMoreFeedback" type="button">Load More</button>
    </section>
  `, req);
}

function ContactPage(req) {
  const sent = new URL(req.url, `http://${req.headers.host || "localhost"}`).searchParams.get("sent") === "1";
  return layout("Contact", `
    <section class="page-title compact"><p class="eyebrow">Contact</p><h1>Send an enquiry for pricing, stock, or bulk supply.</h1></section>
    <section class="contact-layout">
      <form class="contact-form" method="post" action="/contact">
        <label>Name<input name="name" required /></label>
        <label>Email<input name="email" type="email" required /></label>
        <label>Phone<input name="phone" required /></label>
        <label>Message<textarea name="message" rows="5" required></textarea></label>
        <button class="button primary" type="submit">Send Enquiry</button>
        <p class="form-note contact-note">${sent ? "Enquiry saved. We will contact you shortly." : ""}</p>
      </form>
      <aside class="contact-card">
        <h2>Business details</h2>
        <p>${escapeHtml(settings.phone)}</p>
        <p>${escapeHtml(settings.email)}</p>
        <p>${escapeHtml(settings.address)}</p>
        <a class="button ghost" href="https://wa.me/${escapeHtml(settings.whatsapp)}">Open WhatsApp</a>
      </aside>
    </section>
  `, req);
}

function LoginPage(req, error = "") {
  return layout("Admin Login", `
    <section class="login-wrap">
      <form class="login-card" method="post" action="/login">
        <img src="/logo.svg" alt="Shaw Enterprise" />
        <h1>Admin Login</h1>
        ${error ? `<p class="error">${escapeHtml(error)}</p>` : ""}
        <label>Username<input name="username" autocomplete="username" required /></label>
        <label>Password<input name="password" type="password" autocomplete="current-password" required /></label>
        <button class="button primary" type="submit">Login</button>
      </form>
    </section>
  `, req);
}

function AdminPage(req) {
  const inquiries = db.prepare("SELECT * FROM inquiries ORDER BY id DESC LIMIT 50").all();
  return layout("Admin", `
    <section class="admin-shell">
      <div class="admin-head">
        <div><p class="eyebrow">Control room</p><h1>Admin Dashboard</h1></div>
        <a class="button ghost" href="/logout">Logout</a>
      </div>
      <section class="admin-section">
        <h2>Product Management</h2>
        <form id="productForm" class="admin-form">
          <input type="hidden" name="id" />
          <label>Name<input name="name" required /></label>
          <label>Category<input name="category" required /></label>
          <label>Price<input name="price" required /></label>
          <label>Type<input name="productType" required /></label>
          <label>Pack Size<input name="packSize" required /></label>
          <label>Audience<input name="audience" required /></label>
          <label>Summary<textarea name="summary" rows="2" required></textarea></label>
          <label>Details<textarea name="details" rows="4" required></textarea></label>
          <label>Product Images<input name="imageFiles" type="file" accept="image/*" multiple /></label>
          <input name="images" type="hidden" />
          <div class="image-preview-grid" id="imagePreviewGrid"></div>
          <label class="check"><input name="featured" type="checkbox" /> Featured product</label>
          <div class="admin-actions"><button class="button primary" type="submit">Save Product</button><button class="button ghost" id="resetProductForm" type="button">Clear</button></div>
        </form>
        <div id="adminProducts" class="admin-list"></div>
      </section>
      <section class="admin-section">
        <h2>Feedback Moderation</h2>
        <div id="adminFeedback" class="admin-list"></div>
      </section>
      <section class="admin-section">
        <h2>Inquiries</h2>
        <div class="admin-list">${inquiries.map((item) => `<article><strong>${escapeHtml(item.name)}</strong><p>${escapeHtml(item.message)}</p><small>${escapeHtml(item.email)} | ${escapeHtml(item.phone)}</small></article>`).join("") || "<p>No inquiries yet.</p>"}</div>
      </section>
      <section class="admin-section">
        <h2>Audit Log</h2>
        <div id="auditLog" class="audit-list"></div>
      </section>
    </section>
  `, req);
}

function validateProduct(data) {
  const required = ["name", "category", "price", "productType", "summary", "details", "packSize", "audience"];
  for (const key of required) if (!String(data[key] || "").trim()) return `${key} is required`;
  return null;
}

function productPayload(data) {
  const images = Array.isArray(data.images)
    ? data.images.map((item) => String(item).trim()).filter(Boolean)
    : String(data.images || "").split(/\n|,/).map((item) => item.trim()).filter(Boolean);
  return {
    name: data.name.trim(),
    category: data.category.trim(),
    price: data.price.trim(),
    productType: data.productType.trim(),
    summary: data.summary.trim(),
    details: data.details.trim(),
    packSize: data.packSize.trim(),
    audience: data.audience.trim(),
    imagesJson: JSON.stringify(images),
    featured: data.featured === true || data.featured === "on" || data.featured === "true" ? 1 : 0
  };
}

function requireAdmin(req, res) {
  if (!fixedIsAdmin(req)) {
    json(res, 401, { error: "Admin login required" });
    return false;
  }
  return true;
}

function hashOtp(otp) {
  return crypto.createHash("sha256").update(`${otp}:${SESSION_SECRET}`).digest("hex");
}

function imageSvg(label, color) {
  return `<svg width="900" height="620" viewBox="0 0 900 620" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="900" height="620" fill="${color}"/><path d="M0 480C165 395 281 534 435 455C592 375 682 428 900 318V620H0V480Z" fill="rgba(15,47,46,.13)"/><rect x="70" y="70" width="760" height="480" rx="38" fill="rgba(255,255,255,.75)"/><circle cx="450" cy="260" r="128" fill="#0F2F2E" opacity=".12"/><text x="450" y="292" text-anchor="middle" fill="#0F2F2E" font-family="Georgia,serif" font-size="54" font-weight="700">${label}</text><text x="450" y="365" text-anchor="middle" fill="#304B49" font-family="Verdana,sans-serif" font-size="22">Shaw Enterprise</text></svg>`;
}

initDb();

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const visitor = getVisitor(req, res);

    if (url.pathname.startsWith("/images/")) {
      const imageName = url.pathname.toLowerCase();
      const label = imageName.includes("cup") ? "Paper Cups"
        : imageName.includes("plate") ? "Paper Plates"
        : imageName.includes("container") ? "Containers"
        : imageName.includes("cutlery") ? "Cutlery"
        : imageName.includes("napkin") ? "Napkins"
        : imageName.includes("bag") ? "Paper Bags"
        : imageName.includes("straw") ? "Straws"
        : imageName.includes("bowl") ? "Bowls"
        : "Products";
      const colors = ["#F4E9D2", "#D5E4DE", "#E9DFC8", "#D7E5EC", "#EFE6EA"];
      const color = colors[Array.from(imageName).reduce((sum, char) => sum + char.charCodeAt(0), 0) % colors.length];
      return send(res, 200, imageSvg(escapeHtml(label), color), { "Content-Type": "image/svg+xml" });
    }

    if (req.method === "GET" && ["/styles.css", "/client.js", "/logo.svg"].includes(url.pathname)) {
      const file = path.join(PUBLIC_DIR, url.pathname);
      const type = url.pathname.endsWith(".css") ? "text/css" : url.pathname.endsWith(".js") ? "text/javascript" : "image/svg+xml";
      return send(res, 200, fs.readFileSync(file), { "Content-Type": type });
    }

    if (req.method === "GET" && url.pathname === "/") return send(res, 200, HomePage(req), { "Content-Type": "text/html; charset=utf-8" });
    if (req.method === "GET" && url.pathname === "/products") return send(res, 200, ProductsPage(req), { "Content-Type": "text/html; charset=utf-8" });
    if (req.method === "GET" && url.pathname === "/feedback") return send(res, 200, FeedbackPage(req, visitor), { "Content-Type": "text/html; charset=utf-8" });
    if (req.method === "GET" && url.pathname === "/contact") return send(res, 200, ContactPage(req), { "Content-Type": "text/html; charset=utf-8" });
    if (req.method === "GET" && url.pathname === "/wholesale") return send(res, 302, "", { Location: "/products" });
    if (req.method === "POST" && url.pathname === "/contact") {
      const data = await readBody(req);
      const result = saveInquiry(data);
      if (result.error) return send(res, 400, ContactPage(req), { "Content-Type": "text/html; charset=utf-8" });
      return send(res, 302, "", { Location: "/contact?sent=1" });
    }

    if (req.method === "GET" && url.pathname === "/login") return send(res, 200, LoginPage(req), { "Content-Type": "text/html; charset=utf-8" });
    if (req.method === "POST" && url.pathname === "/login") {
      const data = await readBody(req);
      if (data.username === ADMIN_USER && data.password === ADMIN_PASSWORD) {
        setCookie(res, "shaw_admin", sessionToken(), { maxAge: 60 * 60 * 8, httpOnly: true, sameSite: "Lax" });
        logAudit(req, "login", "admin", ADMIN_USER, "Admin login successful");
        return send(res, 302, "", { Location: "/admin" });
      }
      logAudit(req, "login_failed", "admin", data.username || "unknown", "Invalid admin login attempt");
      return send(res, 401, LoginPage(req, "Invalid username or password"), { "Content-Type": "text/html; charset=utf-8" });
    }
    if (req.method === "GET" && url.pathname === "/logout") {
      if (fixedIsAdmin(req)) logAudit(req, "logout", "admin", ADMIN_USER, "Admin logout");
      setCookie(res, "shaw_admin", "", { maxAge: 1, httpOnly: true, sameSite: "Lax" });
      return send(res, 302, "", { Location: "/login" });
    }
    if (req.method === "GET" && url.pathname === "/admin") {
      if (!fixedIsAdmin(req)) return send(res, 302, "", { Location: "/login" });
      return send(res, 200, AdminPage(req), { "Content-Type": "text/html; charset=utf-8" });
    }

    if (req.method === "GET" && url.pathname === "/api/products") return json(res, 200, { products: getProducts() });
    if (req.method === "POST" && url.pathname === "/api/inquiries") {
      const result = saveInquiry(await readBody(req));
      if (result.error) return json(res, 400, { error: result.error });
      return json(res, 201, { inquiry: result.inquiry, message: "Enquiry saved" });
    }
    const productMatch = url.pathname.match(/^\/api\/products\/(\d+)$/);
    if (req.method === "GET" && productMatch) {
      const product = getProduct(Number(productMatch[1]));
      if (!product) return json(res, 404, { error: "Product not found" });
      return json(res, 200, { product, reviews: getFeedbackThreads(visitor.id, { productId: product.id, sort: "top" }) });
    }

    if (req.method === "POST" && url.pathname === "/api/feedback/request-otp") {
      const data = await readBody(req);
      const email = String(data.email || "").trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return json(res, 400, { error: "Valid email is required" });
      const otp = String(Math.floor(100000 + Math.random() * 900000));
      const result = db.prepare("INSERT INTO feedback_identity_otps (visitor_id, email, otp_hash, expires_at, created_at) VALUES (?, ?, ?, ?, ?)")
        .run(visitor.id, email, hashOtp(otp), new Date(Date.now() + 10 * 60 * 1000).toISOString(), nowSql());
      mysqlSyncOtp(db.prepare("SELECT * FROM feedback_identity_otps WHERE id = ?").get(result.lastInsertRowid));
      return json(res, 200, { message: "OTP generated for local testing", devOtp: otp });
    }

    if (req.method === "POST" && url.pathname === "/api/feedback/verify-otp") {
      const data = await readBody(req);
      const email = String(data.email || "").trim().toLowerCase();
      const otp = String(data.otp || "").trim();
      const row = db.prepare(`
        SELECT * FROM feedback_identity_otps
        WHERE visitor_id = ? AND email = ? AND used_at IS NULL
        ORDER BY id DESC LIMIT 1
      `).get(visitor.id, email);
      if (!row || row.expires_at < nowSql() || row.otp_hash !== hashOtp(otp)) return json(res, 400, { error: "Invalid or expired OTP" });
      db.prepare("UPDATE feedback_identity_otps SET used_at = ? WHERE id = ?").run(nowSql(), row.id);
      mysqlSyncOtp(db.prepare("SELECT * FROM feedback_identity_otps WHERE id = ?").get(row.id));
      db.prepare(`
        INSERT INTO feedback_identities (visitor_id, email, verified, created_at, updated_at)
        VALUES (?, ?, 1, ?, ?)
        ON CONFLICT(visitor_id) DO UPDATE SET email = excluded.email, verified = 1, updated_at = excluded.updated_at
      `).run(visitor.id, email, nowSql(), nowSql());
      mysqlSyncIdentity(db.prepare("SELECT * FROM feedback_identities WHERE visitor_id = ?").get(visitor.id));
      return json(res, 200, { identity: { email: safeEmail(email), verified: true } });
    }

    if (req.method === "GET" && url.pathname === "/api/feedback") {
      const sort = url.searchParams.get("sort") || "top";
      const identity = getIdentity(visitor.id);
      return json(res, 200, {
        identity: identity ? { email: safeEmail(identity.email), verified: Boolean(identity.verified) } : null,
        threads: getFeedbackThreads(visitor.id, { sort, productId: null })
      });
    }

    if (req.method === "POST" && url.pathname === "/api/feedback") {
      const data = await readBody(req);
      const identity = getIdentity(visitor.id);
      if (!identity?.verified) return json(res, 403, { error: "Please verify your email before posting" });
      const message = String(data.message || "").trim();
      const parentId = data.parentId ? Number(data.parentId) : null;
      const productId = data.productId ? Number(data.productId) : null;
      if (message.length < 3) return json(res, 400, { error: "Feedback is too short" });
      const result = db.prepare(`
        INSERT INTO feedback_comments (visitor_id, author_email, message, parent_id, product_id, status, created_at)
        VALUES (?, ?, ?, ?, ?, 'visible', ?)
      `).run(visitor.id, identity.email, message, parentId, productId, nowSql());
      mysqlSyncFeedback(db.prepare("SELECT * FROM feedback_comments WHERE id = ?").get(result.lastInsertRowid));
      return json(res, 201, { ok: true });
    }

    const reactionMatch = url.pathname.match(/^\/api\/feedback\/(\d+)\/react$/);
    if (req.method === "POST" && reactionMatch) {
      const data = await readBody(req);
      const id = Number(reactionMatch[1]);
      const reaction = data.reaction === "heart" ? "heart" : "like";
      const existing = db.prepare("SELECT * FROM feedback_reactions WHERE feedback_id = ? AND visitor_id = ?").get(id, visitor.id);
      if (existing?.reaction === reaction) {
        db.prepare("DELETE FROM feedback_reactions WHERE id = ?").run(existing.id);
        mysqlDeleteReaction(existing.id);
        return json(res, 200, { message: "Reaction removed" });
      }
      if (existing) {
        db.prepare("UPDATE feedback_reactions SET reaction = ?, created_at = ? WHERE id = ?").run(reaction, nowSql(), existing.id);
        mysqlSyncReaction(db.prepare("SELECT * FROM feedback_reactions WHERE id = ?").get(existing.id));
      } else {
        const result = db.prepare("INSERT INTO feedback_reactions (feedback_id, visitor_id, reaction, created_at) VALUES (?, ?, ?, ?)").run(id, visitor.id, reaction, nowSql());
        mysqlSyncReaction(db.prepare("SELECT * FROM feedback_reactions WHERE id = ?").get(result.lastInsertRowid));
      }
      return json(res, 200, { message: "Reaction saved" });
    }

    if (url.pathname.startsWith("/api/admin/")) {
      if (!requireAdmin(req, res)) return;
      if (req.method === "GET" && url.pathname === "/api/admin/products") return json(res, 200, { products: getProducts() });
      if (req.method === "POST" && url.pathname === "/api/admin/products") {
        const data = await readBody(req);
        const error = validateProduct(data);
        if (error) return json(res, 400, { error });
        const p = productPayload(data);
        const result = db.prepare(`
          INSERT INTO products (name, category, price, product_type, summary, details, pack_size, audience, images_json, featured, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(p.name, p.category, p.price, p.productType, p.summary, p.details, p.packSize, p.audience, p.imagesJson, p.featured, nowSql(), nowSql());
        mysqlSyncProduct(db.prepare("SELECT * FROM products WHERE id = ?").get(result.lastInsertRowid));
        logAudit(req, "create", "product", result.lastInsertRowid, p.name);
        return json(res, 201, { products: getProducts(), auditLogs: getAuditLogs() });
      }
      const adminProductMatch = url.pathname.match(/^\/api\/admin\/products\/(\d+)$/);
      if (adminProductMatch && req.method === "PUT") {
        const data = await readBody(req);
        const error = validateProduct(data);
        if (error) return json(res, 400, { error });
        const id = Number(adminProductMatch[1]);
        const p = productPayload(data);
        db.prepare(`
          UPDATE products SET name=?, category=?, price=?, product_type=?, summary=?, details=?, pack_size=?, audience=?, images_json=?, featured=?, updated_at=?
          WHERE id=?
        `).run(p.name, p.category, p.price, p.productType, p.summary, p.details, p.packSize, p.audience, p.imagesJson, p.featured, nowSql(), id);
        mysqlSyncProduct(db.prepare("SELECT * FROM products WHERE id = ?").get(id));
        logAudit(req, "update", "product", id, p.name);
        return json(res, 200, { products: getProducts(), auditLogs: getAuditLogs() });
      }
      if (adminProductMatch && req.method === "DELETE") {
        const id = Number(adminProductMatch[1]);
        db.prepare("DELETE FROM products WHERE id = ?").run(id);
        mysqlDeleteProduct(id);
        logAudit(req, "delete", "product", id, "Product deleted");
        return json(res, 200, { products: getProducts(), auditLogs: getAuditLogs() });
      }
      if (req.method === "GET" && url.pathname === "/api/admin/feedback") return json(res, 200, { feedback: getAdminFeedback(), auditLogs: getAuditLogs() });
      const hideMatch = url.pathname.match(/^\/api\/admin\/feedback\/(\d+)\/hide$/);
      if (hideMatch && req.method === "POST") {
        const id = Number(hideMatch[1]);
        const row = db.prepare("SELECT status FROM feedback_comments WHERE id = ?").get(id);
        const status = row?.status === "hidden" ? "visible" : "hidden";
        db.prepare("UPDATE feedback_comments SET status = ? WHERE id = ?").run(status, id);
        mysqlSyncFeedback(db.prepare("SELECT * FROM feedback_comments WHERE id = ?").get(id));
        logAudit(req, status === "hidden" ? "hide" : "restore", "feedback", id, `Feedback ${status}`);
        return json(res, 200, { feedback: getAdminFeedback(), auditLogs: getAuditLogs() });
      }
      const deleteFeedbackMatch = url.pathname.match(/^\/api\/admin\/feedback\/(\d+)$/);
      if (deleteFeedbackMatch && req.method === "DELETE") {
        const id = Number(deleteFeedbackMatch[1]);
        db.prepare("DELETE FROM feedback_comments WHERE id = ?").run(id);
        mysqlDeleteFeedback(id);
        logAudit(req, "delete", "feedback", id, "Feedback deleted");
        return json(res, 200, { feedback: getAdminFeedback(), auditLogs: getAuditLogs() });
      }
    }

    return send(res, 404, layout("Not Found", `<section class="page-title compact"><h1>Page not found</h1><a class="button primary" href="/">Go Home</a></section>`, req), { "Content-Type": "text/html; charset=utf-8" });
  } catch (error) {
    console.error(error);
    return json(res, 500, { error: "Server error" });
  }
});

server.listen(PORT, () => {
  console.log(`Shaw Enterprise running at http://localhost:${PORT}`);
});
