local root = {}

function root.lottery_jsssc_find_history(db, issue)
    local conds = {
        _id = issue
    }
    return db.lottery_jsssc_history:findOne(conds)
end


function root.lottery_jsssc_find_miss_history(db)
    local conds = {
        balls = {
            ["$exists"] = false
        }
    }
    local res = db.lottery_jsssc_history:find(conds)
    local results = {}
	while res:hasNext() do
		local st = res:next()
		st._id = nil
		results[st.issue] = st
	end
	return results
end

function root.lottery_jsssc_append_history(db, data)
    db.lottery_jsssc_history:safe_insert(data)
end

function root.lottery_jsssc_update_history(db, issue, balls, opening_opcode)
    local conds = {
        _id = issue
    }
    local data = {
        ["$set"] = {
            balls = balls,
            opening_opcode = opening_opcode
        }
    }
    db.lottery_jsssc_history:update(conds, data)
end

function root.lottery_jsssc_update_open_quotation(db, issue, lock)
    local conds = {
        _id = issue
    }
    local data = {
        ["$set"] = {
            lock = lock
        }
    }
    db.lottery_jsssc_open_quotation:update(conds, data)
end

function root.lottery_jsssc_get_open_quotation_first(db)
    local res = db.lottery_jsssc_open_quotation:find({}):sort({sealing_date = 1}):limit(1) or {}
    while res:hasNext() do
        return res:next()
    end
end

function root.lottery_jsssc_get_open_quotation_amount(db)
    return db.lottery_jsssc_open_quotation:find({}):count()
end

function root.lottery_jsssc_append_open_quotation(db, data)
    db.lottery_jsssc_open_quotation:safe_insert(data)
end

function root.lottery_jsssc_find_open_quotation_expire(db, curr_date)
    local conds = {
        sealing_date = {
            ["$lt"] = curr_date
        }
    }
    local res = db.lottery_jsssc_open_quotation:find(conds)
    local results = {}
	while res:hasNext() do
		local st = res:next()
		st._id = nil
		results[st.issue] = st
	end
	return results
end

function root.lottery_jsssc_delete_open_quotation_expire(db, curr_date)
    local conds = {
        sealing_date = {
            ["$lt"] = curr_date
        }
    }
    db.lottery_jsssc_open_quotation:delete(conds)
end

return root