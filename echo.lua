require('./lib/util')
local Stack = require('./lib/stack')
local SockJS = require('./lib/sockjs')

local Math = require('math')

local http_stack_layers
http_stack_layers = function()
  return {
    Stack.use('route')({
      {
        'GET /$',
        function(self, nxt)
          return self:render('public/index.html', self.req.context)
        end
      }
    }),
    Stack.use('static')('/public/', 'public/', { }),
    SockJS()
  }
end

SockJS('/echo', {
  sockjs_url = '/public/sockjs.js',
  onconnection = function(conn)
    p('CONNE', conn.sid, conn.id)
    return conn:on('message', function(m)
      return conn:send(m)
    end)
  end
})

SockJS('/close', {
  sockjs_url = '/public/sockjs.js',
  onconnection = function(conn)
    p('CONNC', conn.sid, conn.id)
    return conn:close(3000, 'Go away!')
  end
})

SockJS('/amplify', {
  sockjs_url = '/public/sockjs.js',
  onconnection = function(conn)
    p('CONNA', conn.sid, conn.id)
    conn:on('message', function(m)
      local n
      status, n = pcall(Math.floor, tonumber(m, 10))
      if not status then
        p('MATH FAILED', m, n)
        error(m)
      end
      p('MATH', m, n)
      n = (n > 0 and n < 19) and n or 1
      conn:send(String.rep('x', Math.pow(2, n)))
    end)
  end
})

local s1 = Stack(http_stack_layers()):run(8080)
print('Server listening at http://localhost:8080/')
