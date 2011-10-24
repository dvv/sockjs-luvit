p = print

--Response = require 'response'
CHUNK = 4096
safe_write = (data, cb) =>
  buf = data
  _write = () ->
    return cb() if buf == '' and cb
    @write buf\sub(1, CHUNK), (err, result) ->
      if not err
        buf = buf\sub(CHUNK + 1)
      else if err.code != 'EBUSY' and err.code != 'EINTR'
        p('SAFE_WRITE FAILED', err)
        cb err if cb
        return
      _write()
  _write()

resp = {
  write: (data, cb) =>
    p('WRITE', #data)
    cb()
}

safe_write resp, ('x')\rep(32774), () -> p('DONE')
