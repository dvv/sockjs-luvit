--
-- Handle signin/signout
--

return (url = '/rpc/auth', options = {}) ->

  return (req, res, continue) ->

    if req.url == url

      -- given current session and request body, request new session
      options.authenticate req.session, req.body, (session) ->
        -- falsy session means to remove current session
        req.session = session
        -- go back
        res\send 302, nil, {
          ['Location']: req.headers.referer or req.headers.referrer or '/'
        }

    else
      continue()
