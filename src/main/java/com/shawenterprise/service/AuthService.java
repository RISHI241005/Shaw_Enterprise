package com.shawenterprise.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class AuthService {
    private final JdbcTemplate jdbc;
    private final BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(12);
    private final String envUser;
    private final String envPassword;
    private final boolean registrationEnabled;
    private final boolean exposeOtp;
    private final String otpSecret;
    private final OtpDeliveryService delivery;

    public AuthService(JdbcTemplate jdbc, OtpDeliveryService delivery,
                       @Value("${app.admin.username}") String envUser,
                       @Value("${app.admin.password}") String envPassword,
                       @Value("${app.admin.registration-enabled:false}") boolean registrationEnabled,
                       @Value("${app.otp.expose-in-response:false}") boolean exposeOtp,
                       @Value("${app.otp.secret}") String otpSecret) {
        this.jdbc = jdbc; this.delivery = delivery; this.envUser = envUser; this.envPassword = envPassword; this.registrationEnabled = registrationEnabled; this.exposeOtp = exposeOtp; this.otpSecret = otpSecret;
    }

    public String authenticate(String identifier, String password) {
        var clean = identifier == null ? "" : identifier.trim();
        if (constantEquals(clean, envUser) && constantEquals(password, envPassword)) return envUser;
        var rows = jdbc.queryForList("SELECT username,password_hash,email_verified,phone_verified FROM admin_accounts WHERE username=? OR email=? LIMIT 1", clean, clean.toLowerCase());
        if (rows.isEmpty()) return null;
        var row = rows.getFirst();
        var verified = truthy(row.get("email_verified")) && truthy(row.get("phone_verified"));
        var hash = String.valueOf(row.get("password_hash"));
        return verified && hash.startsWith("$2") && passwords.matches(password == null ? "" : password, hash) ? String.valueOf(row.get("username")) : null;
    }

    @Transactional
    public Map<String, Object> register(String username, String email, String phone, String password) {
        if (!registrationEnabled) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "New administrator registration is disabled. Ask the owner to enable it temporarily.");
        var user = username == null ? "" : username.trim(); var mail = email == null ? "" : email.trim().toLowerCase(); var mobile = normalizePhone(phone);
        if (user.length() < 3 || user.length() > 80) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Username must be 3–80 characters");
        if (!mail.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid email is required");
        if (!mobile.matches("^\\+?[1-9]\\d{7,14}$")) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid mobile number is required");
        if (password == null || password.length() < 12) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at least 12 characters");
        var key = new GeneratedKeyHolder(); var now = LocalDateTime.now();
        try {
            jdbc.update(connection -> {
                var statement = connection.prepareStatement("INSERT INTO admin_accounts(username,email,phone,password_hash,email_verified,phone_verified,created_at,updated_at) VALUES (?,?,?,?,FALSE,FALSE,?,?)", Statement.RETURN_GENERATED_KEYS);
                statement.setString(1, user); statement.setString(2, mail); statement.setString(3, mobile); statement.setString(4, passwords.encode(password)); statement.setTimestamp(5, Timestamp.valueOf(now)); statement.setTimestamp(6, Timestamp.valueOf(now)); return statement;
            }, key);
        } catch (Exception error) { throw new ResponseStatusException(HttpStatus.CONFLICT, "Username, email, or phone is already registered"); }
        var accountId = key.getKey().longValue();
        var result = new LinkedHashMap<String, Object>(); result.put("accountId", accountId); result.put("message", "Account created. Verify both channels.");
        issue(accountId, mail, "email", "signup", "devEmailCode", result); issue(accountId, mobile, "phone", "signup", "devPhoneCode", result);
        return result;
    }

    @Transactional
    public Map<String, Object> resend(long accountId) {
        var account = jdbc.queryForMap("SELECT email,phone FROM admin_accounts WHERE id=?", accountId);
        var result = new LinkedHashMap<String, Object>(); result.put("message", "Fresh verification codes created.");
        issue(accountId, String.valueOf(account.get("email")), "email", "signup", "devEmailCode", result);
        issue(accountId, String.valueOf(account.get("phone")), "phone", "signup", "devPhoneCode", result);
        return result;
    }

    @Transactional
    public void verify(long accountId, String emailCode, String phoneCode) {
        var account = jdbc.queryForMap("SELECT email,phone FROM admin_accounts WHERE id=?", accountId);
        if (!consume(accountId, String.valueOf(account.get("email")), "email", "signup", emailCode) || !consume(accountId, String.valueOf(account.get("phone")), "phone", "signup", phoneCode))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "One or both verification codes are invalid or expired");
        jdbc.update("UPDATE admin_accounts SET email_verified=TRUE,phone_verified=TRUE,updated_at=? WHERE id=?", Timestamp.valueOf(LocalDateTime.now()), accountId);
    }

    @Transactional
    public Map<String, Object> requestReset(String email) {
        var mail = email == null ? "" : email.trim().toLowerCase();
        var result = new LinkedHashMap<String, Object>(); result.put("message", "If that account exists, a reset code has been created.");
        var accounts = jdbc.queryForList("SELECT id FROM admin_accounts WHERE email=?", mail);
        if (!accounts.isEmpty()) issue(((Number) accounts.getFirst().get("id")).longValue(), mail, "email", "reset", "devCode", result);
        return result;
    }

    @Transactional
    public void resetPassword(String email, String code, String password) {
        if (password == null || password.length() < 12) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be at least 12 characters");
        var mail = email == null ? "" : email.trim().toLowerCase(); var accounts = jdbc.queryForList("SELECT id FROM admin_accounts WHERE email=?", mail);
        if (accounts.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired reset code");
        var id = ((Number) accounts.getFirst().get("id")).longValue();
        if (!consume(id, mail, "email", "reset", code)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired reset code");
        jdbc.update("UPDATE admin_accounts SET password_hash=?,updated_at=? WHERE id=?", passwords.encode(password), Timestamp.valueOf(LocalDateTime.now()), id);
    }

    private void issue(long accountId, String destination, String channel, String purpose, String responseKey, Map<String, Object> result) {
        var code = String.valueOf(ThreadLocalRandom.current().nextInt(100000, 1_000_000));
        jdbc.update("INSERT INTO admin_auth_codes(account_id,destination,channel,purpose,code_hash,expires_at,created_at) VALUES (?,?,?,?,?,?,?)",
            accountId, destination, channel, purpose, hash(code), Timestamp.valueOf(LocalDateTime.now().plusMinutes(10)), Timestamp.valueOf(LocalDateTime.now()));
        delivery.deliver(destination, channel, code);
        if (exposeOtp) result.put(responseKey, code);
    }

    private boolean consume(long accountId, String destination, String channel, String purpose, String code) {
        var rows = jdbc.queryForList("SELECT id,code_hash,expires_at FROM admin_auth_codes WHERE account_id=? AND destination=? AND channel=? AND purpose=? AND used_at IS NULL ORDER BY id DESC LIMIT 1", accountId, destination, channel, purpose);
        if (rows.isEmpty()) return false; var row = rows.getFirst();
        if (dateTime(row.get("expires_at")).isBefore(LocalDateTime.now()) || !constantEquals(String.valueOf(row.get("code_hash")), hash(code))) return false;
        jdbc.update("UPDATE admin_auth_codes SET used_at=? WHERE id=?", Timestamp.valueOf(LocalDateTime.now()), row.get("id")); return true;
    }

    private boolean truthy(Object value) { return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1; }
    private String normalizePhone(String value) { return value == null ? "" : value.replaceAll("[\\s()-]", ""); }
    private boolean constantEquals(String one, String two) { if (one == null || two == null) return false; return MessageDigest.isEqual(one.getBytes(StandardCharsets.UTF_8), two.getBytes(StandardCharsets.UTF_8)); }
    private LocalDateTime dateTime(Object value) { if (value instanceof LocalDateTime date) return date; if (value instanceof Timestamp stamp) return stamp.toLocalDateTime(); throw new IllegalArgumentException("Unsupported database date value"); }
    private String hash(String value) { try { return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(((value == null ? "" : value) + ":" + otpSecret).getBytes(StandardCharsets.UTF_8))); } catch (NoSuchAlgorithmException impossible) { throw new IllegalStateException(impossible); } }
}
