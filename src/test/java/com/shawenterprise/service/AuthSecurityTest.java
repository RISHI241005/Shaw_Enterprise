package com.shawenterprise.service;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class AuthSecurityTest {
    @Test void productionNeverExposesDemoRecoveryOrRegistrationCodes() {
        var jdbc = mock(JdbcTemplate.class);
        var auth = new AuthService(jdbc,"admin","test-secret",true,"otp-secret",true);
        assertThatThrownBy(() -> auth.requestReset("admin@example.test")).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> auth.register("newadmin","admin@example.test","9876543210","long-test-password")).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> auth.resend(1)).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> auth.resetPassword("admin@example.test","123456","long-test-password")).isInstanceOf(ResponseStatusException.class);
        verifyNoInteractions(jdbc);
    }
}
