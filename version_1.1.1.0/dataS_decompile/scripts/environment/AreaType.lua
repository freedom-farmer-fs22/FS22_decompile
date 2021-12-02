AreaType = {
	OPEN_FIELD = 1,
	CITY = 2,
	HALL = 3,
	FOREST = 4,
	WATER = 5
}
local all = {}
local allOrdered = {}
local names = {}

for k, v in pairs(AreaType) do
	all[k] = v
	names[v] = k

	table.insert(allOrdered, v)
end

table.sort(allOrdered)

function AreaType.getByName(name)
	name = string.upper(name)

	if ClassUtil.getIsValidIndexName(name) then
		return AreaType[name]
	end

	return nil
end

function AreaType.getName(id)
	return names[id]
end

function AreaType.getAll()
	return all
end

function AreaType.getAllOrdered()
	return allOrdered
end
