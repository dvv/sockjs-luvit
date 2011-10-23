import encode from JSON

--
-- jsonp polling request handler
--
handler = (nxt, root, sid) =>
  options = @get_options(root)
  return nxt() if not options
  @handle_balancer_cookie()
  @auto_chunked = false
  callback = @req.uri.query.c or @req.uri.query.callback
  return @fail '"callback" parameter required' if not callback
  @send 200, nil, {
    ['Content-Type']: 'application/javascript; charset=UTF-8'
    ['Cache-Control']: 'no-store, no-cache, must-revalidate, max-age=0'
  }, false
  -- upgrade response to session handler
  @protocol = 'jsonp'
  @curr_size, @max_size = 0, 1
  @send_frame = (payload) =>
    @write_frame(callback .. '(' .. encode(payload) .. ');\r\n')
  -- register session
  session = @get_session sid, options
  session\bind self
  return

return {
  'GET (/.+)/[^./]+/([^./]+)/jsonp[/]?$'
  handler
}
