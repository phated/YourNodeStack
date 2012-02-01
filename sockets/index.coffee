http = require 'http'
querystring = require 'querystring'

sockets = (io, db) ->
  # Request Options
  request_options =
    host: 'search.npmjs.org'
    port: 80
    method: 'GET'

  upvotes = {}
  dnvotes = {}

  # Sockets
  io.set 'log level', 1
  io.sockets.on 'connection', (socket) ->
    socket.on 'search', (data) ->
      qs = querystring.stringify data
      request_options.path = "/_list/search/search?#{qs}"

      req = http.request request_options, (res) ->
        data = ''
        res.setEncoding 'utf8'
        res.on 'data', (chunk) ->
          data += chunk;
        res.on 'end', ->
          socket.emit 'searchResults', JSON.parse data
      req.on 'error', (err) ->
        console.log "problem with request: #{err.message}"
      req.end()

    socket.on 'share', (data) ->
      error = 'Name Your Stack Correctly'
      return socket.emit 'error', error unless data? and data.name?
      return socket.emit 'error', error unless String(data.name).length < 30
      db.create data, (err, stack) ->
        upvotes[stack._id] = []
        dnvotes[stack._id] = []
        db.findSort (err, stacks) ->
          io.sockets.in('newStacks').emit 'newStack', stacks.slice(-5)
          io.sockets.in('topStacks').emit 'topStack', stacks

    socket.on 'upvote', (id) ->
      error =
        attack: "window.location = 'https://www.google.com/search?q=dont+hack+me+bro'"
      return socket.emit 'error', error if id?
      unless socket.handshake.address in upvotes[id]
        upvotes[id].push socket.handshake.address
        db.findById id, (err, stack) ->
          stack.upVote += 1
          stack.score = stack.upVote - stack.dnVote
          db.update stack._id, stack, (err, stack) ->
            db.findSort (err, stacks) ->
              io.sockets.in('topStacks').emit 'topStack', stacks
      else
        socket.emit 'voteError',
          id: id
          msg: 'You Already Up-Voted This'

    socket.on 'dnvote', (id) ->
      error =
        attack: "window.location = 'https://www.google.com/search?q=dont+hack+me+bro'"
      return socket.emit 'error', error if id?
      unless socket.handshake.address in dnvotes[id]
        dnvotes[id].push socket.handshake.address
        db.findById id, (err, stack) ->
          stack.dnVote += 1
          stack.score = stack.upVote - stack.dnVote
          db.update stack._id, stack, (err, stack) ->
            db.findSort (err, stacks) ->
              io.sockets.in('topStacks').emit 'topStack', stacks
      else
        socket.emit 'voteError',
          id: id
          msg: 'You Already Down-Voted This'

    socket.on 'join', (room) ->
      console.log "joined room: #{room}"
      socket.join room
      db.findSort (err, stacks) ->
        upvotes[stack._id] = [] for stack in stacks
        dnvotes[stack._id] = [] for stack in stacks
        io.sockets.in('newStacks').emit 'newStack', stacks.slice(-5)
        io.sockets.in('topStacks').emit 'topStack', stacks

module.exports = sockets
