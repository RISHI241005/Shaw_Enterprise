CREATE TABLE IF NOT EXISTS product_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
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

CREATE TABLE IF NOT EXISTS product_images (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_data LONGTEXT NOT NULL,
  alt_text VARCHAR(220) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_product_images_product (product_id),
  CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_accounts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  email VARCHAR(180) NOT NULL UNIQUE,
  phone VARCHAR(40) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_auth_codes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  account_id BIGINT UNSIGNED NULL,
  destination VARCHAR(180) NOT NULL,
  channel ENUM('email','phone') NOT NULL,
  purpose ENUM('signup','reset') NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_admin_auth_codes_account (account_id),
  CONSTRAINT fk_admin_auth_codes_account FOREIGN KEY (account_id) REFERENCES admin_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inquiries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL,
  phone VARCHAR(60) NOT NULL,
  message TEXT NOT NULL,
  status ENUM('new','contacted','closed') NOT NULL DEFAULT 'new',
  created_at DATETIME NOT NULL,
  INDEX idx_inquiries_status_created (status, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS feedback_identities (
  visitor_id VARCHAR(80) PRIMARY KEY,
  email VARCHAR(180) NOT NULL UNIQUE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS feedback_identity_otps (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(80) NOT NULL,
  email VARCHAR(180) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_feedback_otps_visitor (visitor_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS feedback_comments (
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

CREATE TABLE IF NOT EXISTS feedback_reactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  feedback_id BIGINT UNSIGNED NOT NULL,
  visitor_id VARCHAR(80) NOT NULL,
  reaction ENUM('like','heart') NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_feedback_reaction_visitor (feedback_id, visitor_id),
  CONSTRAINT fk_reactions_feedback FOREIGN KEY (feedback_id) REFERENCES feedback_comments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  action_type VARCHAR(80) NOT NULL,
  target_type VARCHAR(80) NOT NULL,
  target_id VARCHAR(80),
  details TEXT NOT NULL,
  ip_address VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_audit_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS business_settings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(120) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO business_settings (setting_key, setting_value) VALUES
  ('business_name', 'Shaw Enterprise'),
  ('phone', '+91 00000 00000'),
  ('email', 'sales@shawenterprise.example'),
  ('address', 'Kolkata, West Bengal, India'),
  ('whatsapp', '910000000000'),
  ('hours', 'Monday to Saturday, 10:00 AM–7:00 PM')
ON DUPLICATE KEY UPDATE setting_key = VALUES(setting_key);
