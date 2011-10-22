local Math = require('math')
require('./response-helpers')
local sockjs_routes = {
  require('./xhr-jsonp-send'),
  require('./xhr-polling'),
  require('./jsonp-polling'),
  require('./xhr-streaming'),
  require('./websocket'),
  require('./htmlfile'),
  require('./eventsource'),
  require('./options'),
  (require('./chunking-test'))[1],
  (require('./chunking-test'))[2],
  require('./iframe'),
  require('./base-url-foo')
}
local Session = require('./transport')
local servers = { }
return function(root, options)
  if root then
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
  end
  local parse_url = require('url').parse
  local match, parse_query
  do
    local _table_0 = require('string')
    match = _table_0.match
    parse_query = _table_0.parse_query
  end
  return function(req, res, nxt)
    res.get_options = function(self, root)
      p('ROOT', root)
      return servers[root]
    end
    res.get_session = function(self, sid, options)
      return Session.get_or_create(sid, options)
    end
    res.req = req
    if not req.uri then
      req.uri = parse_url(req.url)
    end
    local str = req.method .. ' ' .. req.uri.pathname
    local _list_0 = sockjs_routes
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local params = {
        match(str, pair[1])
      }
      if params[1] then
        pair[2](res, nxt, unpack(params))
        return 
      end
    end
    nxt()
    return 
  end
end
