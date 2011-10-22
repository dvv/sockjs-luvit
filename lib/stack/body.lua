return function(options)
  if options == nil then
    options = { }
  end
  return function(req, res, nxt)
    req.body = { }
    return nxt()
  end
end
