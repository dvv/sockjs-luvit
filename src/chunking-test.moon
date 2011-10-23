import date, time from require 'os'
import rep from require 'string'
import set_timeout from require 'timer'

--
-- chunking test
--

return {
{
  'POST (/.+)/chunking_test[/]?$'
  (nxt, root) =>
    options = @get_options(root)
    return nxt() if not options
    @handle_xhr_cors()
    @send 200, nil, {
      ['Content-Type']: 'application/javascript; charset=UTF-8' -- for FF
    }, false
    @on 'error', (err) ->
      -- TODO: generalize?
      p('CHUNKERRORRES', err)
      @finish()
    @write 'h\n'
    for k, delay in ipairs {1, 1+5, 25+5+1, 125+25+5+1, 625+125+25+5+1, 3125+625+125+25+5+1}
      set_timeout delay, () ->
        if k == 1
          @write (rep ' ', 2048) .. 'h\n'
        else
          @write 'h\n'
    return
}
{
  'OPTIONS (/.+)/chunking_test[/]?$'
  (nxt, root) =>
    options = @get_options(root)
    return nxt() if not options
    @handle_xhr_cors()
    @handle_balancer_cookie()
    @send 204, nil, {
      ['Allow']: 'OPTIONS, POST'
      ['Cache-Control']: 'public, max-age=${cache_age}' % options
      ['Expires']: date('%c', time() + options.cache_age)
      ['Access-Control-Max-Age']: tostring(options.cache_age)
    }
    return
}
}
