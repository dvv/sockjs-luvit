require('lib/util')
local Stack = require('lib/stack')
local _error = error
local error
error = function(...)
  return p('BADBADBAD ERROR', ...)
end
local layers
layers = function()
  return {
    Stack.use('route')(Stack.use('sockjs')({
      prefix = '/echo',
      sockjs_url = '/public/sockjs.js',
      onconnection = function(conn)
        p('CONN')
        return conn:on('message', function(m)
          return conn:send(m)
        end)
      end
    })),
    Stack.use('route')({
      ['GET /$'] = function(self, nxt)
        return self:render('public/index.html', self.req.context)
      end
    }),
    Stack.use('static')('/public/', 'public/', { })
  }
end
local s1 = Stack(layers()):run(8080)
print('Server listening at http://localhost:8080/')
