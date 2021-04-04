local root = {}

function root.create_user(db, data)
    db.user:safe_insert(data)
end

function root.get_user(db, username)
    return db.user:findOne({
        username = username
    })
end

function root.update_user_money(db, data)
    local conds = {
        _id = data.uid
    }
    local data = {
        ["$inc"] = {
            money = data.win_amount
        }
    }
    db.user:update(conds, data, {upsert = true})
end

return root