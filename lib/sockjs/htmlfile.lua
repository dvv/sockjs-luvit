local encode
do
  local _table_0 = require('cjson')
  encode = _table_0.encode
end
local gsub, rep
do
  local _table_0 = require('string')
  gsub = _table_0.gsub
  rep = _table_0.rep
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
handler = function(self, nxt, root, sid)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  self:handle_balancer_cookie()
  local callback = self.req.uri.query.c or self.req.uri.query.callback
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
  self.send_frame = function(self, payload)
    return self:write_frame('<script>\np(' .. encode(payload) .. ');\n</script>\r\n')
  end
  local session = self:get_session(sid, options)
  session:bind(self)
  return 
end
return {
  'GET (/.+)/[^./]+/([^./]+)/htmlfile[/]?$',
  handler
}
