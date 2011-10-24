String = require('string')
local sub, match, gsub, gmatch, byte, char, format = String.sub, String.match, String.gsub, String.gmatch, String.byte, String.char, String.format
String.interpolate = function(self, data)
  if not data then
    return self
  end
  if type(data) == 'table' then
    if data[1] then
      return format(self, unpack(b))
    end
    return gsub(self, '($%b{})', function(w)
      local var = sub(w, 3, -2)
      local n, def = match(var, '([^|]-)|(.*)')
      if n then
        var = n
      end
      local s = type(data[var]) == 'function' and data[var]() or data[var] or def or w
      s = String.escape(s)
      return s
    end)
  else
    return String.format(self, data)
  end
end
getmetatable('').__mod = String.interpolate
String.tohex = function(str)
  return (gsub(str, '(.)', function(c)
    return format('%02x', byte(c))
  end))
end
String.fromhex = function(str)
  return (gsub(str, '(%x%x)', function(h)
    local n = tonumber(h, 16)
    if n ~= 0 then
      return format('%c', n)
    else
      return '\000'
    end
  end))
end
local base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
String.base64 = function(data)
  return ((gsub(data, '.', function(x)
    local r, b = '', byte(x)
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then
      return ''
    end
    local c = 0
    for i = 1, 6 do
      c = c + (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return sub(base64_table, c + 1, c + 1)
  end) .. ({
    '',
    '==',
    '='
  })[#data % 3 + 1])
end
String.escape = function(str)
  return gsub(str, '<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')
end
String.unescape = function(str)
  return str
end
String.url_decode = function(str)
  str = gsub(str, '+', ' ')
  str = gsub(str, '%%(%x%x)', function(h)
    return char(tonumber(h, 16))
  end)
  str = gsub(str, '\r\n', '\n')
  return str
end
String.url_encode = function(str)
  if str then
    str = gsub(str, '\n', '\r\n')
    str = gsub(str, '([^%w ])', function(c)
      return format('%%%02X', byte(c))
    end)
    str = gsub(str, ' ', '+')
  end
  return str
end
String.parse_query = function(str)
  local allvars = { }
  for pair in gmatch(tostring(str), '[^&]+') do
    local key, value = match(pair, '([^=]*)=(.*)')
    if key then
      allvars[key] = String.url_decode(value)
    end
  end
  return allvars
end
_G.Table = require('table')
_G.is_array = function(obj)
  return type(obj) == 'table' and Table.maxn(obj) > 0
end
_G.is_hash = function(obj)
  return type(obj) == 'table' and Table.maxn(obj) == 0
end
_G.copy = function(obj)
  if type(obj) ~= 'table' then
    return obj
  end
  local x = { }
  setmetatable(x, {
    __index = obj
  })
  return x
end
_G.clone = function(obj)
  local copied = { }
  local new = { }
  copied[obj] = new
  for k, v in pairs(obj) do
    if type(v) ~= 'table' then
      new[k] = v
    elseif copied[v] then
      new[k] = copied[v]
    else
      copied[v] = clone(v, copied)
      new[k] = setmetatable(copied[v], getmetatable(v))
    end
  end
  setmetatable(new, getmetatable(u))
  return new
end
_G.extend = function(obj, with_obj)
  for k, v in pairs(with_obj) do
    obj[k] = v
  end
  return obj
end
_G.extend_unless = function(obj, with_obj)
  for k, v in pairs(with_obj) do
    if obj[k] == nil then
      obj[k] = v
    end
  end
  return obj
end
_G.JSON = require('json')
if process.env.DEBUG == '1' then
  _G.d = function(...)
    return debug('DEBUG', ...)
  end
else
  _G.d = function() end
end
