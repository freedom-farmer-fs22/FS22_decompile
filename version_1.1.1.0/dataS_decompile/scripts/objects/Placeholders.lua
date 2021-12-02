Placeholders = {}
local Placeholders_mt = Class(Placeholders)

function Placeholders:onCreate(id)
	g_currentMission.placeholdersObject = Placeholders.new(id)

	g_currentMission:addNonUpdateable(g_currentMission.placeholdersObject)
end

function Placeholders.new(id)
	local self = {}

	setmetatable(self, Placeholders_mt)

	for i = getNumOfChildren(id) - 1, 0, -1 do
		delete(getChildAt(id, i))
	end

	return self
end

function Placeholders:delete()
end
