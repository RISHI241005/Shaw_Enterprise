USE `shaw_enterprise`;
SET FOREIGN_KEY_CHECKS = 1;

    INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at)
    VALUES (113, 'login', 'admin', 'Rudra', 'Admin login successful', '::1', '2026-07-28 13:27:44')
    ON DUPLICATE KEY UPDATE details = VALUES(details), created_at = VALUES(created_at);
  
