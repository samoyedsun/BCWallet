local skynet = require("skynet")
local profile = require "skynet.profile"
local mongo = require("skynet.db.mongo")
local logger = log4.get_logger("db")

local db

local modules = {}
--modules.vip 				= require("vip.vip_db")
--modules.wishPool 			= require("wish_pool.wish_pool_db")

local ti = {}
local function profileCall(func, cmd, ...)
	profile.start()
	local ret1, ret2, ret3, ret4 = func(...)
	local time = profile.stop()
	local p = ti[cmd]
	if p == nil then
	    p = { n = 0, ti = 0 }
	    ti[cmd] = p
	end
	p.n = p.n + 1
	p.ti = p.ti + time
	return ret1, ret2, ret3, ret4
end

local lua = {}
function lua.dispatch(session, address, cmd, ...)
    local moduleName, funcName = string.match(cmd, "(%w+)%.(%w+)")
    local module = modules[moduleName]
    local ret1, ret2, ret3, ret4
    if module then
        local func = module[funcName]
        if func then
            ret1, ret2, ret3, ret4 = profileCall(func, cmd, db, ...)
        else
            dump(cmd)
            logger.Errorf("db func[%s] is not found", funcName)
        end
    else
        dump(moduleName)
        dump(cmd)
        logger.Errorf("db module[%s] is not found", moduleName)
    end
    if session > 0 then
        skynet.ret(skynet.pack(ret1, ret2, ret3, ret4))
    elseif ret1 ~= nil then
        logger.Errorf("cmd[%s] had return value, but caller[%s] not used call function", cmd, address)
    end
end

skynet.dispatch("lua", lua.dispatch)

skynet.info_func(function()
  return ti
end)

local function connect()
    local dbhost = skynet.getenv("mongo_host")
    local dbport = skynet.getenv("mongo_port")
    local dbname = skynet.getenv("mongo_db_name")
    local username = skynet.getenv("mongo_username")
    local password = skynet.getenv("mongo_password")
    local authmod = skynet.getenv("mongo_auth_mod")

    local conf = {host = dbhost, port = dbport, username = username, password = password, authmod = authmod}
    local dbclient = mongo.client(conf)
    db = dbclient:getDB(dbname)
end

skynet.start(function()
    connect()
end)