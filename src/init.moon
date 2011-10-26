--
-- SockJS server implemented in luvit
-- https://github.com/sockjs/sockjs-protocol for details
--

_G.JSON = require 'server/modules/json'

Stack = require 'stack'

--
-- augment Response.prototype with helper methods
--
require './response-helpers'

--
-- routes that every SockJS server must respond to
--
transport_handlers = {
  xhr_send: require './xhr-jsonp-send'
  jsonp_send: require './xhr-jsonp-send'
  xhr: require './xhr-polling'
  jsonp: require './jsonp-polling'
  xhr_streaming: require './xhr-streaming'
  websocket: require './websocket'
  htmlfile: require './htmlfile'
  eventsource: require './eventsource'
}
other_handlers = {
  options: require './options'
  chunking_test: require './chunking-test'
  iframe: require './iframe'
}

--
-- Session
--
Session = require './session'

--
-- collection of servers
--
servers = {}

return (root, options) ->

  -- register/unregister the server
  assert(root)
  servers[root] = options
  return if not options
  -- default options
  setmetatable options, __index: {
    sockjs_url: 'http://sockjs.github.com/sockjs-client/sockjs-latest.min.js'
    heartbeat_delay: 25000
    disconnect_delay: 5000
    response_limit: 128 * 1024
    origins: {'*:*'}
    disabled_transports: { } --'xhr_send' }
    cache_age: 365 * 24 * 60 * 60 -- one year
  }

  parse_url = require('url').parse
  import sub, gsub, match, gmatch, find, parse_query from require 'string'
  import normalize from require 'path'

  -- return request handler
  return Stack.mount root, (req, res, nxt) ->

    res.req = req

    res.get_session = (sid) => Session.get sid
    res.create_session = (sid, options) => Session.get_or_create sid, options

    -- strip trailing slash
    path = req.uri.pathname
    path = sub(path, 1, -2) if sub(path, -1, -1) == '/'

    -- exact root requested -> serve greeting
    if req.url == '' or req.url == '/' --req.url == '/'
      if req.method == 'GET'
        res\send 200, 'Welcome to SockJS!\n', ['Content-Type']: 'text/plain; charset=UTF-8'
        return

    else if path == '/chunking_test'
      handler = other_handlers.chunking_test[req.method]
      return res\send 405 if not handler
      handler res, options
      return

    else if match(path, '^/iframe[0-9-.a-z_]*%.html$')
      handler = other_handlers.iframe[req.method]
      if handler
        handler res, options
        return

    else
      sid, transport = match path, '^/[^./]+/([^./]+)/([a-z_]+)$'
      --p('???', sid, transport)
      if sid
        if req.method == 'OPTIONS'
          other_handlers.options res, options
        else
          --return res\serve_not_found() if options.disabled_transports[transport]
          for t in *options.disabled_transports
            return res\serve_not_found() if t == transport
          handler = transport_handlers[transport]
          if handler
            handler = handler[req.method]
            return res\send 405 if not handler
            handler res, options, sid, transport
        return

    -- not found
    res\serve_not_found()
    return
