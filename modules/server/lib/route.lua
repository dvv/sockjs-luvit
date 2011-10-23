return function(routes)
  if routes == nil then
    routes = { }
  end
  local parse_url = require('url').parse
  local parse_query, match
  do
    local _table_0 = require('string')
    parse_query = _table_0.parse_query
    match = _table_0.match
  end
  return function(req, res, continue)
    res.req = req
    if not req.uri then
      req.uri = parse_url(req.url)
    end
    req.uri.query = parse_query(req.uri.query)
    local str = req.method .. ' ' .. req.uri.pathname
    local _list_0 = routes
    for _index_0 = 1, #_list_0 do
      local pair = _list_0[_index_0]
      local params = {
        match(str, pair[1])
      }
      if params[1] then
        pair[2](res, continue, unpack(params))
        return 
      end
    end
    continue()
    return 
  end
end
