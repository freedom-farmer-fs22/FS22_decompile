VendingMachine = {}
local VendingMachine_mt = Class(VendingMachine)

function VendingMachine:onCreate(id)
	g_currentMission:addUpdateable(VendingMachine.new(id))
end

function VendingMachine.new(name)
	local self = {}

	setmetatable(self, VendingMachine_mt)

	self.triggerId = name

	addTrigger(name, "triggerCallback", self)

	self.isInTrigger = false
	self.moneyPerObject = 1
	self.time = 0
	self.emitTimer = 0
	self.useSound = createSample("VendingMachine")

	loadSample(self.useSound, "data/maps/sounds/vendingMachine.wav", false)

	self.isEnabled = true
	self.activateEventId = ""
	self.sharedLoadRequestId = nil

	return self
end

function VendingMachine:delete()
	g_currentMission:removeUpdateable(self)
	removeTrigger(self.triggerId)

	if self.useSound ~= nil then
		delete(self.useSound)
	end

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	self.triggerId = 0
end

function VendingMachine:update(dt)
	self.time = self.time + dt

	if self.isInTrigger and self.emitTimer == 0 then
		g_inputBinding:setActionEventActive(self.activateEventId, true)
	end

	if self.emitTimer ~= 0 and self.emitTimer < self.time then
		self.emitTimer = 0
		local rootNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile("data/maps/models/objects/can/can.i3d", true, false)
		self.sharedLoadRequestId = sharedLoadRequestId
		local node = getChildAt(rootNode, 0)

		link(getRootNode(), node)
		delete(rootNode)
		setRotation(node, math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		setTranslation(node, localToWorld(self.triggerId, -0.11 + math.random() * 0.05, -0.25 + math.random() * 0.05, 0.32))

		local dx, dy, dz = localDirectionToWorld(self.triggerId, 0, 0, 0.0005 + math.random() * 0.001)

		addImpulse(node, dx, dy, dz, 0, 0, 0, true)
	end
end

function VendingMachine:onActivate()
	playSample(self.useSound, 1, 1, 0, 0, 0)

	self.emitTimer = self.time + 1900 + math.random(0, 200)

	g_inputBinding:setActionEventActive(self.activateEventId, false)
end

function VendingMachine:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			self.isInTrigger = true
			local _, eventId = g_inputBinding:registerActionEvent(InputAction.ENTER, self, self.onActivate, false, true, false, true)

			g_inputBinding:setActionEventText(eventId, g_i18n:getText("action_activateVendingMachine"))

			self.activateEventId = eventId
		elseif onLeave then
			self.isInTrigger = false

			g_inputBinding:removeActionEventsByTarget(self)
		end
	end
end
