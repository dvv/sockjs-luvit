String = require('string')
String.interpolate = function(self, data)
  if not data then
    return self
  end
  if type(data) == 'table' then
    if data[1] then
      return String.format(self, unpack(b))
    end
    return String.gsub(self, '($%b{})', function(w)
      local var = String.sub(w, 3, -2)
      local n, def = String.match(var, '([^|]-)|(.*)')
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
  return (String.gsub(str, '(.)', function(c)
    return String.format('%02x', String.byte(c))
  end))
end
String.fromhex = function(str)
  return (String.gsub(str, '(%x%x)', function(h)
    return String.format('%c', tonumber(h, 16))
  end))
end
String.escape = function(str)
  return String.gsub(str, '<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')
end
String.unescape = function(str)
  return str
end
String.url_decode = function(str)
  str = String.gsub(str, '+', ' ')
  str = String.gsub(str, '%%(%x%x)', function(h)
    return String.char(tonumber(h, 16))
  end)
  str = String.gsub(str, '\r\n', '\n')
  return str
end
String.url_encode = function(str)
  if str then
    str = String.gsub(str, '\n', '\r\n')
    str = String.gsub(str, '([^%w ])', function(c)
      return String.format('%%%02X', String.byte(c))
    end)
    str = String.gsub(str, ' ', '+')
  end
  return str
end
String.parse_query = function(str)
  local allvars = { }
  for pair in String.gmatch(tostring(str), '[^&]+') do
    local key, value = String.match(pair, '([^=]*)=(.*)')
    if key then
      allvars[key] = String.url_decode(value)
    end
  end
  return allvars
end
_G.Table = require('table')
_G.d = function(...)
  if env.DEBUG then
    return p(...)
  end
end
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
