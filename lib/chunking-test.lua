local date, time
do
  local _table_0 = require('os')
  date, time = _table_0.date, _table_0.time
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
  POST1 = function(self, options)
    self:handle_xhr_cors()
    self:send(200, nil, {
      ['Content-Type'] = 'application/javascript; charset=UTF-8'
    }, false)
    local delays = {
      1,
      5,
      25,
      125,
      625,
      3125
    }
    local send
    send = function(k)
      if k == 2 then
        self:write((rep(' ', 2048)) .. 'h\n')
      else
        self:write('h\n')
      end
      if k == 7 then
        if not self.closed then
          self:finish()
        end
      else
        set_timeout(delays[k], send, k + 1)
      end
      return 
    end
    send(1)
    return 
  end,
  POST = function(self, options)
    self:handle_xhr_cors()
    self:set_code(200)
    self:set_header('Content-Type', 'application/javascript; charset=UTF-8')
    local delays = {
      1,
      5,
      25,
      125,
      625,
      3125
    }
    local send
    send = function(k)
      if k == 2 then
        self:write((rep(' ', 2048)) .. 'h\n')
      else
        self:write('h\n')
      end
      if k == 7 then
        p('CHUNKINGDONE')
        if not self.closed then
          self:finish()
        end
      else
        set_timeout(delays[k], send, k + 1)
      end
      return 
    end
    send(1)
    return 
  end,
  OPTIONS = function(self, options)
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
