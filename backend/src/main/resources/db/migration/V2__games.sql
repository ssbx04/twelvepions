-- Parties online et historique des coups.

CREATE TABLE games (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    player_x_id          UUID         NOT NULL REFERENCES users(id),
    player_o_id          UUID         NOT NULL REFERENCES users(id),

    status               VARCHAR(20)  NOT NULL,                       -- IN_PROGRESS, FINISHED
    turn                 CHAR(1)      NOT NULL DEFAULT 'X',           -- X | O
    board                TEXT         NOT NULL,                       -- 5 lignes \n-séparées
    must_continue_from   VARCHAR(5),                                  -- "r,c" ou NULL

    winner               CHAR(1),                                     -- X | O | NULL (draw / en cours)
    end_reason           VARCHAR(20),                                 -- CAPTURE_ALL, BLOCKED, ONE_VS_ONE, RESIGN

    player_x_elo_before  INTEGER      NOT NULL,
    player_o_elo_before  INTEGER      NOT NULL,
    elo_change_x         INTEGER,
    elo_change_o         INTEGER,

    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    finished_at          TIMESTAMPTZ
);

CREATE INDEX games_player_x_idx       ON games(player_x_id);
CREATE INDEX games_player_o_idx       ON games(player_o_id);
CREATE INDEX games_status_idx         ON games(status);

CREATE TABLE game_moves (
    id             BIGSERIAL    PRIMARY KEY,
    game_id        UUID         NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    ply            INTEGER      NOT NULL,
    player         CHAR(1)      NOT NULL,                              -- X | O
    sequence_json  TEXT         NOT NULL,                              -- JSON de la séquence (chaîne de Move)
    played_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (game_id, ply)
);

CREATE INDEX game_moves_game_id_idx  ON game_moves(game_id);
