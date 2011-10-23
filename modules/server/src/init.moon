--
-- standard HTTP server middleware layers
--

Http = require 'http'

Stack = require 'stack'
Stack.error_handler = (req, res, err) ->
  if err
    reason = err
    print '\n' .. reason .. '\n'
    res\fail reason
  else
    res\send 404

Path = require 'path'

require './util'
require './request'
require './response'

use = (plugin_name) -> require Path.join __dirname, plugin_name

run = (layers, port, host) ->
  handler = Stack.stack unpack(layers)
  server = Http.create_server host or "127.0.0.1", port or 80, handler
  server

-- export module
return {
  use: use
  run: run
}
