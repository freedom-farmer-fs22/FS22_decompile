SlideDoorTrigger = {}
local SlideDoorTrigger_mt = Class(SlideDoorTrigger)

function SlideDoorTrigger:onCreate(id)
	g_currentMission:addUpdateable(SlideDoorTrigger.new(id))
end

function SlideDoorTrigger.new(triggerId)
	local self = {}

	setmetatable(self, SlideDoorTrigger_mt)

	self.triggerId = triggerId

	addTrigger(triggerId, "triggerCallback", self)

	local num = getNumOfChildren(triggerId)
	self.slideDoors = {}

	for i = 1, num do
		local slideDoor = {
			node = getChildAt(triggerId, i - 1)
		}
		slideDoor.startX, slideDoor.startY, slideDoor.startZ = getTranslation(slideDoor.node)
		slideDoor.endX = slideDoor.startX + tonumber(Utils.getNoNil(getUserAttribute(slideDoor.node, "translateX"), "0"))
		slideDoor.endY = slideDoor.startY + tonumber(Utils.getNoNil(getUserAttribute(slideDoor.node, "translateY"), "0"))
		slideDoor.endZ = slideDoor.startZ + tonumber(Utils.getNoNil(getUserAttribute(slideDoor.node, "translateZ"), "0"))

		table.insert(self.slideDoors, slideDoor)
	end

	self.opening = false
	self.closing = false
	self.pausing = false
	self.playerLeft = false
	self.speed = tonumber(Utils.getNoNil(getUserAttribute(triggerId, "speed"), "0.001"))
	self.pauseDuration = tonumber(Utils.getNoNil(getUserAttribute(triggerId, "pauseDuration"), "2000"))
	self.pauseTime = self.pauseDuration
	self.doorPos = 0
	self.isEnabled = true

	return self
end

function SlideDoorTrigger:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)

		self.triggerId = nil
	end
end

function SlideDoorTrigger:update(dt)
	if self.isEnabled then
		local moving = false

		if self.pausing then
			self.pauseTime = self.pauseTime - dt

			if self.pauseTime <= 0 then
				self.pausing = false
				self.closing = true
			end
		end

		if self.opening then
			moving = true
			self.doorPos = self.doorPos + self.speed * dt

			if self.doorPos > 1 then
				self.doorPos = 1
				self.opening = false

				if self.playerLeft then
					self.pausing = true
					self.pauseTime = self.pauseDuration
				end
			end
		end

		if self.closing then
			moving = true
			self.doorPos = self.doorPos - self.speed * dt

			if self.doorPos < 0 then
				self.doorPos = 0
				self.closing = false
			end
		end

		if moving then
			for _, slideDoor in pairs(self.slideDoors) do
				local x = (1 - self.doorPos) * slideDoor.startX + self.doorPos * slideDoor.endX
				local y = (1 - self.doorPos) * slideDoor.startY + self.doorPos * slideDoor.endY
				local z = (1 - self.doorPos) * slideDoor.startZ + self.doorPos * slideDoor.endZ

				setTranslation(slideDoor.node, x, y, z)
			end
		end
	end
end

function SlideDoorTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) and g_currentMission.players[otherId] ~= nil then
		if onEnter then
			self.playerLeft = false

			if self.pausing then
				self.pausing = false
			end

			self.opening = true
			self.closing = false
		else
			self.playerLeft = true

			if not self.opening then
				self.pausing = true
				self.pauseTime = self.pauseDuration
			end
		end
	end
end
