local handler
handler = function(self, options, sid)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  self.auto_chunked = false
  self:send(200, nil, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8'
  }, false)
  self.protocol = 'xhr'
  self.curr_size, self.max_size = 0, 1
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
