local skynet = require "skynet"
require "skynet.manager"
require "skynet.queue"
local queueEnter = skynet.queue()
local logger = log4.get_logger(SERVICE_NAME)

local game_api_list = {
    {
        game_id = 1,
        host = 'http://api.79api.com',
        url = '/test',
        param = { token='9B5C76ABF79459DD', code='cqssc', rows='1', format='json' },
        process = function(res)
            local info = res.data[1]
            local opencode = info.opencode
            local opencodelist = string.split(opencode, ",")
            local expect = info.expect
            local opentime = info.opentime
            logger.info("process_fetch_data, opencodelist:%s, expect:%s, opentime:%s", cjson_encode(opencodelist), expect, opentime)
        end
    }
}

function process_fetch_data()
	skynet.timeout(300, function()
		process_fetch_data()	
	end)
    
    for k, v in ipairs(game_api_list) do
        skynet.fork(function(info)
            local trace_err = ""
            local trace = function (e)
                trace_err = tostring(e) .. debug.traceback()
            end
            local ok, res = xpcall(http_request, trace, "GET", info.host, info.url, info.param)
            if not ok then
                logger.error("process_fetch_data error 1, id:%s, trace_err:%s", info.game_id, trace_err)
            else
                if type(res) == "table" then
                    info.process(res)
                else
                    logger.error("process_fetch_data error 2, id:%s, res:%s", info.game_id, res)
                end
            end
        end, v)
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
        queueEnter(f, ...)
    else
        skynet.ret(skynet.pack(queueEnter(f, ...)))
    end
end)

skynet.start(function()
    skynet.register("THIRD_API")
    process_fetch_data()
end)