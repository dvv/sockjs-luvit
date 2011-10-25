#!/usr/bin/env luvit

local ffi = require('ffi')
local format = require('string').format
local C = ffi.C
ffi.cdef[[
void uuid(uint8_t *buf);
]]
local function uuid(raw)
  local buf = ffi.new("uint8_t[?]", 16)
  C.uuid(buf)
  if raw then
    return ffi.string(buf, 16)
  else
    return format('%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', buf[0], buf[1], buf[2], buf[3], buf[4], buf[5], buf[6], buf[7], buf[8], buf[9], buf[10], buf[11], buf[12], buf[13], buf[14], buf[15])
  end
end

p(uuid())
