USE `shaw_enterprise`;
SET FOREIGN_KEY_CHECKS = 1;

    INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at)
    VALUES (32, 'login', 'admin', 'admin', 'Admin login successful', '::1', '2026-06-08 13:16:57')
    ON DUPLICATE KEY UPDATE details = VALUES(details), created_at = VALUES(created_at);
  
