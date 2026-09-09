package com.shawenterprise.service;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class AuditService {
    private final JdbcTemplate jdbc;
    public AuditService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public void log(HttpServletRequest request, String action, String target, Object targetId, String details) {
        jdbc.update("INSERT INTO admin_audit_logs(action_type,target_type,target_id,details,ip_address,created_at) VALUES (?,?,?,?,?,?)",
            action, target, String.valueOf(targetId == null ? "" : targetId), details == null ? "" : details, request.getRemoteAddr(), Timestamp.valueOf(LocalDateTime.now()));
    }

    public List<Map<String, Object>> latest() {
        return jdbc.queryForList("SELECT id,action_type,target_type,target_id,details,ip_address,created_at FROM admin_audit_logs ORDER BY created_at DESC,id DESC LIMIT 200");
    }
}
