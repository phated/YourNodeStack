http = require 'http'
querystring = require 'querystring'

attackError =
  attack: "window.location = 'https://www.google.com/search?q=dont+hack+me+bro'"

niceError = 'Name Your Stack Correctly'

rooms = [
  'newStacks'
  'topStacks'
]

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
      return socket.emit 'error', attackError unless data? and data.name? and data.packages? and data.upVote? and data.dnVote? and data.score?
      return socket.emit 'error', attackError unless data.upVote is 0 and data.dnVote is 0 and data.score is 0
      return socket.emit 'error', niceError unless String(data.name).length < 30
      db.create data, (err, stack) ->
        upvotes[stack._id] = []
        dnvotes[stack._id] = []
        db.findSort (err, stacks) ->
          io.sockets.in('newStacks').emit 'newStack', stacks.slice(-5)
          io.sockets.in('topStacks').emit 'topStack', stacks

    socket.on 'upvote', (id) ->
      return socket.emit 'error', attackError unless id? and upvotes[id]?
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
      return socket.emit 'error', attackError unless id? and dnvotes[id]?
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
      return socket.emit 'error', attackError unless room in rooms
      console.log "joined room: #{room}"
      socket.join room
      db.findSort (err, stacks) ->
        upvotes[stack._id] = [] for stack in stacks
        dnvotes[stack._id] = [] for stack in stacks
        io.sockets.in('newStacks').emit 'newStack', stacks.slice(-5)
        io.sockets.in('topStacks').emit 'topStack', stacks

module.exports = sockets
