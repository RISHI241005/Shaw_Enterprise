const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { DatabaseSync } = require("node:sqlite");

const root = path.join(__dirname, "..");
const sqlitePath = path.join(root, "data", "shaw-enterprise.db");
const outputPath = path.join(root, "data", "shaw-enterprise-mysql.sql");
const db = new DatabaseSync(sqlitePath);

function esc(value) {
  if (value === null || value === undefined) return "NULL";
  return `'${String(value).replace(/\\/g, "\\\\").replace(/'/g, "''")}'`;
}

function parseJson(value) {
  try {
    return value ? JSON.parse(value) : [];
  } catch {
    return [];
  }
}

function mysqlDate(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toISOString().slice(0, 19).replace("T", " ");
}

function rows(sql) {
  return db.prepare(sql).all();
}

const products = rows("SELECT * FROM products ORDER BY id");
const inquiries = rows("SELECT * FROM inquiries ORDER BY id");
const identities = rows("SELECT * FROM feedback_identities ORDER BY created_at");
const comments = rows("SELECT * FROM feedback_comments ORDER BY id");
const reactions = rows("SELECT * FROM feedback_reactions ORDER BY id");
const auditLogs = rows("SELECT * FROM admin_audit_logs ORDER BY id");
const categoryMap = new Map();
for (const product of products) {
  const key = String(product.category || "Uncategorized").trim().toLowerCase();
  if (!categoryMap.has(key)) categoryMap.set(key, String(product.category || "Uncategorized").trim());
}
const categories = [...categoryMap.values()].sort();
const adminHash = crypto.createHash("sha256").update("change-me-now").digest("hex");

