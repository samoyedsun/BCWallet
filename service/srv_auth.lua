local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()

local sid_to_session = {}

local CMD = {}

function CMD.set_session(sid, session)
    sid_to_session[sid] = session
end

function CMD.get_session(sid)
    return sid_to_session[sid]
end

function CMD.del_session(sid)
    sid_to_session[sid] = nil
end

function CMD.create_sid(uid, timestamp)
    local random_str = random_string(16)
    local sid = md5.sumhexa(string.format("%s:%s:%s:", uid, timestamp, random_str))
    return sid
end

skynet.start(function()
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
end)