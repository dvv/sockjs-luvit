local get_digest
do
  local _table_0 = require('server/modules/crypto')
  get_digest = _table_0.get_digest
end
local floor, random
do
  local _table_0 = require('math')
  floor, random = _table_0.floor, _table_0.random
end
local band, bor, bxor, rshift, lshift
do
  local _table_0 = require('bit')
  band, bor, bxor, rshift, lshift = _table_0.band, _table_0.bor, _table_0.bxor, _table_0.rshift, _table_0.lshift
end
local sub, gsub, match, byte, char
do
  local _table_0 = require('string')
  sub, gsub, match, byte, char = _table_0.sub, _table_0.gsub, _table_0.match, _table_0.byte, _table_0.char
end
local encode, decode = JSON.encode, JSON.decode
local validate_secret
validate_secret = function(req_headers, nonce)
  local k1 = req_headers['sec-websocket-key1']
  local k2 = req_headers['sec-websocket-key2']
  if not k1 or not k2 then
    return false
  end
  local dg = get_digest('md5'):init()
  local _list_0 = {
    k1,
    k2
  }
  for _index_0 = 1, #_list_0 do
    local k = _list_0[_index_0]
    local n = tonumber((gsub(k, '[^%d]', '')), 10)
    local spaces = #(gsub(k, '[^ ]', ''))
    if spaces == 0 or n % spaces ~= 0 then
      return false
    end
    n = n / spaces
    dg:update(char(rshift(n, 24) % 256, rshift(n, 16) % 256, rshift(n, 8) % 256, n % 256))
  end
  dg:update(nonce)
  local r = dg:final()
  dg:cleanup()
  return r
end
return function(self, origin, location, cb)
  self.sec = self.req.headers['sec-websocket-key1']
  local prefix = self.sec and 'Sec-' or ''
  local protocol = self.req.headers['sec-websocket-protocol']
  if protocol then
    protocol = (match(protocol, '[^,]*'))
  end
  self:write_head(101, {
    ['Upgrade'] = 'WebSocket',
    ['Connection'] = 'Upgrade',
    [prefix .. 'WebSocket-Origin'] = origin,
    [prefix .. 'WebSocket-Location'] = location,
    ['Sec-WebSocket-Protocol'] = protocol
  })
  self.has_body = true
  local data = ''
  local ondata
  ondata = function(chunk)
    if chunk then
      data = data .. chunk
    end
    local buf = data
    if #buf == 0 then
      return 
    end
    if byte(buf, 1) == 0 then
      for i = 2, #buf do
        if byte(buf, i) == 255 then
          local payload = sub(buf, 2, i - 1)
          data = sub(buf, i + 1)
          if self.session and #payload > 0 then
            local status, message = pcall(JSON.decode, payload)
            if not status then
              return self:do_reasoned_close(1002, 'Broken framing.')
            end
            self.session:onmessage(message)
          end
          ondata()
          return 
        end
      end
      return 
    else
      if byte(buf, 1) == 255 and byte(buf, 2) == 0 then
        self:do_reasoned_close(1001, 'Socket closed by the client')
      else
        self:do_reasoned_close(1002, 'Broken framing')
      end
    end
    return 
  end
  self.req:once('data', function(chunk)
    data = data .. chunk
    if self.sec == false or #data >= 8 then
      if self.sec then
        local nonce = sub(data, 1, 8)
        data = sub(data, 9)
        local reply = validate_secret(self.req.headers, nonce)
        if not reply then
          self:do_reasoned_close()
          return 
        end
        self:on('data', ondata)
        self:write(reply)
        if cb then
          cb()
        end
      end
    end
    return 
  end)
  self.send_frame = function(self, payload, continue)
    self:write_frame('\000' .. payload .. '\255', continue)
    return 
  end
end
