local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queue_enter = skynet.queue()

local SECRET_8BIT = "lVp4k0vE"
local LIFE_CYCLE = 3600
local sid_to_session = {}
local uid_to_session = {}

local CMD = {}

function CMD.set_session(uid, login_time, password)
    local session = uid_to_session[uid]
    if session then
        uid_to_session[session.uid] = nil
        sid_to_session[session.sid] = nil
    end
    -- 这里为了能检测到其他地点登陆，所以用token的生成算法，方便解析
    local sid = token_create(uid, login_time, password, SECRET_8BIT)
    local expired = login_time + LIFE_CYCLE
    local session = {
        uid = uid,
		sid = sid,
		login_time = login_time,
		expired = expired,
	}
    sid_to_session[sid] = session
    uid_to_session[uid] = session
    return sid
end

function CMD.renew_expired(sid, now_time)
    local session = sid_to_session[sid]
    session.expired = now_time + LIFE_CYCLE
end

function CMD.get_session_by_sid(sid)
    local trace_err = ""
    local trace = function (e)
        trace_err = tostring(e) .. debug.traceback()
    end
    local ok, uid, timestamp, password = xpcall(token_parse, trace, sid, SECRET_8BIT)
    if ok then
        uid = tonumber(uid)
        return sid_to_session[sid], uid, timestamp, password
    end
    skynet.error("sid:%s, trace_err:%s", sid, trace_err)
end

function CMD.get_session_by_uid(uid)
    local session = uid_to_session[uid]
    if session then
        local uid, timestamp, password = token_parse(session.sid, SECRET_8BIT)
        return session, uid, timestamp, password
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
end)