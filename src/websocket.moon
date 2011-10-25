import lower, match from require 'string'

hixie76 = require './websocket-hixie76'
hybi10 = require './websocket-hybi10'

--
-- verify request origin
--
verify_origin = (origin, list_of_origins) ->
  -- TODO: implement
  true
[==[
  if list_of_origins.indexOf('*:*') isnt -1
        return true
    if not origin
        return false
    try
        parts = url.parse(origin)
        origins = [parts.host + ':' + parts.port,
                   parts.host + ':*',
                   '*:' + parts.port]
        if array_intersection(origins, list_of_origins).length > 0
            return true
    catch x
        null
    return false
]==]

--
-- websocket request handler
--
handler = (options) =>
  @auto_chunked = false
  -- Upgrade: WebSocket
  if lower(@req.headers.upgrade or '') != 'websocket'
    return @send 400, 'Can "Upgrade" only to "WebSocket".'
  -- Connection: Upgrade
  -- E.g. FF 6.0.2 sends 'Connection: keep-alive, Upgrade'
  if not match(','..lower(@req.headers.connection or '')..',', '[^%w]+upgrade[^%w]+')
    return @send 400, '"Connection" must be "Upgrade".'
  -- Origin: is good
  origin = @req.headers.origin
  if not verify_origin(origin, options.origins)
    return @send 400, 'Unverified origin.'
  --
  location = (if origin and origin[1..5] == 'https' then 'wss' else 'ws')
  location = location .. '://' .. @req.headers.host .. @req.real_url
  -- upgrade response to session handler
  @nodelay true
  @protocol = 'websocket'
  -- register session
  session = @create_session nil, options
  ver = @req.headers['sec-websocket-version']
  shaker = if ver == '8' or ver == '7' or ver == '13' then hybi10 else hixie76
  shaker self, origin, location, () -> session\bind self
  return

return {

  GET: handler

}
