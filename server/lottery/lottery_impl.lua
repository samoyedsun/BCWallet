local lottery_ctrl = require "lottery.lottery_ctrl"

local root = {}

function root:betting(msg)
    return lottery_ctrl.betting(msg, self.uid)
end

function root:get_lottery_info(msg)
    return lottery_ctrl.get_lottery_info(msg, self.uid)
end

function root:get_lottery_state_list(msg)
    return lottery_ctrl.get_lottery_state_list()
end

function root:clear(msg)
    return lottery_ctrl.clear(msg)
end

function root:detail(msg)
    return lottery_ctrl.detail(msg)
end

return root