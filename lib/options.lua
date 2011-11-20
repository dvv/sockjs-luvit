local date, time
do
  local _table_0 = require('os')
  date, time = _table_0.date, _table_0.time
end
return function(self, options)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  self:send(204, nil, {
    ['Allow'] = 'OPTIONS, POST',
    ['Cache-Control'] = 'public, max-age=${cache_age}' % options,
    ['Expires'] = date('%c', time() + options.cache_age),
    ['Access-Control-Max-Age'] = tostring(options.cache_age)
  })
  return 
end
