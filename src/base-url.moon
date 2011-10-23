--
-- standard routes
--
return {
  'GET (/.-)[/]?$'
  (nxt, root) =>
    options = @get_options(root)
    return nxt() if not options
    @send 200, 'Welcome to SockJS!\n', ['Content-Type']: 'text/plain; charset=UTF-8'
    return
}
