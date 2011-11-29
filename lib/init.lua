_G.JSON = require('server/modules/json')
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
      sockjs_url = 'http://cdn.sockjs.org/sockjs-0.1.min.js',
      heartbeat_delay = 25000,
      disconnect_delay = 5000,
      response_limit = 128 * 1024,
      origins = {
        '*:*'
      },
      disabled_transports = { },
      cache_age = 365 * 24 * 60 * 60
    }
  })
  local parse_url = require('url').parse
  local sub, gsub, match, gmatch, find, parse_query
  do
    local _table_0 = require('string')
    sub, gsub, match, gmatch, find, parse_query = _table_0.sub, _table_0.gsub, _table_0.match, _table_0.gmatch, _table_0.find, _table_0.parse_query
  end
  local normalize
  do
    local _table_0 = require('path')
    normalize = _table_0.normalize
  end
  return Stack.mount(root, function(req, res, nxt)
    res.req = req
    req:once('error', function(err)
      debug('REQ-ERROR', err)
      return req:close()
    end)
    res:once('error', function(err)
      debug('RES-ERROR', err)
      res.closed = true
      return res:close()
    end)
    res.get_session = function(self, sid)
      return Session.get(sid)
    end
    res.create_session = function(self, req, conn, sid, options)
      local session = Session.get_or_create(sid, options)
      return session:bind(req, conn)
    end
    local path = req.uri.pathname
    if sub(path, -1, -1) == '/' then
      path = sub(path, 1, -2)
    end
    if req.url == '' or req.url == '/' then
      if req.method == 'GET' then
        res:send(200, 'Welcome to SockJS!\n', {
          ['Content-Type'] = 'text/plain; charset=UTF-8'
        })
        return 
      end
    else
      if path == '/chunking_test' then
        local handler = other_handlers.chunking_test[req.method]
        if not handler then
          return res:send(405)
        end
        handler(res, options)
        return 
      else
        if match(path, '^/iframe[0-9-.a-z_]*%.html$') then
          local handler = other_handlers.iframe[req.method]
          if handler then
            handler(res, options)
            return 
          end
        else
          local sid, transport = match(path, '^/[^./]+/([^./]+)/([a-z_]+)$')
          if sid then
            if req.method == 'OPTIONS' then
              other_handlers.options(res, options)
            else
              local _list_0 = options.disabled_transports
              for _index_0 = 1, #_list_0 do
                local t = _list_0[_index_0]
                if t == transport then
                  return res:serve_not_found()
                end
              end
              local handler = transport_handlers[transport]
              if handler then
                handler = handler[req.method]
                if not handler then
                  return res:send(405)
                end
                handler(res, options, sid, transport)
              end
            end
            return 
          end
        end
      end
    end
    res:serve_not_found()
    return 
  end)
end
