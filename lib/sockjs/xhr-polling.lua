local handler
handler = function(self, nxt, root, sid)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  self.auto_chunked = false
  self:send(200, nil, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8'
  }, false)
  self.protocol = 'xhr'
  self.curr_size, self.max_size = 0, 1
  self.send_frame = function(self, payload)
    return self:write_frame(payload .. '\n')
  end
  local session = self:get_session(sid, options)
  session:bind(self)
  return 
end
return {
  'POST (/.+)/[^./]+/([^./]+)/xhr[/]?$',
  handler
}
