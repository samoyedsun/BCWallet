local root = {}

function root.get_max_autoincrid(db, key, offset)
	local ta = db[key]:find({},{_id = 1}):sort({ _id = -1}):limit(1)
    while ta:hasNext() do
        local value = ta:next()
        return value._id
    end
end

return root