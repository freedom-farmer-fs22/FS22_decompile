BasketTrigger = {
	threePointDistanceThreshold = 6
}
local BasketTrigger_mt = Class(BasketTrigger)

function BasketTrigger:onCreate(id)
	local trigger = BasketTrigger.new()

	if trigger:load(id) then
		g_currentMission:addNonUpdateable(trigger)
	else
		trigger:delete()
	end
end

function BasketTrigger.new(mt)
	local self = {}

	if mt == nil then
		mt = BasketTrigger_mt
	end

	setmetatable(self, mt)

	self.triggerId = 0
	self.nodeId = 0

	return self
end

function BasketTrigger:load(nodeId)
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

function BasketTrigger:delete()
	removeTrigger(self.triggerId)
end

function BasketTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		if onEnter then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object.thrownFromPosition ~= nil then
				self.triggerObjects[otherActorId] = true
			end
		elseif onLeave and self.triggerObjects[otherActorId] then
			self.triggerObjects[otherActorId] = false
		end
	end
end
