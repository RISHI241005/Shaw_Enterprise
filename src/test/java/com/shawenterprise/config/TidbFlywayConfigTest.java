package com.shawenterprise.config;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class TidbFlywayConfigTest {
    @Test
    void createsCompatibleHistoryThenRunsNormalMigrations() throws Exception {
        var source = mock(DataSource.class);
        var connection = mock(Connection.class);
        var statement = mock(Statement.class);
        var flyway = mock(Flyway.class);
        when(source.getConnection()).thenReturn(connection);
        when(connection.createStatement()).thenReturn(statement);
        new TidbFlywayConfig().compatibleHistoryTable(source).migrate(flyway);
        var sql = ArgumentCaptor.forClass(String.class);
        verify(statement).execute(sql.capture());
        assertThat(sql.getValue()).contains("CREATE TABLE IF NOT EXISTS flyway_schema_history").doesNotContain("SELECT");
        var order = inOrder(statement, flyway);
        order.verify(statement).execute(anyString());
        order.verify(flyway).migrate();
        verify(connection).close();
    }
}
