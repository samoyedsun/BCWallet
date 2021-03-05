local skynet = require("skynet")

local root = {}

function root.send_s2s(address, cmd, ...)
	skynet.send(address, "lua", cmd, ...)
end

function root.call_s2s(address, cmd, ...)
	return skynet.call(address, "lua", cmd, ...)
end

return root
