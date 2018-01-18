DROP INDEX idx_logins;
DROP TABLE notifications;
DROP TABLE post_views;
DROP TABLE likes;
DROP TABLE posts;
DROP TABLE mutes;
DROP TABLE bans;
DROP TABLE ratings;
DROP TABLE logins;
DROP TABLE gamelog;
DROP TABLE gameplayers;
DROP TABLE games;
DROP TABLE users;

/* Original schema: */

CREATE TABLE users
(
    id SERIAL PRIMARY KEY, 
    name VARCHAR(32) NOT NULL UNIQUE, 
    passwd TEXT NOT NULL, 
    is_valid BOOLEAN NOT NULL,
    email TEXT NOT NULL,
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validation_code CHAR(16)
);

CREATE TABLE games
( 
    id SERIAL PRIMARY KEY, 
    start_data TEXT NOT NULL, 
    start_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP(6),
    spies_win BOOLEAN
);

CREATE TABLE gameplayers
(
    game_id INT NOT NULL REFERENCES games(id) ON DELETE CASCADE, 
    seat SMALLINT NOT NULL, 
    player_id INT NOT NULL REFERENCES users(id),
    is_spy BOOLEAN NOT NULL, 
    CONSTRAINT pk_gameplayers PRIMARY KEY (game_id, seat),
    CONSTRAINT unique_player UNIQUE (player_id, game_id)
);

CREATE TABLE gamelog
(
    game_id INT NOT NULL REFERENCES games(id) ON DELETE CASCADE, 
    id INT NOT NULL,
    player_id INT NOT NULL REFERENCES users(id), 
    action TEXT NOT NULL,
    time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_gamelog PRIMARY KEY (game_id, id)
);

CREATE TABLE logins
(
	player_id INT NOT NULL REFERENCES users(id),
	time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
	ip VARCHAR(30) NOT NULL
);

CREATE INDEX idx_logins on logins(player_id, time);

/* CREATE EXTENSION pgcrypto; */

INSERT INTO users(name, passwd, is_valid, email) VALUES ('test', '', true, 'test@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Alpha>', '', true, 'alpha@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Bravo>', '', true, 'bravo@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Charlie>', '', true, 'charlie@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Delta>', '', true, 'delta@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Echo>', '', true, 'echo@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Foxtrot>', '', true, 'foxtrot@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Golf>', '', true, 'golf@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Hotel>', '', true, 'hotel@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<India>', '', true, 'india@example.com');
INSERT INTO users(name, passwd, is_valid, email) VALUES ('<Juliet>', '', true, 'juliet@example.com');

/* Schema change: Games.gameType added */
ALTER TABLE Games ADD game_type SMALLINT NOT NULL DEFAULT 1;
/* Schema change: Games.isRanked added */
ALTER TABLE Games ADD is_ranked BOOLEAN NOT NULL DEFAULT TRUE;
/* Add table: bans (duration in seconds) */
CREATE TABLE bans
(
    player_id INT NOT NULL REFERENCES users(id),
    ip VARCHAR(30) NOT NULL,
    time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duration INT NOT NULL,
    ban_type SMALLINT NOT NULL DEFAULT 1,
    banner_id INT NOT NULL REFERENCES users(id) DEFAULT 1,
    reason TEXT NOT NULL DEFAULT ''
);

ALTER TABLE users ADD num_games INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD stats_hidden BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD unranked_games INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD res_img TEXT NOT NULL DEFAULT 'avatars/base-res.png';
ALTER TABLE users ADD spy_img TEXT NOT NULL DEFAULT 'avatars/base-spy.png';
ALTER TABLE users ADD avatar_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE users ADD role_tokens INT NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX unique_name_on_users ON users (lower(name));

