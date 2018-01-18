pg = require 'pg'
bcrypt = require 'bcryptjs'

class Database
  constructor: ->
    @connString = g.options.db_connection_string # "postgres://username:password@host/dbname"

  initialize: (cb) ->
    cb(null, null)
    return

  withClient: (cb, call) ->
    pg.connect(@connString, (err, client, done) ->
      isErr = false
      handleErr = (err) ->
        return false if not err
        isErr = true
        done(client)
        cb(err)

      call(client, handleErr)
      done() if not isErr
    )

  # cb(err)
  addUser: (name, password, email, cb) ->
    @withClient(cb, (client, errH) =>
      cryptpass = bcrypt.hashSync(password, 8)
      client.query(
        "INSERT INTO users(name, passwd, is_valid, email) VALUES ($1, $2, true, $3)",
        [name, cryptpass, email],
        (err, res) =>
          return errH(err) if err
          @addRatings(name, cb)
      )
    )
  addRatings: (name, cb) ->
    @getUserIdByName(name, (err, id) =>
      return cb(err) if err
      @withClient(cb, (client, errH) ->
        async.map [
          "INSERT INTO ratings(player_id, type) VALUES (#{id}, 1)"
          "INSERT INTO ratings(player_id, type) VALUES (#{id}, 2)"],
          (item, cb) => client.query item, [], cb
          (err, res) =>
            console.log err if err?
            return errH(err) if err?
            cb null
        )
    )
  # addDuplicateUser: (id, name, cb) ->
  #   @getUser id, (err, result) =>


  updatePassword: (id, newPass, cb) ->
    @withClient(cb, (client, errH) ->
      cryptpass = bcrypt.hashSync(newPass, 8)
      client.query(
        "UPDATE users SET passwd = $2 WHERE id = $1",
        [id, cryptpass],
        (err, res) ->
          if err then errH(err) else cb(null)
      )
    )

  # cb(err, ??)
  login: (playerId, ip, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO logins(player_id, ip) VALUES ($1, $2)"
        [playerId, ip],
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  # cb(err, userId)
  getUserId: (name, password, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, passwd FROM users WHERE LOWER(name) = LOWER($1) AND is_valid = true"
        [name]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length isnt 1
            if bcrypt.compareSync(password, result.rows[0].passwd) or (password == "" and result.rows[0].passwd == "")
              cb(null, result.rows[0].id)
            else
              return cb('bad password')
      )
    )

  getUserIdByName: (name, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id FROM users WHERE LOWER(name) = LOWER($1) AND is_valid = true"
        [name]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length isnt 1
            return cb(null, result.rows[0].id)
      )
    )

  getUser: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, res_img, spy_img, avatar_enabled, role_tokens, stats_hidden, unranked_games FROM users WHERE id = $1 AND is_valid = true"
        [id]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length isnt 1
            cb(null, result.rows[0])
      )
    )

  getRatings: (ids, type, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name, r.num_games, r.overall, r.spy, r.res, r.merlin, r.percival, r.regular_res, r.oberon, r.regular_spy, r.assassin, r.morgana, r.mordred, r.mordredassassin, r.norebo, r.palm, r.quickdraw, r.mordredquickdraw, r.good_lancelot, r.evil_lancelot, stats_hidden
        FROM users, ratings as r
        WHERE users.id = r.player_id AND id = ANY ($1) AND r.type = $2"
        [ids, type]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length < ids.length
            return cb(null, result.rows)
      )
    )
  getRatingsByName: (name, type, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name, r.num_games, r.overall, r.spy, r.res, r.merlin, r.percival, r.regular_res, r.oberon, r.regular_spy, r.assassin, r.morgana, r.mordred, r.mordredassassin, r.norebo, r.palm, r.quickdraw, r.mordredquickdraw, r.good_lancelot, r.evil_lancelot, stats_hidden
        FROM users, ratings as r
        WHERE users.id = r.player_id AND LOWER(name) = LOWER($1) AND r.type = $2"
        [name, type]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  # getUser: (id, cb) ->
  #   @withClient(cb, (client, errH) ->
  #     client.query(
  #       "SELECT id, name, num_games, spy_rating, res_rating, rating FROM users WHERE id = $1 AND is_valid = true"
  #       [id]
  #       (err, result) ->
  #           console.log err if err
  #           return errH(err) if err
  #           return cb('not found') if result.rows.length isnt 1
  #           return cb(null, result.rows[0])
  #     )
  #   )

  getUserIp: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT ip FROM logins WHERE player_id = $1 ORDER BY time DESC"
        [id]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0].ip)
      )
    )
  getUserIps: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT DISTINCT ip FROM logins WHERE player_id = $1"
        [id]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb(null, result.rows) if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  updateRatings: (users, type, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "BEGIN;\n" +
        (users.map (user, idx) ->
            "UPDATE ratings
            SET num_games=num_games+1, spy=#{user.spy}, res=#{user.res}, overall=#{user.overall},
                merlin=#{user.merlin}, percival=#{user.percival}, regular_res=#{user.regular_res},
                mordred=#{user.mordred}, regular_spy=#{user.regular_spy}, assassin=#{user.assassin},
                morgana=#{user.morgana}, oberon=#{user.oberon}, mordredassassin=#{user.mordredassassin},
                norebo=#{user.norebo}, palm=#{user.palm}, quickdraw=#{user.quickdraw},
                mordredquickdraw=#{user.mordredquickdraw}, good_lancelot=#{user.good_lancelot}, evil_lancelot=#{user.evil_lancelot}
            WHERE player_id = #{user.id} AND type = #{type};\n").join('') +
        "COMMIT;\n"
        [],
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )


  # updateUsers: (users, cb) ->
  #   @withClient(cb, (client, errH) ->
  #     client.query(
  #       "BEGIN;\n" +
  #       (users.map (user, idx) ->
  #           "UPDATE users SET num_games=num_games+1, spy_rating=#{user.spy_rating}, res_rating=#{user.res_rating}, rating=#{user.rating} WHERE id = #{user.id};\n").join('') +
  #       "COMMIT;\n"
  #       [],
  #       (err, result) ->
  #         console.log err if err
  #         return errH(err) if err
  #         cb(null, result)
  #     )
  #   )

  # cb(err, result)
  createGame: (startData, gameType, isRanked, players, spies, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO games(start_data, game_type, is_ranked) VALUES ($1, $2, $3) RETURNING id"
        [startData, gameType, isRanked]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          id = result.rows[0].id
          client.query(
            "BEGIN;\n" +
            (players.map (player, idx) ->
                "INSERT INTO gameplayers(game_id, seat, player_id, is_spy) VALUES (#{id}, #{idx}, #{player.id}, #{if player in spies then "true" else "false"});\n").join('') +
            "COMMIT;\n"
            [],
            (err, result) ->
              console.log err if err
              return errH(err) if err
              cb(null, id)
          )
      )
    )

  # Unused?
  getUnfinishedGames: (cb) ->

  # cb(err)
  updateGame: (gameId, id, playerId, action, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO gamelog(game_id, id, player_id, action) VALUES ($1, $2, $3, $4)"
        [gameId, id, playerId, action]
        (err, res) ->
          if err
            console.log err
            errH(err)
          else
            cb(null, res)
      )
    )

  updateGameplayer: (gameId, playerId, isSpy, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE gameplayers SET is_spy = $3 WHERE game_id = $1 AND player_id = $2"
        [gameId, playerId, isSpy]
        (err, res) ->
          if err
            console.log err
            errH(err)
          else
            cb(null, res)
      )
    )

  #cb()
  finishGame: (gameId, spiesWin, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE games SET end_time = CURRENT_TIMESTAMP, spies_win = $1 WHERE id = $2"
        [spiesWin, gameId]
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  # cb(err, {games, players, gamePlayers})
  getTables: (cb) ->
    @withClient(cb, (client, errH) ->
      async.map [
        "SELECT id, start_time, end_time, spies_win, game_type FROM games WHERE end_time IS NOT NULL AND is_ranked = true ORDER BY start_time"
        "SELECT id, name, stats_hidden FROM users"
        "SELECT game_id, player_id, is_spy FROM gameplayers as gp, games as g WHERE gp.game_id = g.id AND g.end_time IS NOT NULL AND g.is_ranked = true"
        "SELECT id, name, r.num_games, r.overall, r.res, r.spy, r.merlin, r.percival, r.regular_res, r.oberon, r.regular_spy, r.assassin, r.morgana, r.mordred, stats_hidden FROM users,ratings as r WHERE users.id = r.player_id AND r.type = 1"
        "SELECT id, name, r.num_games, r.overall, r.res, r.spy, r.merlin, r.percival, r.regular_res, r.oberon, r.regular_spy, r.assassin, r.morgana, r.mordred, stats_hidden FROM users,ratings as r WHERE users.id = r.player_id AND r.type = 2"],
        (item, cb) => client.query item, [], cb
        (err, res) =>
          console.log err if err?
          return errH(err) if err?
          # This is a dirty dirty hack around case sensitivity in MSSQL which isn't in Postgres.
          gamesRenamed = res[0].rows.map (x) ->
              id: x.id
              startTime: x.start_time
              endTime: x.end_time
              spiesWin: x.spies_win
              gameType: x.game_type
          gpRenamed = res[2].rows.map (x) ->
              gameId: x.game_id
              playerId: x.player_id
              isSpy: x.is_spy
          cb null,
            games: gamesRenamed
            players: res[1].rows
            gamePlayers: gpRenamed
            ratings1: res[3].rows
            ratings2: res[4].rows
    )

  addBan: (playerId, ip, duration, banType, bannerId, reason, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO bans(player_id, ip, duration, ban_type, banner_id, reason) VALUES ($1, $2, $3, $4, $5, $6)"
        [playerId, ip, duration, banType, bannerId, reason]
        (err, res) ->
          if err
            console.log err
            errH(err)
          else
            cb null, res
      )
    )

  getBans: (playerId, ip, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT player_id, time, duration, ban_type, banner_id, reason FROM bans WHERE player_id = $1 OR ip = $2"
        [playerId, ip]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  updateUserStatsHidden: (playerId, statsHidden, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE users SET stats_hidden = $2 WHERE id = $1"
        [playerId, statsHidden]
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  updateUserAvatarEnabled: (playerId, avatarEnabled, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE users SET avatar_enabled = $2 WHERE id = $1"
        [playerId, avatarEnabled]
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  updateUserName: (playerId, name, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE users SET name = $2 WHERE id = $1"
        [playerId, name]
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  updateUnrankedGames: (users, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "BEGIN;\n" +
        (users.map (user, idx) ->
            "UPDATE users
            SET unranked_games=unranked_games+1
            WHERE id = #{user.id};\n").join('') +
        "COMMIT;\n"
        [],
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  getUnrankedGames: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name, unranked_games FROM users WHERE id = $1"
        [id]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )

  setRoleTokens: (playerId, numTokens, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE users SET role_tokens = $2 WHERE id = $1"
        [playerId, numTokens]
        (err, res) ->
          if err then errH(err) else cb(null, res)
      )
    )

  getRoleTokens: (playerId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name, role_tokens FROM users WHERE id = $1"
        [playerId]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )

  getUserTokens: (ids, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name, r.num_games, unranked_games, role_tokens
        FROM users, ratings as r
        WHERE users.id = r.player_id AND id = ANY ($1) AND r.type = 1"
        [ids]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length < ids.length
            return cb(null, result.rows)
      )
    )
  updateUserTokens: (users, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "BEGIN;\n" +
        (users.map (user, idx) ->
            "UPDATE users
            SET role_tokens = #{user.role_tokens}
            WHERE id = #{user.id};\n").join('') +
        "COMMIT;\n"
        [],
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  addMute: (playerId, mutedId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO mutes(player_id, muted_id) VALUES ($1, $2)"
        [playerId, mutedId]
        (err, res) ->
          if err
            console.log err
            errH(err)
          else
            cb(null, res)
      )
    )

  getMutes: (playerId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, name FROM mutes,users WHERE mutes.player_id = $1 and mutes.muted_id = users.id"
        [playerId]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  deleteMute: (playerId, mutedId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "DELETE FROM mutes WHERE player_id = $1 and muted_id = $2"
        [playerId, mutedId]
        (err, res) ->
          if err
            console.log err
            errH(err)
          else
            cb(null, res)
      )
    )

  createGame: (startData, gameType, isRanked, players, spies, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO games(start_data, game_type, is_ranked) VALUES ($1, $2, $3) RETURNING id"
        [startData, gameType, isRanked]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          id = result.rows[0].id
          client.query(
            "BEGIN;\n" +
            (players.map (player, idx) ->
                "INSERT INTO gameplayers(game_id, seat, player_id, is_spy) VALUES (#{id}, #{idx}, #{player.id}, #{if player in spies then "true" else "false"});\n").join('') +
            "COMMIT;\n"
            [],
            (err, result) ->
              console.log err if err
              return errH(err) if err
              cb(null, id)
          )
      )
    )


  createDiscussion: (posterId, title, content, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO posts(poster_id, is_root, title, content) VALUES ($1, $2, $3, $4) RETURNING id"
        [posterId, true, title, content]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          id = result.rows[0].id
          client.query(
            "UPDATE posts SET discussion_id = $1 WHERE id = $2"
            [id, id]
            (err, result) ->
              console.log err if err
              return errH(err) if err
              cb(null, result)
          )
      )
    )

  createPost: (discussionId, parentId, posterId, content, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO posts(discussion_id, parent_id, poster_id, is_root, content) VALUES ($1, $2, $3, $4, $5) RETURNING id"
        [discussionId, parentId, posterId, false, content]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result.rows[0])
      )
    )

  createLike: (playerId, postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO likes(player_id, post_id) VALUES ($1, $2)"
        [playerId, postId]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  createView: (playerId, postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO post_views(player_id, post_id) VALUES ($1, $2)"
        [playerId, postId]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  getPost: (postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT id, discussion_id, parent_id, poster_id, is_root, title, content FROM posts WHERE id = $1"
        [postId]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )
  getParentPost: (postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT p2.id, p2.discussion_id, p2.poster_id, p2.is_root, p2.title, p2.content
        FROM posts as p1, posts as p2
        WHERE p1.id = $1 AND p1.parent_id = p2.id"
        [postId]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )

  getDiscussions: (cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT p1.id, p1.discussion_id, p1.poster_id, p1.title, u.name, p2.create_time as post_update, CURRENT_TIMESTAMP as current_time,
                p1.create_time as post_date, u2.name as last_name, p3.num_posts
         FROM posts as p1, users as u, users as u2,
          (SELECT * FROM posts
           WHERE id in (SELECT DISTINCT ON(discussion_id) id FROM posts ORDER BY discussion_id,create_time DESC)
          ) as p2,
          (SELECT COUNT(id) as num_posts, discussion_id FROM posts GROUP BY discussion_id) as p3
         WHERE p1.is_root = true AND p1.id = p2.discussion_id AND p1.poster_id = u.id AND p2.poster_id = u2.id AND p3.discussion_id = p1.discussion_id AND p1.hidden = false
         ORDER BY p2.create_time DESC"
        []
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb(null, []) if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  getLikes: (discussionId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT likes.player_id, likes.post_id
         FROM likes, posts
         WHERE likes.post_id = posts.id AND posts.discussion_id = $1"
        [discussionId]
        (err, result) ->
            return errH(err) if err
            return cb(null, []) if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  getDiscussion: (discussionId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT p1.id, p1.discussion_id, p1.parent_id, p1.poster_id, p1.is_root, p1.title, p1.content, p1.create_time, p1.update_time, p1.no_escape, u1.name, CURRENT_TIMESTAMP as current_time,
            (SELECT COUNT(*) FROM likes WHERE p1.id = likes.post_id) as num_likes, (p1.create_time != p1.update_time) as is_edited, u2.name as replied_name
         FROM posts as p1 LEFT OUTER JOIN posts as p2 ON (p1.parent_id=p2.id) LEFT OUTER JOIN users as u2 ON (p2.poster_id=u2.id), users as u1
         WHERE p1.discussion_id = $1 AND p1.poster_id = u1.id
         ORDER BY p1.create_time ASC"
        [discussionId]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

  getLike: (playerId, postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT player_id, post_id FROM likes WHERE player_id = $1 AND post_id = $2"
        [playerId, postId]
        (err, result) ->
            console.log(err) if err?
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )

  updatePost: (postId, title, content, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE posts SET title = $2, content = $3, update_time = $4 WHERE id = $1"
        [postId, title, content, new Date()]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  deletePost: (postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "DELETE FROM posts WHERE id = $1"
        [postId]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  deletePostData: (postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE posts SET poster_id = 1, content='[deleted]', title='[deleted]' WHERE posts.id = $1"
        [postId]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  deleteLike: (playerId, postId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "DELETE FROM likes WHERE player_id = $1 AND post_id = $2"
        [playerId, postId]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )


  getNotification: (notificationId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT n.id, n.post_id, n.type, n.create_time, n.is_seen, n.player_id, p.discussion_id
         FROM notifications as n LEFT JOIN posts as p ON (p.id = n.post_id)
         WHERE n.id = $1"
        [notificationId]
        (err, result) ->
            return errH(err) if err
            return cb('not found') if result.rows.length < 1
            return cb(null, result.rows[0])
      )
    )

  getNotifications: (playerId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT n.id, n.post_id, n.type, n.create_time, n.is_seen, n.content, u.name, p.discussion_id, CURRENT_TIMESTAMP as current_time
         FROM notifications as n LEFT JOIN users as u ON (n.notifier_id = u.id) LEFT JOIN posts as p ON (n.post_id = p.id)
         WHERE n.is_hidden = false AND n.player_id = $1
         ORDER BY n.create_time desc"
        [playerId]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb(null, []) if result.rows.length < 1
            return cb(null, result.rows)
      )
    )

# 1 = post reply, 2 = like
  createNotification: (playerId, notifierId, postId, type, content, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "INSERT INTO notifications(player_id, notifier_id, post_id, type, content) VALUES ($1, $2, $3, $4, $5) RETURNING id"
        [playerId, notifierId, postId, type, content]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          id = result.rows[0].id
          cb(null, result)
      )
    )

  updateNotification: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE notifications SET is_seen = true WHERE id = $1"
        [id]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  updateNotificationHidden: (id, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "UPDATE notifications SET is_hidden = true WHERE id = $1"
        [id]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  deleteNotification: (notifierId, postId, type, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "DELETE FROM notifications
         WHERE id = any (array(SELECT id FROM notifications WHERE notifier_id = $1 AND post_id = $2 AND type = $3 LIMIT 1))"
        [notifierId, postId, type]
        (err, result) ->
          console.log err if err
          return errH(err) if err
          cb(null, result)
      )
    )

  getViews: (playerId, cb) ->
    @withClient(cb, (client, errH) ->
      client.query(
        "SELECT DISTINCT ON (post_id) post_id, create_time
         FROM post_views
         WHERE player_id = $1
         ORDER BY post_id, create_time DESC"
        [playerId]
        (err, result) ->
            console.log err if err
            return errH(err) if err
            return cb(null, []) if result.rows.length < 1
            return cb(null, result.rows)
      )
    )
