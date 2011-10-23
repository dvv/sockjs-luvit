--
-- SockJS server implemented in luvit
-- https://github.com/sockjs/sockjs-protocol for details
--

_G.JSON = require 'server/modules/json'

Math = require 'math'

--
-- augment Response.prototype with helper methods
--
require './response-helpers'

--
-- routes that every SockJS server must respond to
--
sockjs_routes = {
  require './xhr-jsonp-send'
  require './xhr-polling'
  require './jsonp-polling'
  require './xhr-streaming'
  require './websocket'
  require './htmlfile'
  require './eventsource'
  require './options'
  (require './chunking-test')[1]
  (require './chunking-test')[2]
  require './iframe'
  require './base-url'
}
p(sockjs_routes)
--process.exit()

--
-- ???
--
Session = require './session'

--
-- collection of servers
--
servers = {}

return (root, options) ->

  -- register/unregister the server
  if root
    servers[root] = options
    return if not options
    -- default options
    setmetatable options, __index: {
      sockjs_url: 'http://sockjs.github.com/sockjs-client/sockjs-latest.min.js'
      heartbeat_delay: 25000
      disconnect_delay: 5000
      response_limit: 128 * 1024
      origins: {'*:*'}
      disabled_transports: {}
      cache_age: 365 * 24 * 60 * 60 -- one year
      get_nonce: () -> Math.random()
    }

  parse_url = require('url').parse
  import match, parse_query from require 'string'

  -- return request handler
  return (req, res, nxt) ->

    res.get_options = (root) =>
      --p('ROOT', root)
      servers[root]
    res.get_session = (sid, options) => Session.get_or_create sid, options

    -- TODO: these preliminary steps should belong to another implicit layer
    res.req = req
    req.uri = parse_url req.url if not req.uri
    --
    --req.uri.query = parse_query req.uri.query

    str = req.method .. ' ' .. req.uri.pathname
    --p('URI', str, req.uri)
    for pair in *sockjs_routes
      params = { match str, pair[1] }
      if params[1]
        pair[2] res, nxt, unpack params
        return

    nxt()
    return
