--
-- Simple regexp based router
--

-- `routes` are table of tables describing handlers
-- { 1={ <regexp>, <handler> }, 2={ <regexp>, <handler>, ... } }
-- <regexp> is textual concatenation of request method, space and matching url pattern
-- such complicated structure is used to workaround Lua having no ordered dictionaries

return (routes = {}) ->

  parse_url = require('url').parse
  import parse_query, match from require 'string'

  return (req, res, continue) ->

    -- TODO: these preliminary steps should belong to another implicit layer
    res.req = req
    req.uri = parse_url req.url if not req.uri
    --
    req.uri.query = parse_query req.uri.query

    str = req.method .. ' ' .. req.uri.pathname
    for pair in *routes
      params = {match str, pair[1]}
      if params[1]
        pair[2] res, continue, unpack params
        return
    continue()
    return
