local Server = require('server')
local SockJS = require('sockjs-luvit')

local String = require('string')
local Math = require('math')

local http_stack_layers
http_stack_layers = function()
  return {
    Server.use('route')({
      {
        'GET /$',
        function(self, nxt)
          return self:render('public/index.html', self.req.context)
        end
      }
    }),
    SockJS('/echo', {
      sockjs_url = '/sockjs.js',
      onconnection = function(conn)
        p('CONNECTED TO /echo', conn, conn.sid, conn.id)
        conn:on('message', function(m)
          conn:send(m)
        end)
        conn:on('close', function()
          p('DISCONNECTED FROM /echo', conn.sid, conn.id)
        end)
      end
    }),
    SockJS('/close', {
      sockjs_url = '/sockjs.js',
      onconnection = function(conn)
        p('CONNC', conn.sid, conn.id)
        return conn:close(3000, 'Go away!')
      end
    }),
    SockJS('/disabled_websocket_echo', {
      sockjs_url = '/sockjs.js',
      disabled_transports = {'websocket'},
      onconnection = function(conn)
        p('CONNECTED TO /echo', conn.sid, conn.id)
        conn:on('message', function(m)
          conn:send(m)
        end)
        conn:on('close', function()
          p('DISCONNECTED FROM /echo', conn.sid, conn.id)
        end)
      end
    }),
    SockJS('/amplify', {
      sockjs_url = '/sockjs.js',
      onconnection = function(conn)
        p('CONNA', conn.sid, conn.id)
        conn:on('message', function(m)
          local n
          status, n = pcall(Math.floor, tonumber(m, 10))
          if not status then
            error(m)
          end
          n = (n > 0 and n < 19) and n or 1
          conn:send(String.rep('x', Math.pow(2, n)))
        end)
      end
    }),
    Server.use('static')('/', 'public/', { }),
  }
end

local s1 = Server.run(http_stack_layers(), 8080, '0.0.0.0')
print('Server listening at http://localhost:8080/')
