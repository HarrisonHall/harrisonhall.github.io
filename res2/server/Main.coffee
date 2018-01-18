express = require('express')
createSessionKey = require('crypto').randomBytes
toQueryString = require('querystring').stringify
http = require('http')
https = require('https')
fs = require('fs')
cookie = require('cookie')

getPlayer = (req, res) ->
    sessionKey = req.cookies.sessionKey
    if not sessionKey or not g.playersBySessionKey[sessionKey]?
        res.send 401 # Unauthorized
        return null
    return g.playersBySessionKey[sessionKey]

gcPlayers = ->
    now = Date.now()
    playersToGc = (player for sessionKey, player of g.playersBySessionKey when now - player.lastConnectTime > 10 * 60 * 1000)
    
    for player in playersToGc
        player.setRoom(g.lobby) if player.room isnt g.lobby
        g.lobby.onPlayerLeave(player)
        g.lobby.onPlayerLogout(player)
        delete g.playersBySessionKey[player.sessionKey]
        delete g.playersById[player.id]
        
    if playersToGc.length > 0
        for id, player of g.playersById
            player.flush()
    
app = express()

#app.get '*', (req, res) -> res.send('Down for maintenence. ETA: 9pm Pacific (0400 GMT)');
#app.use express.logger()
app.use express.json()
app.use express.cookieParser()

app.get '/server/stats/:statType', (req, res) ->
    res.header('Cache-Control', 'max-age=900')
    res.send(200, g.stats.get(req.params.statType))

app.get '/server/role', (req, res) ->
    player = getPlayer(req, res)
    return res.send(400) if not player?
    role = if g.options.mods.indexOf(player.name.toLowerCase()) >= 0 then 'mod' else 'user'
    return res.send { role: role, id: player.id }
    
app.get '/server/play', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    player.lastConnectTime = Date.now()
    player.connection = res
    player.flush()
    
app.post '/server/play', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    player.onRequest(req.body)
    res.send(200)

app.post '/server/login', (req, res) ->
    g.db.getUserId req.body.username, req.body.password, (err, playerId) ->
        if err
            res.clearCookie('sessionKey')
            res.send(401, 'Invalid username or password.') # Unauthorized
        else
            # check if banned
            g.bans.isBanned playerId, req.ip, (isBanned, duration, reason) ->
                return res.send(401, "You are banned for #{duration} hours. Reason: #{reason}") if isBanned
                sessionKey = createSessionKey(16).toString('hex')
                if g.playersById[playerId]?
                    oldSessionKey = g.playersById[playerId].sessionKey
                    delete g.playersBySessionKey[oldSessionKey]
                    g.playersById[playerId].sessionKey = sessionKey
                    g.playersBySessionKey[sessionKey] = g.playersById[playerId]
                    res.cookie 'sessionKey', sessionKey
                    res.send(200)
                    g.db.login playerId, (req.ip or "0.0.0.0"), (err, x) ->
                        console.log err if err?
                else
                    g.db.getUser playerId, (err, user) ->
                        return res.send(400) if err?
                        g.playersById[playerId] = new Player(req.body.username, playerId, user.res_img, user.spy_img, user.avatar_enabled, user.role_tokens, sessionKey, g.lobby)
                        g.lobby.onPlayerLogin(g.playersById[playerId])
                        g.playersBySessionKey[sessionKey] = g.playersById[playerId]
                        res.cookie 'sessionKey', sessionKey
                        res.send(200)
                        g.db.login playerId, (req.ip or "0.0.0.0"), (err, x) ->
                            console.log err if err?

app.post '/server/register', (req, res) ->
    isEmpty = (x) -> not x? or x is ''
    
    return res.send(400, 'Invalid username') if isEmpty req.body.username
    return res.send(400, 'Invalid character in username') if !req.body.username.split('').every((i) ->  32 <= i.charCodeAt(0) < 127)
    return res.send(400, 'Invalid username') if req.body.username[0] is ' ' or req.body.username[req.body.username.length - 1] is ' '
    return res.send(400, 'Invalid username') if req.body.username.match(/\ \ /)
    return res.send(400, 'Invalid password') if isEmpty(req.body.password1) is '' or req.body.password1 isnt req.body.password2
    return res.send(400, 'Invalid email') if isEmpty(req.body.email) or req.body.email.length < 3 or req.body.email.indexOf('@') is -1

    if g.options.recaptcha_private_key?
      return res.send(400, 'Invalid captcha') if isEmpty req.body.response
      
      captchaReq = https.request
          method: 'POST'
          hostname: 'www.google.com'
          path: '/recaptcha/api/siteverify'
          headers:
              'Content-Type': 'application/x-www-form-urlencoded'
          (captchaRes) ->
              data = ''
              captchaRes.on 'data', (chunk) -> data += chunk
              captchaRes.on 'end', ->
                  obj = JSON.parse(data)
                  return res.send(400, 'Invalid captcha') if obj.success isnt true
                  g.db.addUser req.body.username, req.body.password1, req.body.email, (err) ->
                      return res.send(400, 'Invalid username or username already taken') if err?
                      res.send(200)

      captchaReq.write toQueryString
          #privatekey: g.options.recaptcha_private_key
          secret: g.options.recaptcha_private_key
          remoteip: req.ip
          #challenge: req.body.challenge
          response: req.body.response
      captchaReq.end()  
    else
      g.db.addUser req.body.username, req.body.password1, req.body.email, (err) -> 
          return res.send(400, 'Invalid username or username already taken') if err?
          res.send(200)