CREATE TABLE ratings
(
    player_id INT NOT NULL REFERENCES users(id),
    type INT NOT NULL DEFAULT 1,
    num_games INT NOT NULL DEFAULT 0,

    overall INT NOT NULL DEFAULT 1500,
    spy INT NOT NULL DEFAULT 1500,
    res INT NOT NULL DEFAULT 1500,
    merlin INT NOT NULL DEFAULT 1500,
    percival INT NOT NULL DEFAULT 1500,
    regular_res INT NOT NULL DEFAULT 1500,
    oberon INT NOT NULL DEFAULT 1500,
    regular_spy INT NOT NULL DEFAULT 1500,
    assassin INT NOT NULL DEFAULT 1500,
    morgana INT NOT NULL DEFAULT 1500,
    mordred INT NOT NULL DEFAULT 1500,
    mordredassassin INT NOT NULL DEFAULT 1500,

    norebo INT NOT NULL DEFAULT 1500,
    palm INT NOT NULL DEFAULT 1500,
    quickdraw INT NOT NULL DEFAULT 1500,
    mordredquickdraw INT NOT NULL DEFAULT 1500,
    good_lancelot INT NOT NULL DEFAULT 1500,
    evil_lancelot INT NOT NULL DEFAULT 1500

);
-- ALTER TABLE ratings ADD good_lancelot INT NOT NULL DEFAULT 1500;
-- ALTER TABLE ratings ADD evil_lancelot INT NOT NULL DEFAULT 1500;

-- ALTER TABLE users ADD avatar_enabled BOOLEAN NOT NULL DEFAULT TRUE;
-- ALTER TABLE users ADD role_tokens INT NOT NULL DEFAULT 0;

-- ALTER TABLE users ADD name_copy TEXT;

CREATE TABLE mutes
(
    player_id INT NOT NULL REFERENCES users(id),
    muted_id INT NOT NULL REFERENCES users(id),
    CONSTRAINT unique_mute UNIQUE (player_id, muted_id)
);

CREATE TABLE posts
(
    id SERIAL PRIMARY KEY,
    discussion_id INT REFERENCES posts(id) ON DELETE CASCADE,
    parent_id INT REFERENCES posts(id),
    poster_id INT NOT NULL REFERENCES users(id),
    is_root BOOLEAN NOT NULL DEFAULT FALSE,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    no_escape BOOLEAN NOT NULL DEFAULT FALSE,
    hidden BOOLEAN NOT NULL DEFAULT FALSE
);
-- ALTER TABLE posts ADD no_escape BOOLEAN NOT NULL DEFAULT FALSE;
-- ALTER TABLE posts ADD hidden BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE likes
(
    player_id INT NOT NULL REFERENCES users(id),
    post_id INT NOT NULL REFERENCES posts(id),
    CONSTRAINT unique_like UNIQUE (player_id, post_id)
);

CREATE TABLE post_views
(
    player_id INT NOT NULL REFERENCES users(id),
    post_id INT NOT NULL REFERENCES posts(id),
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications
(
    id SERIAL PRIMARY KEY,
    player_id INT REFERENCES users(id),
    notifier_id INT REFERENCES users(id),
    post_id INT REFERENCES posts(id),
    type INT NOT NULL DEFAULT 1,
    create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_seen BOOLEAN NOT NULL DEFAULT FALSE,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    content TEXT NOT NULL DEFAULT ''
);
-- ALTER TABLE notifications ADD content TEXT NOT NULL DEFAULT '';


-- CREATE TABLE reports
-- (
--     id SERIAL PRIMARY KEY,
--     reporter_id INT NOT NULL REFERENCES users(id),
--     reported_id INT NOT NULL REFERENCES users(id),
--     reason TEXT NOT NULL DEFAULT '',
--     content TEXT NOT NULL DEFAULT '',
--     create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE TABLE mods
-- (
--     player_id INT NOT NULL REFERENCES users(id),
--     level INT NOT NULL DEFAULT 1
-- );

-- ALTER TABLE bans ADD reason TEXT NOT NULL DEFAULT '';

-- CREATE TABLE warnings
-- (
--     id SERIAL PRIMARY KEY,
--     warner_id INT NOT NULL REFRENCES users(id),
--     warned_id INT NOT NULL REFRENCES users(id),
--     create_time TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     reason TEXT NOT NULL DEFAULT ''
-- );
