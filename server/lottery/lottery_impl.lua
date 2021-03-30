local lottery_ctrl = require "lottery.lottery_ctrl"

local root = {}

function root:betting(msg)
    return lottery_ctrl.betting(msg, self.ip)
end

function root:clear(msg)
    return lottery_ctrl.clear(msg)
end

function root:withdraw(msg)
    return lottery_ctrl.withdraw(msg)
end

function root:detail(msg)
    return lottery_ctrl.detail(msg)
end

return root