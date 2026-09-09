package com.shawenterprise.service;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class InquiryService {
    private static final Set<String> STATUSES = Set.of("new", "contacted", "closed");
    private final JdbcTemplate jdbc;
    private final LiveUpdateService live;

    public InquiryService(JdbcTemplate jdbc, LiveUpdateService live) { this.jdbc = jdbc; this.live = live; }

    @Transactional
    public Map<String, Object> create(String name, String email, String phone, String message) {
        if (blank(name) || blank(email) || blank(phone) || blank(message)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "All inquiry fields are required");
        if (!email.trim().matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid email is required");
        var key = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            var statement = connection.prepareStatement("INSERT INTO inquiries(name,email,phone,message,status,created_at) VALUES (?,?,?,?,'new',?)", Statement.RETURN_GENERATED_KEYS);
            statement.setString(1, name.trim()); statement.setString(2, email.trim().toLowerCase()); statement.setString(3, phone.trim()); statement.setString(4, message.trim());
            statement.setTimestamp(5, Timestamp.valueOf(LocalDateTime.now()));
            return statement;
        }, key);
        live.publish("inquiries");
        return byId(key.getKey().longValue());
    }

    public List<Map<String, Object>> all() {
        return jdbc.queryForList("SELECT id,name,email,phone,message,status,created_at FROM inquiries ORDER BY created_at DESC,id DESC");
    }

    @Transactional
    public List<Map<String, Object>> status(long id, String status) {
        if (!STATUSES.contains(status)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid inquiry status");
        if (jdbc.update("UPDATE inquiries SET status=? WHERE id=?", status, id) == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Inquiry not found");
        live.publish("inquiries");
        return all();
    }

    private Map<String, Object> byId(long id) { return jdbc.queryForMap("SELECT id,name,email,phone,message,status,created_at FROM inquiries WHERE id=?", id); }
    private boolean blank(String value) { return value == null || value.trim().isBlank(); }
}
