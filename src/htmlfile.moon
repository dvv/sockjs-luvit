import encode from JSON
import gsub, rep from require 'string'

--
-- template
--
htmlfile_template = [[
<!doctype html>
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

-- Safari needs at least 1024 bytes to parse the website. Relevant:
-- http://code.google.com/p/browsersec/wiki/Part2#Survey_of_content_sniffing_behaviors
htmlfile_template = htmlfile_template .. rep(' ', 1024 - #htmlfile_template + 14) .. '\r\n\r\n'

--
-- htmlfile request handler
--
handler = (nxt, root, sid) =>
  options = @get_options root
  return nxt() if not options
  @handle_balancer_cookie()
  callback = @req.uri.query.c or @req.uri.query.callback
  return @fail '"callback" parameter required' if not callback
  content = gsub htmlfile_template, '{{ callback }}', callback
  @send 200, content, {
    ['Content-Type']: 'text/html; charset=UTF-8'
    ['Cache-Control']: 'no-store, no-cache, must-revalidate, max-age=0'
  }, false
  -- upgrade response to session handler
  @protocol = 'htmlfile'
  @curr_size, @max_size = 0, options.response_limit
  @send_frame = (payload, continue) =>
    @write_frame('<script>\np(' .. encode(payload) .. ');\n</script>\r\n', continue)
  -- register session
  session = @create_session sid, options
  session\bind self
  return

return {
  'GET (/.+)/[^./]+/([^./]+)/htmlfile[/]?$'
  handler
}
