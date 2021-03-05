local context = require("context")
local db_help = require("db_help")
local code = require "config.code"
local root = {}

function root.create()
	-- 创建用户
	local data = {}
	data._id = context.call_s2s("MONGO_DB", "get_autoincrid", "user")
	local roleId = db_help.call("user_db.create", data)

return root