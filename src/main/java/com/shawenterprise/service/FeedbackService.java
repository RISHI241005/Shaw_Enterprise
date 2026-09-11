package com.shawenterprise.service;

import com.shawenterprise.model.FeedbackDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class FeedbackService {
    private final JdbcTemplate jdbc;
    private final LiveUpdateService live;
    private final String otpSecret;

    public FeedbackService(JdbcTemplate jdbc, LiveUpdateService live,
                           @Value("${app.otp.secret}") String otpSecret) {
        this.jdbc = jdbc; this.live = live; this.otpSecret = otpSecret;
    }

    public Map<String, Object> identity(String visitorId) {
        var rows = jdbc.queryForList("SELECT email,verified FROM feedback_identities WHERE visitor_id=?", visitorId);
        if (rows.isEmpty()) return null;
        var row = rows.getFirst();
        return publicIdentity(String.valueOf(row.get("email")), truthy(row.get("verified")));
    }

    @Transactional
    public Map<String, Object> requestOtp(String visitorId, String channel, String destination) {
        var normalized = normalizeDestination(channel, destination);
        var otp = String.valueOf(ThreadLocalRandom.current().nextInt(100000, 1_000_000));
        jdbc.update("INSERT INTO feedback_identity_otps(visitor_id,email,otp_hash,expires_at,created_at) VALUES (?,?,?,?,?)",
            visitorId, normalized, hash(otp), Timestamp.valueOf(LocalDateTime.now().plusMinutes(10)), Timestamp.valueOf(LocalDateTime.now()));
        var result = new LinkedHashMap<String, Object>();
        result.put("message", "Dummy " + ("phone".equals(channel) ? "phone" : "email") + " OTP generated");
        result.put("devOtp", otp);
        return result;
    }

    @Transactional
    public Map<String, Object> verifyOtp(String visitorId, String channel, String destination, String otp) {
        var normalized = normalizeDestination(channel, destination);
        var rows = jdbc.queryForList("SELECT id,otp_hash,expires_at FROM feedback_identity_otps WHERE visitor_id=? AND email=? AND used_at IS NULL ORDER BY id DESC LIMIT 1", visitorId, normalized);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired OTP");
        var row = rows.getFirst();
        var expires = dateTime(row.get("expires_at"));
        if (expires.isBefore(LocalDateTime.now()) || !MessageDigest.isEqual(hash(String.valueOf(otp)).getBytes(StandardCharsets.UTF_8), String.valueOf(row.get("otp_hash")).getBytes(StandardCharsets.UTF_8)))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired OTP");
        jdbc.update("UPDATE feedback_identity_otps SET used_at=? WHERE id=?", Timestamp.valueOf(LocalDateTime.now()), row.get("id"));
        jdbc.update("""
            INSERT INTO feedback_identities(visitor_id,email,verified,created_at,updated_at) VALUES (?,?,TRUE,?,?)
            ON DUPLICATE KEY UPDATE email=VALUES(email),verified=TRUE,updated_at=VALUES(updated_at)
            """, visitorId, normalized, Timestamp.valueOf(LocalDateTime.now()), Timestamp.valueOf(LocalDateTime.now()));
        return publicIdentity(normalized, true);
    }

    public List<FeedbackDto> threads(String visitorId, String sort, Long productId, boolean includeHidden) {
        var sql = new StringBuilder("SELECT id,author_email,message,parent_id,product_id,status,created_at FROM feedback_comments WHERE ");
        var args = new ArrayList<Object>();
        if (!includeHidden) sql.append("status='visible' AND ");
        if (productId == null) sql.append("product_id IS NULL");
        else { sql.append("product_id=?"); args.add(productId); }
        sql.append(" ORDER BY created_at ASC,id ASC");
        var byId = new LinkedHashMap<Long, FeedbackDto>();
        var parents = new LinkedHashMap<Long, Long>();
        jdbc.query(sql.toString(), args.toArray(), row -> {
            var item = new FeedbackDto();
            item.id = row.getLong("id"); item.authorEmail = row.getString("author_email"); item.displayLabel = safeEmail(item.authorEmail);
            item.message = row.getString("message"); item.status = row.getString("status"); item.createdAt = dateTime(row.getObject("created_at"));
            byId.put(item.id, item);
            var parent = row.getObject("parent_id", Long.class); if (parent != null) parents.put(item.id, parent);
        });
        if (byId.isEmpty()) return List.of();
        var marks = String.join(",", byId.keySet().stream().map(ignored -> "?").toList());
        jdbc.query("SELECT feedback_id,reaction,COUNT(*) count FROM feedback_reactions WHERE feedback_id IN (" + marks + ") GROUP BY feedback_id,reaction", byId.keySet().toArray(), row -> {
            var item = byId.get(row.getLong("feedback_id")); if (item != null) item.reactions.put(row.getString("reaction"), row.getInt("count"));
        });
        jdbc.query("SELECT feedback_id,reaction FROM feedback_reactions WHERE visitor_id=? AND feedback_id IN (" + marks + ")",
            combine(visitorId, byId.keySet().toArray()), row -> { var item = byId.get(row.getLong(1)); if (item != null) item.myReaction = row.getString(2); });
        var roots = new ArrayList<FeedbackDto>();
        byId.values().forEach(item -> { var parentId = parents.get(item.id); var parent = parentId == null ? null : byId.get(parentId); if (parent == null) roots.add(item); else parent.replies.add(item); });
        Comparator<FeedbackDto> comparator = "newest".equals(sort)
            ? Comparator.comparing((FeedbackDto item) -> item.createdAt).reversed()
            : Comparator.<FeedbackDto>comparingInt(item -> item.reactions.values().stream().mapToInt(Integer::intValue).sum()).reversed().thenComparing(item -> item.createdAt, Comparator.reverseOrder());
        roots.sort(comparator);
        return roots;
    }

    public List<Map<String, Object>> adminList() {
        return jdbc.query("""
            SELECT f.id,f.author_email,f.message,f.status,f.created_at,COALESCE(p.name,'General feedback') product_name
            FROM feedback_comments f LEFT JOIN products p ON p.id=f.product_id ORDER BY f.created_at DESC,f.id DESC
            """, (row, index) -> {
                var item = new LinkedHashMap<String, Object>();
                item.put("id", row.getLong("id")); item.put("displayLabel", safeEmail(row.getString("author_email")));
                item.put("message", row.getString("message")); item.put("status", row.getString("status"));
                item.put("createdAt", dateTime(row.getObject("created_at"))); item.put("productName", row.getString("product_name"));
                return item;
            });
    }

    @Transactional
    public void post(String visitorId, String message, Long parentId, Long productId) {
        var identity = jdbc.queryForList("SELECT email FROM feedback_identities WHERE visitor_id=? AND verified=TRUE", visitorId);
        if (identity.isEmpty()) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Please verify your email or phone before posting");
        var clean = message == null ? "" : message.trim();
        if (clean.length() < 3 || clean.length() > 5000) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Feedback must be between 3 and 5000 characters");
        if (parentId != null && jdbc.queryForObject("SELECT COUNT(*) FROM feedback_comments WHERE id=?", Integer.class, parentId) == 0)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reply target does not exist");
        if (productId != null && jdbc.queryForObject("SELECT COUNT(*) FROM products WHERE id=?", Integer.class, productId) == 0)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product does not exist");
        jdbc.update("INSERT INTO feedback_comments(visitor_id,author_email,message,parent_id,product_id,status,created_at) VALUES (?,?,?,?,?,'visible',?)",
            visitorId, identity.getFirst().get("email"), clean, parentId, productId, Timestamp.valueOf(LocalDateTime.now()));
        live.publish("feedback");
    }

    @Transactional
    public void react(String visitorId, long feedbackId, String reaction) {
        var clean = "heart".equals(reaction) ? "heart" : "like";
        if (jdbc.queryForObject("SELECT COUNT(*) FROM feedback_comments WHERE id=? AND status='visible'", Integer.class, feedbackId) == 0)
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Feedback not found");
        var existing = jdbc.queryForList("SELECT id,reaction FROM feedback_reactions WHERE feedback_id=? AND visitor_id=?", feedbackId, visitorId);
        if (!existing.isEmpty() && clean.equals(String.valueOf(existing.getFirst().get("reaction")))) jdbc.update("DELETE FROM feedback_reactions WHERE id=?", existing.getFirst().get("id"));
        else jdbc.update("INSERT INTO feedback_reactions(feedback_id,visitor_id,reaction,created_at) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE reaction=VALUES(reaction),created_at=VALUES(created_at)", feedbackId, visitorId, clean, Timestamp.valueOf(LocalDateTime.now()));
        live.publish("feedback");
    }

    @Transactional
    public void toggleVisibility(long id) {
        if (jdbc.update("UPDATE feedback_comments SET status=IF(status='visible','hidden','visible') WHERE id=?", id) == 0)
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Feedback not found");
        live.publish("feedback");
    }

    @Transactional
    public void delete(long id) {
        if (jdbc.update("DELETE FROM feedback_comments WHERE id=?", id) == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Feedback not found");
        live.publish("feedback");
    }

    private Object[] combine(Object first, Object[] rest) { var result = new Object[rest.length + 1]; result[0] = first; System.arraycopy(rest, 0, result, 1, rest.length); return result; }
    private String safeEmail(String email) { var at = email.indexOf('@'); if (at < 1) return "Verified customer"; return email.substring(0, Math.min(2, at)) + "***" + email.substring(at); }
    private String safePhone(String phone) { return phone.length() > 7 ? phone.substring(0, Math.min(3, phone.length() - 4)) + "*****" + phone.substring(phone.length() - 4) : "Verified customer"; }
    private Map<String, Object> publicIdentity(String destination, boolean verified) {
        var channel = destination.contains("@") ? "email" : "phone";
        var contact = "phone".equals(channel) ? safePhone(destination) : safeEmail(destination);
        return Map.of("channel", channel, "contact", contact, "email", contact, "verified", verified);
    }
    private String normalizeDestination(String channel, String destination) {
        var value = destination == null ? "" : destination.trim();
        if ("phone".equals(channel)) {
            var phone = value.replaceAll("[\\s().-]", "");
            if (phone.matches("^\\d{10}$")) phone = "+91" + phone;
            if (!phone.matches("^\\+[1-9]\\d{7,14}$")) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter a valid phone number with country code");
            return phone;
        }
        var email = value.toLowerCase();
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$") || email.length() > 180) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter a valid email address");
        return email;
    }
    private boolean truthy(Object value) { return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1; }
    private LocalDateTime dateTime(Object value) { if (value instanceof LocalDateTime date) return date; if (value instanceof Timestamp stamp) return stamp.toLocalDateTime(); throw new IllegalArgumentException("Unsupported database date value"); }
    private String hash(String value) { try { return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest((value + ":" + otpSecret).getBytes(StandardCharsets.UTF_8))); } catch (NoSuchAlgorithmException impossible) { throw new IllegalStateException(impossible); } }
}
