local root = {}

function root.push_lottery_history(db, param)
	local data = param

    db.lottery_history:safe_insert(data)
    
    return data._id
end

function root.find_lottery_history(db, id)
    return db.lottery_history:findOne({ _id = id })
end

return root