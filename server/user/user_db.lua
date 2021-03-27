local root = {}

function root.create_user(db, data)
    db.user:safe_insert(data)
end

function root.get_user(db, username)
    return db.user:findOne({
        username = username
    })
end

return root