local ffi = require('ffi')
local format = require('string').format

ffi.cdef[[
void uuid(uint8_t *buf);
]]
local uuid_lib = ffi.load(__dirname .. '/uuid.luvit')

local function uuid(raw)
  local buf = ffi.new("uint8_t[?]", 16)
  uuid_lib.uuid(buf)
  if raw then
    return ffi.string(buf, 16)
  else
    -- TODO: move to C?
    return format('%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', buf[0], buf[1], buf[2], buf[3], buf[4], buf[5], buf[6], buf[7], buf[8], buf[9], buf[10], buf[11], buf[12], buf[13], buf[14], buf[15])
  end
end

return uuid
