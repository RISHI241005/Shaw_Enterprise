package com.shawenterprise.service;

import org.junit.jupiter.api.Test;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import static org.assertj.core.api.Assertions.assertThat;

class OrderDateMappingTest {
    @Test void supportsMysqlAndLegacyJdbcDates() {
        var date = LocalDateTime.of(2026, 9, 15, 13, 30);
        assertThat(OrderService.dateTime(date)).isEqualTo(date);
        assertThat(OrderService.dateTime(Timestamp.valueOf(date))).isEqualTo(date);
    }
}
