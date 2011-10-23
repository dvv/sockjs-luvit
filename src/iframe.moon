import date, time from require 'os'
import gsub from require 'string'

--
-- iframe template
--
iframe_template = [[
<!DOCTYPE html>
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

--
-- iframe request handler
--
handler = (nxt, root) =>
  options = @get_options(root)
  return nxt() if not options
  content = gsub iframe_template, '{{ sockjs_url }}', options.sockjs_url
  etag = tostring(#content) -- TODO: more advanced hash needed
  return @send 304 if @req.headers['if-none-match'] == etag
  @send 200, content, {
    ['Content-Type']: 'text/html; charset=UTF-8'
    ['Content-Length']: #content
    ['Cache-Control']: 'public, max-age=${cache_age}' % options
    ['Expires']: date('%c', time() + options.cache_age)
    ['Etag']: etag
  }
  return

return {
  'GET (/.+)/iframe([0-9-.a-z_]*)%.html$'
  handler
}
