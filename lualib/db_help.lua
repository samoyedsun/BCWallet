--db管理类
local skynet = require("skynet")
local root = {}

local db_svc

local function get_db_svc()
    if not db_svc then
        db_svc = skynet.call("MONGO_DB", "lua", "get_svc")
    end
    return db_svc
end

function root.get_db_svc()
    return get_db_svc()
end

function root.send(cmd, ...)
    local svc = get_db_svc()
    skynet.send(svc, "lua", cmd, ...)
end

function root.call(cmd, ...)
    local svc = get_db_svc()
    local ret1, ret2, ret3, ret4 = skynet.call(svc, "lua", cmd, ...)
    return ret1, ret2, ret3, ret4
end

return root