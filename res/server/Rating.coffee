class Rating
    constructor: (@db) ->

    update: (spies, res, spiesWin, gameType, ratingsType, cb) ->
        ids = res.concat(spies).map (obj) -> obj.id
        @db.getRatings ids, ratingsType, (err, users) =>
            return if err?
            resUsers = @getPlayersInfo res, users
            spyUsers = @getPlayersInfo spies, users
            # Set each user's weight on the team's rating
            @setWeights resUsers, ratingsType
            @setWeights spyUsers, ratingsType
            # Get team's rating from weighted average of users on team
            avgResResRating = @avgRating resUsers, "res"
            avgSpySpyRating = @avgRating spyUsers, "spy"
            avgResRating = @avgRating resUsers, "overall"
            avgSpyRating = @avgRating spyUsers, "overall"
            # Determine expectations based on each team's ratings
            resResExpectation = @expectation avgResResRating, avgSpySpyRating
            spySpyExpectation = @expectation avgSpySpyRating, avgResResRating
            resExpectation = @expectation avgResRating, avgSpyRating
            spyExpectation = @expectation avgSpyRating, avgResRating
            resActual = if spiesWin then 0 else 1
            spyActual = if spiesWin then 1 else 0
            # Update ratings based on expectation and actual result
            @setRating resUsers, resExpectation, resActual, "overall"
            @setRating spyUsers, spyExpectation, spyActual, "overall"
            @setRating resUsers, resResExpectation, resActual, "res"
            @setRating spyUsers, spySpyExpectation, spyActual, "spy"
            if gameType is AVALON_GAMETYPE
                @roleRatings resUsers
                @roleRatings spyUsers
                avgResRoleRating = @avgRating resUsers, "roleRating"
                avgSpyRoleRating = @avgRating spyUsers, "roleRating"
                resRoleExpectation = @expectation avgResRoleRating, avgSpyRoleRating
                spyRoleExpectation = @expectation avgSpyRoleRating, avgResRoleRating
                @setRating resUsers, resRoleExpectation, resActual, "roleRating"
                @setRating spyUsers, spyRoleExpectation, spyActual, "roleRating"

            @db.updateRatings resUsers.concat(spyUsers), ratingsType, (err, result) =>
                return cb(err) if err?
                cb(null, resUsers.concat(spyUsers))
            

    getPlayersInfo: (players, users) ->
        playersInfo = []
        players.forEach (player) =>
            user = @findUser users, player
            user.role = player.role
            playersInfo.push user
        return playersInfo

    setWeights: (users, ratingsType) ->
        totalWeight = 0.0
        if ratingsType is 1
            users.forEach (user) ->
                user.weight = if user.num_games < 15 then (user.num_games+1) / 15.0 else 1.0
                totalWeight += user.weight
            users.forEach (user) ->
                user.ratingWeight = user.weight / totalWeight
                user.kFactor = if user.num_games < 15 then 32.0 else 16.0
        else
            ratingWeight = 1.0 / users.length
            kFactor = 32.0
            users.forEach (user) ->
                user.ratingWeight = ratingWeight
                user.kFactor = kFactor

    avgRating: (users, ratingType) ->
        totalRating = 0.0
        users.forEach (user) ->
            totalRating += user.ratingWeight * user[ratingType]
        return totalRating

    roleRatings: (users) ->
        users.forEach (user) =>
            user.roleRating = @getRoleRating user

    getRoleRating: (user) ->
        rating = user[@getRoleName(user.role)]
        return rating

    getRoleName: (role) ->
        roleNames = 
            "Merlin": "merlin"
            "Percival": "percival"
            "Resistance": "regular_res"
            "Oberon": "oberon"
            "Spy": "regular_spy"
            "Assassin": "assassin"
            "Morgana": "morgana"
            "Mordred": "mordred"
            "Mordred/Assassin": "mordredassassin"
            "Norebo": "norebo"
            "Palm": "palm"
            "Quickdraw": "quickdraw"
            "Mordred/Quickdraw": "mordredquickdraw"
            "Good Lancelot": "good_lancelot"
            "Evil Lancelot": "evil_lancelot"
        return roleNames[role]

    setRating: (users, expectation, actual, type) ->
        users.forEach (user) =>
            ratingType = type
            ratingType = @getRoleName user.role if type is "roleRating"
            change = Math.round(user.kFactor * (actual - expectation))
            before = user[ratingType]
            user[ratingType] = user[ratingType] + change
            # Add to list of changes
            user.changes ?= []
            name = @getChangeName user, type
            user.changes.push { "name":name, "before":before, "after":user[ratingType], "change":change }

    getChangeName: (user, type) ->
        changeNames =
            "overall": "Overall"
            "res": "Resistance"
            "spy": "Spy"
            "roleRating": @getChangeRoleName user.role
        return changeNames[type]

    getChangeRoleName: (role) ->
        return "Regular Resistance" if role is "Resistance"
        return "Regular Spy" if role is "Spy"
        return role

    expectation: (rA, rB) ->
        return 1.0 / (1.0 + Math.pow(10, (rB-rA)/400.0))

    findUser: (users, player) ->
        for user in users
            return user if user.id is player.id
        return null
