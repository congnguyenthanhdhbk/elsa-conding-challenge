---
applyTo: '**/*.sql,**/migrations/**,**/schema/**,**/models/**'
description: 'Hackolade PostgreSQL data modeling best practices for designing, documenting, and maintaining database schemas with visual modeling and forward/reverse engineering capabilities.'
---

# Hackolade PostgreSQL Data Modeling Instructions

## Overview

Hackolade is a visual data modeling tool that enables schema design, documentation, and collaboration for PostgreSQL databases. This guide provides best practices for using Hackolade principles in PostgreSQL schema design, whether using the tool itself or applying its methodologies manually.

## Core Principles

### 1. Model-First Design
- **Design Before Implementation**: Create visual data models before writing SQL
- **Iterative Refinement**: Evolve models through stakeholder feedback
- **Version Control**: Treat data models as first-class artifacts in version control
- **Documentation as Code**: Keep schema documentation synchronized with implementation

### 2. Visual Modeling Standards
- **Entity-Relationship Diagrams (ERD)**: Use clear, standardized notation
- **Logical vs Physical Models**: Maintain separation between logical design and physical implementation
- **Denormalization Decisions**: Document all denormalization choices with rationale
- **Constraint Visualization**: Explicitly show all constraints, indexes, and relationships

### 3. Forward and Reverse Engineering
- **Forward Engineering**: Generate SQL DDL scripts from visual models
- **Reverse Engineering**: Import existing schemas into visual models
- **Synchronization**: Keep models and database schemas in sync
- **Change Scripts**: Generate ALTER scripts for schema evolution

## PostgreSQL-Specific Modeling

### 1. Table Design

#### Naming Conventions
```sql
-- Tables: plural, snake_case
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction tables: table1_table2 or descriptive name
CREATE TABLE user_roles (...);
CREATE TABLE quiz_participants (...);

-- Audit tables: original_name + _audit suffix
CREATE TABLE users_audit (...);
```

#### Primary Keys
```sql
-- Prefer UUID for distributed systems
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Use SERIAL/BIGSERIAL for single-instance systems
id BIGSERIAL PRIMARY KEY

-- Composite keys when natural
PRIMARY KEY (user_id, quiz_id)

-- Document PK choice rationale in model
COMMENT ON COLUMN users.id IS 'UUID primary key for global uniqueness across distributed instances';
```

#### Columns Best Practices
```sql
-- Use appropriate data types
user_id UUID NOT NULL,
email VARCHAR(255) NOT NULL,
score INTEGER DEFAULT 0,
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
metadata JSONB,

-- NOT NULL constraints for required fields
username VARCHAR(100) NOT NULL,

-- CHECK constraints for business rules
CHECK (score >= 0),
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),

-- Default values for common cases
is_active BOOLEAN DEFAULT TRUE,
status VARCHAR(20) DEFAULT 'pending',

-- Use domains for reusable types
CREATE DOMAIN email_address AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');
```

### 2. Relationships and Constraints

#### Foreign Keys
```sql
-- Always name foreign key constraints
CONSTRAINT fk_participants_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES users(id) 
    ON DELETE CASCADE,

-- Document referential actions
CONSTRAINT fk_sessions_quiz_id
    FOREIGN KEY (quiz_id)
    REFERENCES quizzes(id)
    ON DELETE RESTRICT  -- Prevent deletion of quiz with active sessions
    ON UPDATE CASCADE,  -- Propagate quiz ID updates

-- Use appropriate ON DELETE actions
-- CASCADE: Child records deleted with parent
-- RESTRICT/NO ACTION: Prevent parent deletion if children exist
-- SET NULL: Set FK to NULL when parent deleted
-- SET DEFAULT: Set FK to default value when parent deleted
```

#### Unique Constraints
```sql
-- Single column uniqueness
CONSTRAINT uk_users_email UNIQUE (email),

-- Composite uniqueness
CONSTRAINT uk_participants_session_user UNIQUE (session_id, user_id),

-- Partial unique indexes for conditional uniqueness
CREATE UNIQUE INDEX uk_active_sessions_quiz 
    ON quiz_sessions(quiz_id) 
    WHERE status = 'active';
```

