local Request = require('request')
local String = require('string')
local match, gmatch = String.match, String.gmatch
Request.prototype.parse_cookies = function(self)
  self.cookies = { }
  if self.headers.cookie then
    for cookie in gmatch(self.headers.cookie, '[^;]+') do
      local name, value = match(cookie, '%s*([^=%s]-)%s*=%s*([^%s]*)')
      if name and value then
        self.cookies[name] = value
      end
    end
  end
end
