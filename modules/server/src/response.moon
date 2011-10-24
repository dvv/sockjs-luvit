--
-- augment Response
--

Response = require 'response'

FS = require 'fs'

noop = () ->

Response.prototype.auto_server = 'U-Gotta-Luvit'

Response.prototype.safe_write0 = (chunk, cb = noop) =>
  @write chunk, (err, result) ->
    return cb err, result if not err
    -- retry on EBUSY
    if err
      p('WRITERR?', err, result)
      if err.code == 'EBUSY' or err.code == 'EINTR'
        @safe_write chunk, cb
    else
      p('WRITE FAILED', err)
      cb err

CHUNK = 4096
Response.prototype.safe_write = (data, cb) =>
  buf = data
  _write = () ->
    return cb() if buf == '' and cb
    s = buf\sub(1, CHUNK)
    @write s, (err, result) ->
      p('WRITTEN', @chunked, #s)
      if not err
        buf = buf\sub(CHUNK + 1)
      else if err.code != 'EBUSY' and err.code != 'EINTR'
        p('SAFE_WRITE FAILED', err)
        cb err if cb
        return
      _write()
      return
  _write()
  return

Response.prototype.send = (code, data, headers, close = true) =>
  p('RESPONSE FOR', @req and @req.method, @req and @req.url, 'IS', code, data)
  @write_head code, headers or {}
  @write data if data
  @finish() if close

-- serve 500 error and reason
Response.prototype.fail = (reason) =>
  @send 500, reason, {
    ['Content-Type']: 'text/plain; charset=UTF-8'
    ['Content-Length']: #reason
  }

-- serve 404 error
Response.prototype.serve_not_found = () =>
  @send 404

-- serve 304 not modified
Response.prototype.serve_not_modified = (headers) =>
  @send 304, nil, headers

-- serve 416 invalid range
Response.prototype.serve_invalid_range = (size) =>
  @send 416, nil, {
    ['Content-Range']: 'bytes=*/' .. size
  }

-- render file named `template` with data from `data` table
-- and serve it with status 200 as text/html
Response.prototype.render = (template, data = {}, options = {}) =>
  -- TODO: caching
  FS.read_file template, (err, text) ->
    if err
      @serve_not_found()
    else
      html = (text % data)
      @send 200, html, {
        ['Content-Type']: 'text/html; charset=UTF-8'
        ['Content-Length']: #html
      }
