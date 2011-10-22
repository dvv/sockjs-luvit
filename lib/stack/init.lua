require('./request')
require('./response')
local library = {
  auth = require('./auth'),
  body = require('./body'),
  health = require('./health'),
  rest = require('./rest'),
  route = require('./route'),
  session = require('./session'),
  static = require('./static'),
  sockjs = require('./../sockjs/')
}
local Stack
Stack = (function()
  local _parent_0 = nil
  local _base_0 = {
    use = function(lib_layer_name)
      return library[lib_layer_name]
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
          if not status then
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
return Stack
