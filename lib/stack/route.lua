return function(routes)
  if routes == nil then
    routes = { }
  end
  local parseUrl = require('url').parse
  return function(req, res, nxt)
    res.req = req
    if not req.uri then
      req.uri = parseUrl(req.url)
    end
    req.uri.query = String.parse_query(req.uri.query)
    local str = req.method .. ' ' .. req.uri.pathname
    for route, handler in pairs(routes) do
      local params = {
        String.match(str, route)
      }
      if params[1] ~= nil then
        handler(res, nxt, unpack(params))
        return 
      end
    end
    nxt()
    return 
  end
end
