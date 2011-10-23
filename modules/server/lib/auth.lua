return function(url, options)
  if url == nil then
    url = '/rpc/auth'
  end
  if options == nil then
    options = { }
  end
  return function(req, res, continue)
    if req.url == url then
      return options.authenticate(req.session, req.body, function(session)
        req.session = session
        return res:send(302, nil, {
          ['Location'] = req.headers.referer or req.headers.referrer or '/'
        })
      end)
    else
      return continue()
    end
  end
end