#### Check Constraints
```sql
-- Value range validation
CONSTRAINT chk_score_range CHECK (score >= 0 AND score <= 1000),

-- Enum-like validation (prefer ENUMs for PostgreSQL)
CONSTRAINT chk_status CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),

-- Date range validation
CONSTRAINT chk_end_after_start CHECK (end_time IS NULL OR end_time > start_time),

-- Complex business rules
CONSTRAINT chk_participant_limit CHECK (
    max_participants IS NULL OR max_participants > 0
),

-- Document constraint rationale
COMMENT ON CONSTRAINT chk_score_range ON participants IS 
    'Quiz scores range from 0 to 1000 points based on correct answers and time bonuses';
```

### 3. Indexes

#### Index Strategy
```sql
-- Primary key indexes (automatic)
-- Unique indexes for unique constraints (automatic)

-- Foreign key indexes (MUST create manually in PostgreSQL)
CREATE INDEX idx_participants_user_id ON participants(user_id);
CREATE INDEX idx_participants_session_id ON participants(session_id);

-- Composite indexes for common query patterns
CREATE INDEX idx_participants_session_score 
    ON participants(session_id, score DESC);

-- Covering indexes for query optimization
CREATE INDEX idx_sessions_status_covering 
    ON quiz_sessions(status) 
    INCLUDE (quiz_id, start_time, max_participants);

-- Partial indexes for filtered queries
CREATE INDEX idx_active_participants 
    ON participants(session_id, score) 
    WHERE status = 'connected';

-- GIN indexes for JSONB and full-text search
CREATE INDEX idx_metadata_gin ON participants USING GIN(metadata);

-- GiST indexes for spatial or range data
CREATE INDEX idx_time_range ON quiz_sessions USING GIST(tstzrange(start_time, end_time));

-- B-tree indexes for sorting and range queries (default)
CREATE INDEX idx_participants_score ON participants(score DESC);
```

#### Index Naming Convention
```
idx_{table}_{column1}_{column2}[_{type}]

Examples:
- idx_participants_user_id
- idx_participants_session_score
- idx_metadata_gin
- idx_active_participants (partial)
```

### 4. Data Types

#### PostgreSQL Type Selection
```sql
-- Numeric Types
SMALLINT          -- -32,768 to 32,767 (2 bytes)
INTEGER           -- -2B to 2B (4 bytes) - default choice
BIGINT            -- Large numbers (8 bytes)
NUMERIC(p, s)     -- Exact decimal (e.g., money: NUMERIC(12, 2))
REAL, DOUBLE PRECISION  -- Floating point (avoid for money)

-- String Types
CHAR(n)           -- Fixed length (rarely used)
VARCHAR(n)        -- Variable length with limit (use for constrained strings)
TEXT              -- Unlimited length (preferred for long text)

-- Date/Time Types
DATE              -- Date only
TIME              -- Time only
TIMESTAMP         -- Date + time without timezone
TIMESTAMP WITH TIME ZONE  -- Preferred for most use cases
INTERVAL          -- Time duration

-- Boolean
BOOLEAN           -- TRUE, FALSE, NULL

-- UUID
UUID              -- 128-bit universally unique identifier

-- JSON
JSON              -- Text-based JSON (legacy)
JSONB             -- Binary JSON (preferred, supports indexing)

-- Arrays
INTEGER[]         -- Array of integers
TEXT[]            -- Array of text

-- Custom Types
CREATE TYPE session_status AS ENUM ('waiting', 'active', 'completed', 'cancelled');
```

