local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()
local db_help = require "db_help"
local logger = log4.get_logger(SERVICE_NAME)

local CMD = {}

function CMD.find_lottery_history(id)
    return db_help.call("lottery_db.find_lottery_history", id)
end

function CMD.push_lottery_info(param)
    return db_help.call("lottery_db.push_lottery_history", param)
end

skynet.dispatch("lua", function(session, _, command, ...)
    local f = CMD[command]
    if not f then
        if session ~= 0 then
            skynet.ret(skynet.pack(nil))
        end
    elseif session == 0 then
        queue_enter(f, ...)
    else
        skynet.ret(skynet.pack(queue_enter(f, ...)))
    end
end)

skynet.start(function()
    skynet.register("LOTTERY")
end)