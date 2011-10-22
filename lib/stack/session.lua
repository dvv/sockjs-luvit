local date, time
do
  local _table_0 = require('os')
  date = _table_0.date
  time = _table_0.time
end
local get_cipher, get_digest
do
  local _table_0 = require('openssl')
  get_cipher = _table_0.get_cipher
  get_digest = _table_0.get_digest
end
local encode, decode
do
  local _table_0 = require('cjson')
  encode = _table_0.encode
  decode = _table_0.decode
end
local module = { }
local expires_in
expires_in = function(ttl)
  return date('%c', time() + ttl)
end
local sign
sign = function(secret, data)
  local digest = get_digest('sha1', secret)
  local mdc = digest:init()
  mdc:update(data)
  return String.tohex(mdc:final())
end
local encrypt
encrypt = function(secret, data)
  local cipher = get_cipher('aes192')
  return String.tohex(cipher:encrypt(data, secret))
end
local uncrypt
uncrypt = function(secret, data)
  local cipher = get_cipher('aes192')
  return cipher:decrypt(String.fromhex(data), secret)
end
local serialize
serialize = function(secret, obj)
  local str = encode(obj)
  local str_enc = encrypt(secret, str)
  local timestamp = time()
  local hmac_sig = sign(secret, timestamp .. str_enc)
  local result = hmac_sig .. timestamp .. str_enc
  return result
end
local deserialize
deserialize = function(secret, ttl, str)
  local hmac_signature = String.sub(str, 1, 40)
  local timestamp = tonumber(String.sub(str, 41, 50), 10)
  local data = String.sub(str, 51)
  local hmac_sig = sign(secret, timestamp .. data)
  if hmac_signature ~= hmac_sig or timestamp + ttl <= time() then
    return nil
  end
  data = uncrypt(secret, data)
  return decode(data)
end
module.read_session = function(key, secret, ttl, req)
  local cookie = type(req) == 'string' and req or req.headers.cookie
  if cookie then
    cookie = String.match(cookie, '%s*;*%s*' .. key .. '=(%w*)')
    if cookie and cookie ~= '' then
      return deserialize(secret, ttl, cookie)
    end
  end
  return nil
end
if false then
  local secret = 'foo-bar-baz$'
  local obj = {
    a = {
      foo = 123,
      bar = "456"
    },
    b = {
      1,
      2,
      nil,
      3
    },
    c = false,
    d = 0
  }
  local ser = serialize(secret, obj)
  p(ser)
  local deser = deserialize(secret, 1, ser)
  p(deser, deser == obj)
end
return function(options)
  if options == nil then
    options = { }
  end
  local key = options.key or 'sid'
  local ttl = options.ttl or 15 * 24 * 60 * 60 * 1000
  local secret = options.secret
  local context = options.context or { }
  return function(req, res, nxt)
    req.session = module.read_session(key, secret, ttl, req)
    local _write_head = res.write_head
    res.write_head = function(self, status, headers)
      local cookie = nil
      if not req.session then
        if req.headers.cookie then
          cookie = String.format('%s=; expires=; httponly; path=/', key, expires_in(0))
        end
      else
        cookie = String.format('%s=%s; expires=; httponly; path=/', key, serialize(secret, req.session), expires_in(ttl))
      end
      if cookie then
        if not headers then
          headers = { }
        end
        headers['Set-Cookie'] = cookie
      end
      return _write_head(self, status, headers)
    end
    if options.default_session and not req.session then
      req.session = options.default_session
    end
    if options.authorize then
      return options.authorize(req.session, function(context)
        req.context = context or { }
        return nxt()
      end)
    else
      req.context = context.guest or { }
      if req.session and req.session.uid then
        req.context = context.user or req.context
      end
      return nxt()
    end
  end
end
