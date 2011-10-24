-----------------------------------------------------------
--
-- string helpers
--
-----------------------------------------------------------

export String
String = require 'string'

import sub, match, gsub, gmatch, byte, char, format from String

-- interpolation
String.interpolate = (data) =>
  return self if not data
  if type(data) == 'table'
    return format(self, unpack(b)) if data[1]
    return gsub self, '($%b{})', (w) ->
      var = sub w, 3, -2
      n, def = match var, '([^|]-)|(.*)'
      var = n if n
      s = type(data[var]) == 'function' and data[var]() or data[var] or def or w
      s = String.escape s
      s
  else
    String.format self, data

getmetatable('').__mod = String.interpolate

String.tohex = (str) ->
  (gsub str, '(.)', (c) -> format('%02x', byte(c)))

String.fromhex = (str) ->
  (gsub str, '(%x%x)', (h) ->
    n = tonumber h, 16
    if n != 0 then format('%c', n) else '\000')

--
-- base64 encoding
-- Thanks: http://lua-users.org/wiki/BaseSixtyFour
--

-- character table string
base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

String.base64 = (data) ->
  ((gsub(data, '.', (x) ->
    r, b = '', byte(x)
    for i = 8, 1, -1
      r = r .. (b%2^i - b%2^(i - 1) > 0 and '1' or '0')
    r) .. '0000')\gsub('%d%d%d?%d?%d?%d?', (x) ->
    return '' if #x < 6
    c = 0
    for i = 1, 6
      c = c + (sub(x, i, i) == '1' and 2^(6 - i) or 0)
    sub(base64_table, c + 1, c + 1)) .. ({'', '==', '='})[#data % 3 + 1])

String.escape = (str) ->
  -- TODO: escape HTML entities
  --return self:gsub('&%w+;', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;')
  -- TODO: escape &
  gsub(str, '<', '&lt;')\gsub('>', '&gt;')\gsub('"', '&quot;')

String.unescape = (str) ->
  -- TODO: unescape HTML entities
  str

String.url_decode = (str) ->
  str = gsub str, '+', ' '
  str = gsub str, '%%(%x%x)', (h) -> char tonumber(h,16)
  str = gsub str, '\r\n', '\n'
  str

String.url_encode = (str) ->
  if str
    str = gsub str, '\n', '\r\n'
    str = gsub str, '([^%w ])', (c) -> format '%%%02X', byte(c)
    str = gsub str, ' ', '+'
  str

String.parse_query = (str) ->
  allvars = {}
  for pair in gmatch tostring(str), '[^&]+'
      key, value = match pair, '([^=]*)=(.*)'
      if key
          allvars[key] = String.url_decode value
  allvars

-----------------------------------------------------------
--
-- collection of various helpers. when critical mass will accumulated
-- they should go to some lib file
--
-----------------------------------------------------------

_G.Table = require 'table'

-- is object an array
_G.is_array = (obj) -> type(obj) == 'table' and Table.maxn(obj) > 0

-- is object a hash
_G.is_hash = (obj) -> type(obj) == 'table' and Table.maxn(obj) == 0

-- shallow copy
_G.copy = (obj) ->
  return obj if type(obj) != 'table'
  x = {}
  setmetatable x, __index: obj
  x

-- deep copy of a table
-- FIXME: that's a blind copy-paste, needs testing
_G.clone = (obj) ->
  copied = {}
  new = {}
  copied[obj] = new
  for k, v in pairs(obj)
    if type(v) != 'table'
      new[k] = v
    elseif copied[v]
      new[k] = copied[v]
    else
      copied[v] = clone v, copied
      new[k] = setmetatable copied[v], getmetatable v
  setmetatable new, getmetatable u
  new

_G.extend = (obj, with_obj) ->
  for k, v in pairs(with_obj)
    obj[k] = v
  obj

_G.extend_unless = (obj, with_obj) ->
  for k, v in pairs(with_obj)
    obj[k] = v if obj[k] == nil
  obj

-----------------------------------------------------------
--
-- JSON
--
-----------------------------------------------------------

_G.JSON = require 'json'

-----------------------------------------------------------
--
-- Debug
--
-----------------------------------------------------------

if process.env.DEBUG == '1'
  _G.d = (...) -> debug('DEBUG', ...)
else
  _G.d = () -> 
