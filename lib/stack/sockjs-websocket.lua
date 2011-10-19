local get_digest
do
  local _table_0 = require('openssl')
  get_digest = _table_0.get_digest
end
local floor
do
  local _table_0 = require('math')
  floor = _table_0.floor
end
local band, bor, rshift, lshift
do
  local _table_0 = require('bit')
  band = _table_0.band
  bor = _table_0.bor
  rshift = _table_0.rshift
  lshift = _table_0.lshift
end
local slice = String.sub
local JSON = require('cjson')
local validate_hixie76_crypto
validate_hixie76_crypto = function(req_headers, nonce)
  local k1 = req_headers['sec-websocket-key1']
  local k2 = req_headers['sec-websocket-key2']
  if not k1 or not k2 then
    return false
  end
  local md5 = get_digest('md5'):init()
  local u = ''
  local _list_0 = {
    k1,
    k2
  }
  for _index_0 = 1, #_list_0 do
    local k = _list_0[_index_0]
    local n = tonumber((String.gsub(k, '[^%d]', '')), 10)
    local spaces = #(String.gsub(k, '[^ ]', ''))
    if spaces == 0 or n % spaces ~= 0 then
      return false
    end
    n = n / spaces
    local s = String.fromhex(String.format('%08x', n))
    p('S!!', n, String.tohex(s), #s)
    u = u .. s
  end
  u = u .. nonce
  p('U', u, String.tohex(u), #u)
  md5:update(u)
  local a = md5:final()
  md5:cleanup()
  p('MD5', String.tohex(a))
  return a
end
local WebHandshakeHixie76
WebHandshakeHixie76 = function(self, origin, location, cb)
  p('SHAKE76', origin, location)
  self.sec = self.req.headers['sec-websocket-key1']
  local wsp = self.sec and self.req.headers['sec-websocket-protocol']
  local prefix = self.sec and 'Sec-' or ''
  local blob = {
    'HTTP/1.1 101 WebSocket Protocol Handshake',
    'Upgrade: WebSocket',
    'Connection: Upgrade',
    prefix .. 'WebSocket-Origin: ' .. origin,
    prefix .. 'WebSocket-Location: ' .. location
  }
  if wsp then
    Table.insert(blob, ('Sec-WebSocket-Protocol: ' .. self.req.headers['sec-websocket-protocol'].split('[^,]*')))
  end
  self:write(Table.concat(blob, '\r\n') .. '\r\n\r\n')
  local data = ''
  local ondata
  ondata = function(chunk)
    p('DATA', chunk)
    if chunk then
      data = data .. chunk
    end
    local buf = data
    if #buf == 0 then
      return 
    end
    if String.byte(buf, 1) == 0 then
      for i = 2, #buf do
        if String.byte(buf, i) == 255 then
          local payload = String.sub(buf, 2, i - 1)
          data = String.sub(buf, i + 1)
          if self.session and #payload > 0 then
            local status, messages = pcall(JSON.decode, payload)
            p('DECODE', payload, status, messages)
            if not status then
              return self:do_reasoned_close(1002, 'Broken framing.')
            end
            if type(messages) == 'table' then
              local _list_0 = messages
              for _index_0 = 1, #_list_0 do
                local message = _list_0[_index_0]
                self.session:onmessage(message)
              end
            else
              self.session:onmessage(messages)
            end
          end
          ondata()
          return 
        end
      end
      return 
    else
      if String.byte(buf, 1) == 255 and String.byte(buf, 2) == 0 then
        self:do_reasoned_close(1001, 'Socket closed by the client')
      else
        self:do_reasoned_close(1002, 'Broken framing')
      end
    end
    return 
  end
  local wait_for_nonce
  wait_for_nonce = function(chunk)
    p('WAIT', chunk, String.tohex(chunk))
    data = data .. chunk
    if self.sec == false or #data >= 8 then
      self:remove_listener('data', wait_for_nonce)
      if self.sec then
        local nonce = slice(data, 1, 8)
        data = slice(data, 9)
        local reply = validate_hixie76_crypto(self.req.headers, nonce)
        if not reply then
          p('NOTREPLY')
          self:do_reasoned_close()
          return 
        end
        p('REPLY', reply, #reply)
        self:on('data', ondata)
        local status, err = pcall(self.write, self, reply)
        p('REPLYWRITTEN', status, err)
        if cb then
          cb()
        end
      end
    end
    return 
  end
  self.req:on('data', wait_for_nonce)
  self.send_frame = function(self, payload)
    p('SEND', payload)
    return self:write_frame('\000' .. payload .. '\255')
  end
end
local verify_hybi_secret
verify_hybi_secret = function(key)
  local data = (String.match(key, '(%S+)')) .. '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
  local dg = get_digest('sha1'):init()
  dg:update(data)
  local r = dg:final()
  dg:cleanup()
  return r
end
local WebHandshake8
WebHandshake8 = function(self, origin, location, cb)
  p('SHAKE8', origin, location)
  local blob = {
    'HTTP/1.1 101 Switching Protocols',
    'Upgrade: WebSocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Accept: ' .. String.base64(verify_hybi_secret(self.req.headers['sec-websocket-key']))
  }
  if self.req.headers['sec-websocket-protocol'] then
    Table.insert(blob, ('Sec-WebSocket-Protocol: ' .. self.req.headers['sec-websocket-protocol'].split('[^,]*')))
  end
  self:write(Table.concat(blob, '\r\n') .. '\r\n\r\n')
  local data = ''
  local ondata
  ondata = function(chunk)
    p('DATA', chunk)
    if chunk then
      data = data .. chunk
    end
    local buf = data
    if #buf == 0 then
      return 
    end
    if String.byte(buf, 1) == 0 then
      for i = 2, #buf do
        if String.byte(buf, i) == 255 then
          local payload = String.sub(buf, 2, i - 1)
          data = String.sub(buf, i + 1)
          if self.session and #payload > 0 then
            local status, messages = pcall(JSON.decode, payload)
            p('DECODE', payload, status, messages)
            if not status then
              return self:do_reasoned_close(1002, 'Broken framing.')
            end
            if type(messages) == 'table' then
              local _list_0 = messages
              for _index_0 = 1, #_list_0 do
                local message = _list_0[_index_0]
                self.session:onmessage(message)
              end
            else
              self.session:onmessage(messages)
            end
          end
          ondata()
          return 
        end
      end
      return 
    else
      if String.byte(buf, 1) == 255 and String.byte(buf, 2) == 0 then
        self:do_reasoned_close(1001, 'Socket closed by the client')
      else
        self:do_reasoned_close(1002, 'Broken framing')
      end
    end
    return 
  end
  self.req:on('data', ondata)
  self.send_frame = function(self, payload)
    p('SEND', payload)
    return self:write_frame('\000' .. payload .. '\255')
  end
end
return {
  WebHandshakeHixie76 = WebHandshakeHixie76,
  WebHandshake8 = WebHandshake8
}
