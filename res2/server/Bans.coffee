class Bans
    constructor: (@db) ->

    addBan: (playerId, duration, banType, bannerId, reason, cb) ->
        @db.getUserIp playerId, (err, ip) =>
            return cb("Player not found") if err?
            return cb("IP is default") if ip is '0.0.0.0'
            @db.addBan playerId, ip, duration, banType, bannerId, reason, cb

    isBanned: (playerId, ip, cb) ->
        @db.getBans playerId, ip, (err, bans) =>
            return cb(false) if err?
            for ban in bans
                # 1: player ban, 2: ip ban
                duration = ban.duration * 1000 # convert from seconds to milliseconds
                timeRemaining = (duration - (Date.now() - ban.time.getTime()))
                if timeRemaining > 0 # If ban still in effect
                    if ban.ban_type is 2 # ip ban
                        return cb true, (timeRemaining / parseFloat(60 * 60 * 1000)).toFixed(2), ban.reason # time remaining in hours
                    if ban.ban_type is 1 and ban.player_id is playerId # player ban
                        return cb true, (timeRemaining / parseFloat(60 * 60 * 1000)).toFixed(2), ban.reason # time remaining in hours
            return cb false # not banned
