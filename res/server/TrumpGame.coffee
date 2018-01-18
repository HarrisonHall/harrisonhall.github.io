class TrumpGame extends Game
    # TODO: Refactor messages
    constructor: (@id, @gameType, @isRanked, @lobby, @db) ->
        super @id, @gameType, @isRanked, @lobby, @db

        askToStartGame: ->
        return if @gameStarted or @activePlayers.length is 0
        gameController = @activePlayers[0]
        
        if @activePlayers.length < 5
            @setStatus 'Waiting for more players ...'
        else
            @setStatus "Waiting for #{gameController} to start the game ..."
        
        choices = ['OK', 'Deport player']
        choices.push(@getAvalonOptions()) if @gameType is AVALON_GAMETYPE
        choices.push(@getHunterOptions()) if @gameType is HUNTER_GAMETYPE
        message = "Press OK to start game"
        message += " with " + @getAvalonRolesString() if @gameType is AVALON_GAMETYPE
        message += " with " + @getHunterRolesString() if @gameType is HUNTER_GAMETYPE
        
        if @questions.every((i)->i.player isnt gameController)
            @startQuestionId = @askOne gameController,
                cmd: 'choose'
                msg: message
                choices: choices
                (response) =>
                    switch response.choice
                        when 'OK'
                            if @activePlayers.length < @getRequiredPlayers()
                                gameController.sendMsg "This game needs at least #{@getRequiredPlayers()} players to start."
                                @askToStartGame()
                            else 
                                @startGame()
                        when 'Deport player'
                            @askToRemovePlayer(gameController)
                        else
                            @setAvalonOption(response.choice) if @gameType is AVALON_GAMETYPE
                            @setHunterOption(response.choice) if @gameType is HUNTER_GAMETYPE
                            @askToStartGame()
        else if @gameType is HUNTER_GAMETYPE
          @updateAskOne @startQuestionId, gameController,
              cmd: 'choose'
              msg: message
              choices: choices

    askToRemovePlayer: (gameController) ->
        @askOne gameController,
            cmd: 'choosePlayers'
            n: 1
            msg: 'Choose which player to deport.'
            canCancel: true
            (response) =>
                if response.choice.length > 0 and response.choice[0] isnt gameController
                    @removedPlayerIds.push(response.choice[0].id)
                    @activePlayers = (p for p in @activePlayers when p isnt response.choice[0])
                    response.choice[0].sendMsg 'You have been deported.'
                    @onPlayersChanged()
                @askToStartGame()

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
                if p.id in [@merlin, @percival, @morgana, @oberon, @mordred, @quickdraw]
                    "You are #{p.role}. "
                else if p.id is @assassin
                    "You are Bernie. "
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

            p.sendMsg "#{roleMsg}You are a FILTHY COMMUNIST! There are #{@spies.length} FILTHY COMMUNISTS in this game. CREATE A DICTATORSHIP OF THE PROLETARIAT!" if p in @spies
            p.sendMsg "#{roleMsg}You are a PROUD AMERICAN!! There are #{@spies.length} FILTHY COMMUNISTS in this game. MAKE AMERICA GREAT AGAIN!" if not (p in @spies)
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
            
        @db.createGame JSON.stringify(state), gameType, @isRanked, @activePlayers, @spies,
            (err, result) => 
                @dbId = result
                @nextRound()
                p.flush() for p in @players

    nextRound: ->
        return @spiesWin() if @round > 5
        @leader = (@leader + 1) % @activePlayers.length
        @sendAll 'scoreboard', @getScoreboard()
        @sendAll 'leader', { player:@activePlayers[@leader].id }
        @setGuns []
        @setInvestigator null
        @gameLog "#{@activePlayers[@leader]} is the mission leader."
        
        return @askToPlayStrongLeader() if @round isnt 1 or @mission < 3
        
        @ask "deciding who to give #{@ladyInquisitorText} to.",
            @makeQuestions @whoeverHas(@ladyInquisitorCard),
                cmd: 'choosePlayers'
                msg: "Choose a player to give #{@ladyInquisitorText} to."
                n: 1,
                players: @getIds @everyoneExcept @ineligibleLadyOfTheLakeRecipients
                (response, doneCb) =>
                    target = response.choice[0]
                    response.player.sendMsg "#{target} is #{if target in @spies then 'a FILTHY COMMUNIST' else 'a PROUD AMERICAN'}!"
                    @sendAllMsgAndGameLog "#{response.player} gave #{@ladyInquisitorText} to #{target}.", [response.player]
                    @subCard response.player, @ladyInquisitorCard
                    @addCard target, @ladyInquisitorCard
                    @ineligibleLadyOfTheLakeRecipients.push(target)
                    doneCb()
            => @askToPlayStrongLeader()

    askMissionMembersForVote: (context) ->
        context.votes = []
        context.spyChiefFail = false
        team = context.team
        spyChiefsOnTeam = []
        if @spyChiefs?
            team = []
            for p in context.team
                if p.id in @spyChiefs
                    spyChiefsOnTeam.push(p)
                else
                    team.push(p)
        questions = @makeQuestions team,
            cmd: 'choose'
            msg: 'Do you want the mission to succeed or fail?'
            choices: ['Succeed', 'Fail'],
            (response, doneCb) => 
                if response.player not in @spies and response.choice is 'Fail'
                    response.player.sendMsg "You are not a Filthy Communist! Your vote has been changed to 'Succeed', since surely that's what you meant to do."
                    response.choice = 'Succeed'
                context.votes.push(response)
                doneCb()
        if spyChiefsOnTeam.length > 0
            questionsSpyChiefs = @makeQuestions spyChiefsOnTeam,
                cmd: 'choose'
                msg: 'Do you want the mission to succeed or fail?'
                choices: ['Succeed', "#{if @activePlayers.length > 6 then 'Chief Fail' else 'Fail'}"]
                (response, doneCb) => 
                    context.spyChiefFail = true if response.choice isnt 'Succeed'
                    context.votes.push(response)
                    doneCb()
            questions.push(questionsSpyChiefs...) if questionsSpyChiefs.length > 0
        @ask 'voting on the success of the mission ...',
            questions,
            =>
                for response in context.votes when context.spotlight is response.player
                    @sendAllMsgAndGameLog "#{context.spotlight} voted for #{if response.choice is 'Succeed' then 'SUCCESS' else 'FAILURE'}."
                @askKeepingCloseEyes(context)

    askToAssassinateMerlin: ->
        return @resistanceWins() if @gameType isnt AVALON_GAMETYPE or @quickdrawHasShot
        assassin = @findPlayer(@assassin)
        @ask 'choosing a player to assassinate ...',
            @makeQuestions [assassin],
                cmd: 'choosePlayers'
                msg: 'Choose a player to assassinate.'
                n: 1
                players: @getIds @activePlayers.filter((player) =>
                    if @avalonOptions.useNorebo or @avalonOptions.usePalm
                        return player.id isnt @assassin
                    return player not in @spies or player.id is @oberon
                )
                (response, doneCb) =>
                    @sendAllMsgAndGameLog "#{assassin} chose to assassinate #{response.choice[0]}."
                    if response.choice[0].id is @merlin
                        @sendAllMsgAndGameLog "#{assassin} guessed RIGHT. #{response.choice[0]} was Trump!"
                        @spiesWin()
                    else
                        @sendAllMsgAndGameLog "#{assassin} guessed WRONG. #{@findPlayer(@merlin)} was Trump, not #{response.choice[0]}!"
                        @resistanceWins()
                    doneCb()

    gameOver: (spiesWin) ->
        @gameFinished = true
        @sendAll 'gameover'
        @sendAll '-vote'
        @sendPlayers(p) for p in @players
        @setStatus (if spiesWin then 'The Filthy Communists win! DEMOCRACY IS DOOMED! THE DICTATORSHIP OF THE PROLETARIAT IS AT HAND COMRADE!' else 'The Proud Americans win! YOU BUILT A WALL! AMERICA IS GREAT AGAIN!')
        @lobby.onGameUpdate(this)
        @lobby.sendAllChat null, "Game ##{@id} finished: the #{if spiesWin then 'Filthy Communists' else 'Proud Americans'} won! #{if spiesWin then 'DEMOCRACY IS DOOMED! THE DICTATORSHIP OF THE PROLETARIAT IS AT HAND COMRADE!' else 'YOU BUILT A WALL! AMERICA IS GREAT AGAIN!'}"
        @db.finishGame @dbId, spiesWin, =>
            if @isRanked
                res = @activePlayers.filter((player) => player not in @spies)
                g.rating.update @spies, res, spiesWin, @gameType, (err, users) =>
                    return console.log "Rating error" if err?
                    g.stats.refresh()
                    for user in users
                        if not user.stats_hidden
                            player = @findPlayer user.id
                            msg = ""
                            l = user.changes.length
                            sign = if user.changes[0].change >= 0 then "+" else ""
                            for i in [0..l-2]
                                msg += "#{user.changes[i].name}: #{user.changes[i].before} → #{user.changes[i].after} (#{sign}#{user.changes[i].change}), "
                            msg += "#{user.changes[l-1].name}: #{user.changes[l-1].before} → #{user.changes[l-1].after} (#{sign}#{user.changes[l-1].change})"
                            cmd = { player:"server", msg:msg, serverMsg:true, isSpectator:false }
                            player.send 'chat', cmd
            else
                @db.updateUnrankedGames @activePlayers, (err, result) =>
                    return console.log err if err?

    sendPlayers: (me) ->
        isSpy = (player) => 
            @spies.some((i) -> i.id is player.id)

        response =
            for them in @activePlayers
                if @gameType is HUNTER_GAMETYPE
                  iKnowTheyAreASpy =
                    me.id is them.id or
                    (isSpy(me) and me.id isnt @deepAgent and
                     not (@pretender? and them.id is @deepAgent)) or
                    (@spyHunterRevealed and them.id is @spyHunter)
                else
                  iKnowTheyAreASpy =
                    me.id is them.id or
                    (isSpy(me) and me.id isnt @oberon and them.id isnt @oberon) or
                    (me.id is @merlin and them.id isnt @mordred)
                   
                {
                    isSpy:
                        (isSpy(me) and them.id in [@norebo, @palm] and not @gameFinished and me.id isnt @oberon) or
                        (me.id is @merlin and them.id is @palm and not (them.id is me.id) and not @gameFinished) or
                        (isSpy(them) and (@gameFinished or iKnowTheyAreASpy))
                    id: them.id
                    name: them.name
                    resImg: 'avatars/rep.png'
                    spyImg: 'avatars/dem.png'
                    role:
                        if @gameFinished or (me.id is them.id) or
                          (@resHunterRevealed and them.id is @resistanceHunter) or
                          (@spyHunterRevealed and them.id is @spyHunter)
                            them.role
                        else if me.id is @percival and (them.id is @merlin or them.id is @morgana)
                            if @morgana? then "Trump?" else "Trump"
                        else if @resistanceChiefs? and me.id in @resistanceChiefs and
                          (them.id in @resistanceChiefs or them.id is @coordinator)
                            them.role
                        else if isSpy(me) and me.id isnt @deepAgent
                            if @spyChiefs? and them.id in @spyChiefs
                                them.role
                            else if them.id is @deepAgent or them.id is @pretender
                                if @pretender? then "Deep Agent?" else "Deep Agent"
                            else
                                undefined
                        else
                            undefined
                    role2: if @gameFinished then them.role2 else undefined
                }
      
        me.send 'players', { players:response, amSpy:isSpy(me) }

    getInitialState: ->
        state = 
            spies: []
            leader: Math.floor(Math.random() * @activePlayers.length)
        resistanceTeam = []
            
        resistanceRoles = ['Proud American', 'Trump', 'Paul Ryan', 'Norebo', 'Palm']
        resistanceRoles = ['Resistance', 'Resistance Chief', 'Resistance Hunter',
          'Dummy Agent','Coordinator','Pretender'] if @gameType is HUNTER_GAMETYPE
        spiesRequired = Math.floor((@activePlayers.length - 1) / 3) + 1

        roles = []
        if @gameType is AVALON_GAMETYPE then roles = @getAvalonRoles()
        if @gameType is HUNTER_GAMETYPE then roles = @getHunterRolesForGame()
        for i in [roles.filter((i) -> i not in resistanceRoles).length ... spiesRequired]
            roles.push('Filthy Communist')
        for i in [roles.length ... @activePlayers.length]
            roles.push('Proud American')
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
              state.merlin = @activePlayers[i].id if role is 'Trump'
              state.assassin = @activePlayers[i].id if role in ['Bernie', 'Biden/Bernie', 'Quickdraw', 'Mordred/Quickdraw']
              state.percival = @activePlayers[i].id if role is 'Paul Ryan'
              state.morgana = @activePlayers[i].id if role is 'Hillary'
              state.oberon = @activePlayers[i].id if role is 'Obameron'
              state.mordred = @activePlayers[i].id if role in ['Biden', 'Biden/Bernie', 'Mordred/Quickdraw']
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

    getAvalonOptions: ->
        ans = ['Options']
        
        addRemove = (flag, role) ->
            ans.push((if flag then 'Remove ' else 'Add ') + role)
        
        if @avalonOptions.usePercival
            ans.push(if @avalonOptions.useMorgana then 'Remove Paul Ryan and Hillary' else 'Remove Paul Ryan')
        else
            ans.push('Add Paul Ryan')

        if @avalonOptions.useMorgana
            ans.push('Remove Hillary')
        else
            ans.push(if @avalonOptions.usePercival then 'Add Hillary' else 'Add Paul Ryan and Hillary')
            
        addRemove @avalonOptions.useOberon, 'Obameron'
        addRemove @avalonOptions.useMordred, 'Biden'

        if @avalonOptions.useMordred 
            if not @avalonOptions.useQuickdraw
                ans.push(if @avalonOptions.combineMordredAndAssassin then 'Separate Biden and Bernie' else 'Combine Biden and Bernie')
            else
                ans.push(if @avalonOptions.combineMordredAndAssassin then 'Separate Mordred and Quickdraw' else 'Combine Mordred and Quickdraw')
        
        addRemove @avalonOptions.useLadyOfTheLake, 'Lady of the Lake'
        return ans

    setAvalonOption: (choice) ->
        switch choice
            when 'Add Paul Ryan'
                @avalonOptions.usePercival = true
            when 'Add Hillary', 'Add Paul Ryan and Hillary'
                @avalonOptions.usePercival = true
                @avalonOptions.useMorgana = true
            when 'Add Obameron'
                @avalonOptions.useOberon = true
            when 'Add Biden'
                @avalonOptions.useMordred = true
            when 'Add Lady of the Lake'
                @avalonOptions.useLadyOfTheLake = true
            when 'Remove Paul Ryan', 'Remove Paul Ryan and Hillary'
                @avalonOptions.usePercival = false
                @avalonOptions.useMorgana = false
            when 'Remove Hillary'
                @avalonOptions.useMorgana = false
            when 'Remove Obameron'
                @avalonOptions.useOberon = false
            when 'Remove Biden'
                @avalonOptions.useMordred = false
            when 'Remove Lady of the Lake'
                @avalonOptions.useLadyOfTheLake = false
            when 'Combine Biden and Bernie'
                @avalonOptions.combineMordredAndAssassin = true
            when 'Separate Biden and Bernie'
                @avalonOptions.combineMordredAndAssassin = false

    getAvalonRoles: ->
        roles = ['Trump']
        roles.push('Paul Ryan') if @avalonOptions.usePercival
        roles.push('Hillary') if @avalonOptions.useMorgana
        roles.push('Obameron') if @avalonOptions.useOberon
        if not @avalonOptions.useMordred
            if not @avalonOptions.useQuickdraw
                roles.push('Bernie')
            else
                roles.push('Quickdraw')
        else if @avalonOptions.combineMordredAndAssassin and not @avalonOptions.useQuickdraw
            roles.push('Biden/Bernie')
        else if @avalonOptions.combineMordredAndAssassin and @avalonOptions.useQuickdraw
            roles.push('Mordred/Quickdraw')
        else
            roles.push('Biden')
            if not @avalonOptions.useQuickdraw
                roles.push('Bernie')
            else
                roles.push('Quickdraw')
        return roles

    getRequiredPlayers: ->
        if @gameType is AVALON_GAMETYPE
          goodGuys = @getAvalonRoles().reduce ((total, role) -> total + (role in ['Trump', 'Paul Ryan','Norebo','Palm'] ? 1 : 0)), 0
          badGuys = @getAvalonRoles().length - goodGuys
          goodMin = [5, 5, 5, 5, 6, 8][goodGuys]
          badMin = [5, 5, 5, 7, 10][badGuys]
          return Math.max(goodMin, badMin, goodGuys + badGuys)
        if @gameType is HUNTER_GAMETYPE
          resRoles = 0
          ++resRoles if @hunterOptions.useDummyAgent
          ++resRoles if @hunterOptions.useCoordinator
          ++resRoles if @hunterOptions.usePretender
          if resRoles is 3 then return 9
          if @hunterOptions.useDeepAgent then return 7
          if resRoles is 2 then return 6
        return 5


