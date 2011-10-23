--
-- augment Request
--

Request = require 'request'

String = require 'string'
import match, gmatch from String

--
-- parse request cookies
--
Request.prototype.parse_cookies = () =>
  @cookies = {}
  if @headers.cookie
    for cookie in gmatch(@headers.cookie, '[^;]+')
      name, value = match cookie, '%s*([^=%s]-)%s*=%s*([^%s]*)'
      @cookies[name] = value if name and value
