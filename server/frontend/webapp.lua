local skynet = require "skynet"
local jproto = require "jproto"
local webapp = require "web.app"
local webproto = require "web.proto"
local web_util = require "utils.web_util"
local code = require "config.code"
local logger = log4.get_logger(SERVICE_NAME)
web_util.set_logger(logger)

local modules = {}

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

webapp.use("^/user/:name$", function (req, res)
    modules.user = modules.user or require "user.user_impl"
    local REQUEST = modules.user

    local name = req.params.name
    if not REQUEST[name] then
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
    local ok, res_data = xpcall(REQUEST[name], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        local result = {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
        res:json(result)
        return true
    end
    res:json(res_data)
    return true
end)

webapp.use("^/wallet/:name$", function (req, res)
    res:json(wallet.request(req))
    return true
end)

webapp.post("^/jproto$", function ( ... )
    webproto:process(...)
end)

webapp.after(".*", function(req, res)
    logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), string.len(res.body))
    return true
end)

webapp.static("^/*", "./server/frontend/views/")

return webapp