const lines = [];
lines.push("-- Shaw Enterprise full MySQL database");
lines.push("-- Generated from the local SQLite project database.");
lines.push("CREATE DATABASE IF NOT EXISTS shaw_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
lines.push("USE shaw_enterprise;");
lines.push("SET FOREIGN_KEY_CHECKS = 0;");
lines.push("DROP TABLE IF EXISTS feedback_reactions;");
lines.push("DROP TABLE IF EXISTS feedback_comments;");
lines.push("DROP TABLE IF EXISTS feedback_identity_otps;");
lines.push("DROP TABLE IF EXISTS feedback_identities;");
lines.push("DROP TABLE IF EXISTS inquiries;");
lines.push("DROP TABLE IF EXISTS product_images;");
lines.push("DROP TABLE IF EXISTS products;");
lines.push("DROP TABLE IF EXISTS product_categories;");
lines.push("DROP TABLE IF EXISTS admin_audit_logs;");
lines.push("DROP TABLE IF EXISTS admin_users;");
lines.push("DROP TABLE IF EXISTS business_settings;");
lines.push("SET FOREIGN_KEY_CHECKS = 1;");

lines.push(`
CREATE TABLE product_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(180) NOT NULL,
  sku VARCHAR(60) NOT NULL UNIQUE,
  price_label VARCHAR(80) NOT NULL,
  product_type VARCHAR(160) NOT NULL,
  summary TEXT NOT NULL,
  details TEXT NOT NULL,
  pack_size VARCHAR(160) NOT NULL,
  audience VARCHAR(180) NOT NULL,
  featured BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_products_category (category_id),
  INDEX idx_products_featured (featured),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(id)
) ENGINE=InnoDB;

CREATE TABLE product_images (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_data LONGTEXT NOT NULL,
  alt_text VARCHAR(220) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_product_images_product (product_id),
  CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE admin_users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('owner','manager','staff') NOT NULL DEFAULT 'owner',
  status ENUM('active','disabled') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE inquiries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL,
  phone VARCHAR(60) NOT NULL,
  message TEXT NOT NULL,
  status ENUM('new','contacted','closed') NOT NULL DEFAULT 'new',
  created_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_identities (
  visitor_id VARCHAR(80) PRIMARY KEY,
  email VARCHAR(180) NOT NULL UNIQUE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_identity_otps (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(80) NOT NULL,
  email VARCHAR(180) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_feedback_otps_visitor (visitor_id)
) ENGINE=InnoDB;

CREATE TABLE feedback_comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(80) NOT NULL,
  author_email VARCHAR(180) NOT NULL,
  message TEXT NOT NULL,
  parent_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NULL,
  status ENUM('visible','hidden') NOT NULL DEFAULT 'visible',
  created_at DATETIME NOT NULL,
  INDEX idx_feedback_parent (parent_id),
  INDEX idx_feedback_product (product_id),
  CONSTRAINT fk_feedback_parent FOREIGN KEY (parent_id) REFERENCES feedback_comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_feedback_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_reactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  feedback_id BIGINT UNSIGNED NOT NULL,
  visitor_id VARCHAR(80) NOT NULL,
  reaction ENUM('like','heart') NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_feedback_reaction_visitor (feedback_id, visitor_id),
  CONSTRAINT fk_reactions_feedback FOREIGN KEY (feedback_id) REFERENCES feedback_comments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE admin_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  action_type VARCHAR(80) NOT NULL,
  target_type VARCHAR(80) NOT NULL,
  target_id VARCHAR(80),
  details TEXT NOT NULL,
  ip_address VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE business_settings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(120) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
`);

for (const category of categories) {
  lines.push(`INSERT INTO product_categories (name, description) VALUES (${esc(category)}, ${esc(`${category} products for Shaw Enterprise catalog`)});`);
}

lines.push(`INSERT INTO admin_users (username, password_hash, role, status) VALUES ('admin', ${esc(adminHash)}, 'owner', 'active');`);
lines.push("INSERT INTO business_settings (setting_key, setting_value) VALUES");
lines.push("('business_name', 'Shaw Enterprise'),");
lines.push("('phone', '+91 00000 00000'),");
lines.push("('email', 'sales@shawenterprise.example'),");
lines.push("('address', 'Your shop address, city, state'),");
lines.push("('whatsapp', '910000000000');");

for (const product of products) {
  const sku = `SE-${String(product.id).padStart(4, "0")}`;
  lines.push(`INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT ${product.id}, id, ${esc(product.name)}, ${esc(sku)}, ${esc(product.price)}, ${esc(product.product_type)}, ${esc(product.summary)}, ${esc(product.details)}, ${esc(product.pack_size)}, ${esc(product.audience)}, ${product.featured ? 1 : 0}, 'active', ${esc(mysqlDate(product.created_at))}, ${esc(mysqlDate(product.updated_at))}
FROM product_categories WHERE LOWER(name) = LOWER(${esc(product.category)});`);

  parseJson(product.images_json).forEach((image, index) => {
    lines.push(`INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (${product.id}, ${esc(image)}, ${esc(product.name)}, ${index});`);
  });
}

for (const inquiry of inquiries) {
  lines.push(`INSERT INTO inquiries (id, name, email, phone, message, status, created_at) VALUES (${inquiry.id}, ${esc(inquiry.name)}, ${esc(inquiry.email)}, ${esc(inquiry.phone)}, ${esc(inquiry.message)}, ${esc(inquiry.status || "new")}, ${esc(mysqlDate(inquiry.created_at))});`);
}

for (const identity of identities) {
  lines.push(`INSERT INTO feedback_identities (visitor_id, email, verified, created_at, updated_at) VALUES (${esc(identity.visitor_id)}, ${esc(identity.email)}, ${identity.verified ? 1 : 0}, ${esc(mysqlDate(identity.created_at))}, ${esc(mysqlDate(identity.updated_at))});`);
}

for (const comment of comments) {
  lines.push(`INSERT INTO feedback_comments (id, visitor_id, author_email, message, parent_id, product_id, status, created_at) VALUES (${comment.id}, ${esc(comment.visitor_id)}, ${esc(comment.author_email)}, ${esc(comment.message)}, ${comment.parent_id || "NULL"}, ${comment.product_id || "NULL"}, ${esc(comment.status)}, ${esc(mysqlDate(comment.created_at))});`);
}

for (const reaction of reactions) {
  lines.push(`INSERT INTO feedback_reactions (id, feedback_id, visitor_id, reaction, created_at) VALUES (${reaction.id}, ${reaction.feedback_id}, ${esc(reaction.visitor_id)}, ${esc(reaction.reaction)}, ${esc(mysqlDate(reaction.created_at))});`);
}

for (const log of auditLogs) {
  lines.push(`INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (${log.id}, ${esc(log.action_type)}, ${esc(log.target_type)}, ${esc(log.target_id)}, ${esc(log.details)}, ${esc(log.ip_address)}, ${esc(mysqlDate(log.created_at))});`);
}

lines.push("ALTER TABLE products AUTO_INCREMENT = 1001;");
lines.push("ALTER TABLE product_images AUTO_INCREMENT = 1001;");
lines.push("ALTER TABLE inquiries AUTO_INCREMENT = 1001;");
lines.push("ALTER TABLE feedback_comments AUTO_INCREMENT = 1001;");
lines.push("ALTER TABLE feedback_reactions AUTO_INCREMENT = 1001;");
lines.push("ALTER TABLE admin_audit_logs AUTO_INCREMENT = 1001;");

fs.writeFileSync(outputPath, `${lines.join("\n")}\n`, "utf8");
db.close();
console.log(outputPath);
