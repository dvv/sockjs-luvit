--
-- SockJS server implemented in luvit
-- https://github.com/sockjs/sockjs-protocol for details
--

EventEmitter = setmetatable {}, __index: require('emitter').meta
import set_timeout, clear_timer from require 'timer'
import encode, decode from JSON
uuid = require 'server/modules/uuid'
Table = require 'table'

--
-- Session -- bidirectional WebSocket-like channel between client and server
--

--
-- collection of registered sessions
--
sessions = {}

-- TODO: get rid in production
_G.s = () -> sessions

class Session extends EventEmitter

  -- session status constants
  CONNECTING: 0
  OPEN: 1
  CLOSING: 2
  CLOSED: 3

  -- given session id return session, if any
  get: (sid) -> sessions[sid]

  -- given session id, return existing, or create new session, with options
  get_or_create: (sid, options) ->
    session = Session.get sid
    session = Session(sid, options) if not session
    session

  -- compose closing frame
  closing_frame: (status, reason) -> 'c' .. encode({status, reason})

  --
  -- create new session
  --

  new: (@sid, options) =>

    -- setup options
    @heartbeat_delay = options.heartbeat_delay
    @disconnect_delay = options.disconnect_delay
    @id = uuid()

    -- allocate buffer for outgoing messages
    @send_buffer = {}
    -- put this session in collection of sessions
    @ready_state = Session.CONNECTING
    sessions[@sid] = self if @sid

    -- setup inactivity timeout
    @to_tref = set_timeout @disconnect_delay, @ontimeout, self

    -- setup one-time connection event
    @emit_connection_event = ->
      @emit_connection_event = nil
      options.onconnection self
      --options.onconnection setmetatable {foo: 'bar'}, {__index: self}
      return

  --
  -- bind a connection to this session
  --

  bind: (conn) =>
    --d('BIND', @sid, @id)

    -- can't bind more than one connection
    if @conn
      conn\send_frame Session.closing_frame(2010, 'Another connection still open')
      return

    -- closing session rejects bindings
    if @ready_state == Session.CLOSING
      conn\send_frame @close_frame
      if @to_tref
        clear_timer @to_tref
      @to_tref = set_timeout @disconnect_delay, @ontimeout, self
      return

    -- bind connection
    @conn = conn
    conn.session = self
    -- when connection ends, unbind it
    conn\once 'closed', () ->
      --d('CLOSEDEVENT')
      @unbind()
    conn\once 'end', () ->
      --d('END')
      @unbind()
    conn\once 'error', (err) ->
      --d('ERROR', err)
      --error(err)
      conn\finish()

    -- send the opening frame
    if @ready_state == Session.CONNECTING
      @conn\send_frame 'o'
      -- and mark this session as open
      @ready_state = Session.OPEN
      -- emit connection event asynchronously
      set_timeout 0, @emit_connection_event

    -- reset inactivity timeout
    if @to_tref
      clear_timer @to_tref
      @to_tref = nil

    -- try to flush pending outgoing messages
    @flush()

    return

  --
  -- unbind connection bound to this session
  --

  unbind: =>
    --d('UNREGISTER', @sid, @id, not not @conn)

    -- cleanup
    if @conn
      @conn.session = nil
      @conn = nil
    if @to_tref
      clear_timer @to_tref

    -- shedule disconnect event
    @to_tref = set_timeout @disconnect_delay, @ontimeout, self

    return

  --
  -- timeout expired, close the session
  --

  ontimeout: =>
    --p('TIMEDOUT', @sid, @conn)

    -- cleanup
    if @to_tref
      clear_timer @to_tref
      @to_tref = nil

    -- can't close closed session
    if @ready_state != Session.CONNECTING and @ready_state != Session.OPEN and @ready_state != Session.CLOSING
      error 'INVALID_STATE_ERR'

    -- can't close while connection is bound
    if @conn
      error 'RECV_STILL_THERE'

    -- mark this session as closed
    @ready_state = Session.CLOSED
    @emit 'close'

    -- remove this session from collection of sessions
    if @sid
      sessions[@sid] = nil
      @sid = nil

    return

  --
  -- process incoming message
  --

  onmessage: (payload) =>
    --p('MESSAGE', #payload < 128 and payload or #payload)

    -- trigger event handlers if this session is open
    if @ready_state == Session.OPEN
      @emit 'message', payload

    return

  --
  -- try to flush outgoing messages queue
  --

  flush: =>

    return if not @conn

    -- there are messages in queue
    if #@send_buffer > 0

      -- send them as encoded array, and empty the queue
      messages = @send_buffer
      @send_buffer = {}
      @conn\send_frame 'a' .. encode(messages)

    -- queue is empty
    else

      -- shedule heartbeat
      if @to_tref
        clear_timer @to_tref
        @to_tref = nil

      heartbeat = ->
        if @conn
          @conn\send_frame 'h'
          @to_tref = set_timeout @heartbeat_delay, heartbeat
        else
          @to_tref = nil

      @to_tref = set_timeout @heartbeat_delay, heartbeat

    return

  --
  -- orderly close this session
  --

  close: (status = 1000, reason = 'Normal closure') =>

    -- can't close not opened session
    return false if @ready_state != Session.OPEN

    -- mark as closing
    @ready_state = Session.CLOSING
    -- compose closing frame
    @close_frame = Session.closing_frame status, reason
    -- if connection is bound, use it to send the closing frame
    if @conn
      @conn\send_frame @close_frame, () -> @conn\finish()
      --@conn\send_frame @close_frame
      --@conn\finish()

    return

  --
  -- send data to the remote end
  -- N.B. we always buffer outgoing messages
  --

  send: (payload) =>

    -- can't send if session is not opened
    return false if @ready_state != Session.OPEN

    -- stringify payload
    -- TODO: booleans won't get stringified by concat
    -- enqueue message
    Table.insert @send_buffer, type(payload) == 'table' and Table.concat(payload, ',') or tostring(payload)
    -- if connection is bound, try to flush the queue
    --if @conn
    --  set_timeout 0, () -> @flush()
    set_timeout 0, () -> @flush()

    true

-- export
return Session
