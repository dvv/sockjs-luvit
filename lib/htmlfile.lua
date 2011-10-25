local encode = JSON.encode
local gsub, rep, parse_query
do
  local _table_0 = require('string')
  gsub = _table_0.gsub
  rep = _table_0.rep
  parse_query = _table_0.parse_query
end
local htmlfile_template = [[<!doctype html>
<html><head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head><body><h2>Don't panic!</h2>
  <script>
    document.domain = document.domain;
    var c = parent.{{ callback }};
    c.start();
    function p(d) {c.message(d);};
    window.onload = function() {c.stop();};
  </script>
]]
htmlfile_template = htmlfile_template .. rep(' ', 1024 - #htmlfile_template + 14) .. '\r\n\r\n'
local handler
handler = function(self, options, sid)
  self:handle_balancer_cookie()
  local query = parse_query(self.req.uri.query)
  local callback = query.c or query.callback
  if not callback then
    return self:fail('"callback" parameter required')
  end
  local content = gsub(htmlfile_template, '{{ callback }}', callback)
  self:send(200, content, {
    ['Content-Type'] = 'text/html; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'htmlfile'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function(self, payload, continue)
    return self:write_frame('<script>\np(' .. encode(payload) .. ');\n</script>\r\n', continue)
  end
  local session = self:create_session(sid, options)
  session:bind(self)
  return 
end
return {
  GET = handler
}
