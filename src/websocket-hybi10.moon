--
-- http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-10
--

import get_digest from require 'server/modules/crypto'
import floor, random from require 'math'
import band, bor, bxor, rshift, lshift from require 'bit'
import sub, gsub, match, byte, char, base64 from require 'string'
Table = require 'table'
push = Table.insert
import encode, decode from JSON

verify_secret = (key) ->
  data = (match(key, '(%S+)')) .. '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
  dg = get_digest('sha1')\init()
  dg\update data
  r = dg\final()
  dg\cleanup()
  r

rand256 = () -> floor(random() * 256)

-- TODO: VERY INEFFICIENT!!!
table_to_string = (tbl) ->
  s = ''
  for i = 1, #tbl
    s = s .. char tbl[i]
  s

return (origin, location, cb) =>
  protocol = @req.headers['sec-websocket-protocol']
  protocol = (match protocol, '[^,]*') if protocol
  @write_head 101, {
    ['Upgrade']: 'WebSocket'
    ['Connection']: 'Upgrade'
    ['Sec-WebSocket-Accept']: base64(verify_secret(@req.headers['sec-websocket-key']))
    ['Sec-WebSocket-Protocol']: protocol
  }
  @has_body = true -- override bodyless assumption on 101
  -- parse incoming data
  data = ''
  ondata = (chunk) ->
    if chunk
      data = data .. chunk
    -- TODO: support length in framing
    return if #data < 2
    --
    buf = data
    status = nil
    reason = nil
    first = band byte(buf, 2), 0x7F
    if band(byte(buf, 1), 0x80) != 0x80
      error('fin flag not set')
      @do_reasoned_close 1002, 'Fin flag not set'
      return
    opcode = band byte(buf, 1), 0x0F
    if opcode != 1 and opcode != 8
      error('not a text nor close frame', opcode)
      @do_reasoned_close 1002, 'not a text nor close frame'
      return
    if opcode == 8 and first >= 126
      error('wrong length for close frame!!!')
      @do_reasoned_close 1002, 'wrong length for close frame'
      return
    l = 0
    length = 0
    key = {}
    masking = band(byte(buf, 2), 0x80) != 0
    if first < 126
      length = first
      l = 2
    else if first == 126
      return if #buf < 4
      length = bor lshift(byte(buf, 3), 8), byte(buf, 4)
      l = 4
    else if first == 127
      if #buf < 10 then return
      length = 0
      for i = 3, 10
        length = bor length, lshift(byte(buf, i), (10 - i) * 8)
      l = 10
    if masking
      return if #buf < l + 4
      key[1] = byte(buf, l + 1)
      key[2] = byte(buf, l + 2)
      key[3] = byte(buf, l + 3)
      key[4] = byte(buf, l + 4)
      l = l + 4
    if #buf < l + length
      return
    payload = sub buf, l + 1, l + length
    tbl = {}
    if masking
      for i = 1, length
        push tbl, bxor(byte(payload, i), key[(i - 1) % 4 + 1])
      payload = table_to_string tbl
    data = sub buf, l + length + 1
    if opcode == 1
      if @session and #payload > 0
        status, message = pcall decode, payload
        --d('DECODE', status, message)
        return @do_reasoned_close(1002, 'Broken framing.') if not status
        -- process message
        @session\onmessage message
      ondata()
      return
    else if opcode == 8
      if #payload >= 2
        status = bor lshift(byte(payload, 1), 8), byte(payload, 2)
      else
        status = 1002
      if #payload > 2
        reason = sub payload, 3
      else
        reason = 'Connection closed by user'
      @do_reasoned_close status, reason
    return
  @req\on 'data', ondata
  @send_frame = (payload, continue) =>
    pl = #payload
    a = {}
    push a, 128 + 1
    push a, 0x80 -- N.B. masking 0x80
    if pl < 126
      a[2] = bor a[2], pl
    else if pl < 65536
      a[2] = bor a[2], 126
      push a, rshift(pl, 8) % 256
      push a, pl % 256
    else
      for i = 1, 8
        push a, true
      pl2 = pl
      a[2] = bor a[2], 127
      for i = 10, 3, -1
        a[i] = pl2 % 256
        pl2 = rshift pl2, 8
    key = {rand256(), rand256(), rand256(), rand256()}
    push a, key[1]
    push a, key[2]
    push a, key[3]
    push a, key[4]
    for i = 1, pl
      push a, bxor(byte(payload, i), key[(i - 1) % 4 + 1])
    a = table_to_string a
    @write_frame a, continue
    return
  cb() if cb
