local skynet = require "skynet"
local code = require "server.config.code"
local conf = require "server.config.conf"
local comm = require "server.config.comm"
local logger = log4.get_logger(SERVICE_NAME)

local REQUEST = {}

-- 创建钱包
function REQUEST:createwallet(msg)
    if type(msg) ~= "table" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local wallet_name = msg.wallet_name
    local method = "createwallet"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {wallet_name})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
       return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 加密钱包
function REQUEST:encryptwallet(msg)
    if type(msg) ~= "table" or
        type(msg.passphrase) ~= "string" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local passphrase = msg.passphrase
    local wallet_name = msg.wallet_name
    local method = "encryptwallet"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {passphrase})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 解密钱包 超时后自动锁定
function REQUEST:walletpassphrase(msg)
    if type(msg) ~= "table" or
        type(msg.wallet_name) ~= "string" or
        type(msg.passphrase) ~= "string" or
        type(msg.timeout) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local passphrase = msg.passphrase
    local timeout = msg.timeout
    local wallet_name = msg.wallet_name
    local method = "walletpassphrase"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {passphrase, timeout})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 获取钱包信息
function REQUEST:getwalletinfo(msg)
    if type(msg) ~= "table" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local wallet_name = msg.wallet_name
    local method = "getwalletinfo"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
       return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 新建钱包地址
function REQUEST:getnewaddress(msg)
    if type(msg) ~= "table" or
        type(msg.lable) ~= "string" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local lable = msg.lable
    local wallet_name = msg.wallet_name
    local method = "getnewaddress"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {lable})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 获取钱包地址
function REQUEST:getaddressesbylabel(msg)
    if type(msg) ~= "table" or
        type(msg.lable) ~= "string" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local lable = msg.lable
    local wallet_name = msg.wallet_name
    local method = "getaddressesbylabel"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {lable})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 获取钱包地址信息
function REQUEST:getaddressinfo(msg)
    if type(msg) ~= "table" or
        type(msg.address) ~= "string" or
        type(msg.wallet_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local address = msg.address
    local wallet_name = msg.wallet_name
    local method = "getaddressinfo"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {address})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 获取USDT数量
function REQUEST:omni_getbalance(msg)
    if type(msg) ~= "table" or
        type(msg.address) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local address = msg.address
    local method = "omni_getbalance"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {address, 31})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

-- 获取USDT数量  need to add config to bitcoin.conf
-- please see http://www.ryanbrowndev.com/2017/06/21/dash-node-address-balance-querying-error-no-information-available-for-address/
-- please see https://github.com/bitpay/bitcore-node/blob/master/docs/upgrade.md
function REQUEST:getaddressbalance(msg)
    if type(msg) ~= "table" or
        type(msg.addresses) ~= "table" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local addresses = msg.addresses
    local method = "getaddressbalance"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {{addresses = addresses}})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:omni_funded_send(msg)
    if type(msg) ~= "table" or
        type(msg.wallet_name) ~= "string" or
        type(msg.fromaddress) ~= "string" or
        type(msg.toaddress) ~= "string" or
        type(msg.amount) ~= "string" or
        type(msg.feeaddress) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local wallet_name = msg.wallet_name
    local fromaddress = msg.fromaddress
    local toaddress = msg.toaddress
    local amount = msg.amount
    local feeaddress = msg.feeaddress
    local method = "omni_funded_send"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {fromaddress, toaddress, 31, amount, feeaddress})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:omni_gettransaction(msg)
    if type(msg) ~= "table" or
        type(msg.wallet_name) ~= "string" or
        type(msg.txid) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local wallet_name = msg.wallet_name
    local txid = msg.txid
    local method = "omni_funded_send"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {txid})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = comm.http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
        logger.debug("%s error_msg:%s", method, cjson_encode(res.error))
        return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG}
    end
    local data = res.result
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
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