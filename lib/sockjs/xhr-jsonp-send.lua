local decode
do
  local _table_0 = require('cjson')
  decode = _table_0.decode
end
local match, parse_query
do
  local _table_0 = require('string')
  match = _table_0.match
  parse_query = _table_0.parse_query
end
local push = require('table').insert
local join = require('table').concat
local allowed_content_types = {
  xhr = {
    ['application/json'] = decode,
    ['text/plain'] = decode,
    ['application/xml'] = decode,
    ['T'] = decode,
    [''] = decode
  },
  jsonp = {
    ['application/x-www-form-urlencoded'] = parse_query,
    ['text/plain'] = true,
    [''] = true
  }
}
local Session = require('./transport')
local handler
handler = function(self, nxt, root, sid, transport)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  local xhr = transport == 'xhr'
  if xhr then
    self:handle_xhr_cors()
  end
  self:handle_balancer_cookie()
  self.auto_chunked = false
  local ctype = self.req.headers['content-type'] or ''
  ctype = match(ctype, '[^;]*')
  local decoder = allowed_content_types[transport][ctype]
  if not decoder then
    return self:fail('Payload expected.')
  end
  local session = Session.get(sid)
  if not session then
    return self:send(404)
  end
  local data = { }
  self.req:on('data', function(chunk)
    push(data, chunk)
    return 
  end)
  self.req:on('end', function()
    data = join(data, '')
    if data == '' then
      return self:fail('Payload expected.')
    end
    if not xhr then
      if decoder ~= true then
        data = decoder(data).d or ''
      end
      if data == '' then
        return self:fail('Payload expected.')
      end
    end
    local status
    status, data = pcall(decode, data)
    if not status then
      return self:fail('Broken JSON encoding.')
    end
    if not is_array(data) then
      return self:fail('Payload expected.')
    end
    local _list_0 = data
    for _index_0 = 1, #_list_0 do
      local message = _list_0[_index_0]
      session:onmessage(message)
    end
    if xhr then
      self:send(204, nil, {
        ['Content-Type'] = 'text/plain'
      })
    else
      self.auto_content_type = false
      self:send(200, 'ok', {
        ['Content-Length'] = 2
      })
    end
    return 
  end)
  self.req:on('error', function(err)
    error(err)
    return 
  end)
  return 
end
return {
  'POST (/.+)/[^./]+/([^./]+)/(%w+)_send[/]?$',
  handler
}
