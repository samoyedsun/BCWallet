local root = {}

function root.create_user(db, param)
	local data = {}
    data._id = param._id
	data.create_time = param.create_time
    data.username = param.username
    data.password = param.password
    data.login_ip = param.login_ip
    data.avatar = param.avatar
    data.gender = param.gender

    db.user:safe_insert(data)
    
    return data._id
end

function root.get_user(db, param)
    local username = param.username
    local ret = db.user:findOne({username = username}, {_id = 1})
    return ret and ret._id
end

return root