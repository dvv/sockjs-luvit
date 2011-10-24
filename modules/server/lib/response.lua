local Response = require('response')
local FS = require('fs')
local noop
noop = function() end
Response.prototype.auto_server = 'U-Gotta-Luvit'
Response.prototype.safe_write0 = function(self, chunk, cb)
  if cb == nil then
    cb = noop
  end
  return self:write(chunk, function(err, result)
    if not err then
      return cb(err, result)
    end
    if err then
      p('WRITERR?', err, result)
      if err.code == 'EBUSY' or err.code == 'EINTR' then
        return self:safe_write(chunk, cb)
      end
    else
      p('WRITE FAILED', err)
      return cb(err)
    end
  end)
end
local CHUNK = 4096
Response.prototype.safe_write = function(self, data, cb)
  local buf = data
  local _write
  _write = function()
    if buf == '' and cb then
      return cb()
    end
    local s = buf:sub(1, CHUNK)
    return self:write(s, function(err, result)
      p('WRITTEN', self.chunked, #s)
      if not err then
        buf = buf:sub(CHUNK + 1)
      else
        if err.code ~= 'EBUSY' and err.code ~= 'EINTR' then
          p('SAFE_WRITE FAILED', err)
          if cb then
            cb(err)
          end
          return 
        end
      end
      _write()
      return 
    end)
  end
  _write()
  return 
end
Response.prototype.send = function(self, code, data, headers, close)
  if close == nil then
    close = true
  end
  p('RESPONSE FOR', self.req and self.req.method, self.req and self.req.url, 'IS', code, data)
  self:write_head(code, headers or { })
  if data then
    self:write(data)
  end
  if close then
    return self:finish()
  end
end
Response.prototype.fail = function(self, reason)
  return self:send(500, reason, {
    ['Content-Type'] = 'text/plain; charset=UTF-8',
    ['Content-Length'] = #reason
  })
end
Response.prototype.serve_not_found = function(self)
  return self:send(404)
end
Response.prototype.serve_not_modified = function(self, headers)
  return self:send(304, nil, headers)
end
Response.prototype.serve_invalid_range = function(self, size)
  return self:send(416, nil, {
    ['Content-Range'] = 'bytes=*/' .. size
  })
end
Response.prototype.render = function(self, template, data, options)
  if data == nil then
    data = { }
  end
  if options == nil then
    options = { }
  end
  return FS.read_file(template, function(err, text)
    if err then
      return self:serve_not_found()
    else
      local html = (text % data)
      return self:send(200, html, {
        ['Content-Type'] = 'text/html; charset=UTF-8',
        ['Content-Length'] = #html
      })
    end
  end)
end
