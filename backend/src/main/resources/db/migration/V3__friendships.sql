-- Système d'amis bidirectionnel (demande + acceptation).

CREATE TABLE friendships (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status       VARCHAR(10) NOT NULL DEFAULT 'PENDING',  -- PENDING | ACCEPTED
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT friendships_no_self CHECK (requester_id != addressee_id),
    CONSTRAINT friendships_unique   UNIQUE (requester_id, addressee_id)
);

CREATE INDEX friendships_requester_idx ON friendships(requester_id);
CREATE INDEX friendships_addressee_idx ON friendships(addressee_id);
