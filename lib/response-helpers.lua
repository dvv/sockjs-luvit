local Response = require('response')
Response.prototype.handle_xhr_cors = function(self)
  local origin = self.req.headers['origin'] or '*'
  self:set_header('Access-Control-Allow-Origin', origin)
  local headers = self.req.headers['access-control-request-headers']
  if headers then
    self:set_header('Access-Control-Allow-Headers', headers)
  end
  self:set_header('Access-Control-Allow-Credentials', 'true')
  return 
end
Response.prototype.handle_balancer_cookie = function(self)
  if not self.req.cookies then
    self.req:parse_cookies()
  end
  local jsid = self.req.cookies['JSESSIONID'] or 'dummy'
  self:set_header('Set-Cookie', 'JSESSIONID=' .. jsid .. '; path=/')
  return 
end
Response.prototype.write_frame = function(self, payload, continue)
  if self.max_size then
    self.curr_size = self.curr_size + #payload
  end
  debug('WRITE_FRAME', #payload < 128 and payload or #payload)
  self:write(payload, function(err)
    if self.max_size and self.curr_size >= self.max_size then
      debug('MAXSIZE EXCEEDED, CLOSING', err)
      self:finish(function()
        if continue then
          return continue(err)
        end
      end)
    end
    return 
  end)
  return 
end
Response.prototype.do_reasoned_close = function(self, status, reason)
  p('REASONED_CLOSE', self.session and self.session.sid, status, reason)
  if self.session then
    self.session:unbind()
  end
  self:finish()
  return 
end
return Response
