import encode from JSON
import parse_query from require 'string'

--
-- jsonp polling request handler
--
handler = (options, sid) =>
  @handle_balancer_cookie()
  @auto_chunked = false
  query = parse_query @req.uri.query
  callback = query.c or query.callback
  return @fail '"callback" parameter required' if not callback
  @send 200, nil, {
    ['Content-Type']: 'application/javascript; charset=UTF-8'
    ['Cache-Control']: 'no-store, no-cache, must-revalidate, max-age=0'
  }, false
  -- upgrade response to session handler
  @protocol = 'jsonp'
  @curr_size, @max_size = 0, 1
  @send_frame = (payload, continue) =>
    @write_frame(callback .. '(' .. encode(payload) .. ');\r\n', continue)
  -- register session
  @create_session @req, self, sid, options
  return

return {

  GET: handler

}
