fs = require('fs')

class Commands
    constructor: (@db) ->
        @questionId = 0
        @questions = {}
        setInterval (=> @questions = {}), 4 * 60 * 60 * 1000
        @dispatchTable =
            "rank": @onRatings
            "rankings": @onRatings
            "ratings": @onRatings
            "rating": @onRatings
            "statistics": @onStats
            "stats": @onStats
            "wr": @onWinRates
            "winrates": @onWinRates
            "winrate": @onWinRates
            "msg": @onMsg
            "r": @onRe
            "lm": @onLeaveMessage
            "unrankedgames": @onUnrankedGames
            "unrankedGames": @onUnrankedGames
            "unranked_games": @onUnrankedGames
            "ug": @onUnrankedGames
            "changepass": @onChangePassword
            "changepassword": @onChangePassword
            "roll": @onRoll
            "role": @onRole
            "name": @onName
            "buzz": @onBuzz
            "ping": @onBuzz
            "notify": @onBuzz
            "alert": @onBuzz
            "poke": @onBuzz
            "beep": @onBuzz
            "nudge": @onBuzz
            "slap": @onBuzz
            "tickle": @onBuzz
            "punch": @onBuzz
            "boop": @onBuzz
            "globalmute": @onGlobalMute
            "globalunmute": @onGlobalUnmute
            "ban": @onBan
            "avatar": @onAvatar
            "av": @onAvatar
            "help": @onHelp
            "special": @onSpecial
            "logout": @onLogout
            "disableavatar": @onDisableAvatar
            "enableavatar": @onEnableAvatar
            "roletokens": @onRoleTokens
            "addtokens": @onAddRoleTokens
            "resetstats": @onResetStats
            "tstats": @onTstats
            "tratings": @onTstats
            "trating": @onTstats
            "mute": @onMute
            "mutes": @onMute
            "addmod": @onAddMod
            "addadmin": @onAddAdmin
            "answerbuzz": @onAnswerBuzz
            "modhelp": @onModHelp
            "notification": @onNotification
            "anonnames": @onAnonNames


    onCommand: (line, source, player) ->
        args = @parseCommand(line)
        cmd = args[0].substring(1).toLowerCase()
        handler = @dispatchTable[cmd]
        handler.apply(this, [args, source, player]) if handler?
        @sendChatTo player, 'Invalid command. Type "/help" for a list of valid commands.', source if not handler?

    onRatings: (args, source, player) ->
        name = if args.length is 1 then player.name else xmlEscape(args[1..].join(' '))
        # name = player.name
        @db.getRatingsByName name, 1, (err, results) =>
            return if err?
            stats = results[0]
            return if stats.stats_hidden and name.toLowerCase() isnt player.name.toLowerCase()
            html = "<strong>#{stats.name}</strong>
                    <div class='row'><table class='table table-condensed span2'>
                        <thead><tr><th>Type</th><th>Rating</th></tr></thead>
                        <tbody>
                            <tr> <td>Overall</td> <td>#{stats.overall}</td> </tr>
                            <tr> <td>Spy</td> <td>#{stats.spy}</td> </tr>
                            <tr> <td>Resistance</td> <td>#{stats.res}</td> </tr>
                            <tr> <td>Merlin</td> <td>#{stats.merlin}</td> </tr>
                            <tr> <td>Percival</td> <td>#{stats.percival}</td> </tr>
                            <tr> <td>Regular Resistance</td> <td>#{stats.regular_res}</td> </tr>
                            <tr> <td>Oberon</td> <td>#{stats.oberon}</td> </tr>
                            <tr> <td>Regular Spy</td> <td>#{stats.regular_spy}</td> </tr>
                            <tr> <td>Assassin</td> <td>#{stats.assassin}</td> </tr>
                            <tr> <td>Morgana</td> <td>#{stats.morgana}</td> </tr>
                            <tr> <td>Mordred</td> <td>#{stats.mordred}</td> </tr>
                            <tr> <td>Good Lancelot</td> <td>#{stats.good_lancelot}</td> </tr>
                            <tr> <td>Evil Lancelot</td> <td>#{stats.evil_lancelot}</td> </tr>
                        </tbody>
                    </table></div>"
            @sendChatTo player, html, source, 'server', true

    onWinRates: (args, source, player) ->
        name = if args.length is 1 then player.name else xmlEscape(args[1..].join(' '))
        # name = player.name
        g.stats.playerStats name, (err, stats) =>
            return if err?
            return if stats.stats_hidden and name.toLowerCase() isnt player.name.toLowerCase()
            html = "<strong>#{stats.name}</strong>
                    <div class='row'><table class='table table-condensed span6'>
                        <thead><tr><th>Resistance</th><th>Spy</th><th>All</th></thead>
                        <tbody>
                            <tr> <td>#{stats.resistance}</td> <td>#{stats.spy}</td> <td>#{stats.all}</td> </tr>
                        </tbody>
                    </div>"
            @sendChatTo player, html, source, 'server', true

    onStats: (args, source, player) ->
        name = if args.length is 1 then player.name else xmlEscape(args[1..].join(' '))
        # name = player.name
        @db.getRatingsByName name, 1, (err, results) =>
            return if err?
            stats = results[0]
            return if stats.stats_hidden and name.toLowerCase() isnt player.name.toLowerCase()
            html = "<strong>#{stats.name}</strong>
                    <div class='row'><table class='table table-condensed span2'>
                        <thead><tr><th>Type</th><th>Rating</th></tr></thead>
                        <tbody>
                            <tr> <td>Overall</td> <td>#{stats.overall}</td> </tr>
                            <tr> <td>Spy</td> <td>#{stats.spy}</td> </tr>
                            <tr> <td>Resistance</td> <td>#{stats.res}</td> </tr>
                            <tr> <td>Merlin</td> <td>#{stats.merlin}</td> </tr>
                            <tr> <td>Percival</td> <td>#{stats.percival}</td> </tr>
                            <tr> <td>Regular Resistance</td> <td>#{stats.regular_res}</td> </tr>
                            <tr> <td>Oberon</td> <td>#{stats.oberon}</td> </tr>
                            <tr> <td>Regular Spy</td> <td>#{stats.regular_spy}</td> </tr>
                            <tr> <td>Assassin</td> <td>#{stats.assassin}</td> </tr>
                            <tr> <td>Morgana</td> <td>#{stats.morgana}</td> </tr>
                            <tr> <td>Mordred</td> <td>#{stats.mordred}</td> </tr>
                            <tr> <td>Good Lancelot</td> <td>#{stats.good_lancelot}</td> </tr>
                            <tr> <td>Evil Lancelot</td> <td>#{stats.evil_lancelot}</td> </tr>
                        </tbody>
                    </table></div>"
            g.stats.playerStats name, (err, stats) =>
                return if err?
                html += "<div class='row'><table class='table table-condensed span6'>
                            <thead><tr><th>Resistance</th><th>Spy</th><th>All</th></thead>
                            <tbody>
                                <tr> <td>#{stats.resistance}</td> <td>#{stats.spy}</td> <td>#{stats.all}</td> </tr>
                            </tbody>
                        </div>"
                @sendChatTo player, html, source, 'server', true

    onMsg: (args, source, player) ->
        return if not @isMod(player)
        return @sendChatTo player, 'Too few arguments. Type "/help" for valid syntax.', source if args.length < 3
        name = args[1].toLowerCase()
        toPlayer = @getOnlinePlayer name
        return @sendChatTo player, 'Player not found.', source if not toPlayer?
        msg = xmlEscape(args[2..].join(' '))
        fromText = "<span style='color:orange;'>You</span><span style='color:grey;'> &#45;&gt; </span><span style='color:black'>#{toPlayer.name}</span>"
        toText = "<span style='color:black;'>#{player.name}</span><span style='color:grey;'> &#45;&gt; </span><span style='color:orange'>You</span>"
        @sendChatTo toPlayer, msg, source, toText, false, true
        @sendChatTo player, msg, source, fromText, false, true

    onRe: (args, source, player) ->
        names = g.options.admin
        msg = xmlEscape(args[1..].join(' '))
        for name in names
            toPlayer = @getOnlinePlayer name
            continue if not toPlayer?
            fromText = "<span style='color:orange;'>You</span><span style='color:grey;'> &#45;&gt; </span><span style='color:black'>#{toPlayer.name}</span>"
            toText = "<span style='color:black;'>#{player.name}</span><span style='color:grey;'> &#45;&gt; </span><span style='color:orange'>You</span>"
            @sendChatTo toPlayer, msg, source, toText, false, true
            @sendChatTo player, msg, source, fromText, false, true if toPlayer.name.toLowerCase() is ":(" or g.options.mods.indexOf(player.name.toLowerCase()) >= 0

    onLeaveMessage: (args, source, player) ->
        @sendChatTo player, "Thank you for your message!", source
        @onRe args, source, player
        msg = xmlEscape(args[1..].join(' '))
        msg = player.name + ": " + msg + '\n'
        d = new Date()
        fs.appendFile('logs/lm.txt', "[" + d.toLocaleDateString() + " " + d.toLocaleTimeString() + "] " + msg)

    onUnrankedGames: (args, source, player) ->
        @db.getUnrankedGames player.id, (err, user) =>
            return console.log err if err?
            msg = "You have played <strong>#{user.unranked_games}</strong> unranked game" + if user.unranked_games is 1 then "." else "s."
            @sendChatTo player, msg, source

    onChangePassword: (args, source, player) ->
        return @sendChatTo player, "Too few arguments. Enter password twice.", source if args.length < 3
        return @sendChatTo player, "Passwords do not match.", source if args[1] isnt args[2]
        return @sendChatTo player, "Password has too few characters.", source if args[1].length is 0

        @db.updatePassword player.id, args[1], (err, result) =>
            return console.log err if err?
            @sendChatTo player, "Your password has been successfully changed.", source

    onRoll: (args, source, player) ->
        if args.length is 3
            min = Number(args[1]) or 1
            max = Number(args[2]) or 100
        else
            min = 1
            max = Number(args[1]) or 100
        roll = Math.floor(Math.random() * (max+1 - min)) + min
        @sendChatTo player, roll.toString(), source

    onRole: (args, source, player) ->
        return if not player.room.activePlayers
        return if not (player.id in player.room.getIds player.room.activePlayers)
        p = player.room.findPlayer player.id
        article = if p.role is "Spy" then "a " else if p.role is "Assassin" then "the " else ""
        @sendChatTo player, "You are #{article}<strong>#{p.role}</strong>.", source if p.role

    onName: (args, source, player) ->
        return @sendChatTo player, "You are <strong>#{player.name}</strong>.", source if not player.room.activePlayers
        return @sendChatTo player, "You are <strong>#{player.name}</strong>.", source if not (player.id in player.room.getIds player.room.activePlayers)
        p = player.room.findPlayer player.id
        @sendChatTo player, "You are <strong>#{p.room.nameOf(player)}</strong>.", source

    onBuzz: (args, source, player) ->
        return @sendChatTo player, "Too few arguments. Enter a name.", source if args.length < 2
        name = args[1..].join(' ').toLowerCase()
        toPlayer = @getOnlinePlayer name
        return @sendChatTo player, "Player not found.", source if not toPlayer?
        return @sendChatTo player, "#{toPlayer.name} is in an active game.", source if toPlayer.room.gameStarted and not toPlayer.room.gameFinished
        buzzTypes = { "buzz":"buzzed", "ping":"pinged", "notify":"notified", "alert": "alerted", "poke":"poked", "beep":"beeped", "nudge":"nudged", "slap":"slapped", "tickle":"tickled", "punch":"punched", "boop":"booped" }
        buzzType = buzzTypes[args[0].substring(1).toLowerCase()]
        questionId = @questionId++
        @questions[questionId] = { toPlayer: toPlayer, type: 'buzz', player: player, source: source, buzzWord: buzzType }
        toPlayer.send 'buzz', { player: player.name, buzzType: buzzType, questionId:questionId }
        toPlayer.flush()
        # If the player is logged on but not responding, report after 3 seconds
        setTimeout () =>
            if @questions[questionId]?
                delete @questions[questionId]
                @sendChatTo player, "#{toPlayer.name} has NOT been #{buzzType}.", source
        , 3000

    onGlobalMute: (args, source, player) ->
        return if args.length < 2
        return if g.options.mods.indexOf(player.name.toLowerCase()) < 0
        name = args[1..].join(' ').toLowerCase()
        return @sendChatTo player, 'Player is already globally muted.', source if name in g.mutedPlayers
        @sendChatTo player, 'Player has been globally muted.', source
        # toPlayer = (g.playersById[id] for id of g.playersById when g.playersById[id].name.toLowerCase() is name)[0]
        # return if not toPlayer?
        g.mutedPlayers.push(name)
        # @sendAllChat toPlayer, 'You have been muted.'

    onGlobalUnmute: (args, source, player) ->
        return if args.length < 2
        return if g.options.mods.indexOf(player.name.toLowerCase()) < 0
        name = args[1..].join(' ').toLowerCase()
        return @sendChatTo player, 'Player is not globally muted.', source if not (name in g.mutedPlayers)
        @sendChatTo player, 'Player has been globally unmuted', source
        # toPlayer = (g.playersById[id] for id of g.playersById when g.playersById[id].name.toLowerCase() is name)[0]
        # return if not toPlayer?
        g.mutedPlayers.remove(name)
        # @sendAllChat toPlayer, 'You have been unmuted.'

    onBan: (args, source, player) ->
        return if not @isMod player
        return @sendChatTo player, 'Too few arguments. Type "/modhelp" for valid syntax.', source if args.length < 4
        name = args[3]
        reason = if args[4] then args[4..].join(' ') else ''
        # toPlayer = (g.playersById[id] for id of g.playersById when g.playersById[id].name.toLowerCase() is name)[0]
        # return if not toPlayer
        return @sendChatTo player, 'Invalid ban type. Type "/modhelp" for valid syntax.', source if not (args[1] is 'ip' or args[1] is 'user' or args[1] is 'player')
        banType = if args[1] is 'ip' then 2 else 1
        @db.getUserIdByName name, (err, playerId) =>
            return if err?
            g.bans.addBan playerId, args[2], banType, player.id, reason, (err) =>
                return console.log err if err?
                @sendChatTo player, 'Player has been banned.', source
                # log player out
                p = g.playersById[playerId]
                return if not p
                p.setRoom(g.lobby) if p.room isnt g.lobby
                g.lobby.onPlayerLeave(p)
                g.lobby.onPlayerLogout(p)
                delete g.playersBySessionKey[p.sessionKey]
                delete g.playersById[p.id]
                for id, pl of g.playersById
                    pl.flush()

    onAvatar: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isMod player
        return @sendChatTo player, 'Too few arguments.', source if args.length < 4
        name = args[3..].join(' ').toLowerCase()
        @db.getUserIdByName name, (err, playerId) =>
            console.log err if err?
            return @sendChatTo player, err, source if err?
            p = g.playersById[playerId]
            return @sendChatTo player, 'Player is not logged in.', source if not p?
            p.resImg = args[1]
            p.spyImg = args[2]
            @sendChatTo player, 'Avatar has been successfully changed.', source

    onHelp: (args, source, player) ->
        commands = [
            { command: '/stats', args: '', desc: 'Get your ratings and win rates.' },
            { command: '/ratings', args: '', desc: 'Get your ratings.' },
            { command: '/winrates', args: '', desc: 'Get your win rates.' },
            { command: '/r', args: ' <message>', desc: 'Send a private in-game message to me.' },
            { command: '/lm', args: ' <message>', desc: 'Leave a private message for me.' },
            { command: '/ug', args: '', desc: 'Get the number of unranked games you have played.' },
            { command: '/changepassword', args: '<new password> <repeat new password>', desc: 'Change your password.' },
            { command: '/roll', args: ' <max integer>', desc: 'Generate a random integer in the range [1,<max integer>].' },
            { command: '/role', args: '', desc: 'Get your role.' },
            { command: '/name', args: '', desc: 'Get your name.' },
            { command: '/buzz', args: ' <player name>', desc: 'Notify the player if they have the “Player Notifications” options selected, have not been notified in the last 15 seconds, and are not in an active game.' },
            { command: '/disableavatar', args: '', desc: 'Disable your custom avatar.' },
            { command: '/enableavatar', args: '', desc: 'Enable your custom avatar.' },
            { command: '/roletokens', args: '', desc: 'Get the number of role tokens you have.' },
            { command: '/mute', args: '', desc: 'Mute a player.'},
            { command: '/help', args:'', desc: 'Display a list of commands.' }
        ]
        msg = '<span style="color:darkcyan">COMMANDS</span><br>'
        for cmd in commands
            msg += "<span><b>#{cmd.command}</b></span>
                    <span style='color:orange'>#{xmlEscape(cmd.args)}</span><span> :</span>
                    <span style='color:blue'> #{xmlEscape(cmd.desc)}</span>
                    <br>"
        @sendChatTo player, msg, source, 'server', false, false, true

    onSpecial: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isMod player
        return if args.length < 2
        newMode = Number(args[1]) or 0
        g.specialMode = newMode
        @sendChatTo player, "Special mode changed to #{newMode}", source

    onLogout: (args, source, player) ->
        return if not player
        player.setRoom(g.lobby) if player.room isnt g.lobby
        g.lobby.onPlayerLeave(player)
        g.lobby.onPlayerLogout(player)
        delete g.playersBySessionKey[player.sessionKey]
        delete g.playersById[player.id]
        for id, p of g.playersById
            p.flush()

    onDisableAvatar: (args, source, player) ->
        return if not player
        player.avatarEnabled = false
        @db.updateUserAvatarEnabled player.id, false, (err) =>
            return console.log err if err?
            @sendChatTo player, 'Your avatar has been disabled.', source

    onEnableAvatar: (args, source, player) ->
        return if not player
        player.avatarEnabled = true
        @db.updateUserAvatarEnabled player.id, true, (err) =>
            return console.log err if err?
            @sendChatTo player, 'Your avatar has been enabled.', source

    onRoleTokens: (args, source, player) ->
        return if not player
        return if args.length > 1 and g.options.mods.indexOf(player.name.toLowerCase()) < 0
        name = if args.length is 1 then player.name else args[1..].join(' ')
        @db.getUserIdByName name, (err, playerId) =>
            return if err?
            @db.getRoleTokens playerId, (err, result) =>
                return if err?
                numTokens = result.role_tokens
                n = if player.name is name then 'You have' else "#{name} has"
                tokenWord = if numTokens is 1 then 'token' else 'tokens'
                @sendChatTo player, "#{n} #{numTokens} #{tokenWord}.", source

    onAddRoleTokens: (args, source, player) ->
        return if not player
        return if args.length < 3
        return @sendInvalidCommand player, source if not @isAdmin(player)
        name = args[2..].join(' ').toLowerCase()
        numTokens = parseInt args[1]
        @db.getUserIdByName name, (err, playerId) =>
            return if err?
            @db.getRoleTokens playerId, (err, result) =>
                return if err?
                @db.setRoleTokens playerId, result.role_tokens + numTokens, (err, res) =>
                    return if err?
                    toPlayer = @getOnlinePlayer name
                    if toPlayer
                        toPlayer.roleTokens += numTokens
                    @sendChatTo player, "#{name} tokens changed by #{numTokens} to #{result.role_tokens + numTokens}.", source

    # onResetStats: (args, source, player) ->
    #     return if not player
        # change this players name
        # create new user with old name and old information (avatar_enabled, role_tokens, unranked_games, res_img, spy_img, stats_hidden)

    onTstats: (args, source, player) ->
        # name = if args.length is 1 then player.name else xmlEscape(args[1..].join(' '))
        name = player.name
        @db.getRatingsByName name, 2, (err, results) =>
            return if err?
            stats = results[0]
            return if stats.stats_hidden and name.toLowerCase() isnt player.name.toLowerCase()
            html = "<strong>#{stats.name}</strong>
                    <div class='row'><table class='table table-condensed span2'>
                        <thead><tr><th>Type</th><th>Rating</th></tr></thead>
                        <tbody>
                            <tr> <td>Overall</td> <td>#{stats.overall}</td> </tr>
                            <tr> <td>Spy</td> <td>#{stats.spy}</td> </tr>
                            <tr> <td>Resistance</td> <td>#{stats.res}</td> </tr>
                            <tr> <td>Merlin</td> <td>#{stats.merlin}</td> </tr>
                            <tr> <td>Percival</td> <td>#{stats.percival}</td> </tr>
                            <tr> <td>Regular Resistance</td> <td>#{stats.regular_res}</td> </tr>
                            <tr> <td>Oberon</td> <td>#{stats.oberon}</td> </tr>
                            <tr> <td>Regular Spy</td> <td>#{stats.regular_spy}</td> </tr>
                            <tr> <td>Assassin</td> <td>#{stats.assassin}</td> </tr>
                            <tr> <td>Morgana</td> <td>#{stats.morgana}</td> </tr>
                            <tr> <td>Mordred</td> <td>#{stats.mordred}</td> </tr>
                        </tbody>
                    </table></div>"
            @sendChatTo player, html, source, 'server', true

    onMute: (args, source, player) ->
        # todo: command argument parsing
        usage = () =>
            commands = [
                { command: '/mute list', args: '', desc: 'List the players you have muted.' },
                { command: '/mute add', args: ' <player name>', desc: 'Mute a player.' },
                { command: '/mute remove', args: ' <player name>', desc: 'Unmute a player.' },
            ]
            msg = '<span style="color:darkcyan">USAGE</span><br>'
            for cmd in commands
                msg += "<span><b>#{cmd.command}</b></span>
                        <span style='color:orange'>#{xmlEscape(cmd.args)}</span><span> :</span>
                        <span style='color:blue'> #{xmlEscape(cmd.desc)}</span>
                        <br>"
            @sendChatTo player, msg, source, 'server', false, false, true
        if args.length is 1
            return usage()
        if args[1].toLowerCase() is 'list'
            @db.getMutes player.id, (err, results) =>
                return @sendChatTo player, 'You have no muted players.', source if err?
                msg = '<span style="color:darkcyan">MUTED PLAYERS</span><br>'
                for row in results
                    msg += "<span>#{row.name}</span><br>"
                return @sendChatTo player, msg, source, 'server', false, false, true
        if args.length is 2 and args[1].toLowerCase() isnt 'list'
            return usage()
        return if args.length < 3
        name = args[2..].join(' ').toLowerCase()
        @db.getUserIdByName name, (err, playerId) =>
            return @sendChatTo player, 'Player not found.', source if err?
            if args[1].toLowerCase() is 'add'
                @db.addMute player.id, playerId, (err, result) =>
                    return console.log err if err?
                    player.send 'mute', {}
                    return @sendChatTo player, 'Player has been muted.', source
            else if args[1].toLowerCase() is 'remove'
                @db.deleteMute player.id, playerId, (err, result) =>
                    return if err?
                    player.send 'mute', {}
                    return @sendChatTo player, 'Player has been unmuted.', source
            else
                return usage()

    onAddMod: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isAdmin(player)
        return if args.length < 2
        name = args[1..].join(' ').toLowerCase()
        g.options.mods.push name
        fs.writeFileSync('sample_options.json', JSON.stringify(g.options))
        @sendChatTo player, 'Mod added.', source

    onAddAdmin: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isAdmin(player)
        return if args.length < 2
        name = args[1..].join(' ').toLowerCase()
        g.options.admin.push name
        fs.writeFileSync('sample_options.json', JSON.stringify(g.options))
        @sendChatTo player, 'Admin added.', source

    onAnswerBuzz: (args, source, player) ->
        return if args.length < 3
        questionId = parseInt(args[1])
        return if not @questions[questionId]
        question = @questions[args[1]]
        return if not (question.toPlayer.id is player.id and question.type is 'buzz')
        delete @questions[questionId]
        switch args[2]
            when 'success'
                @sendChatTo question.player, "#{player.name} has been #{question.buzzWord}.", question.source
            when 'recent'
                # @sendChatTo question.player, "#{player.name} has been notified too recently.", question.source
                @sendChatTo question.player, "#{player.name} has NOT been #{question.buzzWord}.", question.source
            when 'notification'
                # @sendChatTo question.player, "#{player.name} has notifications disabled.", question.source
                @sendChatTo question.player, "#{player.name} has NOT been #{question.buzzWord}.", question.source

    onModHelp: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isMod player
        commands = [
            { command: '/ban', args: ' user/ip <duration_in_seconds> <player_name> <reason>', desc: 'Ban a player. <player_name> may need to be delimited with `s (backticks).' },
            { command: '/globalmute', args: ' <player_name>', desc: 'Mute a player.' },
            { command: '/globalunmute', args: ' <player_name>', desc: 'Unmute a player.' },
            { command: '/msg', args: ' <player_name> <message>', desc: 'Message a player. Note: <player_name> can be delimited with ` (backtick) if needed.' }

        ]
        msg = '<span style="color:darkcyan">COMMANDS</span><br>'
        for cmd in commands
            msg += "<span><b>#{cmd.command}</b></span>
                    <span style='color:orange'>#{xmlEscape(cmd.args)}</span><span> :</span>
                    <span style='color:blue'> #{xmlEscape(cmd.desc)}</span>
                    <br>"
        @sendChatTo player, msg, source, 'server', false, false, true

    onNotification: (args, source, player) ->
        return @sendInvalidCommand player, source if not @isMod player
        return @sendChatTo player, 'Too few arguments', source if args.length < 3
        name = args[1]
        content = args[2..].join(' ')
        @db.getUserIdByName name, (err, playerId) =>
            return @sendChatTo player, 'Player not found.', source if err?
            g.discussions.createMessageNotification player, { playerId: playerId, content: content }, (res) =>
                return @sendChatTo player, 'Notification created.', source if res is 200

    onAnonNames: (args, source, player) ->
        return @sendInvalidCommand if not @isMod player
        return @sendChatTo player, 'Too few arguments', source if args.length < 2
        g.anonNames = JSON.parse(fs.readFileSync(args[1], 'utf8')).names
        @sendChatTo player, 'Anonymous names have been changed.', source



    parseCommand: (line) ->
        newString = ""
        delimited = false
        for i in [0..line.length-1]
            if line[i] is '`'
                delimited = not delimited
            else if delimited and line[i] is ' '
                newString += '`'
            else
                newString += line[i]
        args = newString.split ' '
        for i in [0..args.length-1]
            args[i] = args[i].replace(/`/g, ' ')
        return args

    sendChatTo: (player, msg, dest, from, noBreak=false, privateMsg=false, custom=false) ->
        player.send dest, { serverMsg: true, player: from || 'server', msg: msg, noBreak: noBreak, isPrivate: true, privateMsg: privateMsg, custom: custom}
        player.flush()

    sendChat: (player, msg) ->
        @sendChatTo player, msg, 'chat'

    sendAllChat: (player, msg) ->
        @sendChatTo player, msg, 'allChat'

    indicesOf: (str, symbol) ->
        indices = [];
        for i in [0..str.length-1]
            indices.push(i) if str[i] is symbol
        return indices

    randomElement: (arr) ->
        return arr[Math.floor(Math.random() * arr.length)]

    isAdmin: (player) ->
        return g.options.admin.indexOf(player.name.toLowerCase()) >= 0

    isMod: (player) ->
        return g.options.mods.indexOf(player.name.toLowerCase()) >= 0

    getOnlinePlayer: (name) ->
        return (g.playersById[id] for id of g.playersById when g.playersById[id].name.toLowerCase() is name)[0]

    sendInvalidCommand: (player, source) ->
        @sendChatTo player, 'Invalid command. Type "/help" for a list of valid commands.', source       
