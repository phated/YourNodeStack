$ = jQuery

# Current Stack Being Worked On
stackPackages = []

# Functions to Bind
checked = (event) ->
  if $(@).is ':checked'
    stackPackages.push @value
  else
    stackPackages = stackPackages.filter (word) => word isnt @value
    $("input[value=#{@value}]").attr 'checked', false
  stack = $ '#stack'
  source = $ '#stack-template'
  generateTemplate stack, source, stackPackages, bindStackCheckbox

searchType = (event) ->
  socket.emit 'search',
    startkey: "\"#{@value}\""
    endkey: "\"#{@value}ZZZZZZZZZZZZZZZZZZZ\""
    limit: 50

shareStack = (event) ->
  name = $('#stackName').val()
  error = $ '#error'
  source = $ '#error-template'
  if name.length is 0
    msg = 'Name Your Stack'
    generateTemplate error, source, msg
  else if stackPackages.length is 0
    msg = 'Add Some Packages'
    generateTemplate error, source, msg
  else
    error.html ''
    socket.emit 'share',
      name: name.substr 0, 30
      packages: stackPackages
      upVote: 0
      dnVote: 0
      score: 0

upVote = (event) ->
  stack = $(@).parents '.stack'
  stackId = stack.data 'id'
  socket.emit 'upvote', stackId

dnVote = (event) ->
  stack = $(@).parents '.stack'
  stackId = stack.data 'id'
  socket.emit 'dnvote', stackId

# Bindings
bindVote = ->
  upVoteButton = $ '.vote-up'
  upVoteButton.on 'click', upVote
  dnVoteButton = $ '.vote-down'
  dnVoteButton.on 'click', dnVote

bindResultsCheckbox = ->
  resultCheckbox = $ '.resultCheckbox'
  resultCheckbox.on 'change', checked

bindStackCheckbox = ->
  resultCheckbox = $ '.stackCheckbox'
  resultCheckbox.on 'change', checked

# Templating
generateTemplate = (append, source, data, bind) ->
  template = Handlebars.compile source.html()
  html = template data
  append.html html
  bind() if bind?

init = ->
  # Initial Bindings
  search = $ '#search'
  search.on 'keyup', searchType

  share = $ '#share'
  share.on 'click', shareStack

  dependeeCheckbox = $ '.dependeeCheckbox'
  dependeeCheckbox.on 'change', checked

  # Inialize Sockets when DOM Ready
  socket.on 'searchResults', (data) ->
    results = $ '#results'
    source = $ "#results-template"
    generateTemplate results, source, data, bindResultsCheckbox

  socket.on 'newStack', (data) ->
    newStack = $ '#newStacks'
    source = $ "#stacksList-template"
    generateTemplate newStack, source, data, bindVote

  socket.on 'topStack', (data) ->
    topStack = $ '#topStacks'
    source = $ "#stacksList-template"
    generateTemplate topStack, source, data, bindVote

  socket.on 'error', (data) ->
    error = $ "[data-id=#{data.id}] .voteError"
    source = $ '#error-template'
    generateTemplate error, source, data.msg

$ ->
  init()
