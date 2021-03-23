local skynet = require "skynet"

local BETTING_MODULE = {
    SINGLE_BALL_1_VALUE,
    SINGLE_BALL_1_FACE,
    SINGLE_BALL_1_SIZE,
    SINGLE_BALL_2_VALUE,
    SINGLE_BALL_2_FACE,
    SINGLE_BALL_2_SIZE,
    SINGLE_BALL_3_VALUE,
    SINGLE_BALL_3_FACE,
    SINGLE_BALL_3_SIZE,
    SINGLE_BALL_4_VALUE,
    SINGLE_BALL_4_FACE,
    SINGLE_BALL_4_SIZE,
    SINGLE_BALL_5_VALUE,
    SINGLE_BALL_5_FACE,
    SINGLE_BALL_5_SIZE,
    SUM_BALL_FACE,
    SUM_BALL_SIZE,
    FIRST_THREE_BALL,
    MIDDLE_THREE_BALL,
    LAST_THREE_BALL,
    DRAGON_TIGER_TIE
}

local BETTING_SINGLE_BALL_VALUE_PLAY = {
    NUMBER0 = "NUMBER0",
    NUMBER1 = "NUMBER1",
    NUMBER2 = "NUMBER2",
    NUMBER3 = "NUMBER3",
    NUMBER4 = "NUMBER4",
    NUMBER5 = "NUMBER5",
    NUMBER6 = "NUMBER6",
    NUMBER7 = "NUMBER7",
    NUMBER8 = "NUMBER8",
    NUMBER9 = "NIMBER9"
}

local BETTING_FACE_PLAY = {
    SINGLE = "SINGLE",
    DOUBLE = "DOUBLE"
}

local BETTING_SIZE_PLAY = {
    LARGE = "LARGE",
    SMALL = "SMALL"
}

local BETTING_THREE_BALL_PLAY = {
    LEOPARD = "LEOPARD",                -- 豹子
    STRAIGHT = "STRAIGHT",              -- 顺子
    COUPLET = "COUPLET",                -- 对子
    SEMI_STRAIGHT = "SEMI_STRAIGHT",    -- 半顺
    DISORDER = "DISORDER"               -- 杂六
}

local BETTING_DRAGON_TIGER_TIE_PLAY = {
    DRAGON = "DRAGON",
    TIGER = "TIGER",
    TIE = "TIE"
}

local function match_state_single_ball_value_play(ball)
    local state_map = {
        [0] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER0,
        [1] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER1,
        [2] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER2,
        [3] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER3,
        [4] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER4,
        [5] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER5,
        [6] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER6,
        [7] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER7,
        [8] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER8,
        [9] = BETTING_SINGLE_BALL_VALUE_PLAY.NUMBER9
    }
    return state_map[ball]
end

local function match_state_single_ball_face_play(ball)
    return ((ball % 2) == 0 and {BETTING_FACE_PLAY.DOUBLE} or {BETTING_FACE_PLAY.SINGLE})[1]
end

local function match_state_single_ball_size_play(ball)
    return (ball >= 5 and {BETTING_SIZE_PLAY.LARGE} or {BETTING_SIZE_PLAY.SMALL})[1]
end

local function match_state_sum_ball_face_play(balls)
    local sum_ball = 0
    for k, ball in ipairs(balls) do
        sum_ball = sum_ball + ball
    end
    return ((sum_ball % 2) == 0 and {BETTING_FACE_PLAY.DOUBLE} or {BETTING_FACE_PLAY.SINGLE})[1]
end

local function match_state_sum_ball_size_play(balls)
    local sum_ball = 0
    for k, ball in ipairs(balls) do
        sum_ball = sum_ball + ball
    end
    return (sum_ball >= 23 and {BETTING_SIZE_PLAY.LARGE} or {BETTING_SIZE_PLAY.SMALL})[1]
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
        return BETTING_THREE_BALL_PLAY.LEOPARD
    elseif is_straight(balls) then
        return BETTING_THREE_BALL_PLAY.STRAIGHT
    elseif is_couplet(balls) then
        return BETTING_THREE_BALL_PLAY.COUPLET
    elseif is_semi_straight(balls) then
        return BETTING_THREE_BALL_PLAY.SEMI_STRAIGHT
    else
        return BETTING_THREE_BALL_PLAY.DISORDER
    end
end

local function match_state_dragon_tiger_tie_play(balls)
    if balls[1] > balls[5] then
        return BETTING_DRAGON_TIGER_TIE_PLAY.DRAGON
    elseif balls[1] < balls[5] then
        return BETTING_DRAGON_TIGER_TIE_PLAY.TIGER
    else
        return BETTING_DRAGON_TIGER_TIE_PLAY.TIE
    end
end

skynet.start(function ( ... )
    local balls = {0, 2, 5, 4, 3}
    local state = match_state_single_ball_value_play(balls[1])
    print(state)
    local state = match_state_single_ball_face_play(balls[1])
    print(state)
    local state = match_state_single_ball_size_play(balls[1])
    print(state)
    local state = match_state_sum_ball_face_play(balls)
    print(state)
    local state = match_state_sum_ball_size_play(balls)
    print(state)
    local state = match_state_three_ball_play({balls[1], balls[2], balls[3]})
    print(state)
    local state = match_state_three_ball_play({balls[2], balls[3], balls[4]})
    print(state)
    local state = match_state_three_ball_play({balls[3], balls[4], balls[5]})
    print(state)
    local state = match_state_dragon_tiger_tie_play(balls)
    print(state)
    skynet.exit()
end)
