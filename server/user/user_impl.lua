local code = require "config.code"
local user_ctrl = require "user.user_ctrl"

local root = {}

function root:register(msg)
    return user_ctrl.register(msg, self.ip)
end

function root:login(msg)
    return user_ctrl.login(msg)
end

return root