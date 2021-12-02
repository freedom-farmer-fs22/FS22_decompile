StartMissionInfo = {}
local StartMissionInfo_mt = Class(StartMissionInfo)

function StartMissionInfo.new(subclass_mt)
	local self = setmetatable({}, subclass_mt or StartMissionInfo_mt)

	self:reset()

	return self
end

function StartMissionInfo:reset()
	self.difficulty = 1
	self.mapId = "MapUS"
	self.isMultiplayer = false
	self.createGame = false
	self.canStart = false
end
