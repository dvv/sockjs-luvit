local EventEmitter = setmetatable({ }, {
  __index = require('emitter').meta
})
local set_timeout, clear_timer
do
  local _table_0 = require('timer')
  set_timeout = _table_0.set_timeout
  clear_timer = _table_0.clear_timer
end
local encode, decode = JSON.encode, JSON.decode
local Table = require('table')
local sessions = { }
_G.s = function()
  return sessions
end
local Session
Session = (function()
  local _parent_0 = EventEmitter
  local _base_0 = {
    CONNECTING = 0,
    OPEN = 1,
    CLOSING = 2,
    CLOSED = 3,
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
    closing_frame = function(status, reason)
      return 'c' .. encode({
        status,
        reason
      })
    end,
    bind = function(self, conn)
      if self.conn then
        conn:send_frame(Session.closing_frame(2010, 'Another connection still open'))
        return 
      end
      if self.ready_state == Session.CLOSING then
        conn:send_frame(self.close_frame)
        if self.to_tref then
          clear_timer(self.to_tref)
        end
        self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
        return 
      end
      self.conn = conn
      conn.session = self
      conn:once('closed', function()
        return self:unbind()
      end)
      conn:once('end', function()
        return self:unbind()
      end)
      conn:once('error', function(err)
        return conn:finish()
      end)
      if self.ready_state == Session.CONNECTING then
        self.conn:send_frame('o')
        self.ready_state = Session.OPEN
        set_timeout(0, self.emit_connection_event)
      end
      if self.to_tref then
        clear_timer(self.to_tref)
        self.to_tref = nil
      end
      if self.conn then
        self:flush()
      end
      return 
    end,
    unbind = function(self)
      if self.conn then
        self.conn.session = nil
        self.conn = nil
      end
      if self.to_tref then
        clear_timer(self.to_tref)
      end
      self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
      return 
    end,
    ontimeout = function(self)
      if self.to_tref then
        clear_timer(self.to_tref)
        self.to_tref = nil
      end
      if self.ready_state ~= Session.CONNECTING and self.ready_state ~= Session.OPEN and self.ready_state ~= Session.CLOSING then
        error('INVALID_STATE_ERR')
      end
      if self.conn then
        error('RECV_STILL_THERE')
      end
      self.ready_state = Session.CLOSED
      self:emit('close')
      if self.sid then
        sessions[self.sid] = nil
        self.sid = nil
      end
      return 
    end,
    onmessage = function(self, payload)
      if self.ready_state == Session.OPEN then
        self:emit('message', payload)
      end
      return 
    end,
    flush = function(self)
      if #self.send_buffer > 0 then
        local messages = self.send_buffer
        self.send_buffer = { }
        self.conn:send_frame('a' .. encode(messages))
      else
        if self.to_tref then
          clear_timer(self.to_tref)
          self.to_tref = nil
        end
        local heartbeat
        heartbeat = function()
          if self.conn then
            self.conn:send_frame('h')
            self.to_tref = set_timeout(self.heartbeat_delay, heartbeat)
          else
            self.to_tref = nil
          end
        end
        self.to_tref = set_timeout(self.heartbeat_delay, heartbeat)
      end
      return 
    end,
    close = function(self, status, reason)
      if status == nil then
        status = 1000
      end
      if reason == nil then
        reason = 'Normal closure'
      end
      if self.ready_state ~= Session.OPEN then
        return false
      end
      self.ready_state = Session.CLOSING
      self.close_frame = Session.closing_frame(status, reason)
      if self.conn then
        self.conn:send_frame(self.close_frame, function()
          return self.conn:finish()
        end)
      end
      return 
    end,
    send = function(self, payload)
      if self.ready_state ~= Session.OPEN then
        return false
      end
      Table.insert(self.send_buffer, type(payload) == 'table' and Table.concat(payload, ',') or tostring(payload))
      if self.conn then
        set_timeout(0, function()
          return self:flush()
        end)
      end
      return true
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
      self.ready_state = Session.CONNECTING
      if self.sid then
        sessions[self.sid] = self
      end
      self.to_tref = set_timeout(self.disconnect_delay, self.ontimeout, self)
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