#### Type Usage Guidelines
```sql
-- User identification
user_id UUID DEFAULT gen_random_uuid(),

-- Email addresses
email VARCHAR(255) NOT NULL,

-- Usernames
username VARCHAR(100) NOT NULL,

-- Scores and metrics
score INTEGER DEFAULT 0,
accuracy NUMERIC(5, 2),  -- e.g., 98.75%

-- Timestamps (always use WITH TIME ZONE)
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

-- Status fields (use ENUMs)
status session_status DEFAULT 'waiting',

-- Money (use NUMERIC, never REAL/FLOAT)
amount NUMERIC(12, 2),  -- up to 9,999,999,999.99

-- Large text content
description TEXT,
content TEXT,

-- Metadata and dynamic attributes
metadata JSONB DEFAULT '{}',

-- Flags
is_active BOOLEAN DEFAULT TRUE,
is_deleted BOOLEAN DEFAULT FALSE,
```

### 5. Schema Organization

#### Multi-Schema Design
```sql
-- Separate schemas for different concerns
CREATE SCHEMA core;      -- Core business entities
CREATE SCHEMA audit;     -- Audit and history tables
CREATE SCHEMA analytics; -- Reporting and aggregations
CREATE SCHEMA staging;   -- ETL staging area

-- Schema-qualified table names
CREATE TABLE core.users (...);
CREATE TABLE core.quiz_sessions (...);
CREATE TABLE audit.users_audit (...);
CREATE TABLE analytics.daily_quiz_stats (...);

-- Set search path for convenience
SET search_path TO core, public;

-- Document schema purpose
COMMENT ON SCHEMA core IS 'Core application entities for quiz system';
COMMENT ON SCHEMA audit IS 'Audit trail and change history tables';
```

### 6. Temporal Data and Audit

#### Audit Columns Pattern
```sql
-- Standard audit columns (add to all tables)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- ... business columns ...
    
    -- Audit columns
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,  -- Soft delete
    version INTEGER DEFAULT 1 NOT NULL    -- Optimistic locking
);

-- Auto-update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### Audit Table Pattern
```sql
-- Audit table mirrors source table
CREATE TABLE users_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    operation CHAR(1) NOT NULL,  -- 'I', 'U', 'D'
    audit_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    audit_user UUID,
    
    -- All columns from source table
    id UUID NOT NULL,
    username VARCHAR(100),
    email VARCHAR(255),
    -- ... all other columns ...
    
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Audit trigger
CREATE OR REPLACE FUNCTION audit_users()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO users_audit SELECT nextval('users_audit_audit_id_seq'), 'D', NOW(), current_user, OLD.*;
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO users_audit SELECT nextval('users_audit_audit_id_seq'), 'U', NOW(), current_user, NEW.*;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO users_audit SELECT nextval('users_audit_audit_id_seq'), 'I', NOW(), current_user, NEW.*;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_users_audit
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_users();
```

### 7. Partitioning

#### Range Partitioning (Time-based)
```sql
-- Partition by time range for large tables
CREATE TABLE answer_submissions (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    session_id UUID NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    -- ... other columns ...
) PARTITION BY RANGE (submitted_at);

-- Create partitions
CREATE TABLE answer_submissions_2025_11 
    PARTITION OF answer_submissions
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE answer_submissions_2025_12 
    PARTITION OF answer_submissions
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Create default partition for future data
CREATE TABLE answer_submissions_default 
    PARTITION OF answer_submissions DEFAULT;

-- Automate partition creation
CREATE OR REPLACE FUNCTION create_monthly_partition()
RETURNS void AS $$
DECLARE
    partition_date DATE;
    partition_name TEXT;
    start_date TEXT;
    end_date TEXT;
BEGIN
    partition_date := DATE_TRUNC('month', NOW() + INTERVAL '1 month');
    partition_name := 'answer_submissions_' || TO_CHAR(partition_date, 'YYYY_MM');
    start_date := partition_date::TEXT;
    end_date := (partition_date + INTERVAL '1 month')::TEXT;
    
    EXECUTE FORMAT(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF answer_submissions FOR VALUES FROM (%L) TO (%L)',
        partition_name, start_date, end_date
    );
