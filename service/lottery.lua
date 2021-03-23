local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()
local db_help = require "db_help"
local lottery_ctrl = require "lottery.lottery_ctrl"
local logger = log4.get_logger(SERVICE_NAME)

local function check_lottery_history()
    -- 将漏掉的记录补回来
    -- 然后再唤醒拉取数据服务
    skynet.send("THIRD_API", "lua", "start")
end

local CMD = {}

function CMD.calculate_lottery_results(balls)
    return lottery_ctrl.calculate_lottery_results(balls)
end

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

    check_lottery_history()
end)