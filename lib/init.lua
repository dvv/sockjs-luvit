_G.JSON = require('server/modules/json')
local Math = require('math')
local Stack = require('stack')
require('./response-helpers')
local transport_handlers = {
  xhr_send = require('./xhr-jsonp-send'),
  jsonp_send = require('./xhr-jsonp-send'),
  xhr = require('./xhr-polling'),
  jsonp = require('./jsonp-polling'),
  xhr_streaming = require('./xhr-streaming'),
  websocket = require('./websocket'),
  htmlfile = require('./htmlfile'),
  eventsource = require('./eventsource')
}
local other_handlers = {
  options = require('./options'),
  chunking_test = require('./chunking-test'),
  iframe = require('./iframe')
}
local Session = require('./session')
local servers = { }
return function(root, options)
  assert(root)
  servers[root] = options
  if not options then
    return 
  end
  setmetatable(options, {
    __index = {
      sockjs_url = 'http://sockjs.github.com/sockjs-client/sockjs-latest.min.js',
      heartbeat_delay = 25000,
      disconnect_delay = 5000,
      response_limit = 128 * 1024,
      origins = {
        '*:*'
      },
      disabled_transports = { },
      cache_age = 365 * 24 * 60 * 60,
      get_nonce = function()
        return Math.random()
      end
    }
  })
  local parse_url = require('url').parse
  local sub, gsub, match, gmatch, find, parse_query
  do
    local _table_0 = require('string')
    sub = _table_0.sub
    gsub = _table_0.gsub
    match = _table_0.match
    gmatch = _table_0.gmatch
    find = _table_0.find
    parse_query = _table_0.parse_query
  end
  local normalize
  do
    local _table_0 = require('path')
    normalize = _table_0.normalize
  end
  return Stack.mount(root, function(req, res, nxt)
    res.req = req
    res.get_session = function(self, sid)
      return Session.get(sid)
    end
    res.create_session = function(self, sid, options)
      return Session.get_or_create(sid, options)
    end
    local path = req.uri.pathname
    if sub(path, -1, -1) == '/' then
      path = sub(path, 1, -2)
    end
    p()
    p('REQUEST ' .. root, req.method, path, req.url, req.real_url)
    if req.url == '/' then
      p('ROOT?', parts)
      if req.method ~= 'GET' then
        return res:e404()
      end
      res:send(200, 'Welcome to SockJS!\n', {
        ['Content-Type'] = 'text/plain; charset=UTF-8'
      })
      return 
    end
    if path == '/chunking_test' then
      local handler = other_handlers.chunking_test[req.method]
      if not handler then
        return res:send(405)
      end
      p('CHUNKING')
      handler(res, options)
      return 
    end
    if match(path, '^/iframe[0-9-.a-z_]*%.html$') then
      local handler = other_handlers.iframe[req.method]
      if not handler then
        return res:e404()
      end
      p('IFRAME')
      handler(res, options)
      return 
    end
    local sid, transport = match(path, '^/[^./]+/([^./]+)/([a-z_]+)$')
    p('???', sid, transport, req.uri)
    if sid then
      if req.method == 'OPTIONS' then
        other_handlers.options(res, options)
      else
        local _list_0 = options.disabled_transports
        for _index_0 = 1, #_list_0 do
          local t = _list_0[_index_0]
          if t == transport then
            return res:e404()
          end
        end
        local handler = transport_handlers[transport]
        if not handler then
          return res:e404()
        end
        handler = handler[req.method]
        if not handler then
          return res:send(405)
        end
        p('SESSION!', req.method, root, sid, transport)
        handler(res, options, sid, transport)
      end
      return 
    end
    p('FALLEN BACK', req.url)
    res:e404()
    return 
  end)
end
