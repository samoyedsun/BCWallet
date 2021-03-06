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
    data.wallet_name = param.wallet_name
    data.wallet_address = param.wallet_address

    db.user:safe_insert(data)
    
    return data._id
end

function root.get_user(db, param)
    local username = param.username
    return db.user:findOne({
        username = username
    }, {
        _id = 1,
        wallet_name = 1,
        wallet_address = 1
    })
end

return root