DailySound = {}
local DailySound_mt = Class(DailySound)

function DailySound:onCreate(id)
	g_currentMission:addNonUpdateable(DailySound.new(id))
end

function DailySound.new(id, customMt)
	local instance = {}

	if customMt ~= nil then
		setmetatable(instance, customMt)
	else
		setmetatable(instance, DailySound_mt)
	end

	instance.soundId = id
	instance.startTime = Utils.getNoNil(getUserAttribute(id, "startTime"), 0)
	instance.endTime = Utils.getNoNil(getUserAttribute(id, "endTime"), 24)

	setVisibility(id, false)

	instance.isActive = false
	instance.oldIsActive = false
	instance.timerId = addTimer(1000, "dailySoundTimerCallback", instance)

	return instance
end

function DailySound:delete()
	removeTimer(self.timerId)
end

function DailySound:dailySoundTimerCallback()
	if g_currentMission ~= nil then
		if self.endTime < self.startTime then
			self.isActive = g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 or g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
		else
			self.isActive = g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 and g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
		end

		if self.isActive ~= self.oldIsActive then
			setVisibility(self.soundId, self.isActive)

			self.oldIsActive = self.isActive
		end
	end

	return true
end
