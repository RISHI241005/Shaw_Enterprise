CREATE TABLE IF NOT EXISTS sync_state (
  topic VARCHAR(40) PRIMARY KEY,
  version BIGINT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

INSERT INTO sync_state(topic, version) VALUES
  ('products', 0),
  ('feedback', 0),
  ('inquiries', 0),
  ('orders', 0),
  ('settings', 0)
ON DUPLICATE KEY UPDATE topic = VALUES(topic);
