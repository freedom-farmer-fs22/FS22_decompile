FieldSprayType = {
	NONE = 0,
	FERTILIZER = 1,
	LIME = 2,
	MANURE = 3,
	LIQUID_MANURE = 4
}
local all = {}
local allOrdered = {}
local names = {}

for k, v in pairs(FieldSprayType) do
	all[k] = v
	names[v] = k

	table.insert(allOrdered, v)
end

table.sort(allOrdered)

function FieldSprayType.getByName(name)
	name = string.upper(name)

	if ClassUtil.getIsValidIndexName(name) then
		return FieldSprayType[name]
	end

	return nil
end

function FieldSprayType.getName(id)
	return names[id]
end

function FieldSprayType.getAll()
	return all
end

function FieldSprayType.getAllOrdered()
	return allOrdered
end
