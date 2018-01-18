# Threads = require 'webworker-threads'

class Statistics
    constructor: (@db) ->
        @stats = {}
        @tables = {}
        # setInterval (=> @refresh()), 4 * 60 * 60 * 1000
        @statsWorkers = new StatisticsWorkers()
        @statsWorker = @statsWorkers.newWorker()
        @statsWorker.onmessage = (e) =>
            @tables = e.data
            @stats = 
                activeplayers: @getActivePlayers(@tables)
                leaderboard: @getLeaderboard(@tables)
                recentgames: @getRecentGames(@tables)
                winrates: @getWinRates(@tables)
                activity: @getActivity(@tables)
                ratings: @getRatings(@tables)
                ratings2: @getRatings2(@tables)
            @tables = e.data.tables
            @stats = e.data.stats
        @refresh()

        
    get: (param) ->
        return @stats[param] or "not found: #{param}"
        
    refresh: ->
        @db.getTables (err, tables) =>
            return if err?
            @statsWorker.postMessage(tables)
            # @joinTables(tables)
            # @tables = tables
            # @stats = 
            #     activeplayers: @getActivePlayers(@tables)
            #     leaderboard: @getLeaderboard(@tables)
            #     recentgames: @getRecentGames(@tables)
            #     winrates: @getWinRates(@tables)
            #     activity: @getActivity(@tables)
            #     ratings: @getRatings(@tables)
            #     ratings2: @getRatings2(@tables)

    joinTables: (tables) ->
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

        for ratings in tables.ratings1
            playerIdx[ratings.id].ratings1 = ratings
        for ratings in tables.ratings2
            playerIdx[ratings.id].ratings2 = ratings
        
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
                
    getActivePlayers: (tables) ->
        html = "<table class='table table-striped table-condensed'><tr><th>Player</th> <th>Games</th></tr>"
        
        for player in tables.players.sort((a, b) -> b.lastMonthGames - a.lastMonthGames)[..25]
            html += "<tr><td>#{player.name}</td><td>#{player.lastMonthGames}</td></tr>"
        
        html += "</table>"
        return html
    
    getLeaderboard: (tables) ->
        oneMonthAgo = Date.now() - 30 * 24 * 3600 * 1000
        
        html = "<table class='table table-striped table-condensed'><tr><th>Player</th> <th>Resistance</th> <th>Spy</th> <th>Total</th></tr>"
        filteredPlayers = tables.players
            .filter((i) -> i.lastGame.getTime() > oneMonthAgo)
            .sort((a,b) -> a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
            
        for player in filteredPlayers
            if not player.stats_hidden
                html += "<tr>" +
                    "<td>#{player.name}</td> " +
                    "<td>#{@frac(player.resistanceWins, player.resistanceGames)}</td> " +
                    "<td>#{@frac(player.spyWins, player.spyGames)}</td> " +
                    "<td>#{@frac(player.spyWins + player.resistanceWins, player.spyGames + player.resistanceGames)}</td></tr>"
                
        html += "</table>"
        return html
        
    getRecentGames: (tables) ->
        html = "<table class='table table-striped table-condensed'><tr><th>Start Time</th> <th>Type</th> <th>Players</th> <th>Duration (minutes)</th> <th>Resistance</th> <th>Spies</th></tr>"
        
        gameTypeName =
            1: "Original"
            2: "Avalon"
            3: "Basic"
            4: "Avalon+"
            5: "Hunter"
            6: "Hunter+"
        if tables.games.length > 0
          max = Math.min(25,tables.games.length)
          for i in [0 ... max]
              game = tables.games[tables.games.length - i - 1]
              html += "<tr>" +
                  "<td>#{game.startTime.toUTCString()}</td> " +
                  "<td>#{gameTypeName[game.gameType]}</td> " +
                  "<td>#{game.spies.length + game.resistance.length}</td> " +
                  "<td>#{((game.endTime.getTime() - game.startTime.getTime()) / 60000).toFixed(0)}</td> " +
                  "<td class='#{if game.spiesWin then '' else 'info'}'>#{game.resistance.map((i) -> i.name).join(', ')}</td> " +
                  "<td class='#{if game.spiesWin then 'info' else ''}'>#{game.spies.map((i) -> i.name).join(', ')}</td></tr>"
            
        html += "</table>"
        return html
        
    getWinRates: (tables) ->
        html = "<table class='table table-striped table-condensed'><tr><th>Players</th> <th>Basic</th> <th>Original</th> <th>Avalon</th> <th>Avalon+</th> <th>Hunter</th> <th>Hunter+</th></tr>"
        
        for n in [5 .. 10]
            html += "<tr><td>#{n}</td>"
            for type in [3, 1, 2, 4, 5, 6]
                games = tables.games.filter((i) -> i.spies.length + i.resistance.length is n and i.gameType is type)
                html += "<td>#{@frac(games.filter((i) -> i.spiesWin).length, games.length)}</td> "
            html += "</tr>"
            
        html += "</table>"
        return html
        
    getActivity: (tables) ->
        millisInHour = 60 * 60 * 1000
        millisInDay = 24 * millisInHour
        millisInWeek = 7 * millisInDay
        rows = []
        if tables.games.length > 0
        
          startDays = tables.games.map (i) -> Math.floor(i.startTime.getTime() / millisInDay)
          minDay = Math.min.apply null, startDays
          maxDay = Math.max.apply null, startDays
          
          rows =
              for startDay in [minDay .. maxDay - 7]
                  startTime = startDay * millisInDay
                  games = 0
                  players = {}
                  playerHours = 0
                  for game in tables.games when game.startTime.getTime() >= startTime and game.startTime.getTime() < startTime + millisInWeek
                      ++games
                      for player in game.spies
                          players[player.id] = true
                      for player in game.resistance
                          players[player.id] = true
                      playerHours += (game.spies.length + game.resistance.length) * (game.endTime.getTime() - game.startTime.getTime()) / millisInHour 
                  "[ new Date(#{startTime + millisInWeek}), #{games}, #{playerHours.toFixed(1)}, #{Object.keys(players).length} ],\n"
        
        html = "<script>drawChart([['Date', 'Weekly Games', 'Player Hours', 'Unique Players'], #{rows.join('')}]);</script>"
        return html

    getRatings: (tables) ->
        oneMonthAgo = Date.now() - 30 * 24 * 3600 * 1000
        html = "<table id='ratingsTable' class='table table-striped table-condensed'>"
        html += "<colgroup>
           <col span='1' style='width: 22%;'>
           <col span='1' style='width: 26%;'>
           <col span='1' style='width: 26%;'>
           <col span='1' style='width: 26%;'>
          </colgroup>"
        html += "<tr><th>Player</th><th>Resistance</th><th>Spy</th><th>Overall</th></tr>"

        filteredPlayers = tables.players
            .filter((i) -> i.lastGame.getTime() > oneMonthAgo)
        for player in filteredPlayers.sort((a, b) -> b.ratings1.overall - a.ratings1.overall)
            if player.ratings1.num_games > 15 and not player.stats_hidden
                ratings = player.ratings1
                color = "hsl(0,0%,#{if ratings.num_games < 250 then (100-(100*(ratings.num_games/312.5)+20))+"%" else "0%"})"
                html += "<tr style='color:#{color};'><td>#{player.name}</td><td>#{ratings.res}</td><td>#{ratings.spy}</td><td>#{ratings.overall}</td></tr>"
        
        html += "</table>"
        return html

    getRatings2: (tables) ->
        oneMonthAgo = Date.now() - 30 * 24 * 3600 * 1000
        html = "<table id='ratingsTable2' class='table table-striped table-condensed'>"
        html += "<colgroup>
           <col span='1' style='width: 22%;'>
           <col span='1' style='width: 26%;'>
           <col span='1' style='width: 26%;'>
           <col span='1' style='width: 26%;'>
          </colgroup>"
        html += "<tr><th>Player</th><th>Resistance</th><th>Spy</th><th>Overall</th></tr>"

        filteredPlayers = tables.players
            .filter((i) -> i.lastGame.getTime() > oneMonthAgo)
        for player in filteredPlayers.sort((a, b) -> b.ratings2.overall - a.ratings2.overall)
            if player.ratings2.num_games > 0 and not player.stats_hidden
                ratings = player.ratings2
                # color = "hsl(0,0%,#{if ratings.num_games < 250 then (100-(100*(ratings.num_games/312.5)+20))+"%" else "0%"})"
                color = "hsl(0,0%,0%)"
                html += "<tr style='color:#{color};'><td>#{player.name}</td><td>#{ratings.res}</td><td>#{ratings.spy}</td><td>#{ratings.overall}</td></tr>"
        
        html += "</table>"
        return html
        
    frac: (n, d) ->
        pct = if d is 0 then 0 else 100 * n / d
        return "#{pct.toFixed(1)}% (#{n} / #{d})"

    playerStats: (playerName, cb) ->
        players = @tables.players.filter((i) -> i.name.toLowerCase() is playerName.toLowerCase())
        return cb("No matching players.") if players.length is 0
        player = players[0]
        return cb null,
            name: player.name
            resistance: @frac(player.resistanceWins, player.resistanceGames)
            spy: @frac(player.spyWins, player.spyGames)
            all: @frac(player.spyWins + player.resistanceWins, player.spyGames + player.resistanceGames)
            stats_hidden: player.stats_hidden
