require("skynet.manager")
local skynet = require("skynet")

local DB_SVC_COUNT = ...
local svcs = {}
local index = 1

local function initSvcPool()
	for i = 1, DB_SVC_COUNT do
		svcs[#svcs + 1] = skynet.newservice("mongo_svc")
	end
end

local function getSvc()
	local svc = svcs[index]
	index = index + 1
	if index > #svcs then
		index = 1
	end
	return svc
end

local lua = {}
function lua.dispatch(session, address, cmd, ...)
    local svc = getSvc()
    if session > 0 then
        if cmd == "getSvc" then
            skynet.ret(skynet.pack(getSvc()))
        else
            skynet.ret(skynet.pack(skynet.call(svc, "lua", cmd, ...)))
        end
    else
        skynet.send(svc, "lua", cmd, ...)
    end
end
skynet.dispatch("lua", lua.dispatch)

skynet.start(function()
	initSvcPool()
	skynet.register("MONGO")
end)