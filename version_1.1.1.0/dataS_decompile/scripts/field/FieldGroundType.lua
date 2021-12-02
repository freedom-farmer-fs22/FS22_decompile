FieldGroundType = {
	NONE = 0,
	STUBBLE_TILLAGE = 1,
	CULTIVATED = 2,
	SEEDBED = 3,
	PLOWED = 4,
	ROLLED_SEEDBED = 5,
	SOWN = 6,
	DIRECT_SOWN = 7,
	PLANTED = 8,
	RIDGE = 9,
	ROLLER_LINES = 10,
	HARVEST_READY = 11,
	HARVEST_READY_OTHER = 12,
	GRASS = 13,
	GRASS_CUT = 14
}
local all = {}
local names = {}
local allOrdered = {}

for k, v in pairs(FieldGroundType) do
	all[k] = v
	names[v] = k

	table.insert(allOrdered, v)
end

table.sort(allOrdered)

function FieldGroundType.getByName(name)
	name = string.upper(name)

	if ClassUtil.getIsValidIndexName(name) then
		return FieldGroundType[name]
	end

	return nil
end

function FieldGroundType.getName(id)
	return names[id]
end

function FieldGroundType.getAll()
	return all
end

function FieldGroundType.getAllOrdered()
	return allOrdered
end
