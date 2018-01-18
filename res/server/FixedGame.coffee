class FixedGame extends Game
    constructor: (@id, @gameType, @isRanked, @lobby, @db) ->
        super @id, @gameType, @isRanked, @lobby, @db

    startGame: ->
        @cancelQuestions @everyoneExcept(@activePlayers, @players)
        
        @lobby.onGameUpdate(this)
        @activePlayers.shuffle()
        state = @getInitialState()

        for own key, value of state
            this[key] = value
        
        @gameStarted = true
        @onPlayersChanged()
        @missionTeamSizes = [
            [2, 3, 2, 3, 3]
            [2, 3, 4, 3, 4]
            [2, 3, 3, 4, 4]
            [3, 4, 4, 5, 5]
            [3, 4, 4, 5, 5]
            [3, 4, 4, 5, 5]][@activePlayers.length - 5]
        @failuresRequired = [
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 2, 1],
            [1, 1, 1, 2, 1],
            [1, 1, 1, 2, 1],
            [1, 1, 1, 2, 1]][@activePlayers.length - 5]
            
        if @gameType is AVALON_GAMETYPE
            whoIsInTheGame = "#{@getAvalonRolesString()} are in this game."
            @gameLog whoIsInTheGame
        if @gameType is HUNTER_GAMETYPE
            whoIsInTheGame = "#{@getHunterRolesString()} are in this game."
            @gameLog whoIsInTheGame
          
        for p in @activePlayers
            roleMsg = ""
            if @gameType is AVALON_GAMETYPE
              roleMsg = 
                if p.id in [@merlin, @percival, @morgana, @oberon, @mordred]
                    "You are #{p.role}. "
                else if p.id is @assassin
                    "You are the assassin. "
                else
                    ""
            if @gameType is HUNTER_GAMETYPE
                for chiefs in [@resistanceChiefs, @spyChiefs]
                    if p.id in chiefs
                      if chiefs.length is 1
                        roleMsg = "You are the #{p.role}. "
                      else
                        roleMsg = "You are a #{p.role}. "
                if p.id in [@resistanceHunter, @spyHunter, @dummyAgent, @coordinator, @deepAgent, @pretender]
                    roleMsg = "You are the #{p.role}. "

            spiesRequired = Math.floor((@activePlayers.length - 1) / 3) + 1
            p.sendMsg "#{roleMsg}You are #{if p in @spies then 'a SPY' else 'RESISTANCE!'}! There are #{spiesRequired} spies in this game."
            p.sendMsg whoIsInTheGame if @gameType is AVALON_GAMETYPE or @gameType is HUNTER_GAMETYPE
                
        delete state.spies
        gameType = @gameType
        gameType = AVALON_PLUS_GAMETYPE if @percival or @morgana or @oberon or @mordred or @ladyOfTheLake
        gameType = HUNTER_PLUS_GAMETYPE if @dummyAgent or @coordinator or @deepAgent or @pretender or @inquisitor
        
        if @inquisitor? then @ladyOfTheLake = @inquisitor
        if @ladyOfTheLake
            if @inquisitor?
                @ladyInquisitorCard = 'Inquisitor'
                @ladyInquisitorText = 'INQUISITOR'
            else
                @ladyInquisitorCard = 'LadyOfTheLake'
                @ladyInquisitorText = 'LADY OF THE LAKE'

            ladyOfTheLake = @findPlayer(@ladyOfTheLake)
            @addCard ladyOfTheLake, @ladyInquisitorCard
            @ineligibleLadyOfTheLakeRecipients.push(ladyOfTheLake)
            
        if @gameType is HUNTER_GAMETYPE
            @ineligibleResHunterAccusees.push(@findPlayer(@resistanceHunter))
            @ineligibleSpyHunterAccusees.push(@findPlayer(@spyHunter))
            
        state.special = true
        @db.createGame JSON.stringify(state), gameType, false, @activePlayers, @spies,
            (err, result) => 
                @dbId = result
                @nextRound()
                p.flush() for p in @players

    getInitialState: ->
        state = 
            spies: []
            leader: Math.floor(Math.random() * @activePlayers.length)
        resistanceTeam = []

        resistanceRoles = ['Resistance', 'Merlin', 'Percival', 'Norebo', 'Palm']
        resistanceRoles = ['Resistance', 'Resistance Chief', 'Resistance Hunter',
          'Dummy Agent','Coordinator','Pretender'] if @gameType is HUNTER_GAMETYPE
        spiesRequired = Math.floor((@activePlayers.length - 1) / 3) + 1

        roles = []
        if @gameType is AVALON_GAMETYPE then roles = @getFixedAvalonRoles()
        if @gameType is HUNTER_GAMETYPE then roles = @getHunterRolesForGame()
        # for i in [roles.filter((i) -> i not in resistanceRoles).length ... spiesRequired]
        #     roles.push('Spy')
        for i in [roles.length ... @activePlayers.length] # make all roles resistance
            roles.push('Resistance')
        roles.shuffle()
        
        if @gameType is HUNTER_GAMETYPE
          state.resistanceChiefs = []
          state.spyChiefs = []
          state.earlyAccusationUsed = false
          
        for role, i in roles
            @activePlayers[i].role = role
            state.spies.push(@activePlayers[i]) if role not in resistanceRoles
            resistanceTeam.push(@activePlayers[i]) if role in resistanceRoles
            if @gameType is AVALON_GAMETYPE
              state.merlin = @activePlayers[i].id if role is 'Merlin'
              state.assassin = @activePlayers[i].id if role in ['Assassin', 'Mordred/Assassin', 'Quickdraw', 'Mordred/Quickdraw']
              state.percival = @activePlayers[i].id if role is 'Percival'
              state.morgana = @activePlayers[i].id if role is 'Morgana'
              state.oberon = @activePlayers[i].id if role is 'Oberon'
              state.mordred = @activePlayers[i].id if role in ['Mordred', 'Mordred/Assassin', 'Mordred/Quickdraw']
              state.quickdraw = @activePlayers[i].id if role in ['Quickdraw', 'Mordred/Quickdraw']
            if @gameType is HUNTER_GAMETYPE
              state.resistanceChiefs.push(@activePlayers[i].id) if role is 'Resistance Chief'
              state.resistanceHunter = @activePlayers[i].id if role is 'Resistance Hunter'
              state.spyChiefs.push(@activePlayers[i].id) if role is 'Spy Chief'
              state.spyHunter = @activePlayers[i].id if role is 'Spy Hunter'
              state.dummyAgent = @activePlayers[i].id if role is 'Dummy Agent'
              state.coordinator = @activePlayers[i].id if role is 'Coordinator'
              state.deepAgent = @activePlayers[i].id if role is 'Deep Agent'
              state.pretender = @activePlayers[i].id if role is 'Pretender'

        if @avalonOptions.useLadyOfTheLake
            state.ladyOfTheLake = @activePlayers[state.leader].id

        if @hunterOptions.useInquisitor
            state.inquisitor = @activePlayers[state.leader].id

        if @gameType is AVALON_GAMETYPE
            resistanceTeam.shuffle()
            for role, i in @getAvalonRoles2()
                resistanceTeam[i].role2 = role
                state.norebo = resistanceTeam[i].id if role is 'Norebo'
                state.palm = resistanceTeam[i].id if role is 'Palm'

        if @gameType is ORIGINAL_GAMETYPE
            deck = [
                "KeepingCloseEye"
                "KeepingCloseEye"
                "NoConfidence" 
                "OpinionMaker"
                "TakeResponsibility"
                "StrongLeader"
                "StrongLeader"
            ]
            
            if @activePlayers.length > 6
                deck = deck.concat [
                    "NoConfidence"
                    "NoConfidence"
                    "OpenUp"
                    "OpinionMaker"
                    "Overheard"
                    "Overheard"
                    "InTheSpotlight"
                    "EstablishConfidence"
                ]
                
            deck.shuffle()
            state.deck = deck
        
        return state

    getFixedAvalonRoles: ->
        roles = []
        return roles

    checkMissionSuccess: (context) ->
        nPlayers = [
            "No one",
            "One player",
            "Two players",
            "Three players",
            "Four players"
        ]
        
        chiefFailMsg = [
            " No failure votes were CHIEF fails.",
            " One failure vote was a CHIEF fail.",
            " Two failure votes were CHIEF fails."
        ]
    
        requiredFailures = @failuresRequired[@mission - 1]
        actualFailures = (vote for vote in context.votes when vote.choice isnt 'Succeed').length
        success = actualFailures < requiredFailures

         # fix logic - Always go to mission 5. Always succeed m1 and m5. Succeed and fail based on table.
        shouldFail = [
            [true, false, true],
            [false, true, true],
            [true, true, false],
            [true, true, false],
            [true, true, false]
        ]
        numSuccesses = (score for score in @score when score).length
        numFails = (score for score in @score when not score).length
        if @mission is 1 or @mission is 5
            actualFailures = 0
            success = true
        else if shouldFail[@activePlayers.length-5][@mission-2]
            actualFailures = requiredFailures
            success = false
        else
            actualFailures = 0
            success = true


        msg = "The mission #{if success then 'SUCCEEDED' else 'FAILED'}. #{nPlayers[actualFailures]} voted for failure."
        chiefFailures = 0
        if @gameType is HUNTER_GAMETYPE and @activePlayers.length > 6 and actualFailures > 0
            chiefFailures = (vote for vote in context.votes when vote.choice is 'Chief Fail').length
            msg += chiefFailMsg[chiefFailures]
        @sendAllMsgAndGameLog msg
        
        @score.push success
        context.success = success
        @sendAll 'scoreboard', @getScoreboard()
        if @gameType is HUNTER_GAMETYPE and !success and
          (@activePlayers.length < 7 or chiefFailures > 0) and
          (score for score in @score when not score).length < 3
              return @askEarlySpyHunterAccuse(context)
        @checkScoreForWinners(context)

    checkScoreForWinners: (context) ->
        if (score for score in @score when not score).length is 3
            return @spiesWin() if @gameType isnt HUNTER_GAMETYPE
            return @askSpyHunterToAcuse(context)
        if (score for score in @score when score).length is 3
            return @resistanceWins()
            # return @askToAssassinateMerlin() if @gameType isnt HUNTER_GAMETYPE # no assassin
            return @askResHunterToAcuse(context)
        return @askInvestigator(context) if context.investigator?
        @nextMission()

    gameOver: (spiesWin) ->
        @gameFinished = true
        @sendAll 'gameover'
        @sendAll '-vote'
        @sendPlayers(p) for p in @players
        @setStatus (if spiesWin then 'The spies win!' else 'The resistance wins! (You are all resistance)')
        @lobby.onGameUpdate(this)
        @lobby.sendAllChat null, "Game ##{@id} finished: the #{if spiesWin then 'spies' else 'resistance'} won!"
        @db.finishGame @dbId, spiesWin, ->
