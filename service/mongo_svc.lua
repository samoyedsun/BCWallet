local skynet = require "skynet"
local profile = require "skynet.profile"
local mongo = require "skynet.db.mongo"
local logger = log4.get_logger(SERVICE_NAME)

local db

local modules = {}
modules.user_db             =   require "user.user_db"
modules.autoincrid_db       =   require "autoincrid.autoincrid_db"

local ti = {}
local function profile_call(func, cmd, ...)
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
    local module_name, func_name = string.match(cmd, "([_%w]+)%.([_%w]+)")
    local module = modules[module_name]
    local ret1, ret2, ret3, ret4
    if module then
        local func = module[func_name]
        if func then
            ret1, ret2, ret3, ret4 = profile_call(func, cmd, db, ...)
        else
            logger.error("db func[%s] is not found", func_name)
        end
    else
        logger.error("db module[%s] is not found", module_name)
    end
    if session > 0 then
        skynet.ret(skynet.pack(ret1, ret2, ret3, ret4))
    elseif ret1 ~= nil then
        logger.error("cmd[%s] had return value, but caller[%s] not used call function", cmd, address)
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