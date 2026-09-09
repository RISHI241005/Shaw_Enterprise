package com.shawenterprise.web;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RequestGuard {
    private final SessionContext sessions;
    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    public RequestGuard(SessionContext sessions) {
        this.sessions = sessions;
    }

    public void csrf(HttpServletRequest request) {
        if (!sessions.validCsrf(request)) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Security token expired. Reload and try again.");
    }

    public void admin(HttpServletRequest request) {
        if (!sessions.isAdmin(request)) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Admin login required");
    }

    public void limit(HttpServletRequest request, String bucket, int maximum, long windowSeconds) {
        var key = bucket + ":" + request.getRemoteAddr();
        var now = Instant.now().getEpochSecond();
        var result = windows.compute(key, (ignored, old) -> old == null || now - old.started >= windowSeconds
            ? new Window(now, 1) : new Window(old.started, old.count + 1));
        if (result.count > maximum) throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Too many requests. Try again shortly.");
    }

    private record Window(long started, int count) {}
}
