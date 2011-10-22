local date, time
do
  local _table_0 = require('os')
  date = _table_0.date
  time = _table_0.time
end
local gsub
do
  local _table_0 = require('string')
  gsub = _table_0.gsub
end
local iframe_template = [[<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script>
    document.domain = document.domain;
    _sockjs_onload = function(){SockJS.bootstrap_iframe();};
  </script>
  <script src="{{ sockjs_url }}"></script>
</head>
<body>
  <h2>Don't panic!</h2>
  <p>This is a SockJS hidden iframe. It's used for cross domain magic.</p>
</body>
</html>
]]
local handler
handler = function(self, nxt, root)
  local options = self:get_options(root)
  if not options then
    return nxt()
  end
  local content = gsub(iframe_template, '{{ sockjs_url }}', options.sockjs_url)
  local etag = tostring(#content)
  if self.req.headers['if-none-match'] == etag then
    return self:send(304)
  end
  self:send(200, content, {
    ['Content-Type'] = 'text/html; charset=UTF-8',
    ['Content-Length'] = #content,
    ['Cache-Control'] = 'public, max-age=${cache_age}' % options,
    ['Expires'] = date('%c', time() + options.cache_age),
    ['Etag'] = etag
  })
  return 
end
return {
  'GET (/.+)/iframe([0-9-.a-z_]*)%.html$',
  handler
}
