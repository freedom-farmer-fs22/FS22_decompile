InsideBuildingTrigger = {}
local InsideBuildingTrigger_mt = Class(InsideBuildingTrigger)

function InsideBuildingTrigger.onCreate(_, id)
	local trigger = InsideBuildingTrigger.new()

	if trigger:load(id) then
		g_currentMission:addNonUpdateable(trigger)
	else
		trigger:delete()
	end
end

function InsideBuildingTrigger.new(customMt)
	local self = {}

	setmetatable(self, customMt or InsideBuildingTrigger_mt)

	self.triggerId = 0
	self.nodeId = 0

	return self
end

function InsideBuildingTrigger:load(nodeId)
	self.nodeId = nodeId
	self.triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "triggerIndex"))

	if self.triggerId == nil then
		self.triggerId = nodeId
	end

	addTrigger(self.triggerId, "insideBuildingTriggerCallback", self)

	self.isEnabled = true

	return true
end

function InsideBuildingTrigger:delete()
	removeTrigger(self.triggerId)
end

function InsideBuildingTrigger:insideBuildingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if g_currentMission.player ~= nil and g_currentMission.player.rootNode == otherActorId and self.isEnabled then
		if onEnter then
			g_currentMission:setIsInsideBuilding(true)
		elseif onLeave then
			g_currentMission:setIsInsideBuilding(false)
		end
	end
end
