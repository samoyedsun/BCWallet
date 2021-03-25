local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()
local logger = log4.get_logger(SERVICE_NAME)

local game_api_list = {
    {
        game_id = 1,
        game_name = "lottery_jsssc",
        suspension_begin = "0400",
        suspension_end = "0730",
        newest_issue_request = {
            host = 'http://api.api68.com',
            url = '/CQShiCai/getBaseCQShiCai.do',
            param = { lotCode='10036' }
        },
        period_issue_request = {
            host = 'http://api.api68.com',
            url = '/CQShiCai/getBaseCQShiCaiList.do',
            param = { lotCode='10036' }
        },
        process = function(response, game_id, game_name)
            if not response.errorCode or response.errorCode ~= 0 then return end
            local result = response.result
            if not result.businessCode or result.businessCode ~= 0 then return end
            local data = result.data

            local issue = tonumber(data.preDrawIssue)
            local result = skynet.call("LOTTERY", "lua", "lottery_jsssc_find_history", issue)
            if not result then
                local opening_date = data.preDrawTime
                local opening_time = date_to_timestamp(opening_date)
                local sealing_time = opening_time - 15
                local sealing_date = timestamp_to_date(sealing_time)
                local balls_str = string.split(data.preDrawCode, ",")
                local balls = {}
                for k, v in ipairs(balls_str) do
                    balls[k] = tonumber(v)
                end
                local opening_opcode = skynet.call("LOTTERY", "lua", "calculate_lottery_jsssc_results", balls)
                skynet.call("LOTTERY", "lua", "lottery_jsssc_update_history", issue, balls, opening_opcode)
                
                logger.info("记录开奖信息成功! game_name:%s issue:%s", game_name, issue)
                --[[ -- 检查时间是否对的上，对不上打出报错
                if opening_date ~= result.opening_date or sealing_date ~= result.sealing_date then
                    logger.error("记录开奖信息错误! game_name:%s, issue:%s, error_info:%s", game_name, issue, cjson_encode({
                        opening_date = result.opening_date,
                        sealing_date = result.sealing_date,
                        fresh_opening_date = opening_date,
                        fresh_sealing_date = sealing_date
                    }))
                end
                --]]
            end
        end
    }
}

local function make_fetch_newest_data()
    local process_time = 0
    return function(last_tick_time)
        if (last_tick_time - process_time) >= 3 then
            process_time = last_tick_time
            for k, v in ipairs(game_api_list) do
                local curr_date_min = os.date("%H%M", skynet_time())
                if curr_date_min > v.suspension_begin or curr_date_min < v.suspension_begin then
                    skynet.fork(function(info)
                        local trace_err = ""
                        local trace = function (e)
                            trace_err = tostring(e) .. debug.traceback()
                        end
                        local host = info.newest_issue_request.host
                        local url = info.newest_issue_request.url
                        local param = info.newest_issue_request.param
                        local ok, res = xpcall(http_request, trace, "GET", host, url, param)
                        if not ok then
                            logger.error("process_fetch_data error 1, id:%s, trace_err:%s", info.game_id, trace_err)
                        else
                            if type(res) == "table" then
                                info.process(res, info.game_id, info.game_name)
                            else
                                logger.error("process_fetch_data error 2, id:%s, res:%s", info.game_id, res)
                            end
                        end
                    end, v)
                end
            end
        end
    end
end

local function filling_period_data()
    local process_time = 0
    return function(last_tick_time)
        if (last_tick_time - process_time) >= 3 then
            process_time = last_tick_time
        end
    end
    -- curr_date_min > v.suspension_begin or curr_date_min < v.suspension_begin
    -- https://api.api68.com/CQShiCai/getBaseCQShiCaiList.do?lotCode=10036&date=2019-04-15
end

local function on_tick(fetch_newest_data)
	skynet.timeout(100, function()
        on_tick(fetch_newest_data)
    end)
	local last_tick_time = skynet_time()
    fetch_newest_data(last_tick_time)
    
    -- filling_period_data(last_tick_time)
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
    skynet.register("REQUEST3RD")

    skynet.timeout(3 * 100, function()
        logger.info("启动 REQUEST3RD")
        on_tick(make_fetch_newest_data())  
    end)
end)