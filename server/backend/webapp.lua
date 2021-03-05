local skynet = require "skynet"
local webapp = require "web.app"
local jproto = require "jproto"
local webproto = require "web.proto"
local user = require "server.backend.request.web_user"
local web_util = require "utils.web_util"
local logger = log4.get_logger(SERVICE_NAME)
web_util.set_logger(logger)
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
    res:json(user.request(req))
    return true
end)

webapp.post("^/jproto$", function ( ... )
    webproto:process(...)
end)

webapp.after(".*", function(req, res)
    logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), tostring(res.body))
    return true
end)

webapp.static("^/*", "./server/backend/views/")

return webapp