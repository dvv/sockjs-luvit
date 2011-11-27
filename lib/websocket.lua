local lower, match
do
  local _table_0 = require('string')
  lower, match = _table_0.lower, _table_0.match
end
local hixie76 = require('./websocket-hixie76')
local hybi10 = require('./websocket-hybi10')
local verify_origin
verify_origin = function(origin, list_of_origins)
  return true
end
local _ = [==[  if list_of_origins.indexOf('*:*') isnt -1
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
local handler
handler = function(self, options)
  self.auto_chunked = false
  if lower(self.req.headers.upgrade or '') ~= 'websocket' then
    return self:send(400, 'Can "Upgrade" only to "WebSocket".')
  end
  if not match(',' .. lower(self.req.headers.connection or '') .. ',', '[^%w]+upgrade[^%w]+') then
    return self:send(400, '"Connection" must be "Upgrade".')
  end
  local origin = self.req.headers.origin
  if not verify_origin(origin, options.origins) then
    return self:send(400, 'Unverified origin.')
  end
  local location = ((function()
    if origin and origin[1 .. 5] == 'https' then
      return 'wss'
    else
      return 'ws'
    end
  end)())
  location = location .. '://' .. self.req.headers.host .. self.req.real_url
  self:nodelay(true)
  self.protocol = 'websocket'
  local ver = self.req.headers['sec-websocket-version']
  local shaker
  if ver == '8' or ver == '7' or ver == '13' then
    shaker = hybi10
  else
    shaker = hixie76
  end
  shaker(self, origin, location, function()
    return self:create_session(self.req, self, nil, options)
  end)
  return 
end
return {
  GET = handler
}
