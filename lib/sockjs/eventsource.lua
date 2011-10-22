local gsub
do
  local _table_0 = require('string')
  gsub = _table_0.gsub
end
local escape_for_eventsource
escape_for_eventsource = function(str)
  str = gsub(str, '%%', '%25')
  str = gsub(str, '\r', '%0D')
  str = gsub(str, '\n', '%0A')
  return str
end
local handler
handler = function(self, nxt, root, sid)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  self:handle_balancer_cookie()
  self:send(200, '\r\n', {
    ['Content-Type'] = 'text/event-stream; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'eventsource'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function(self, payload)
    return self:write_frame('data: ' .. escape_for_eventsource(payload) .. '\r\n\r\n')
  end
  local session = self:get_session(sid, options)
  session:bind(self)
  return 
end
return {
  'GET (/.+)/[^./]+/([^./]+)/eventsource[/]?$',
  handler
}
