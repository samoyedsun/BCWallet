local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local md5 =	require	"md5"
local queue_enter = skynet.queue()

local LIFE_CYCLE = 3600
local sid_to_session = {}

local CMD = {}

function CMD.set_session(uid, now_time)
    local session = sid_to_session[uid]
    if session then
        sid_to_session[session.uid] = nil
    end
    local sid = md5.sumhexa(string.format("%s:session:%s", uid, random_string(32)))
    local expired = now_time + LIFE_CYCLE
    local session = {
        uid = uid,
		sid = sid,
		login_time = now_time,
		expired = expired,
	}
    sid_to_session[sid] = session
    return sid, LIFE_CYCLE
end

function CMD.renew_expired(sid)
    local now_time = skynet_time()
    local session = sid_to_session[sid]
    session.expired = now_time + LIFE_CYCLE
end

function CMD.get_session(sid)
    local now_time = skynet_time()
    local session = sid_to_session[sid]
    if session and session.expired < now_time then
        sid_to_session[sid] = nil
    end
    return sid_to_session[sid]
end

local function on_tick()
    create_timeout(60 * 100, function() on_tick() end)
    
    local now_time = skynet_time()
    local session = sid_to_session[sid]
    for sid, session in pairs(sid_to_session) do
        if session and session.expired < now_time then
            sid_to_session[sid] = nil
        end
    end
end

skynet.start(function()
    skynet.register(SERVICE_NAME)
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

    create_timeout(3 * 100, function() on_tick() end)
end)