http = require 'http'
querystring = require 'querystring'

request_options =
  host: 'search.npmjs.org',
  port: 80,
  method: 'GET'

exports.index = (req, res) ->
  request_options.path = '/_list/dependencies_limit/dependencies?group=true&descending=true&list_limit=15'

  request = http.request request_options, (response) ->
    data = ''
    response.setEncoding 'utf8'
    response.on 'data', (chunk) ->
      data += chunk;
    response.on 'end', ->
      res.render 'index',
        title: 'Your Node Stack'
        name: 'Phated (blaine@iceddev.com)'
        dependees: JSON.parse(data).rows

  request.on 'error', (err) ->
    console.log "problem with request: #{err.message}"

  request.end()
