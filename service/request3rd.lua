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
        issue_request = {
            host = 'http://api.api68.com',
            url = '/CQShiCai/getBaseCQShiCai.do',
            param = { lotCode='10036' }
        },
        miss_issue_request = {
            host = 'http://api.api68.com',
            url = '/CQShiCai/getBaseCQShiCaiList.do',
            param = { lotCode='10036' }
        },
        issue_request_process = function(res, game_id, game_name)
            if not res.errorCode or res.errorCode ~= 0 then return end
            local result = res.result
            if not result.businessCode or result.businessCode ~= 0 then return end
            local data = result.data

            local issue = tonumber(data.preDrawIssue)
            local result = skynet.call("LOTTERY", "lua", "lottery_jsssc_find_history", issue)
            if result and not result.balls then
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
                
                if opening_date ~= result.opening_date or sealing_date ~= result.sealing_date then
                    logger.error("记录开奖信息错误! game_name:%s, issue:%s, error_info:%s", game_name, issue, cjson_encode({
                        opening_date = result.opening_date,
                        sealing_date = result.sealing_date,
                        fresh_opening_date = opening_date,
                        fresh_sealing_date = sealing_date
                    }))
                end
            end
        end,
        miss_issue_request_process = function(res, game_id, game_name)
            if not res.errorCode or res.errorCode ~= 0 then return end
            local result = res.result
            if not result.businessCode or result.businessCode ~= 0 then return end
            local data_list = result.data
            for k, data in ipairs(data_list) do
                local issue = tonumber(data.preDrawIssue)
                local result = skynet.call("LOTTERY", "lua", "lottery_jsssc_find_history", issue)
                if result and not result.balls then
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
                    logger.info("漏补开奖信息成功! game_name:%s issue:%s", game_name, issue)
                    
                    if opening_date ~= result.opening_date or sealing_date ~= result.sealing_date then
                        logger.error("漏补开奖信息错误! game_name:%s, issue:%s, error_info:%s", game_name, issue, cjson_encode({
                            opening_date = result.opening_date,
                            sealing_date = result.sealing_date,
                            fresh_opening_date = opening_date,
                            fresh_sealing_date = sealing_date
                        }))
                    end
                end
            end
        end
    }
}

local function make_fetching_newest_data()
    local function process_fetch_data(info)
        local trace_err = ""
        local trace = function(e)
            trace_err = tostring(e) .. debug.traceback()
        end
        local host = info.issue_request.host
        local url = info.issue_request.url
        local param = info.issue_request.param
        
        local ok, res = xpcall(http_request, trace, "GET", host, url, param)
        if not ok then
            logger.error("fetching_newest_data error 1, game_id:%s, trace_err:%s", info.game_id, trace_err)
        else
            if type(res) == "table" then
                info.issue_request_process(res, info.game_id, info.game_name)
            else
                logger.error("fetching_newest_data error 2, game_id:%s, res:%s", info.game_id, res)
            end
        end
    end
    local function ready_request(info)
    end
    local process_time = 0
    return function(last_tick_time)
        if (last_tick_time - process_time) < 3 then return end
        process_time = last_tick_time

        for k, info in ipairs(game_api_list) do
            local curr_date_min = os.date("%H%M", skynet_time())
            if curr_date_min < info.suspension_begin or curr_date_min > info.suspension_begin then
                skynet.fork(process_fetch_data, info)
            end
        end
    end
end

local function make_filling_miss_data()
    local function process_fetch_data(info, opening_date_since_year_to_day)
        local host = info.miss_issue_request.host
        local url = info.miss_issue_request.url
        local param = info.miss_issue_request.param
        param.date = opening_date_since_year_to_day
        
        logger.info("漏期补回, opening_date_since_year_to_day:%s", opening_date_since_year_to_day)
        local trace_err = ""
        local trace = function(e)
            trace_err = tostring(e) .. debug.traceback()
        end    
        local ok, res = xpcall(http_request, trace, "GET", host, url, param)
        if not ok then
            logger.error("filling_miss_data error 1, game_id:%s, trace_err:%s", info.game_id, trace_err)
        else
            if type(res) == "table" then
                info.miss_issue_request_process(res, info.game_id, info.game_name)
            else
                logger.error("filling_miss_data error 2, game_id:%s, res:%s", info.game_id, res)
            end
        end
    end
    local process_time = 0
    return function(last_tick_time)
        if (last_tick_time - process_time) < 84600 then return end
        process_time = last_tick_time
        
        for k, v in ipairs(game_api_list) do
            skynet.fork(function(info)
                local results = skynet.call("LOTTERY", "lua", "lottery_jsssc_find_miss_history", issue)
                local filter_date_map = {}
                for _, v in pairs(results) do
                    local issue = math.floor(v.issue)
                    local opening_time = date_to_timestamp(v.opening_date)
                    local opening_date_since_year_to_day = timestamp_to_date_since_year_to_day(opening_time)
                    if not filter_date_map[opening_date_since_year_to_day] then
                        filter_date_map[opening_date_since_year_to_day] = true
                        process_fetch_data(info, opening_date_since_year_to_day)
                    end
                end
            end, v)
        end
    end
end

local function on_tick(processes)
	create_timeout(100, function()
        on_tick(processes)
    end)

	local last_tick_time = skynet_time()
    for k, process in ipairs(processes) do
        process(last_tick_time)
    end
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

    create_timeout(3 * 100, function()
        logger.info("启动 REQUEST3RD")

        local fetch_newest_data = make_fetching_newest_data()
        local fill_miss_data = make_filling_miss_data()
        on_tick({fetch_newest_data, fill_miss_data}) 
    end)
end)