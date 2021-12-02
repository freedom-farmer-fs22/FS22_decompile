MissionCollaborators = {}
local MissionCollaborators_mt = Class(MissionCollaborators)

function MissionCollaborators.new()
	local self = setmetatable({}, MissionCollaborators_mt)
	self.savegameController = nil
	self.messageCenter = nil
	self.achievementManager = nil
	self.inputManager = nil
	self.inputDisplayManager = nil
	self.modManager = nil
	self.fillTypeManager = nil
	self.fruitTypeManager = nil
	self.inGameMenu = nil
	self.shopMenu = nil
	self.guiSoundPlayer = nil
	self.shopController = nil

	return self
end
