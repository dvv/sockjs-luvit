local encode = JSON.encode
local parse_query
do
  local _table_0 = require('string')
  parse_query = _table_0.parse_query
end
local handler
handler = function(self, options, sid)
  self:handle_balancer_cookie()
  self.auto_chunked = false
  local query = parse_query(self.req.uri.query)
  local callback = query.c or query.callback
  if not callback then
    return self:fail('"callback" parameter required')
  end
  self:send(200, nil, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'jsonp'
  self.curr_size, self.max_size = 0, 1
  self.send_frame = function(self, payload, continue)
    return self:write_frame(callback .. '(' .. encode(payload) .. ');\r\n', continue)
  end
  local session = self:create_session(sid, options)
  session:bind(self)
  return 
end
return {
  GET = handler
}
