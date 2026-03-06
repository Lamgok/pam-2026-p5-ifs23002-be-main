CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    photo VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID NOT NULL,
     refresh_token TEXT NOT NULL,
     auth_token TEXT NOT NULL,
     created_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    is_done BOOLEAN NOT NULL,
    cover TEXT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- ==========================================================
-- Tambahan fitur baru (tanpa mengubah 3 tabel utama di atas)
-- ==========================================================

-- Master level urgensi todo: Low, Medium, High
CREATE TABLE IF NOT EXISTS todo_urgency_levels (
    id SMALLSERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    label VARCHAR(20) NOT NULL,
    sort_order SMALLINT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_todo_urgency_levels_code CHECK (code IN ('LOW', 'MEDIUM', 'HIGH'))
);

-- Relasi setiap todo memiliki 1 level urgensi
CREATE TABLE IF NOT EXISTS todo_urgencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    todo_id UUID NOT NULL UNIQUE,
    urgency_level_id SMALLINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_todo_urgencies_todo
        FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE,
    CONSTRAINT fk_todo_urgencies_level
        FOREIGN KEY (urgency_level_id) REFERENCES todo_urgency_levels(id)
);

-- Informasi tambahan profile (about)
CREATE TABLE IF NOT EXISTS user_profile_abouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    about TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_profile_abouts_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================================
-- Constraint/index untuk optimisasi
-- ==================================
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username ON users(username);
CREATE UNIQUE INDEX IF NOT EXISTS uq_refresh_tokens_refresh_token ON refresh_tokens(refresh_token);

-- Home summary + filter status + pagination todo
CREATE INDEX IF NOT EXISTS idx_todos_user_is_done_created_at
    ON todos(user_id, is_done, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_todos_user_is_done
    ON todos(user_id, is_done);

-- Search title/description
CREATE INDEX IF NOT EXISTS idx_todos_title_trgm
    ON todos USING GIN (LOWER(title) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_todos_description_trgm
    ON todos USING GIN (LOWER(description) gin_trgm_ops);

-- Urgency filter/sort
CREATE INDEX IF NOT EXISTS idx_todo_urgencies_todo_id
    ON todo_urgencies(todo_id);
CREATE INDEX IF NOT EXISTS idx_todo_urgencies_level_id
    ON todo_urgencies(urgency_level_id);
CREATE INDEX IF NOT EXISTS idx_todo_urgency_levels_sort_order
    ON todo_urgency_levels(sort_order);

-- Lookup data pendukung
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
    ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profile_abouts_user_id
    ON user_profile_abouts(user_id);

-- Seed master urgency
INSERT INTO todo_urgency_levels (code, label, sort_order)
VALUES
    ('LOW', 'Low', 1),
    ('MEDIUM', 'Medium', 2),
    ('HIGH', 'High', 3)
ON CONFLICT (code) DO NOTHING;
