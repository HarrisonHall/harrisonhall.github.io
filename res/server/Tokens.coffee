class Tokens
    constructor: (@db) ->
        
    update: (players, cb) ->
        ids = players.map (obj) -> obj.id
        @db.getUserTokens ids, (err, users) =>
            return cb(err) if err?
            users.forEach (user) =>
                user.newToken = false
                if @enoughGames user
                    @incrementTokens user
                    user.newToken = true

            @db.updateUserTokens users, (err, result) =>
                return cb(err) if err?
                return cb(null, users)

    enoughGames: (user) ->
        return (user.num_games + user.unranked_games) % 100 is 0

    incrementTokens: (user) ->
        user.role_tokens += 1