END;
$$ LANGUAGE plpgsql;
```

#### List Partitioning (Category-based)
```sql
-- Partition by discrete values
CREATE TABLE quiz_sessions (
    id UUID DEFAULT gen_random_uuid(),
    status VARCHAR(20) NOT NULL,
    -- ... other columns ...
) PARTITION BY LIST (status);

CREATE TABLE quiz_sessions_active PARTITION OF quiz_sessions FOR VALUES IN ('active');
CREATE TABLE quiz_sessions_completed PARTITION OF quiz_sessions FOR VALUES IN ('completed');
CREATE TABLE quiz_sessions_other PARTITION OF quiz_sessions DEFAULT;
```

### 8. Views and Materialized Views

#### Standard Views
```sql
-- Encapsulate complex queries
CREATE OR REPLACE VIEW v_active_sessions AS
SELECT 
    qs.id,
    qs.quiz_id,
    q.title AS quiz_title,
    qs.start_time,
    COUNT(DISTINCT p.user_id) AS participant_count,
    COALESCE(MAX(p.score), 0) AS highest_score
FROM quiz_sessions qs
JOIN quizzes q ON qs.quiz_id = q.id
LEFT JOIN participants p ON qs.id = p.session_id AND p.status = 'connected'
WHERE qs.status = 'active'
GROUP BY qs.id, qs.quiz_id, q.title, qs.start_time;

-- Document view purpose
COMMENT ON VIEW v_active_sessions IS 
    'Real-time view of active quiz sessions with participant counts and scores';
```

#### Materialized Views for Performance
```sql
-- Pre-aggregate expensive queries
CREATE MATERIALIZED VIEW mv_daily_quiz_statistics AS
SELECT 
    DATE_TRUNC('day', qs.start_time) AS quiz_date,
    q.id AS quiz_id,
    q.title AS quiz_title,
    COUNT(DISTINCT qs.id) AS session_count,
    COUNT(DISTINCT p.user_id) AS unique_participants,
    AVG(p.score) AS average_score,
    MAX(p.score) AS highest_score,
    SUM(CASE WHEN qs.status = 'completed' THEN 1 ELSE 0 END) AS completed_sessions
FROM quiz_sessions qs
JOIN quizzes q ON qs.quiz_id = q.id
LEFT JOIN participants p ON qs.id = p.session_id
GROUP BY DATE_TRUNC('day', qs.start_time), q.id, q.title;

-- Create index on materialized view
CREATE INDEX idx_mv_daily_stats_date ON mv_daily_quiz_statistics(quiz_date);

-- Refresh strategy
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_quiz_statistics;

-- Automate refresh
CREATE OR REPLACE FUNCTION refresh_daily_statistics()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_quiz_statistics;
END;
$$ LANGUAGE plpgsql;

-- Schedule with pg_cron (if available)
-- SELECT cron.schedule('refresh-stats', '0 1 * * *', 'SELECT refresh_daily_statistics()');
```

### 9. Documentation and Comments

#### Table and Column Documentation
```sql
-- Table-level documentation
COMMENT ON TABLE quiz_sessions IS 
    'Quiz session instances where participants compete in real-time. Each session is associated with a quiz and tracks participant scores and rankings.';

-- Column-level documentation
COMMENT ON COLUMN quiz_sessions.id IS 
    'Unique session identifier (UUID v4)';
COMMENT ON COLUMN quiz_sessions.quiz_id IS 
    'Reference to the quiz being played in this session';
COMMENT ON COLUMN quiz_sessions.status IS 
    'Current session state: waiting (not started), active (in progress), completed (finished), cancelled';
COMMENT ON COLUMN quiz_sessions.start_time IS 
    'Timestamp when the quiz session began (UTC)';
COMMENT ON COLUMN quiz_sessions.max_participants IS 
    'Maximum number of participants allowed (NULL = unlimited)';

-- Constraint documentation
COMMENT ON CONSTRAINT fk_sessions_quiz_id ON quiz_sessions IS 
    'Ensures quiz exists and prevents deletion of quizzes with active sessions';
