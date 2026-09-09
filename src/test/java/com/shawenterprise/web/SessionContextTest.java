package com.shawenterprise.web;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;

class SessionContextTest {
    private final SessionContext sessions = new SessionContext();

    @Test
    void createsStableVisitorAndCsrfTokens() {
        var request = new MockHttpServletRequest();
        assertThat(sessions.visitorId(request)).hasSize(32).isEqualTo(sessions.visitorId(request));
        var csrf = sessions.csrfToken(request);
        request.addHeader("X-CSRF-Token", csrf);
        assertThat(csrf).hasSize(48);
        assertThat(sessions.validCsrf(request)).isTrue();
    }

    @Test
    void tracksAdminLoginAndLogoutInTheSession() {
        var request = new MockHttpServletRequest();
        sessions.login(request, "owner");
        assertThat(sessions.isAdmin(request)).isTrue();
        assertThat(sessions.adminIdentity(request)).isEqualTo("owner");
        sessions.logout(request);
        assertThat(sessions.isAdmin(request)).isFalse();
    }
}
