local skynet = require "skynet"
local jproto = require "jproto"
local webapp = require "web.app"
local webproto = require "web.proto"
local web_util = require "utils.web_util"
local code = require "config.code"
local logger = log4.get_logger(SERVICE_NAME)
web_util.set_logger(logger)

local modules = {
    user = require "user.user_impl"
}

local webproto = webproto:new(jproto.host)

webproto:use("error", function ( ... )
    print(...)
    return false
end)

webproto:use(".*", function (req, name, args, res)
    table.merge(res, { test = "is test rpc ", msg = "hello world"})
    return true
end)

webproto:before(".*", web_util.before_log)
webproto:after(".*", web_util.after_log)

--------------------------------------------------------------
webapp.before(".*", function (req, res)
    res.headers["Access-Control-Allow-Origin"] = "*"
    res.headers["Access-Control-Allow-Methods"] = "*"
    res.headers["Access-Control-Allow-Credentials"] = "true"
    return true
end)
webapp.before(".*", function(req, res)
    logger.debug("before web req %s body %s", tostring(req.url), tostring(req.body))
    return true
end)

webapp.use("^/:module/:command$", function (req, res)
    local module = req.params.module
    local command = req.params.command

    local REQUEST = modules[module]
    if not REQUEST or not REQUEST[command] then
        local result = {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
        res:json(result)
        return true
    end
    local msg = req.query
    if req.method == "POST" then
        msg = cjson_decode(req.body)
    end
    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res_data = xpcall(REQUEST[command], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        local result = {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
        res:json(result)
        return true
    end
    res:json(res_data)
    return true
end)

webapp.post("^/jproto$", function ( ... )
    webproto:process(...)
end)

webapp.after(".*", function(req, res)
    if req.params and req.params.module then
        logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), tostring(res.body))
    else
        logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), string.len(res.body))
    end
    return true
end)

-- webapp.static("^/*", "./server/frontend/views/")

return webapp