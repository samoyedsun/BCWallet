local skynet = require "skynet"
local context = require "context"
local db_help = require "db_help"
local code = require "config.code"

local root = {}

function root.register(msg, ip)
	if type(msg) ~= "table" or
		type(msg.username) ~= "string" or
		type(msg.password) ~= "string" then
		return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
	end

	-- 先查询
	local param = {
		username = msg.username
	}
	local user_id = db_help.call("user_db.get_user", param);
	if user_id then
		return {code = code.ERROR_USER_ALREADY_EXISTED, err = code.ERROR_USER_ALREADY_EXISTED_MSG}
	end
	
	local param = {
		_id = context.call_s2s("MONGO_DB", "get_autoincrid", "user"),
		create_time = skynet.time(),
		username = msg.username,
		password = msg.password,
		login_ip = ip,
		avatar = 1,
		gender = 1,
	}

	db_help.call("user_db.create_user", param)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function root.login(msg)
	if type(msg) ~= "table" or
		type(msg.username) ~= "string" or
		type(msg.password) ~= "string" then
		return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
	end

	-- 先查询
	local param = {
		username = msg.username
	}
	local user_id = db_help.call("user_db.get_user", param);
	if not user_id then
		return {code = code.ERROR_USER_NOT_EXIST, err = code.ERROR_USER_NOT_EXIST_MSG}
	end
	
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

return root