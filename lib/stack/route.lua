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
    local _list_0 = routes
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local params = {
        String.match(str, pair[1])
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
