local date, time
do
  local _table_0 = require('os')
  date = _table_0.date
  time = _table_0.time
end
local rep
do
  local _table_0 = require('string')
  rep = _table_0.rep
end
local set_timeout
do
  local _table_0 = require('timer')
  set_timeout = _table_0.set_timeout
end
return {
  {
    'POST (/.+)/chunking_test[/]?$',
    function(self, nxt, root)
      local options = self:get_options(root)
      if not options then
        return nxt()
      end
      self:handle_xhr_cors()
      self:send(200, nil, {
        ['Content-Type'] = 'application/javascript; charset=UTF-8'
      }, false)
      self:on('error', function(err)
        p('CHUNKERRORRES', err)
        return self:finish()
      end)
      self:write('h\n')
      for k, delay in ipairs({
        1,
        1 + 5,
        25 + 5 + 1,
        125 + 25 + 5 + 1,
        625 + 125 + 25 + 5 + 1,
        3125 + 625 + 125 + 25 + 5 + 1
      }) do
        set_timeout(delay, function()
          if k == 1 then
            return self:write((rep(' ', 2048)) .. 'h\n')
          else
            return self:write('h\n')
          end
        end)
      end
      return 
    end
  },
  {
    'OPTIONS (/.+)/chunking_test[/]?$',
    function(self, nxt, root)
      local options = self:get_options(root)
      if not options then
        return nxt()
      end
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
  }
}
