class Player
    constructor: (@name, @id, @resImg, @spyImg, @avatarEnabled, @roleTokens, @sessionKey, @room) ->
        @connection = null
        @lastConnectTime = Date.now()
        @pendingMessages = []
        @room.onPlayerJoin(this)
        @socket = null
    
    setRoom: (newRoom) ->
        @room.onPlayerLeave(this)
        @room = newRoom
        @room.onPlayerJoin(this)
        
    onRequest: (request) ->
        console.log "#{this}: #{JSON.stringify(request)}" if request.cmd is 'clientCrash'
        @room.onRequest(this, request)
            
    send: (cmd, params = {}) ->
        params.cmd = cmd
        return @socket.emit('play', params) if @socket?
        @pendingMessages.push(params)
        
    sendMsg: (msg) ->
        @send 'msg', {msg: msg}
    
    toString: ->
        @name
        
    flush: ->
        return if @pendingMessages.length is 0
        @forceFlush()
        
    forceFlush: ->
        return if not @connection?
        @connection.header('Cache-Control', 'no-cache')
        @connection.json(@pendingMessages)
        @pendingMessages = []
        @connection = null

