package com.shawenterprise.config;

import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import javax.sql.DataSource;

@Configuration
public class TidbFlywayConfig {
    @Bean
    FlywayMigrationStrategy compatibleHistoryTable(DataSource dataSource) {
        return flyway -> {
            // Flyway 12's MySQL bootstrap uses CREATE TABLE ... SELECT, which
            // TiDB does not support. Pre-create only its standard empty history
            // table; Flyway still owns locking, checksums and all migrations.
            try (var connection = dataSource.getConnection(); var statement = connection.createStatement()) {
                statement.execute("""
                    CREATE TABLE IF NOT EXISTS flyway_schema_history (
                      installed_rank INT NOT NULL,
                      version VARCHAR(50),
                      description VARCHAR(200) NOT NULL,
                      type VARCHAR(20) NOT NULL,
                      script VARCHAR(1000) NOT NULL,
                      checksum INT,
                      installed_by VARCHAR(100) NOT NULL,
                      installed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                      execution_time INT NOT NULL,
                      success BOOLEAN NOT NULL,
                      PRIMARY KEY (installed_rank),
                      INDEX flyway_schema_history_s_idx (success)
                    ) ENGINE=InnoDB
                    """);
            } catch (java.sql.SQLException error) {
                throw new IllegalStateException("Cannot initialize migration history", error);
            }
            flyway.migrate();
        };
    }
}
