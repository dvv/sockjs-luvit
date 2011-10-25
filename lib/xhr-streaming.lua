local rep
do
  local _table_0 = require('string')
  rep = _table_0.rep
end
local handler
handler = function(self, options, sid)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  local content = rep('h', 2048) .. '\n'
  self:send(200, content, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8'
  }, false)
  self.protocol = 'xhr-streaming'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function(self, payload, continue)
    return self:write_frame(payload .. '\n', continue)
  end
  local session = self:create_session(sid, options)
  session:bind(self)
  return 
end
return {
  POST = handler
}
