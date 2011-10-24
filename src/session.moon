--
-- SockJS server implemented in luvit
-- https://github.com/sockjs/sockjs-protocol for details
--

EventEmitter = setmetatable {}, __index: require('emitter').meta
import set_timeout, clear_timer from require 'timer'
import encode, decode from JSON
Table = require 'table'

--
-- Transport abstraction
--
Transport = {
  CONNECTING: 0
  OPEN: 1
  CLOSING: 2
  CLOSED: 3
  closing_frame: (status, reason) ->
    'c' .. encode({status, reason})
}

--
-- Session -- bidirectional WebSocket-like channel between client and server
--

--
-- collection of registered sessions
--
sessions = {}

-- TODO: get rid in production
_G.s = () -> sessions
_G.f = () -> sessions = {}

class Session extends EventEmitter

  get: (sid) -> sessions[sid]

  get_or_create: (sid, options) ->
    session = Session.get sid
    session = Session(sid, options) if not session
    session

  new: (@sid, options) =>
    @heartbeat_delay = options.heartbeat_delay
    @disconnect_delay = options.disconnect_delay
    @id = options.get_nonce()
    @send_buffer = {}
    @readyState = Transport.CONNECTING
    sessions[@sid] = self if @sid
    @to_tref = set_timeout @disconnect_delay, @ontimeout, self
    @TO = 'TIMEOUT1'
    @emit_connection_event = ->
      @emit_connection_event = nil
      options.onconnection self

  bind: (recv) =>
    p('BIND', @sid, @id)
    if @recv
      p('ALREADY REGISTERED!!!')
      recv\send_frame Transport.closing_frame(2010, 'Another connection still open')
      return
    if @readyState == Transport.CLOSING
      p('STATEISCLOSING', @close_frame)
      recv\send_frame @close_frame
      if @to_tref
        clear_timer @to_tref
      @to_tref = set_timeout @disconnect_delay, @ontimeout, self
      @TO = 'TIMEOUTINREGISTER1'
      return
    --
    p('DOREGISTER', @readyState)
    @recv = recv
    @recv.session = self
    @recv\once 'closed', () ->
      p('CLOSEDEVENT')
      @unbind()
    @recv\once 'end', () ->
      p('END')
      @unbind()
    @recv\once 'error', (err) ->
      p('ERROR', err)
      --error(err)
      @recv\finish()
    -- send the open frame
    if @readyState == Transport.CONNECTING
      @recv\send_frame 'o'
      @readyState = Transport.OPEN
      -- emit connection event
      set_timeout 0, @emit_connection_event
    if @to_tref
      clear_timer @to_tref
      @TO = 'CLEAREDINREGISTER:' .. @TO
      @to_tref = nil
    @flush() if @recv
    return

  unbind: =>
    p('UNREGISTER', @sid, @id, not not @recv)
    if @recv
      @recv.session = nil
      @recv = nil
    if @to_tref
      clear_timer @to_tref
    @to_tref = set_timeout @disconnect_delay, @ontimeout, self
    @TO = 'TIMEOUTINUNREGISTER'
    return

  close: (status = 1000, reason = 'Normal closure') =>
    return false if @readyState != Transport.OPEN
    @readyState = Transport.CLOSING
    @close_frame = Transport.closing_frame status, reason
    if @recv
      @recv\send_frame @close_frame
      --WAS@unbind()
      @recv\finish()
    return

  ontimeout: =>
    p('TIMEDOUT', @sid, @recv)
    if @to_tref
      clear_timer @to_tref
      @to_tref = nil
    if @readyState != Transport.CONNECTING and @readyState != Transport.OPEN and @readyState != Transport.CLOSING
      error 'INVALID_STATE_ERR'
    if @recv
      error 'RECV_STILL_THERE'
    @readyState = Transport.CLOSED
    @emit 'close'
    if @sid
      sessions[@sid] = nil
      @sid = nil
    return

  onmessage: (payload) =>
    if @readyState == Transport.OPEN
      p('MESSAGE', #payload < 128 and payload or #payload)
      @emit 'message', payload
    return

  send: (payload) =>
    return false if @readyState != Transport.OPEN
    -- TODO: booleans won't get stringified by concat
    Table.insert @send_buffer, type(payload) == 'table' and Table.concat(payload, ',') or tostring(payload)
    if @recv
      set_timeout 0, () -> @flush()
    true

  flush: =>
    p('INFLUSH', #@send_buffer)
    if #@send_buffer > 0
      messages = @send_buffer
      @send_buffer = {}
      @recv\send_frame 'a' .. encode(messages), (err) ->
        debug('SENT_FRAME', err)
    else
      p('TOTREF?', @TO, @to_tref)
      [==[
      if @to_tref
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
    return

return Session
