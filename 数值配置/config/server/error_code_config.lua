-- .//g_公共配置表.xlsx error_code_config
-- key:标识  value:值  desc:描述 
local error_code_config = {
	["SUCCEED"] = {
		key = [[SUCCEED]],
		value = 10000,
		desc = [[成功！]],
	},
	["ERROR_INTERNAL_SERVER"] = {
		key = [[ERROR_INTERNAL_SERVER]],
		value = 10001,
		desc = [[服务器内部错误！]],
	},
	["ERROR_NAME_UNFOUND"] = {
		key = [[ERROR_NAME_UNFOUND]],
		value = 10002,
		desc = [[接口名未找到！]],
	},
	["ERROR_CLIENT_PARAMETER_TYPE"] = {
		key = [[ERROR_CLIENT_PARAMETER_TYPE]],
		value = 10003,
		desc = [[客户端参数类型错误！]],
	},
	["ERROR_CLIENT_PARAMETER_VALUE"] = {
		key = [[ERROR_CLIENT_PARAMETER_VALUE]],
		value = 10004,
		desc = [[客户端参数值错误！]],
	},
	["ERROR_REQUEST_THIRD_PARTY"] = {
		key = [[ERROR_REQUEST_THIRD_PARTY]],
		value = 10005,
		desc = [[请求第三方出错,请查看日志了解详情！]],
	},
	["ERROR_VERSION_OLDER"] = {
		key = [[ERROR_VERSION_OLDER]],
		value = 10006,
		desc = [[版本更新，请重新登陆！]],
	},
	["ERROR_INVALID_OPERATION"] = {
		key = [[ERROR_INVALID_OPERATION]],
		value = 10007,
		desc = [[非法操作!]],
	},
	["ERROR_USER_UNAUTH"] = {
		key = [[ERROR_USER_UNAUTH]],
		value = 10100,
		desc = [[未授权！]],
	},
	["ERROR_USER_ALREADY_EXISTED"] = {
		key = [[ERROR_USER_ALREADY_EXISTED]],
		value = 10101,
		desc = [[用户已经存在，请登陆！]],
	},
	["ERROR_USER_NOT_EXIST"] = {
		key = [[ERROR_USER_NOT_EXIST]],
		value = 10102,
		desc = [[用户不存在，需要先注册！]],
	},
	["ERROR_USER_PASSWORD"] = {
		key = [[ERROR_USER_PASSWORD]],
		value = 10103,
		desc = [[用户密码错误！]],
	},
	["ERROR_USER_AUTH_FAILED"] = {
		key = [[ERROR_USER_AUTH_FAILED]],
		value = 10104,
		desc = [[数据非法，验证失败！]],
	},
	["ERROR_USER_LOGIIN_OTHER_DEVICE"] = {
		key = [[ERROR_USER_LOGIIN_OTHER_DEVICE]],
		value = 10105,
		desc = [[您的账号在其他设备登陆！]],
	},
	["ERROR_USER_SESSION_EXPIRED"] = {
		key = [[ERROR_USER_SESSION_EXPIRED]],
		value = 10106,
		desc = [[会话过期，验证失败！]],
	},
	["ERROR_USER_NEED_TO_LOGIN"] = {
		key = [[ERROR_USER_NEED_TO_LOGIN]],
		value = 10107,
		desc = [[您未登陆，需先登陆!]],
	},
	["ERROR_SEALING_CAN_NOT_BETTING"] = {
		key = [[ERROR_SEALING_CAN_NOT_BETTING]],
		value = 10200,
		desc = [[封盘期间不可下注!]],
	},
}

return error_code_config