COMMENT ON CONSTRAINT chk_end_after_start ON quiz_sessions IS 
    'Business rule: quiz cannot end before it starts';

-- Index documentation
COMMENT ON INDEX idx_participants_session_score IS 
    'Optimizes leaderboard queries (session + score descending) for real-time ranking calculations';
```

#### Schema Change Documentation
```sql
-- Migration tracking table
CREATE TABLE schema_migrations (
    version VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    applied_by VARCHAR(100) NOT NULL,
    checksum VARCHAR(64),
    execution_time_ms INTEGER
);

-- Document each migration
INSERT INTO schema_migrations (version, description, applied_by, checksum)
VALUES ('001', 'Initial schema: users, quizzes, sessions, participants', CURRENT_USER, md5('schema_content'));
```

### 10. Performance Optimization

#### Query Optimization Patterns
```sql
-- Use EXPLAIN ANALYZE to profile queries
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM participants 
WHERE session_id = '...' 
ORDER BY score DESC;

-- Covering indexes to avoid table lookups
CREATE INDEX idx_participants_leaderboard 
    ON participants(session_id, score DESC) 
    INCLUDE (user_id, username);

-- Partial indexes for frequently filtered data
CREATE INDEX idx_active_participants 
    ON participants(session_id, score) 
    WHERE status = 'connected';

-- Appropriate JOIN types
-- INNER JOIN for required relationships
-- LEFT JOIN when right side may be NULL
-- Avoid unnecessary JOINs

-- Use WITH (Common Table Expressions) for clarity
WITH active_sessions AS (
    SELECT id, quiz_id FROM quiz_sessions WHERE status = 'active'
)
SELECT * FROM active_sessions JOIN participants ON ...;

-- Batch operations for bulk inserts
INSERT INTO participants (user_id, session_id, username)
SELECT user_id, session_id, username FROM staging_participants
ON CONFLICT (session_id, user_id) DO NOTHING;
```

#### Connection Pooling Configuration
```sql
-- PostgreSQL connection settings (postgresql.conf)
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1  -- For SSD
effective_io_concurrency = 200
work_mem = 4MB

-- Connection pooling (application level with PgBouncer)
-- Use transaction pooling for stateless applications
-- Use session pooling when necessary
```

### 11. Security Best Practices

#### Role-Based Access Control
```sql
-- Create roles for different access levels
CREATE ROLE quiz_app_read;
CREATE ROLE quiz_app_write;
CREATE ROLE quiz_app_admin;

-- Grant appropriate permissions
GRANT CONNECT ON DATABASE quiz_db TO quiz_app_read;
GRANT USAGE ON SCHEMA core TO quiz_app_read;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO quiz_app_read;

GRANT quiz_app_read TO quiz_app_write;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO quiz_app_write;

GRANT quiz_app_write TO quiz_app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO quiz_app_admin;

-- Create application user
CREATE USER quiz_app WITH PASSWORD 'secure_password';
GRANT quiz_app_write TO quiz_app;
```

#### Row-Level Security (RLS)
```sql
-- Enable RLS on tables
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY participants_select_policy ON participants
    FOR SELECT
    USING (user_id = current_setting('app.current_user_id')::UUID OR current_user = 'admin');

CREATE POLICY participants_insert_policy ON participants
    FOR INSERT
    WITH CHECK (user_id = current_setting('app.current_user_id')::UUID);

-- Set user context in application
SET app.current_user_id = 'user-uuid-here';
```

#### Sensitive Data Protection
```sql
-- Use pgcrypto for sensitive data
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Hash passwords
UPDATE users SET password_hash = crypt('plain_password', gen_salt('bf'));

-- Verify passwords
SELECT id FROM users WHERE email = 'user@example.com' 
    AND password_hash = crypt('input_password', password_hash);

-- Encrypt sensitive columns
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    ssn BYTEA,  -- Encrypted
    credit_card BYTEA  -- Encrypted
);

