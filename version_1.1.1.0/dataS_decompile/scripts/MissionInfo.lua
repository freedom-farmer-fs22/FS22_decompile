MissionInfo = {}
local MissionInfo_mt = Class(MissionInfo)

function MissionInfo.new(baseDirectory, customEnvironment, customMt)
	local self = setmetatable({}, customMt or MissionInfo_mt)
	self.baseDirectory = baseDirectory
	self.customEnvironment = customEnvironment

	return self
end

function MissionInfo:loadDefaults()
	self.id = "invalid"
	self.scriptFilename = ""
	self.scriptClass = ""
end

function MissionInfo:isValidMissionId(id)
	if id == nil or id:len() == 0 then
		return false
	end

	if id:find("[^%w_]") ~= nil then
		return false
	end

	return true
end
