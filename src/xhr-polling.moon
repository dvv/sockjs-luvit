--
-- xhr polling request handler
--
handler = (nxt, root, sid) =>
  options = @get_options root
  return nxt() if not options
  @handle_xhr_cors()
  @handle_balancer_cookie()
  @auto_chunked = false
  @send 200, nil, {
    ['Content-Type']: 'application/javascript; charset=UTF-8'
  }, false
  -- upgrade response to session handler
  @protocol = 'xhr'
  @curr_size, @max_size = 0, 1
  @send_frame = (payload, continue) =>
    @write_frame(payload .. '\n', continue)
  -- register session
  session = @create_session sid, options
  session\bind self
  return

return {
  'POST (/.+)/[^./]+/([^./]+)/xhr[/]?$'
  handler
}
