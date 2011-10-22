local EventEmitter = setmetatable({ }, {
  __index = require('emitter').meta
})
local set_timeout, clear_timer
do
  local _table_0 = require('timer')
  set_timeout = _table_0.set_timeout
  clear_timer = _table_0.clear_timer
end
local JSON = require('cjson')
local Table = require('table')
local Transport = {
  CONNECTING = 0,
  OPEN = 1,
  CLOSING = 2,
  CLOSED = 3,
  closing_frame = function(status, reason)
    return 'c' .. JSON.encode({
      status,
      reason
    })
  end
}
local sessions = { }
_G.s = function()
  return sessions
end
_G.f = function()
  sessions = { }
end
local Session
Session = (function()
  local _parent_0 = EventEmitter
  local _base_0 = {
    get = function(sid)
      return sessions[sid]
    end,
    get_or_create = function(sid, options)
      local session = Session.get(sid)
      if not session then
        session = Session(sid, options)
      end
      return session
    end,
    bind = function(self, recv)
      p('BIND', self.sid, self.id)
      if self.recv then
        p('ALREADY REGISTERED!!!')
        recv:send_frame(Transport.closing_frame(2010, 'Another connection still open'))
        return 
      end
      if self.readyState == Transport.CLOSING then
        p('STATEISCLOSING', self.close_frame)
        recv:send_frame(self.close_frame)
        if self.to_tref then
          clear_timer(self.to_tref)
        end
        self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
        self.TO = 'TIMEOUTINREGISTER1'
        return 
      end
      p('DOREGISTER', self.readyState)
      self.recv = recv
      self.recv.session = self
      self.recv:once('closed', function()
        p('CLOSEDEVENT')
        return self:unbind()
      end)
      self.recv:once('end', function()
        p('END')
        return self:unbind()
      end)
      self.recv:once('error', function(err)
        p('ERROR', err)
        return self.recv:finish()
      end)
      if self.readyState == Transport.CONNECTING then
        self.recv:send_frame('o')
        self.readyState = Transport.OPEN
        set_timeout(0, self.emit_connection_event)
      end
      if self.to_tref then
        clear_timer(self.to_tref)
        self.TO = 'CLEAREDINREGISTER:' .. self.TO
        self.to_tref = nil
      end
      if self.recv then
        self:flush()
      end
      return 
    end,
    unbind = function(self)
      p('UNREGISTER', self.sid, self.id, not not self.recv)
      if self.recv then
        self.recv.session = nil
        self.recv = nil
      end
      if self.to_tref then
        clear_timer(self.to_tref)
      end
      self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
      self.TO = 'TIMEOUTINUNREGISTER'
      return 
    end,
    close = function(self, status, reason)
      if status == nil then
        status = 1000
      end
      if reason == nil then
        reason = 'Normal closure'
      end
      if self.readyState ~= Transport.OPEN then
        return false
      end
      self.readyState = Transport.CLOSING
      self.close_frame = Transport.closing_frame(status, reason)
      if self.recv then
        self.recv:send_frame(self.close_frame)
        self:unbind()
      end
      return 
    end,
    ontimeout = function(self)
      p('TIMEDOUT', self.sid, self.recv)
      if self.to_tref then
        clear_timer(self.to_tref)
        self.to_tref = nil
      end
      if self.readyState ~= Transport.CONNECTING and self.readyState ~= Transport.OPEN and self.readyState ~= Transport.CLOSING then
        error('INVALID_STATE_ERR')
      end
      if self.recv then
        error('RECV_STILL_THERE')
      end
      self.readyState = Transport.CLOSED
      self:emit('close')
      if self.sid then
        sessions[self.sid] = nil
        self.sid = nil
      end
      return 
    end,
    onmessage = function(self, payload)
      if self.readyState == Transport.OPEN then
        p('MESSAGE', payload)
        self:emit('message', payload)
      end
      return 
    end,
    send = function(self, payload)
      if self.readyState ~= Transport.OPEN then
        return false
      end
      Table.insert(self.send_buffer, type(payload) == 'table' and Table.concat(payload, ',') or tostring(payload))
      if self.recv then
        self:flush()
      end
      return true
    end,
    flush = function(self)
      p('INFLUSH', self.send_buffer)
      if #self.send_buffer > 0 then
        local messages = self.send_buffer
        self.send_buffer = { }
        self.recv:send_frame('a' .. JSON.encode(messages))
      else
        p('TOTREF?', self.TO, self.to_tref)
        local _ = [==[      if @to_tref
        clear_timer @to_tref
        @to_tref = nil
      heart = ->
        p('INHEART', not not @recv)
        if @recv
          @recv\send_frame 'h'
          @to_tref = set_timeout @heartbeat_delay, heart
          @TO = 'TIMEOUTINHEARTX'
        else
          @to_tref = nil
          @TO = 'TIMEOUTINHEARTDOWNED'
      @to_tref = set_timeout @heartbeat_delay, heart
      @TO = 'TIMEOUTINHEART0'
      ]==]
      end
      return 
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, getmetatable(_parent_0).__index)
  end
  local _class_0 = setmetatable({
    __init = function(self, sid, options)
      self.sid = sid
      self.heartbeat_delay = options.heartbeat_delay
      self.disconnect_delay = options.disconnect_delay
      self.id = options.get_nonce()
      self.send_buffer = { }
      self.readyState = Transport.CONNECTING
      if self.sid then
        sessions[self.sid] = self
      end
      self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
      self.TO = 'TIMEOUT1'
      self.emit_connection_event = function()
        self.emit_connection_event = nil
        return options.onconnection(self)
      end
    end
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  return _class_0
end)()
return Session
