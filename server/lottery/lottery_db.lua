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
        issue = issue
    }
    local data = {
        ["$set"] = {
            lock = lock
        }
    }
    db.lottery_jsssc_open_quotation:update(conds, data)
end

function root.lottery_jsssc_get_open_quotation_by_lock(db, lock)
    local conds = {
        lock = lock
    }
    return db.lottery_jsssc_open_quotation:findOne(conds)
end

function root.lottery_jsssc_get_open_quotation_first(db)
    local res = db.lottery_jsssc_open_quotation:find({}):sort({issue = 1}):limit(1) or {}
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

function root.lottery_jsssc_update_betting_record_amount(db, data)
    local conds = {
        uid = data.uid,
        issue = data.issue,
        game_type = data.game_type,
        kind = data.kind,
        slot = data.slot
    }
    local amount = db.lottery_jsssc_betting_record:find(conds):count()
    if amount == 0 then
        db.lottery_jsssc_betting_record:safe_insert(data)
    else
        local conds = {
            uid = data.uid,
            issue = data.issue,
            game_type = data.game_type,
            kind = data.kind,
            slot = data.slot
        }
        local data = {
            ["$set"] = {
                amount = data.amount,
                date = data.date
            }
        }
        db.lottery_jsssc_betting_record:update(conds, data)
    end
end

function root.lottery_jsssc_update_betting_record_win_amount(db, data)
    local conds = {
        uid = data.uid,
        issue = data.issue,
        game_type = data.game_type,
        kind = data.kind,
        slot = data.slot
    }
    local data = {
        ["$set"] = {
            win_amount = data.win_amount
        }
    }
    db.lottery_jsssc_betting_record:update(conds, data, {upsert = true})
end

function root.lottery_jsssc_find_betting_record_unsettled(db, game_type)
    local conds = {
        game_type = game_type,
        win_amount = {
            ["$exists"] = false
        }
    }
    local res = db.lottery_jsssc_betting_record:find(conds)
    local results = {}
	while res:hasNext() do
		local st = res:next()
		st._id = nil
        results[st.issue] = results[st.issue] or {}
        table.insert(results[st.issue], st)
	end
	return results
end

function root.lottery_jsssc_find_betting_record(db, data)
    local conds = {
        uid = data.uid,
        issue = data.issue,
        game_type = data.game_type
    }
    local res = db.lottery_jsssc_betting_record:find(conds)
    local results = {}
	while res:hasNext() do
		local st = res:next()
		st._id = nil
        table.insert(results, st)
	end
	return results
end

return root