import date, time from require 'os'
import rep from require 'string'
import set_timeout from require 'timer'

--
-- chunking test
--

return {

  POST1: (options) =>
    @handle_xhr_cors()
    @send 200, nil, {
      ['Content-Type']: 'application/javascript; charset=UTF-8' -- for FF
    }, false
    delays = {1, 5, 25, 125, 625, 3125}
    send = (k) ->
      if k == 2
        @write (rep ' ', 2048) .. 'h\n'
      else
        @write 'h\n'
      if k == 7
        @finish() if not @closed
      else
        set_timeout delays[k], send, k + 1
      return
    send 1
    return

  POST: (options) =>
    @handle_xhr_cors()
    @set_code 200
    @set_header 'Content-Type', 'application/javascript; charset=UTF-8' -- for FF
    delays = {1, 5, 25, 125, 625, 3125}
    send = (k) ->
      if k == 2
        @write (rep ' ', 2048) .. 'h\n'
      else
        @write 'h\n'
      if k == 7
        p('CHUNKINGDONE')
        @finish() if not @closed
      else
        set_timeout delays[k], send, k + 1
      return
    send 1
    return

  OPTIONS: (options) =>
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
