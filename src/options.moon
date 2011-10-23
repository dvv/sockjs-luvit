import date, time from require 'os'

--
-- xhr transport OPTIONS request handler
--
handler = (nxt, root, sid, transport) =>
  options = @get_options(root)
  return nxt() if not options
  -- TODO: guard
  --return nxt() if not transport in {'xhr_send', 'xhr', 'xhr_streaming'}
  @handle_xhr_cors()
  @handle_balancer_cookie()
  @send 204, nil, {
    ['Allow']: 'OPTIONS, POST'
    ['Cache-Control']: 'public, max-age=${cache_age}' % options
    ['Expires']: date('%c', time() + options.cache_age)
    ['Access-Control-Max-Age']: tostring(options.cache_age)
  }
  return

return {
  'OPTIONS (/.+)/[^./]+/([^./]+)/(xhr_?%w*)[/]?$'
  handler
}
