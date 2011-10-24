Response = require 'response'

--
-- allow cross-origin requests
--
Response.prototype.handle_xhr_cors = () =>
  origin = @req.headers['origin'] or '*'
  @set_header 'Access-Control-Allow-Origin', origin
  headers = @req.headers['access-control-request-headers']
  if headers
    @set_header 'Access-Control-Allow-Headers', headers
  @set_header 'Access-Control-Allow-Credentials', 'true'
  return

--
-- inject sticky session cookie
--
Response.prototype.handle_balancer_cookie = () =>
  @req\parse_cookies() if not @req.cookies
  jsid = @req.cookies['JSESSIONID'] or 'dummy'
  @set_header 'Set-Cookie', 'JSESSIONID=' .. jsid .. '; path=/'
  return

--
-- write a frame, honoring max_size set for this request
--
Response.prototype.write_frame = (payload, continue) =>
  @curr_size = @curr_size + #payload if @max_size
  debug('WRITE_FRAME', #payload < 128 and payload or #payload)
  @write payload, (err) ->
    if @max_size and @curr_size >= @max_size
      debug('MAXSIZE EXCEEDED, CLOSING', err)
      @finish () ->
        continue err if continue
    return
  return

--
-- ???
--
Response.prototype.do_reasoned_close = (status, reason) =>
  p('REASONED_CLOSE', @session and @session.sid, status, reason)
  -- TODO: unbind on @on('closed')?
  @session\unbind() if @session
  @finish()
  return

return Response
