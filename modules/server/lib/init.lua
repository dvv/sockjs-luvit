local Http = require('http')
local Stack = require('stack')
Stack.error_handler = function(req, res, err)
  if err then
    local reason = err
    print('\n' .. reason .. '\n')
    return res:fail(reason)
  else
    return res:send(404)
  end
end
local Path = require('path')
require('./util')
require('./request')
require('./response')
local use
use = function(plugin_name)
  return require(Path.join(__dirname, plugin_name))
end
local run
run = function(layers, port, host)
  local handler = Stack.stack(unpack(layers))
  local server = Http.create_server(host or "127.0.0.1", port or 80, handler)
  return server
end
return {
  use = use,
  run = run
}
