RainDropFactorTrigger = {}
local RainDropFactorTrigger_mt = Class(RainDropFactorTrigger)

function RainDropFactorTrigger:onCreate(id)
	local trigger = RainDropFactorTrigger.new()

	if trigger:load(id) then
		g_currentMission:addNonUpdateable(trigger)
	else
		trigger:delete()
	end
end

function RainDropFactorTrigger.new(mt)
	local self = {}

	if mt == nil then
		mt = RainDropFactorTrigger_mt
	end

	setmetatable(self, mt)

	self.triggerId = 0
	self.nodeId = 0

	return self
end

function RainDropFactorTrigger:load(nodeId)
	self.nodeId = nodeId
	self.triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "triggerIndex"))

	if self.triggerId == nil then
		self.triggerId = nodeId
	end

	addTrigger(self.triggerId, "triggerCallback", self)

	self.triggerObjects = {}
	self.isEnabled = true

	return true
end

function RainDropFactorTrigger:delete()
	removeTrigger(self.triggerId)
end

function RainDropFactorTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
end
