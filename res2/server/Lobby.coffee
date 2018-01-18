class Lobby extends Room
    constructor: () ->
        super
            'allChat': @onAllChat
            'join': @onJoin
            'refresh': @onRefresh
        @nextId = 1
        @games = {}

    onPlayerJoin: (player) ->
        super
        @onRefresh(player)
        
    onPlayerLogin: (player) ->
        @sendAllChat null, "#{player} has joined."
        for id, p of g.playersById
            p.send '+player', { id: player.id, name: player.name }
        
    onPlayerLogout: (player) ->
        @sendAllChat null, "#{player} has left."
        for id, p of g.playersById
            p.send '-player', { id: player.id }
        
    onRefresh: (player) ->
        for gameId in Object.keys(@games)
            @sendGame @games[gameId], player
            
        for id, p of g.playersById
            player.send '+player', { id: p.id, name: p.name }

    onGameUpdate: (game) ->
        for player in @players
            @sendGame game, player
            player.flush()
            
    onGameEnd: (game) ->
        for p in @players
            p.send '-game', {id: game.id}
        delete @games[game.id]
            
    onAllChat: (player, request) ->
        return if player? and player.name.toLowerCase() in g.mutedPlayers and not (player.name.toLowerCase() in g.options.mods)
        if request.msg[0] is '/'
            g.commands.onCommand request.msg, 'allChat', player
        else
            @sendAllChat player.name, request.msg
        
    sendAllChat: (playerName, msg) ->
        for id, p of g.playersById
            cmd = 
                player: playerName or 'server'
                msg: msg
            cmd.serverMsg = true if not playerName?
            p.send 'allChat', cmd
            p.flush() # TODO: remove?
            
    onJoin: (player, request) ->
        gameId = request.id
        if not gameId?
            throw 'Invalid gametype' if request.gameType not in allGameTypes
            gameId = @nextId++
            isRankedName = if request.isRanked then "Ranked" else "Unranked"
            # TODO: Refactor gametype and the "special" gametypes
            if request.gameType is AVALON_GAMETYPE and request.special is 2
                @games[gameId] = new TrumpGame(gameId, request.gameType, request.isRanked, this, g.db)
            else if request.gameType is AVALON_GAMETYPE and g.specialMode is 1
                @games[gameId] = new FixedGame(gameId, request.gameType, request.isRanked, this, g.db)
            else if request.gameType is AVALON_GAMETYPE and g.specialMode is 3
                @games[gameId] = new PercivalGame(gameId, request.gameType, request.isRanked, this, g.db)
            else
                @games[gameId] = new Game(gameId, request.gameType, request.isRanked, this, g.db)

            if request.special is 2
                @sendAllChat null, "#{player} has created #{isRankedName} Trumpmode game ##{gameId}."
            else
                @sendAllChat null, "#{player} has created #{isRankedName} #{gameTypeNames[request.gameType]} game ##{gameId}." 
            @onGameUpdate(@games[gameId])
        
        room = @games[gameId]
        if not room?
            player.sendMsg 'Cannot join game'
        else
            player.setRoom(room)
            
    sendGame: (game, player) ->
        player.send '+game', { id:game.id, msg:game.getLobbyStatus(), gameType:game.gameType, isRanked:game.isRanked }
