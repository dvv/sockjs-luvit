--
-- http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76
--

import get_digest from require 'server/modules/crypto'
import floor, random from require 'math'
import band, bor, bxor, rshift, lshift from require 'bit'
String = require 'string'
slice = String.sub
byte = String.byte
Table = require 'table'
push = Table.insert
join = Table.concat
import encode, decode from JSON

validate_secret = (req_headers, nonce) ->
  k1 = req_headers['sec-websocket-key1']
  k2 = req_headers['sec-websocket-key2']
  return false if not k1 or not k2
  dg = get_digest('md5')\init()
  for k in *{k1, k2}
    n = tonumber (String.gsub(k, '[^%d]', '')), 10
    spaces = #(String.gsub(k, '[^ ]', ''))
    return false if spaces == 0 or n % spaces != 0
    n = n / spaces
    dg\update String.char(rshift(n, 24) % 256, rshift(n, 16) % 256, rshift(n, 8) % 256, n % 256)
  dg\update nonce
  r = dg\final()
  dg\cleanup()
  r

return (origin, location, cb) =>
  p('SHAKE76', origin, location)
  @sec = @req.headers['sec-websocket-key1']
  prefix = @sec and 'Sec-' or ''
  @write_head 101, {
    ['Upgrade']: 'WebSocket'
    ['Connection']: 'Upgrade'
    [prefix .. 'WebSocket-Origin']: origin
    [prefix .. 'WebSocket-Location']: location
    --TODO['Sec-WebSocket-Protocol']: @req.headers['sec-websocket-protocol'].split('[^,]*')
  }
  @has_body = true -- override bodyless assumption on 101
  -- parse incoming data
  data = ''
  ondata = (chunk) ->
    --p('DATA', chunk)
    if chunk
      data = data .. chunk
    buf = data
    return if #buf == 0
    if String.byte(buf, 1) == 0
      for i = 2, #buf
        if String.byte(buf, i) == 255
          payload = String.sub(buf, 2, i - 1)
          data = String.sub(buf, i + 1)
          if @session and #payload > 0
            status, message = pcall JSON.decode, payload
            p('DECODE', payload, status, message)
            return @do_reasoned_close(1002, 'Broken framing.') if not status
            -- process message
            @session\onmessage message
          ondata()
          return
      -- wait for more data
      return
    else if String.byte(buf, 1) == 255 and String.byte(buf, 2) == 0
      @do_reasoned_close 1001, 'Socket closed by the client'
    else
      @do_reasoned_close 1002, 'Broken framing'
    return
  @req\once 'data', (chunk) ->
    --p('WAIT', chunk)
    data = data .. chunk
    if @sec == false or #data >= 8
      if @sec
        nonce = slice data, 1, 8
        data = slice data, 9
        reply = validate_secret @req.headers, nonce
        if not reply
          @do_reasoned_close()
          return
        --p('REPLY', reply, #reply)
        @on 'data', ondata
        --status, err = pcall @write, self, reply
        @write reply
        cb() if cb
    return
  @send_frame = (payload, continue) =>
    @write_frame '\000' .. payload .. '\255', continue
    return
