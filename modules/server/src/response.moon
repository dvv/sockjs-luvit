--
-- augment Response
--

Response = require 'response'

FS = require 'fs'

noop = () ->

Response.prototype.auto_server = 'U-Gotta-Luvit'

Response.prototype.send = (code, data, headers, close = true) =>
  d('RESPONSE FOR', @req and @req.method, @req and @req.url, 'IS', code, data)
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
