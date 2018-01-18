
joinTables = (tables) ->
    oneMonthAgo = Date.now() - 30 * 24 * 3600 * 1000

    gameIdx = {}
    for game in tables.games
        game.spies = []
        game.resistance = []
        gameIdx[game.id] = game
    
    playerIdx = {}
    for player in tables.players
        player.lastMonthGames = 0
        player.spyGames = 0
        player.spyWins = 0
        player.resistanceGames = 0
        player.resistanceWins = 0
        player.lastGame = new Date(0)
        player.name = xmlEscape(player.name)
        playerIdx[player.id] = player 
    
    for gameplayer in tables.gamePlayers
        game = gameIdx[gameplayer.gameId]
        which = if gameplayer.isSpy then game.spies else game.resistance
        which.push playerIdx[gameplayer.playerId]
    
    for game in tables.games
        for player in game.spies
            player.lastGame = game.startTime
            ++player.spyGames
            ++player.spyWins if game.spiesWin
            ++player.lastMonthGames if game.startTime.getTime() > oneMonthAgo
        for player in game.resistance
            player.lastGame = game.startTime
            ++player.resistanceGames
            ++player.resistanceWins if not game.spiesWin
            ++player.lastMonthGames if game.startTime.getTime() > oneMonthAgo

onMessage = (e) ->
    console.log('Message received from main script')
    workerResult = 'Result: ' + (e.data)
    console.log('Posting message back to main script')
    postMessage(workerResult)
