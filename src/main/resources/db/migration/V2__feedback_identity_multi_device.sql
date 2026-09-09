ALTER TABLE feedback_identities DROP INDEX email;
CREATE INDEX idx_feedback_identity_email ON feedback_identities(email);
