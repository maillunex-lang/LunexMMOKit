-- F04 scaffold: authoritative persistence for Closed Beta 0.1.0
-- Apply only via isolated compose / explicit migrate tool. Do not touch other VPS DBs.

CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS accounts (
    id BIGSERIAL PRIMARY KEY,
    login TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS characters (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    name TEXT NOT NULL UNIQUE,
    class_actor_id TEXT NOT NULL,
    level INT NOT NULL DEFAULT 1,
    xp BIGINT NOT NULL DEFAULT 0,
    hp INT NOT NULL DEFAULT 500,
    mp INT NOT NULL DEFAULT 100,
    currency BIGINT NOT NULL DEFAULT 0,
    location_id TEXT NOT NULL DEFAULT 'eternity_capital',
    pos_x DOUBLE PRECISION NOT NULL DEFAULT 0,
    pos_y DOUBLE PRECISION NOT NULL DEFAULT 0,
    pos_z DOUBLE PRECISION NOT NULL DEFAULT 0,
    quest_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    inventory JSONB NOT NULL DEFAULT '[]'::jsonb,
    equipment JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS characters_account_idx ON characters(account_id);
