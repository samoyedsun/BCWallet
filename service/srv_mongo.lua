local skynet = require "skynet"
require "skynet.manager"
local autoincrid_ctrl = require "autoincrid.autoincrid_ctrl"

local DB_SVC_COUNT = ...
local svcs = {}
local index = 1

local function init_svc_pool()
	for i = 1, DB_SVC_COUNT do
		svcs[#svcs + 1] = skynet.newservice("srv_mongo_agent", i)
	end
end

local function get_svc()
	local svc = svcs[index]
	index = index + 1
	if index > #svcs then
		index = 1
	end
	return svc
end

local function get_autoincrid(key)
    return autoincrid_ctrl.get_autoincrid(key)
end

local lua = {}
function lua.dispatch(session, address, cmd, ...)
    local svc = get_svc()
    if session > 0 then
        if cmd == "get_svc" then
            skynet.ret(skynet.pack(get_svc()))
        elseif cmd == "get_autoincrid" then
            skynet.ret(skynet.pack(get_autoincrid(...)))
        else
            skynet.ret(skynet.pack(skynet.call(svc, "lua", cmd, ...)))
        end
    else
        skynet.send(svc, "lua", cmd, ...)
    end
end
skynet.dispatch("lua", lua.dispatch)

skynet.start(function()
	init_svc_pool()
    create_timeout(1, function() autoincrid_ctrl.init_autoincrid() end)
end)