USE `shaw_enterprise`;
SET FOREIGN_KEY_CHECKS = 1;

    INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at)
    VALUES (111, 'logout', 'admin', 'admin', 'Admin logout', '::1', '2026-07-28 11:55:22')
    ON DUPLICATE KEY UPDATE details = VALUES(details), created_at = VALUES(created_at);
  
