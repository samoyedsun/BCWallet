local skynet = require "skynet"
local code = require "server.config.code"
local conf = require "server.config.conf"
local comm = require "server.config.comm"
local logger = log4.get_logger("server_frontend_request_web_user")

local REQUEST = {}

function REQUEST:create_wallet(msg)
    if type(msg) ~= "table" or type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local wallet_name = msg.wallet_name
    local sendheader = {
        ["Content-Type"] = "application/json",
        ["Accept-Charset"] = "utf-8",
        ["Authorization"] = "Basic " .. conf.OMNICORE_BASIC_AUTH
    }
    local param = {
        id = "1",
        jsonrpc = "2.0",
        method = "createwallet",
        params = {
            wallet_name
        }
    }
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, sendheader)
    if type(res.error) == "table" then
       logger.debug("REQUEST:create_wallet error_msg:%s", cjson_encode(res.error))
       return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_login(msg)
    local tmp_code = msg.code
    local platform = msg.platform
    if type(tmp_code) ~= "string" or
        type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:fetch_token(msg)
    local uid = msg.uid
    local platform = msg.platform
    if type(uid) ~= "number" or
        type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_config(msg)
    local platform = msg.platform
    if type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_pay_unifiedorder(msg)
    local uid = msg.uid
    local id = msg.id
    if type(uid) ~= "number" or
        type(id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_pay(msg)
    local uid = msg.uid
    local id = msg.id
    local out_trade_no = msg.out_trade_no
    if type(uid) ~= "number" or
        type(id) ~= "number" or
        type(out_trade_no) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:apple_pay(msg)
    local uid = msg.uid
    local id = msg.id
    local reciept_data = msg.reciept_data
    if type(uid) ~= "number" or
        type(id) ~= "number" or
        type(reciept_data) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

local root = {}

function root.request(req)
    local name = req.params.name
    if not REQUEST[name] then
        return {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
    end
    local msg
    if req.method == "GET" then
        msg = req.query
    else
        msg = cjson_decode(req.body)
    end
    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res = xpcall(REQUEST[name], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        return {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
    end
    return res
end

return root