-- Encrypt data
INSERT INTO user_profiles (user_id, ssn)
VALUES ('...', pgp_sym_encrypt('123-45-6789', 'encryption_key'));

-- Decrypt data
SELECT pgp_sym_decrypt(ssn, 'encryption_key') FROM user_profiles;
```

## Hackolade Workflow Integration

### 1. Model Creation Workflow
1. **Start with Logical Model**: Define entities, attributes, relationships
2. **Add Business Rules**: Constraints, validation rules, cardinality
3. **Convert to Physical Model**: Map to PostgreSQL types, add indexes
4. **Generate DDL Scripts**: Export CREATE statements
5. **Version Control**: Commit model files (.json, .png diagrams) to Git
6. **Apply to Database**: Run forward engineering scripts
7. **Document Changes**: Update migration tracking and documentation

### 2. Reverse Engineering Workflow
1. **Connect to Existing Database**: Import schema from live PostgreSQL instance
2. **Generate Visual Model**: Automatically create ERD
3. **Enhance Documentation**: Add comments, business rules, rationale
4. **Compare with Logical Model**: Identify deviations
5. **Refine and Normalize**: Apply normalization rules, optimize
6. **Export Updated Schema**: Generate ALTER scripts for changes

### 3. Schema Evolution Workflow
1. **Update Model**: Modify entities, attributes, relationships in visual tool
2. **Generate Migration Scripts**: Create ALTER TABLE statements
3. **Review Changes**: Validate impact on existing data and applications
4. **Test in Staging**: Apply changes to test environment
5. **Document Migration**: Add version, description, rollback plan
6. **Apply to Production**: Execute migration with proper monitoring
7. **Update Model Version**: Commit updated model to version control

### 4. Collaboration Workflow
1. **Share Models**: Export models for team review (.png, .pdf, .html)
2. **Review and Annotate**: Gather feedback on design decisions
3. **Track Changes**: Use version control for model evolution
4. **Maintain Consistency**: Ensure all team members work from latest model
5. **Generate Documentation**: Auto-generate schema documentation

## Migration Best Practices

### Migration File Structure
```sql
-- migrations/V001__initial_schema.sql
-- Migration version: 001
-- Description: Initial database schema for quiz application
-- Author: Engineering Team
-- Date: 2025-11-16

BEGIN;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS audit;

-- Create types
CREATE TYPE core.session_status AS ENUM ('waiting', 'active', 'completed', 'cancelled');

-- Create tables
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT uk_users_email UNIQUE (email)
);

-- Create indexes
CREATE INDEX idx_users_email ON core.users(email);

-- Add comments
COMMENT ON TABLE core.users IS 'Application users who participate in quizzes';

-- Record migration
INSERT INTO schema_migrations (version, description, applied_by)
VALUES ('001', 'Initial schema: users, quizzes, sessions, participants', CURRENT_USER);

COMMIT;
```

### Rollback Scripts
```sql
-- migrations/V001__initial_schema.down.sql
-- Rollback for migration 001

BEGIN;

-- Drop in reverse order of creation
DROP INDEX IF EXISTS core.idx_users_email;
DROP TABLE IF EXISTS core.users CASCADE;
DROP TYPE IF EXISTS core.session_status;
DROP SCHEMA IF EXISTS audit CASCADE;
DROP SCHEMA IF EXISTS core CASCADE;

-- Remove migration record
DELETE FROM schema_migrations WHERE version = '001';

