local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()
local db_help = require "db_help"
local lottery_const = require "lottery.lottery_const"
local lottery_ctrl = require "lottery.lottery_ctrl"
local logger = log4.get_logger(SERVICE_NAME)

local function jsssc_init_open_quotation()
    local one_day_sec = 86400
    local one_day_issue = 1152

    local base_issue = 11757921
    local base_date = "2021-01-30 06:00:30"

    local base_time = date_to_timestamp(base_date)
    local base_date_since_year_to_day = timestamp_to_date_since_year_to_day(base_time)
    local base_date_since_hour_to_sec = timestamp_to_date_since_hour_to_sec(base_time)

    local curr_time = skynet_time()
    local curr_date_since_year_to_day = timestamp_to_date_since_year_to_day(curr_time)
    local insert_date = curr_date_since_year_to_day .. " " .. base_date_since_hour_to_sec
    
    local time_span = date_since_year_to_day_to_timestamp(curr_date_since_year_to_day) - date_since_year_to_day_to_timestamp(base_date_since_year_to_day)
    local insert_issue = base_issue + time_span / one_day_sec * one_day_issue;
    
    local open_quotations = {}
    for idx = 1, one_day_issue do
        insert_issue = insert_issue + 1

        local need_time_span_amount = idx
        local need_time_span = lottery_const.GAME_JSSSC_ONE_ISSUE_TIME_SPAN * need_time_span_amount
        local opening_time = date_to_timestamp(insert_date) + need_time_span
        
        local opening_date = timestamp_to_date(opening_time)
        local sealing_date = timestamp_to_date(opening_time - 15)
        table.insert(open_quotations, {
            _id = issue,
            issue = insert_issue,
            opening_date = opening_date,
            sealing_date = sealing_date,
            lock = (idx == 1 and {lottery_const.LOCK_STATE.YES} or {lottery_const.LOCK_STATE.NO})[1]
        })
    end

    for k, v in ipairs(open_quotations) do -- 这里需要优化为一次性插入多条
        local data = v
        db_help.call("lottery_db.lottery_jsssc_append_open_quotation", data)
    end
end

local function jsssc_exec_open_quotation()
    local curr_date = timestamp_to_date(skynet_time())
    local results = db_help.call("lottery_db.lottery_jsssc_find_open_quotation_expire", curr_date)
    for k, v in pairs(results) do
        local issue = v.issue
        local result = db_help.call("lottery_db.lottery_jsssc_find_history", issue)
        if not result then
            local data = {
                _id = issue,
                issue = issue,
                sealing_date = v.sealing_date,
                opening_date = v.opening_date
            }
            db_help.call("lottery_db.lottery_jsssc_append_history", data)
        end
    end
    if not table.empty(results) then
        logger.info("到期封盘! game_type:%s issue:%s", "lottery_jsssc", curr_date)
        db_help.call("lottery_db.lottery_jsssc_delete_open_quotation_expire", curr_date)

        local result = db_help.call("lottery_db.lottery_jsssc_get_open_quotation_first")
        if result then
            local issue = result.issue
            local lock = lottery_const.LOCK_STATE.YES
            db_help.call("lottery_db.lottery_jsssc_update_open_quotation", issue, lock)
        else
            jsssc_init_open_quotation()
        end
    end
end

local function jsssc_exec_settle_betting_record(game_type)
    local results = db_help.call("lottery_db.lottery_jsssc_find_betting_record_unsettled", game_type)
    local issue_list = table.indices(results)
    for _, issue in ipairs(issue_list) do
        local betting_record_list = results[issue]
        local result = db_help.call("lottery_db.lottery_jsssc_find_history", issue)
        if result and result.balls then
            local opening_opcode = result.opening_opcode
            for _, betting_record in ipairs(betting_record_list) do
                local win_amount = 0
                local slot = opening_opcode[betting_record.kind]
                if slot and slot == betting_record.slot then
                    local odds = lottery_const.GAME_JSSSC_ODDS[betting_record.kind][slot]
                    win_amount = win_amount + betting_record.amount * odds - betting_record.amount
                else
                    win_amount = win_amount - betting_record.amount
                end
                db_help.call("lottery_db.lottery_jsssc_update_betting_record_win_amount", {
                    uid = betting_record.uid,
                    issue = betting_record.issue,
                    game_type = betting_record.game_type,
                    kind = betting_record.kind,
                    slot = betting_record.slot,
                    win_amount = win_amount
                })
                db_help.call("user_db.update_user_money", {
                    uid = betting_record.uid,
                    win_amount = win_amount
                })
            end
        end
    end
end

local function on_tick()
	create_timeout(100, function()
        on_tick()
    end)

    jsssc_exec_open_quotation()
end

local CMD = {}

function CMD.calculate_lottery_jsssc_results(balls)
    return lottery_ctrl.calculate_lottery_jsssc_results(balls)
end

function CMD.lottery_jsssc_find_history(issue)
    return db_help.call("lottery_db.lottery_jsssc_find_history", issue)
end

function CMD.lottery_jsssc_find_miss_history()
    return db_help.call("lottery_db.lottery_jsssc_find_miss_history")
end

function CMD.lottery_jsssc_update_history(issue, balls, opening_opcode)
    db_help.call("lottery_db.lottery_jsssc_update_history", issue, balls, opening_opcode)
    jsssc_exec_settle_betting_record("lottery_jsssc")
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
    skynet.register(SERVICE_NAME)
    create_timeout(3 * 100, function()
        logger.info("启动 " .. SERVICE_PATH .. SERVICE_NAME)
        
        local amount = db_help.call("lottery_db.lottery_jsssc_get_open_quotation_amount")
        if amount == 0 then
            jsssc_init_open_quotation()
        end

        on_tick()
    end)
end)