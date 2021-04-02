local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local md5 =	require	"md5"
local queue_enter = skynet.queue()

local LIFE_CYCLE = 3600
local uid_to_session = {}

local CMD = {}

function CMD.set_session(uid, now_time)
    local session = uid_to_session[uid]
    if session then
        uid_to_session[session.uid] = nil
    end
    local sid = md5.sumhexa(string.format("%s:session:%s", uid, random_string(32)))
    local expired = now_time + LIFE_CYCLE
    local session = {
        uid = uid,
		sid = sid,
		login_time = now_time,
		expired = expired,
	}
    uid_to_session[uid] = session
    return sid, expired
end

function CMD.renew_expired(uid, now_time)
    local session = uid_to_session[uid]
    session.expired = now_time + LIFE_CYCLE
end

function CMD.get_session_by_uid(uid)
    return uid_to_session[uid]
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
end)