app.post '/server/ban', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    return if g.options.mods.indexOf(player.name.toLowerCase()) < 0
    g.bans.addBan req.body.playerId, req.body.duration, req.body.banType, player.id, req.body.reason || '', (err) ->
        return console.log err if err?
        # log player out
        player = g.playersById[req.body.playerId]
        player.setRoom(g.lobby) if player.room isnt g.lobby
        g.lobby.onPlayerLeave(player)
        g.lobby.onPlayerLogout(player)
        delete g.playersBySessionKey[player.sessionKey]
        delete g.playersById[player.id]
        for id, player of g.playersById
            player.flush()
        res.send(200)

app.post '/server/mod', (req, res) ->
    player = getPlayer(req, res)
    return res.send(401) if not player?
    return res.send(401) if g.options.admin.indexOf(player.name.toLowerCase()) < 0
    return res.send(200) if g.options.mods.indexOf(req.body.name.toLowerCase()) >= 0
    g.options.mods.push req.body.name
    fs.writeFileSync('options.json', JSON.stringify(g.options))

app.put '/server/hide', (req, res) ->
    player = getPlayer(req, res)
    return res.send(401) if not player?
    g.db.updateUserStatsHidden player.id, req.body.statsHidden, (err) ->
        return res.send(400) if err?
        res.send(200)

app.put '/server/avatar', (req, res) ->
    player = getPlayer(req, res)
    return if not player?
    return res.send(401) if g.options.admin.indexOf(player.name.toLowerCase()) < 0
    g.db.getUserIdByName req.body.name, (err, playerId) ->
        console.log err if err?
        return res.send(400) if err?
        p = g.playersById[playerId]
        return res.send(400) if not p?
        p.resImg = req.body.resImg
        p.spyImg = req.body.spyImg
        return res.send(200)

app.get '/server/mutes', (req, res) ->
    player = getPlayer(req, res)
    return res.send(400) if not player?
    g.db.getMutes player.id, (err, results) ->
        return res.send { names: [] } if err?
        names = results.map (p) -> return p.name
        return res.send { names: names }

    
app.get '/server/discussions', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.getDiscussions (result) ->
        res.send result
app.get '/server/discussions/:id', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.getDiscussion req.params.id, (result) ->
        res.send result
        g.discussions.createView player, req.params.id, (result) ->
app.get '/server/likes/:id', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.getLikes req.params.id, (result) ->
        res.send result
app.get '/server/views', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.getViews player.id, (result) ->
        res.send result
app.post '/server/posts', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.createPost player, req.body, (result, post) ->
        res.send result
app.post '/server/discussions', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.createDiscussion player, req.body, (result) ->
        res.send result
app.post '/server/likes', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.createLike player, req.body, (result) ->
        res.send result
app.put '/server/posts', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.updatePost player, req.body, (result) ->
        res.send result
app.delete '/server/posts', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.deletePostData player, req.body, (result) ->
        res.send result
app.delete '/server/likes', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.deleteLike player, req.body, (result) ->
        res.send result

app.get '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.getNotifications player, req.body, (result) ->
        res.send result
app.put '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.updateNotification player, req.body, (result) ->
        res.send result
app.delete '/server/notifications', (req, res) ->
    player = getPlayer(req, res)
    return res.send(403) if not player?
    g.discussions.updateNotificationHidden player, req.body, (result) ->
        res.send result


app.use express.static(__dirname + "/client")




# SOCKET IO
server = http.Server(app)
io = require('socket.io')(server)

io.use (socket, next) ->
    return next(new Error('Authentication error')) if not socket.request.headers.cookie?
    cookies = cookie.parse socket.request.headers.cookie
    return next(new Error('Authentication error')) if not cookies.sessionKey or not g.playersBySessionKey[cookies.sessionKey]?
    player = g.playersBySessionKey[cookies.sessionKey]
    socket.player = player
    player.socket = socket
    next()

io.on 'connection', (socket) ->
    socket.on 'play', (data) ->
        socket.player.onRequest data
    socket.on 'connected', () ->
        socket.player.lastConnectTime = Date.now()
    socket.on 'disconnect', () ->
        socket.player.socket = null
    socket.on 'disconn', () ->
        socket.player.socket = null
        socket.disconnect(true)



# INITIALIZATION
throw "Syntax: node Server.js options.json" if process.argv.length isnt 3
g.options = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))
g.db = new Database()
g.db.initialize (err) -> 
    return console.log err if err
    g.lobby = new Lobby()
    g.stats = new Statistics(g.db)
    g.bans = new Bans(g.db)
    g.rating = new Rating(g.db)
    g.commands = new Commands(g.db)
    g.tokens = new Tokens(g.db)
    g.discussions = new Discussions(g.db)
    g.specialMode = 0
    g.anonNames = JSON.parse(fs.readFileSync('misc/anon_names.json', 'utf8')).names
    setInterval gcPlayers, 60000
    server.listen(g.options.port)
    console.log 'Server started.'
