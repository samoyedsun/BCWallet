local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()
local db_help = require "db_help"
local logger = log4.get_logger(SERVICE_NAME)

local game_api_list = {
    {
        game_id = 1,
        host = 'http://api.api68.com',
        url = '/CQShiCai/getBaseCQShiCai.do',
        param = { lotCode='10036' },
        process = function(response, game_id)
            if not response.errorCode or response.errorCode ~= 0 then return end
            local result = response.result
            if not result.businessCode or result.businessCode ~= 0 then return end
            local data = result.data

            local param = {
                game_id = game_id,
                draw_issue = pre_draw_issue,
                draw_time = pre_draw_time,
                draw_code_list = pre_draw_code_list
            }

            local sealing_time = date_to_timestamp(data.preDrawTime)
            local sealing_date = timestamp_to_date(sealing_time - 15)
            local db_index = game_id .. "-" .. data.preDrawIssue
            local res = skynet.call("LOTTERY", "lua", "find_lottery_history", db_index)
            if not res then
                local param = {
                    _id = db_index,
                    game_id = game_id,
                    draw_issue = data.preDrawIssue,
                    sealing_date = sealing_date,
                    draw_date = data.preDrawTime,
                    boll_1 = data.firstNum,
                    boll_2 = data.secondNum,
                    boll_3 = data.thirdNum,
                    boll_4 = data.fourthNum,
                    boll_5 = data.fifthNum
                }
    
                local id = skynet.call("LOTTERY", "lua", "push_lottery_info", param)
                logger.info("记录开奖信息成功! id:%s", id)
            end
        end
    }
}

local process_time = 0

local function process_fetch_data(last_tick_time)
    if (last_tick_time - process_time) >= 3 then
        process_time = last_tick_time
        for k, v in ipairs(game_api_list) do
            -- 拉取数据
            -- 加生效条件: !("0900" < $ntime || $ntime < "0401")
            skynet.fork(function(info)
                local trace_err = ""
                local trace = function (e)
                    trace_err = tostring(e) .. debug.traceback()
                end
                local ok, res = xpcall(http_request, trace, "GET", info.host, info.url, info.param)
                if not ok then
                    logger.error("process_fetch_data error 1, id:%s, trace_err:%s", info.game_id, trace_err)
                else
                    if type(res) == "table" then
                        info.process(res, info.game_id)
                    else
                        logger.error("process_fetch_data error 2, id:%s, res:%s", info.game_id, res)
                    end
                end
            end, v)
            -- 结算
        end
    end
end

local function onTick()
	skynet.timeout(100, function()
        onTick()
    end)

	local last_tick_time = skynet.time()
    process_fetch_data(last_tick_time)
end

local CMD = {}

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
    skynet.register("THIRD_API")

    onTick()
end)