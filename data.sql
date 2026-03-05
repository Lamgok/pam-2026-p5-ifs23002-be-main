CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =========================
-- Tables
-- =========================
CREATE TABLE IF NOT EXISTS users (
                                     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    photo VARCHAR(255) NULL,               -- profile photo
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS refresh_tokens (
                                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    refresh_token TEXT NOT NULL,
    auth_token TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_refresh_tokens_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

CREATE TABLE IF NOT EXISTS todos (
                                     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    is_done BOOLEAN NOT NULL DEFAULT FALSE, -- done/pending filter + summary
    cover TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_todos_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

-- =========================
-- Constraints (logical)
-- =========================
-- username harus unik untuk update akun/login
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username ON users(username);

-- token sebaiknya unik
CREATE UNIQUE INDEX IF NOT EXISTS uq_refresh_tokens_refresh_token ON refresh_tokens(refresh_token);

-- filter done/pending + pagination
CREATE INDEX IF NOT EXISTS idx_todos_user_is_done_created_at
    ON todos(user_id, is_done, created_at DESC);

-- summary home (count by user + status)
CREATE INDEX IF NOT EXISTS idx_todos_user_is_done
    ON todos(user_id, is_done);

-- search optimization (lower(title/description) LIKE ...)
CREATE INDEX IF NOT EXISTS idx_todos_title_trgm
    ON todos USING GIN (LOWER(title) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_todos_description_trgm
    ON todos USING GIN (LOWER(description) gin_trgm_ops);

-- refresh token lookup by user
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
    ON refresh_tokens(user_id);