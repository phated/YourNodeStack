express = require 'express'
socketio = require 'socket.io'

routes = require './routes'
provider = require './provider'
sockets = require './sockets'

app = module.exports = express.createServer()
io = socketio.listen app

# Database
db = new provider.StackProvider()

# Configuration

app.configure ->
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static "#{__dirname}/public"

app.configure 'development', ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure 'production', ->
  app.use express.errorHandler()

# Routes

app.get '/', routes.index

# Sockets
sockets io, db

app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
