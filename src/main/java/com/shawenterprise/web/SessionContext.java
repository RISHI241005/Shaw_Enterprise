package com.shawenterprise.web;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.HexFormat;

@Component
public class SessionContext {
    private static final String VISITOR = "visitorId";
    private static final String CSRF = "csrfToken";
    private static final String ADMIN = "adminIdentity";
    private final SecureRandom random = new SecureRandom();

    public String visitorId(HttpServletRequest request) {
        return value(request.getSession(true), VISITOR, 16);
    }

    public String csrfToken(HttpServletRequest request) {
        return value(request.getSession(true), CSRF, 24);
    }

    public boolean validCsrf(HttpServletRequest request) {
        var supplied = request.getHeader("X-CSRF-Token");
        if (supplied == null || supplied.isBlank()) supplied = request.getParameter("_csrf");
        return supplied != null && supplied.equals(csrfToken(request));
    }

    public boolean isAdmin(HttpServletRequest request) {
        return request.getSession(false) != null && request.getSession(false).getAttribute(ADMIN) != null;
    }

    public String adminIdentity(HttpServletRequest request) {
        if (!isAdmin(request)) return null;
        return String.valueOf(request.getSession(false).getAttribute(ADMIN));
    }

    public void login(HttpServletRequest request, String identity) {
        request.getSession(true).setAttribute(ADMIN, identity);
        request.changeSessionId();
    }

    public void logout(HttpServletRequest request) {
        var session = request.getSession(false);
        if (session != null) session.invalidate();
    }

    private String value(HttpSession session, String key, int bytes) {
        var current = session.getAttribute(key);
        if (current != null) return String.valueOf(current);
        var buffer = new byte[bytes];
        random.nextBytes(buffer);
        var created = HexFormat.of().formatHex(buffer);
        session.setAttribute(key, created);
        return created;
    }
}
