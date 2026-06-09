-- Run: sudo -u postgres psql -d finsight_db -f schema.sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Uploaded statement files (metadata only)
CREATE TABLE IF NOT EXISTS statements(
    id             SERIAL PRIMARY KEY,
    filename       TEXT NOT NULL,
    account_name   INT,
    row_count      INT,
    uploaded_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Every parsed transaction row
CREATE TABLE IF NOT EXISTS transactions(
    id              SERIAL PRIMARY KEY,
    statement_id    INT REFERENCES statements(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    description     TEXT NOT NULL,
    amount          NUMERIC(12, 2) NOT NULL, -- negative=expense, positive=income
    balance         NUMERIC(12, 2),
    category        TEXT DEFAULT 'Other',
    account_name    TEXT,
    embedding       vector(384), -- 384-dim for semantic search
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Chat history
CREATE TABLE IF NOT EXISTS conversations (
    id         SERIAL PRIMARY KEY,
    title      TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id              SERIAL PRIMARY KEY,
    conversation_id INT REFERENCES conversations(id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('user','assistant')),
    content         TEXT NOT NULL,
    sql_used        TEXT,          -- the SQL Phi-4 generated (shown in chat UI)
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Cached AI monthly reports
CREATE TABLE IF NOT EXISTS insights (
    id         SERIAL PRIMARY KEY,
    period     TEXT NOT NULL UNIQUE,   -- e.g. '2025-01'
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_tx_date      ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_tx_category  ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_tx_statement ON transactions(statement_id);
CREATE INDEX IF NOT EXISTS idx_msg_conv     ON messages(conversation_id);

-- Vector index — create AFTER inserting at least 100 transactions:
-- CREATE INDEX idx_tx_embedding ON transactions
--     USING ivfflat (embedding vector_cosine_ops) WITH (lists = 50);