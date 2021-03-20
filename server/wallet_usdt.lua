local skynet = require "skynet"
local conf = require "config.conf"
local logger = log4.get_logger(SERVICE_NAME)

local root = {}

-- 创建钱包
function root.createwallet(wallet_name)
    local method = "createwallet"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {wallet_name})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 加密钱包
function root.encryptwallet(wallet_name, passphrase)
    local method = "encryptwallet"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {passphrase})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 解密钱包 超时后自动锁定
function root.walletpassphrase(wallet_name, passphrase, timeout)
    local method = "walletpassphrase"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {passphrase, timeout})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 获取钱包信息
function root.getwalletinfo(wallet_name)
    local method = "getwalletinfo"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 新建钱包地址
function root.getnewaddress(wallet_name, lable)
    local method = "getnewaddress"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {lable})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 获取钱包地址
function root.getaddressesbylabel(wallet_name, lable)
    local method = "getaddressesbylabel"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {lable})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 获取钱包地址信息
function root.getaddressinfo(wallet_name, address)
    local method = "getaddressinfo"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {address})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 获取USDT数量
function root.omni_getbalance(address)
    local method = "omni_getbalance"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {address, 31})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

-- 获取USDT数量
function root.omni_getallbalancesforid()
    local method = "omni_getallbalancesforid"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {31})
    local path = "/"
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

function root.omni_funded_send(wallet_name, fromaddress, toaddress, amount, feeaddress)
    local method = "omni_funded_send"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {fromaddress, toaddress, 31, amount, feeaddress})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

function root.omni_gettransaction(wallet_name, txid)
    local method = "omni_funded_send"
    local param = conf.OMNICORE_GENERATION_PARAMS(method, {txid})
    local path = "/wallet/" .. wallet_name
    local host = conf.OMNICORE_HOST
    local res = http_request("POST", host, path, param, conf.OMNICORE_SENDHEADER)
    if type(res.error) == "table" then
       return false, res.error
    end
    return true, res.result
end

return root