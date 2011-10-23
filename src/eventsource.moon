import sub from require 'string'

--
-- escape given string for passing safely via EventSource transport
--
escape_for_eventsource1 = (str) ->
  s = ''
  for i = 1, #str
    c = sub str, i, i
    print('C', c, c == '\r')
    if c == '%'
      c = '%25'
    if c == '\0'
      c = '%00'
    if c == '\r'
      c = '%0A'
    if c == '\n'
      c = '%0D'
    s = s .. c
  print(str, '->', s)
  s

--
-- eventsource request handler
--
handler = (nxt, root, sid) =>
  options = @get_options(root)
  return nxt() if not options
  @handle_balancer_cookie()
  -- N.B. Opera needs one more new line at the start
  @send 200, '\r\n', {
    ['Content-Type']: 'text/event-stream; charset=UTF-8'
    ['Cache-Control']: 'no-store, no-cache, must-revalidate, max-age=0'
  }, false
  -- upgrade response to session handler
  @protocol = 'eventsource'
  @curr_size, @max_size = 0, options.response_limit
  @send_frame = (payload) =>
    p('SEND', payload)
    @write_frame('data: ' .. payload .. '\r\n\r\n')
  -- register session
  session = @get_session sid, options
  session\bind self
  return

return {
  'GET (/.+)/[^./]+/([^./]+)/eventsource[/]?$'
  handler
}
