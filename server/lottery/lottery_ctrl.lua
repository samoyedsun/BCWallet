local db_help = require "db_help"
local lottery_const = require "lottery.lottery_const"

local function match_state_single_ball_value_play(ball)
    local state_map = {
        [0] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER0,
        [1] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER1,
        [2] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER2,
        [3] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER3,
        [4] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER4,
        [5] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER5,
        [6] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER6,
        [7] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER7,
        [8] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER8,
        [9] = lottery_const.GAME_JSSSC_BETTING.BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER9
    }
    return state_map[ball]
end

local function match_state_single_ball_face_play(ball)
    if (ball % 2) == 0 then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_FACE_PLAY.DOUBLE
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_FACE_PLAY.SINGLE
    end
end

local function match_state_single_ball_size_play(ball)
    if ball >= 5 then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_SIZE_PLAY.LARGE
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_SIZE_PLAY.SMALL
    end
end

local function match_state_sum_ball_face_play(balls)
    local sum_ball = 0
    for k, ball in ipairs(balls) do
        sum_ball = sum_ball + ball
    end
    if (sum_ball % 2) == 0 then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_FACE_PLAY.DOUBLE
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_FACE_PLAY.SINGLE
    end
end

local function match_state_sum_ball_size_play(balls)
    local sum_ball = 0
    for k, ball in ipairs(balls) do
        sum_ball = sum_ball + ball
    end
    if sum_ball >= 23 then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_SIZE_PLAY.LARGE
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_SIZE_PLAY.SMALL
    end
end

local function match_state_three_ball_play(balls)
    local function next_ball_value(bv)
        local bv = bv + 1
        if bv > 9 then bv = 0 end
        return bv
    end
    local function is_leopard(balls)
        local cond1 = balls[1] == balls[2]
        local cond2 = balls[1] == balls[3]
        local cond3 = balls[2] == balls[3]
        return cond1 and cond2 and cond3
    end
    local function is_straight(balls)
        local cond1 = (next_ball_value(balls[1]) == balls[2] and next_ball_value(balls[2]) == balls[3])
        local cond2 = (next_ball_value(balls[1]) == balls[3] and next_ball_value(balls[3]) == balls[2])
        local cond3 = (next_ball_value(balls[2]) == balls[1] and next_ball_value(balls[1]) == balls[3])
        local cond4 = (next_ball_value(balls[2]) == balls[3] and next_ball_value(balls[3]) == balls[1])
        local cond5 = (next_ball_value(balls[3]) == balls[2] and next_ball_value(balls[2]) == balls[1])
        local cond6 = (next_ball_value(balls[3]) == balls[1] and next_ball_value(balls[1]) == balls[2])
        return cond1 or cond2 or cond3 or cond4 or cond5 or cond6
    end
    local function is_couplet(balls)
        local cond1 = balls[1] == balls[2]
        local cond2 = balls[1] == balls[3]
        local cond3 = balls[2] == balls[3]
        return cond1 or cond2 or cond3
    end
    local function is_semi_straight(balls)
        local cond1 = next_ball_value(balls[1]) == balls[2]
        local cond2 = next_ball_value(balls[2]) == balls[1]
        local cond3 = next_ball_value(balls[3]) == balls[2]
        local cond4 = next_ball_value(balls[2]) == balls[3]
        local cond5 = next_ball_value(balls[1]) == balls[3]
        local cond6 = next_ball_value(balls[3]) == balls[1]
        return cond1 or cond2 or cond3 or cond4 or cond5 or cond6
    end
    if is_leopard(balls) then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_THREE_BALL_PLAY.LEOPARD
    elseif is_straight(balls) then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_THREE_BALL_PLAY.STRAIGHT
    elseif is_couplet(balls) then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_THREE_BALL_PLAY.COUPLET
    elseif is_semi_straight(balls) then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_THREE_BALL_PLAY.SEMI_STRAIGHT
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_THREE_BALL_PLAY.DISORDER
    end
end

local function match_state_dragon_tiger_tie_play(balls)
    if balls[1] > balls[5] then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_DRAGON_TIGER_TIE_PLAY.DRAGON
    elseif balls[1] < balls[5] then
        return lottery_const.GAME_JSSSC_BETTING.BETTING_DRAGON_TIGER_TIE_PLAY.TIGER
    else
        return lottery_const.GAME_JSSSC_BETTING.BETTING_DRAGON_TIGER_TIE_PLAY.TIE
    end
end

local root = {}

function root.calculate_lottery_jsssc_results(balls)
    local open_award_opcode = {}

    local state = match_state_single_ball_value_play(balls[1])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_1_VALUE] = state
    local state = match_state_single_ball_face_play(balls[1])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_1_FACE] = state
    local state = match_state_single_ball_size_play(balls[1])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_1_SIZE] = state
    
    local state = match_state_single_ball_value_play(balls[2])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_2_VALUE] = state
    local state = match_state_single_ball_face_play(balls[2])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_2_FACE] = state
    local state = match_state_single_ball_size_play(balls[2])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_2_SIZE] = state

    local state = match_state_single_ball_value_play(balls[3])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_3_VALUE] = state
    local state = match_state_single_ball_face_play(balls[3])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_3_FACE] = state
    local state = match_state_single_ball_size_play(balls[3])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_3_SIZE] = state

    local state = match_state_single_ball_value_play(balls[4])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_4_VALUE] = state
    local state = match_state_single_ball_face_play(balls[4])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_4_FACE] = state
    local state = match_state_single_ball_size_play(balls[4])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_4_SIZE] = state

    local state = match_state_single_ball_value_play(balls[5])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_5_VALUE] = state
    local state = match_state_single_ball_face_play(balls[5])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_5_FACE] = state
    local state = match_state_single_ball_size_play(balls[5])
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SINGLE_BALL_5_SIZE] = state

    
    local state = match_state_sum_ball_face_play(balls)
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SUM_BALL_FACE] = state
    local state = match_state_sum_ball_size_play(balls)
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.SUM_BALL_SIZE] = state
    
    local state = match_state_three_ball_play({balls[1], balls[2], balls[3]})
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.FIRST_THREE_BALL] = state
    local state = match_state_three_ball_play({balls[2], balls[3], balls[4]})
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.MIDDLE_THREE_BALL] = state
    local state = match_state_three_ball_play({balls[3], balls[4], balls[5]})
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.LAST_THREE_BALL] = state

    local state = match_state_dragon_tiger_tie_play(balls)
    open_award_opcode[lottery_const.GAME_JSSSC_BETTING.BETTING_MODULE.LAST_THREE_BALL] = state

    return open_award_opcode
end

function root.betting(msg)
	if type(msg) ~= "table" or
        type(msg.game_type) ~= "string" or
		type(msg.module) ~= "string" or
		type(msg.slot) ~= "string" or
		type(msg.amount) ~= "number" then
		return {code = error_code_config.ERROR_CLIENT_PARAMETER_TYPE.value, err = error_code_config.ERROR_CLIENT_PARAMETER_TYPE.desc}
	end
    -- 下注时间,用户ID,开盘期数,游戏类型,模块,位置,下注金额,结算金额
    local data = {
        
    }
    db_help.call("lottery_db.lottery_append_betting_record", data)

end

function root.clear()
end

function root.detail()
end

return root