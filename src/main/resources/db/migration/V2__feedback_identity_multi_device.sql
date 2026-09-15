SET @drop_email_index = IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'feedback_identities' AND index_name = 'email'), 'ALTER TABLE feedback_identities DROP INDEX email', 'SELECT 1');
PREPARE migration_statement FROM @drop_email_index;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;
SET @create_email_index = IF(EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'feedback_identities' AND index_name = 'idx_feedback_identity_email'), 'SELECT 1', 'CREATE INDEX idx_feedback_identity_email ON feedback_identities(email)');
PREPARE migration_statement FROM @create_email_index;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;
