local db_help = require "db_help"
local autoincrid_const = require "autoincrid.autoincrid_const"

local SERVER_PART_OFFSET = 11
local serverId
local function get_key_max_id(key_name)
	local max_id = db_help.call("autoincrid_db.get_max_autoincrid", key_name, SERVER_PART_OFFSET)
	if max_id then
		local tmp_max_id = tonumber(max_id)
		assert(tmp_max_id ~= nil, "获取最大自增加ID失败，key_name = " .. key_name .. " 返回的 max_id =" .. max_id)
		return tmp_max_id
	end
	return 1000
end

local autoincrid_list = {}
local root = {}

function root.init_autoincrid()
	for _, key_name in ipairs(autoincrid_const) do
		autoincrid_list[key_name] = get_key_max_id(key_name)
	end
end

function root.get_autoincrid(key_name)
	if not autoincrid_list[key_name] then
		autoincrid_list[key_name] = get_key_max_id(key_name)
	end

	autoincrid_list[key_name] = autoincrid_list[key_name] + math.random(1, 10)
	return autoincrid_list[key_name]
end

return root