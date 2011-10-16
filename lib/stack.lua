local Stack
Stack = (function()
  local _parent_0 = nil
  local _base_0 = {
    use = function(lib_layer_name)
      return require('lib/stack/' .. lib_layer_name)
    end,
    error_handler = function(req, res, err)
      if err then
        local reason = err
        print('\n' .. reason .. '\n')
        return res:fail(reason)
      else
        return res:send(404)
      end
    end,
    run = function(self, port, host)
      if port == nil then
        port = 80
      end
      if host == nil then
        host = '0.0.0.0'
      end
      local server = require('http').create_server(host, port, self.handler)
      server:on('upgrade', self.handler)
      return server
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, layers)
      local error_handler = self.error_handler
      local handler = error_handler
      for i = #layers, 1, -1 do
        local layer = layers[i]
        local child = handler
        handler = function(req, res)
          local fn
          fn = function(err)
            if err then
              return error_handler(req, res, err)
            else
              return child(req, res)
            end
          end
          local status, err = pcall(layer, req, res, fn)
          if err then
            return error_handler(req, res, err)
          end
        end
      end
      self.handler = handler
    end
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
local Request = require('request')
local Response = require('response')
local FS = require('fs')
local noop
noop = function() end
Response.prototype.safe_write = function(self, chunk, cb)
  if cb == nil then
    cb = noop
  end
  return self:write(chunk, function(err, result)
    if not err then
      return cb(err, result)
    end
    if err == 16 then
      return self:safe_write(chunk, cb)
    else
      p('WRITE FAILED', err)
      return cb(err)
    end
  end)
end
Response.prototype.send = function(self, code, data, headers, close)
  if close == nil then
    close = true
  end
  local h = self.headers or { }
  for k, v in pairs(headers or { }) do
    h[k] = v
  end
  p('RESPONSE', self.req and self.req.url, code, data, h)
  self:write_head(code, h or { })
  local _ = [==[  if data
    @safe_write data, () -> @close()
  else
    @close()
  ]==]
  if data then
    self:write(data)
  end
  if close then
    return self:close()
  end
end
Response.prototype.set_header = function(self, name, value)
  if not self.headers then
    self.headers = { }
  end
  self.headers[name] = value
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
  d('render', template, data)
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
return Stack