COMMIT;
```

## Naming Conventions Summary

### Database Objects
```
Tables:         plural_snake_case           (users, quiz_sessions)
Columns:        snake_case                  (user_id, created_at)
Primary Keys:   pk_{table}                  (pk_users)
Foreign Keys:   fk_{table}_{column}         (fk_participants_user_id)
Unique Keys:    uk_{table}_{column(s)}      (uk_users_email)
Check Constraints: chk_{table}_{description} (chk_score_range)
Indexes:        idx_{table}_{column(s)}     (idx_participants_session_score)
Sequences:      seq_{table}_{column}        (seq_users_id)
Views:          v_{description}             (v_active_sessions)
Materialized Views: mv_{description}        (mv_daily_statistics)
Functions:      {verb}_{object}             (update_leaderboard, calculate_score)
Triggers:       tr_{table}_{event}          (tr_users_audit, tr_users_updated_at)
Schemas:        lowercase_noun              (core, audit, analytics)
Enums:          {domain}_type               (session_status, user_role)
```

## Documentation Requirements

### Required Documentation in Model
1. **Purpose**: Why does this entity/table exist?
2. **Business Rules**: What constraints and validations apply?
3. **Relationships**: How does it relate to other entities?
4. **Performance Considerations**: Expected volume, access patterns
5. **Security**: Access control requirements, sensitive data
6. **Change History**: When created, major modifications

### Model Metadata Checklist
- [ ] Entity/table descriptions
- [ ] Column descriptions with business meaning
- [ ] Primary key rationale
- [ ] Foreign key actions documented (CASCADE, RESTRICT, etc.)
- [ ] Index purpose and query patterns
- [ ] Constraint business rules
- [ ] Data type justifications
- [ ] Default value explanations
- [ ] Partition strategy (if applicable)
- [ ] Estimated row counts and growth
- [ ] Retention policies
- [ ] Security classification

## Quality Checklist

### Schema Design Review
- [ ] All tables have primary keys
- [ ] Foreign keys have indexes
- [ ] Appropriate data types selected
- [ ] NOT NULL constraints on required fields
- [ ] CHECK constraints for business rules
- [ ] Unique constraints on natural keys
- [ ] Proper ON DELETE/UPDATE actions
- [ ] Indexes for frequent queries
- [ ] Audit columns present (created_at, updated_at)
- [ ] Table and column comments added
- [ ] Naming conventions followed
- [ ] Normalization appropriate for use case
- [ ] Partitioning strategy for large tables
- [ ] Security policies defined
- [ ] Backup and recovery considered

### Performance Review
- [ ] Indexes cover common query patterns
- [ ] Covering indexes for hot queries
- [ ] Partial indexes for filtered queries
- [ ] No missing foreign key indexes
- [ ] Appropriate use of JSONB vs normalized tables
- [ ] Materialized views for expensive aggregations
- [ ] Partitioning for time-series data
- [ ] Connection pooling configured
- [ ] Query timeout settings
- [ ] Statistics collection configured

### Security Review
- [ ] Roles and permissions defined
- [ ] Row-level security policies (if needed)
- [ ] Sensitive data encrypted
- [ ] SQL injection prevention (parameterized queries)
- [ ] Audit logging enabled
- [ ] Backup encryption configured
- [ ] SSL/TLS for connections
- [ ] Password policies enforced
- [ ] Least privilege access

## Tools Integration

### Hackolade Studio
- Visual data modeling with ERD
- Forward engineering (model → DDL)
- Reverse engineering (database → model)
- Schema comparison and migration scripts
- Documentation generation (HTML, PDF, Markdown)
- Team collaboration features
- Version control integration

### Compatible Tools
- **DBeaver**: Database IDE with ER diagram support
- **pgAdmin 4**: PostgreSQL administration with schema visualization
- **DBSchema**: Interactive diagrams and documentation
- **pgModeler**: Open-source PostgreSQL modeler
- **Flyway/Liquibase**: Database migration tools
- **Git**: Version control for model files

## References and Resources

- [Hackolade Official Documentation](https://hackolade.com/help/)
- [PostgreSQL Documentation - Data Definition](https://www.postgresql.org/docs/current/ddl.html)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don%27t_Do_This)
- [Database Normalization Guide](https://en.wikipedia.org/wiki/Database_normalization)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

---

**Last Updated**: November 16, 2025  
**Applies To**: PostgreSQL 12+, Hackolade Studio 6.x+  
**Maintained By**: Data Engineering Team
