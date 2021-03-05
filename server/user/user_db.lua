local root = {}

function root.create_user(db, data)
	data._id = data._id
	data.create_time = skynet.time()
    data.username = data.username
    data.password = data.password
    data.login_ip = data.ip
    data.avatar = data.avatar
    data.gender = data.gender

    db.user:safe_insert(data)
    
    return data._id
end

return root