mongoose = require 'mongoose'

mongoose.connect 'YOUR_DB_CONNECTION'

Schema   = mongoose.Schema
ObjectId = Schema.ObjectId

Stack = new Schema
  id : ObjectId
  name : String
  packages : Array
  upVote : Number
  dnVote : Number
  score: Number

mongoose.model 'Stack', Stack
Stack = mongoose.model 'Stack'

class StackProvider
  findAll: (cb) ->
    Stack.find {}, (err, stacks) ->
      cb null, stacks unless err

  findById: (id, cb) ->
    Stack.findById id, (err, stack) ->
      cb null, stack unless err

  findSort: (cb) ->
    query = Stack.find {}
    query.desc 'score', 'upVote'
    query.exec (err, stacks) ->
      cb null, stacks unless err

  update: (id, params, cb) ->
    Stack.findById id, (err, stack) ->
      unless err
        stack.name = params.name
        stack.packages = params.packages
        stack.upVote = params.upVote
        stack.dnVote = params.dnVote
        stack.score = params.score
        stack.save (err) ->
          cb null, stack unless err

  create: (params, cb) ->
	  stack = new Stack
      name: params.name
      packages: params.packages
      upVote: params.upVote
      dnVote: params.dnVote
      score: params.score
    stack.save (err) ->
      cb null, stack unless err

  destroy: (name, cb) ->
    Stack.find {name: name}, (err, stack) ->
      unless err
        stack.remove()
        stack.save (err) ->
          cb null, stack unless err

exports.StackProvider = StackProvider
