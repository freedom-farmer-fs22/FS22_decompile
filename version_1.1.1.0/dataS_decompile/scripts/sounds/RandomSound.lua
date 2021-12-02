RandomSound = {
	STATE_WAITING = 0,
	STATE_PLAYING = 1
}
local RandomSound_mt = Class(RandomSound)

function RandomSound:onCreate(id)
	g_currentMission:addNonUpdateable(RandomSound.new(id))
end

function RandomSound.new(id, customMt)
	local instance = {}

	if customMt ~= nil then
		setmetatable(instance, customMt)
	else
		setmetatable(instance, RandomSound_mt)
	end

	instance.soundId = id
	instance.randomMin = Utils.getNoNil(getUserAttribute(id, "randomMin"), 1000)
	instance.randomMax = Utils.getNoNil(getUserAttribute(id, "randomMax"), 2000)
	instance.playByNight = Utils.getNoNil(getUserAttribute(id, "playByNight"), false)
	instance.playTime = getSampleDuration(getAudioSourceSample(id))

	setVisibility(id, false)

	instance.playState = RandomSound.STATE_WAITING
	instance.timerId = addTimer(instance:getRandomTime(), "randomSoundTimerCallback", instance)

	return instance
end

function RandomSound:delete()
	removeTimer(self.timerId)
end

function RandomSound:randomSoundTimerCallback()
	if self.playState == RandomSound.STATE_WAITING then
		local play = false

		if g_currentMission ~= nil and g_currentMission.isRunning then
			play = self.playByNight or g_currentMission.environment.dayTime > 18000000 and g_currentMission.environment.dayTime < 79200000
		end

		if play then
			setVisibility(self.soundId, true)
			setTimerTime(self.timerId, self.playTime)
		else
			setVisibility(self.soundId, false)
			setTimerTime(self.timerId, self.randomMax)
		end

		self.playState = RandomSound.STATE_PLAYING
	else
		setVisibility(self.soundId, false)

		local randomDelay = self:getRandomTime()

		setTimerTime(self.timerId, randomDelay)

		self.playState = RandomSound.STATE_WAITING
	end

	return true
end

function RandomSound:getRandomTime()
	return math.random(self.randomMin, self.randomMax)
end
