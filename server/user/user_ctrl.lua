local skynet = require "skynet"
local context = require "context"
local db_help = require "db_help"
local code = require "config.code"
local wallet_usdt = require "wallet_usdt"

local root = {}

function root.register(msg, ip)
	if type(msg) ~= "table" or
		type(msg.username) ~= "string" or
		type(msg.password) ~= "string" then
		return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
	end
	local username = msg.username
	local password = msg.password
	
	local param = {
		username = username
	}
	local user_id = db_help.call("user_db.get_user", param);
	if user_id then
		local data = {user_id = user_id}
		return {code = code.ERROR_USER_ALREADY_EXISTED, err = code.ERROR_USER_ALREADY_EXISTED_MSG, data = data}
	end
	
	local ok, result = wallet_usdt.createwallet(username)
	if not ok then
		return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG, data = result}
	end
	local wallet_name = result.name

	local ok, result = wallet_usdt.getnewaddress(wallet_name, "default")
	if not ok then
		return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG, data = result}
	end
	local wallet_address = result

	local param = {
		_id = context.call_s2s("MONGO_DB", "get_autoincrid", "user"),
		create_time = skynet.time(),
		username = username,
		password = password,
		login_ip = ip,
		avatar = 1,
		gender = 1,
		wallet_name = wallet_name,
		wallet_address = wallet_address,
	}

	local user_id = db_help.call("user_db.create_user", param)

	local data = {user_id = user_id}
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function root.login(msg)
	if type(msg) ~= "table" or
		type(msg.username) ~= "string" or
		type(msg.password) ~= "string" then
		return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
	end
	
	local param = {
		username = msg.username
	}
	local result = db_help.call("user_db.get_user", param);
	if not result then
		return {code = code.ERROR_USER_NOT_EXIST, err = code.ERROR_USER_NOT_EXIST_MSG}
	end
	local wallet_address = result.wallet_address

	local ok, result = wallet_usdt.omni_getbalance(wallet_address)
	if not ok then
		return {code = code.ERROR_REQUEST_THIRD_PARTY, err = code.ERROR_REQUEST_THIRD_PARTY_MSG, data = result}
	end

	
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = result}
end

return root