-- Schéma initial : utilisateurs.
-- L'auth se fait par numéro de téléphone + OTP. L'OTP lui-même est stocké
-- en Redis (TTL court), pas en DB.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       VARCHAR(20)  NOT NULL UNIQUE,
    full_name   VARCHAR(100),
    username    VARCHAR(20),
    level       VARCHAR(20),                              -- BEGINNER, INTERMEDIATE, ADVANCED, EXPERT
    elo         INTEGER      NOT NULL DEFAULT 1000,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Username case-insensitive unique (NULL autorisé pendant la phase
-- "profile incomplete" entre verify-otp et complete-profile).
CREATE UNIQUE INDEX users_username_lower_uidx
    ON users (LOWER(username))
    WHERE username IS NOT NULL;
