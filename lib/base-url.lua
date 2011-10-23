return {
  'GET (/.-)[/]?$',
  function(self, nxt, root)
    local options = self:get_options(root)
    if not options then
      return nxt()
    end
    self:send(200, 'Welcome to SockJS!\n', {
      ['Content-Type'] = 'text/plain; charset=UTF-8'
    })
    return 
  end
}
