--
-- Listen to specified URL and respond with status 200
-- to signify this server is alive
--
-- Use to notify upstream haproxy load-balancer
--

return (url = '/haproxy?monitor') ->

  return (req, res, continue) ->

    if req.url == url
      res\send 200, nil, {}
    else
      continue()
