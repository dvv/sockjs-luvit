import date, time from require 'os'

--
-- xhr transport OPTIONS request handler
--
return (options) =>
    @handle_xhr_cors()
    @handle_balancer_cookie()
    @send 204, nil, {
      ['Allow']: 'OPTIONS, POST'
      ['Cache-Control']: 'public, max-age=${cache_age}' % options
      ['Expires']: date('%c', time() + options.cache_age)
      ['Access-Control-Max-Age']: tostring(options.cache_age)
    }
    return
