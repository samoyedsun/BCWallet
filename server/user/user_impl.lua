local code = require "config.code"

local root = {}

function root:register(msg)
    print("===============register", tostring(self))
    print("===============register", tostring(msg))
    local username = msg.username
    local password = msg.password

    local data = {
        username = username,
        password = password
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function root:login(msg)
    print("===============login", tostring(self))
    print("===============login", tostring(msg))
    local username = msg.username
    local password = msg.password

    local data = {
        username = username,
        password = password
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

return root