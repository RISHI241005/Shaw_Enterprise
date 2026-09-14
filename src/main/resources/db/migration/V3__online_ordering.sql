SET @column_sql = IF(
  EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='products' AND COLUMN_NAME='unit_price'),
  'SELECT 1', 'ALTER TABLE products ADD COLUMN unit_price DECIMAL(12,2) NULL AFTER price_label'
);
PREPARE column_statement FROM @column_sql;
EXECUTE column_statement;
DEALLOCATE PREPARE column_statement;

SET @column_sql = IF(
  EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='products' AND COLUMN_NAME='stock_quantity'),
  'SELECT 1', 'ALTER TABLE products ADD COLUMN stock_quantity INT UNSIGNED NOT NULL DEFAULT 100 AFTER unit_price'
);
PREPARE column_statement FROM @column_sql;
EXECUTE column_statement;
DEALLOCATE PREPARE column_statement;

SET @column_sql = IF(
  EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='products' AND COLUMN_NAME='ordering_enabled'),
  'SELECT 1', 'ALTER TABLE products ADD COLUMN ordering_enabled BOOLEAN NOT NULL DEFAULT TRUE AFTER stock_quantity'
);
PREPARE column_statement FROM @column_sql;
EXECUTE column_statement;
DEALLOCATE PREPARE column_statement;

UPDATE products
SET unit_price = CAST(REPLACE(REGEXP_SUBSTR(price_label, '[0-9][0-9,]*(\\.[0-9]{1,2})?'), ',', '') AS DECIMAL(12,2))
WHERE unit_price IS NULL;

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(32) NOT NULL UNIQUE,
  visitor_id VARCHAR(80) NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL,
  phone VARCHAR(40) NOT NULL,
  fulfillment_method ENUM('delivery','pickup') NOT NULL,
  payment_method ENUM('cash_on_delivery','pay_on_pickup') NOT NULL,
  address_line VARCHAR(255) NOT NULL DEFAULT '',
  city VARCHAR(120) NOT NULL DEFAULT '',
  state VARCHAR(120) NOT NULL DEFAULT '',
  postal_code VARCHAR(20) NOT NULL DEFAULT '',
  notes TEXT NOT NULL,
  status ENUM('placed','confirmed','packing','ready','out_for_delivery','delivered','cancelled') NOT NULL DEFAULT 'placed',
  subtotal DECIMAL(12,2) NOT NULL,
  delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_orders_visitor_created(visitor_id, created_at),
  INDEX idx_orders_status_created(status, created_at),
  INDEX idx_orders_phone_number(phone, order_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  sku VARCHAR(60) NOT NULL,
  product_name VARCHAR(180) NOT NULL,
  price_label VARCHAR(80) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_order_items_order(order_id),
  INDEX idx_order_items_product(product_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB;
