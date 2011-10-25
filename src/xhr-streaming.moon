import rep from require 'string'

--
-- xhr streaming request handler
--
handler = (options, sid) =>
  @handle_xhr_cors()
  @handle_balancer_cookie()
  -- IE requires 2KB prefix:
  -- http://blogs.msdn.com/b/ieinternals/archive/2010/04/06/comet-streaming-in-internet-explorer-with-xmlhttprequest-and-xdomainrequest.aspx
  content = rep('h', 2048) .. '\n'
  @send 200, content, {
    ['Content-Type']: 'application/javascript; charset=UTF-8'
  }, false
  -- upgrade response to session handler
  @protocol = 'xhr-streaming'
  @curr_size, @max_size = 0, options.response_limit
  @send_frame = (payload, continue) =>
    @write_frame(payload .. '\n', continue)
  -- register session
  session = @create_session sid, options
  session\bind self
  return

return {

  POST: handler

}
