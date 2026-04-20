-- ==========================================================
-- VIKING CLAN WARS - DATA MODEL PREVIEW (PostgreSQL)
-- ==========================================================

-- 1. Usuarios del sistema
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      VARCHAR(50)  UNIQUE NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url    VARCHAR(512),            -- URL pública en MinIO
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  modify_at     TIMESTAMPTZ  
);

-- 2. Personajes (un usuario puede tener varios)
CREATE TABLE characters (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id),
  clan_id    VARCHAR(50) NOT NULL,  -- 'berserkers', 'valkirias', etc.
  name       VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Registro de partidas
CREATE TABLE games (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status               VARCHAR(20) NOT NULL DEFAULT 'waiting', -- waiting, preparation, war, end, finished
  max_players          SMALLINT    NOT NULL CHECK (max_players BETWEEN 2 AND 6),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at           TIMESTAMPTZ,
  ended_at             TIMESTAMPTZ,
  winner_character_id  UUID REFERENCES characters(id)
);

-- 4. Participantes de cada partida
CREATE TABLE game_participants (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id          UUID    NOT NULL REFERENCES games(id),
  character_id     UUID    NOT NULL REFERENCES characters(id),
  join_order       SMALLINT NOT NULL,
  eliminated       BOOLEAN NOT NULL DEFAULT false,
  eliminated_at    TIMESTAMPTZ,
  UNIQUE (game_id, character_id)
);

-- 5. Volcados periódicos del estado de partida (cada ~15 min)
CREATE TABLE game_state_dumps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id     UUID  NOT NULL REFERENCES games(id),
  state_json  JSONB NOT NULL,
  dumped_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_game_state_dumps_game_id ON game_state_dumps(game_id);

-- ==========================================================
-- ANALYTICS MODEL (MongoDB - Conceptual)
-- ==========================================================
/*
Collection: game_snapshots
{
  "gameId": "uuid",
  "snapshotAt": "date",
  "phase": "string",
  "players": [...]
}

Collection: battle_events
{
  "gameId": "uuid",
  "timestamp": "date",
  "attacker": "id",
  "defender": "id",
  "outcome": "string"
}
*/
