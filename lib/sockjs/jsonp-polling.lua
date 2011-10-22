local encode
do
  local _table_0 = require('cjson')
  encode = _table_0.encode
end
local handler
handler = function(self, nxt, root, sid)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  self:handle_balancer_cookie()
  self.auto_chunked = false
  local callback = self.req.uri.query.c or self.req.uri.query.callback
  if not callback then
    return self:fail('"callback" parameter required')
  end
  self:send(200, nil, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'jsonp'
  self.curr_size, self.max_size = 0, 1
  self.send_frame = function(self, payload)
    return self:write_frame(callback .. '(' .. encode(payload) .. ');\r\n')
  end
  local session = self:get_session(sid, options)
  session:bind(self)
  return 
end
return {
  'GET (/.+)/[^./]+/([^./]+)/jsonp[/]?$',
  handler
}
