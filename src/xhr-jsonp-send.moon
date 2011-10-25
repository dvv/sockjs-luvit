import decode from JSON
import match, parse_query from require 'string'
push = require('table').insert
join = require('table').concat

--
-- given Content-Type:, provide content decoder
--
allowed_content_types = {
  xhr_send:
    ['application/json']: decode
    ['text/plain']: decode
    ['application/xml']: decode
    ['T']: decode
    ['']: decode
  jsonp_send:
    ['application/x-www-form-urlencoded']: parse_query
    ['text/plain']: true
    ['']: true
}

--
-- xhr_send and jsonp_send request handlers
--
handler = (options, sid, transport) =>
  xhr = transport == 'xhr_send'
  @handle_xhr_cors() if xhr
  @handle_balancer_cookie()
  @auto_chunked = false
  -- bail out unless content-type is known
  ctype = @req.headers['content-type'] or ''
  ctype = match ctype, '[^;]*'
  decoder = allowed_content_types[transport][ctype]
  return @fail 'Payload expected.' if not decoder
  -- bail out unless such session exists
  session = @get_session sid
  return @serve_not_found() if not session
  -- collect data
  data = {}
  @req\on 'data', (chunk) ->
    push data, chunk
    return
  -- process data
  @req\on 'end', ->
    data = join data, ''
    return @fail 'Payload expected.' if data == ''
    if not xhr
      -- FIXME: data can be uri.query.d
      if decoder != true
        data = decoder(data).d or ''
      return @fail 'Payload expected.' if data == ''
    status, messages = pcall decode, data
    if not status
      return @fail 'Broken JSON encoding.'
    -- we expect array of messages
    return @fail 'Payload expected.' if not is_array messages
    -- process messages
    for message in *messages
      session\onmessage message
    -- respond ok
    if xhr
      @send 204, nil, ['Content-Type']: 'text/plain' -- for FF
    else
      @auto_content_type = false
      @send 200, 'ok', ['Content-Length']: 2
    return
  @req\on 'error', (err) ->
    error err
    return
  return

return {

  POST: handler

}
