CrowSoundStateDefault = {}
local CrowSoundStateDefault_mt = Class(CrowSoundStateDefault, SimpleState)

function CrowSoundStateDefault.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowSoundStateDefault_mt)

	return self
end

CrowSoundStateTakeOff = {}
local CrowSoundStateTakeOff_mt = Class(CrowSoundStateTakeOff, SimpleState)

function CrowSoundStateTakeOff.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowSoundStateTakeOff_mt)
	self.currentIdx = 0

	return self
end

function CrowSoundStateTakeOff:activate(parms)
	CrowSoundStateTakeOff:superClass().activate(self, parms)

	if self.owner.samples.flyAwayCount > 0 then
		self.currentIdx = math.floor(math.random(1, self.owner.samples.flyAwayCount))

		g_soundManager:playSample(self.owner.samples.flyAway[self.currentIdx])
	else
		self.stateMachine:changeState(CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND)
	end
end

function CrowSoundStateTakeOff:deactivate()
	CrowSoundStateTakeOff:superClass().deactivate(self)

	if self.currentIdx > 0 then
		local sample = self.owner.samples.flyAway[self.currentIdx]

		g_soundManager:stopSample(sample)

		self.currentIdx = 0
	end
end

function CrowSoundStateTakeOff:update(dt)
	CrowSoundStateTakeOff:superClass().update(self, dt)

	if self.currentIdx > 0 then
		local sample = self.owner.samples.flyAway[self.currentIdx]

		if not g_soundManager:getIsSamplePlaying(sample) then
			self.currentIdx = 0

			self.stateMachine:changeState(CrowsWildlife.CROW_SOUND_STATES.BUSY)
		end
	end
end

CrowSoundStateBusy = {}
local CrowSoundStateBusy_mt = Class(CrowSoundStateBusy, SimpleState)

function CrowSoundStateBusy.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowSoundStateBusy_mt)
	self.minTimeUntilNextSamplePlay = 6000
	self.maxTimeUntilNextSamplePlay = 8000
	self.timer = 0

	return self
end

function CrowSoundStateBusy:activate(parms)
	CrowSoundStateBusy:superClass().activate(self, parms)
	g_soundManager:playSample(self.owner.samples.busy)

	self.timer = self.minTimeUntilNextSamplePlay + math.random() * (self.maxTimeUntilNextSamplePlay - self.minTimeUntilNextSamplePlay)
end

function CrowSoundStateBusy:deactivate()
	CrowSoundStateBusy:superClass().deactivate(self)
	g_soundManager:stopSample(self.owner.samples.busy)
end

function CrowSoundStateBusy:update(dt)
	CrowSoundStateBusy:superClass().update(self, dt)

	self.timer = math.max(self.timer - dt, 0)

	if self.timer == 0 then
		self.stateMachine:changeState(CrowsWildlife.CROW_SOUND_STATES.CALM_AIR)
	end
end

CrowSoundStateCalmGround = {}
local CrowSoundStateCalmGround_mt = Class(CrowSoundStateCalmGround, SimpleState)

function CrowSoundStateCalmGround.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowSoundStateCalmGround_mt)
	self.minTimeUntilNextSamplePlay = 6000
	self.maxTimeUntilNextSamplePlay = 8000
	self.timer = 0
	self.currentIdx = 0

	return self
end

function CrowSoundStateCalmGround:activate(parms)
	CrowSoundStateCalmGround:superClass().activate(self, parms)

	if self.owner.samples.calmCount > 0 then
		local birdsOnGround, soundPosX, soundPosY, soundPosZ = self.owner:getAverageLocationOfIdleAnimals()
		self.timer = self.minTimeUntilNextSamplePlay + math.random() * (self.maxTimeUntilNextSamplePlay - self.minTimeUntilNextSamplePlay)

		if birdsOnGround then
			setWorldTranslation(self.owner.soundsNode, soundPosX, soundPosY, soundPosZ)

			self.currentIdx = math.floor(math.random(1, self.owner.samples.calmCount))

			g_soundManager:playSample(self.owner.samples.calmGround[self.currentIdx])
		end
	end
end

function CrowSoundStateCalmGround:deactivate()
	CrowSoundStateCalmGround:superClass().deactivate(self)

	if self.currentIdx > 0 then
		local sample = self.owner.samples.calmGround[self.currentIdx]

		g_soundManager:stopSample(sample)

		self.currentIdx = 0
	end
end

function CrowSoundStateCalmGround:update(dt)
	CrowSoundStateCalmGround:superClass().update(self, dt)

	if self.currentIdx > 0 then
		local sample = self.owner.samples.calmGround[self.currentIdx]

		if not g_soundManager:getIsSamplePlaying(sample) then
			self.currentIdx = 0
		end
	end

	self.timer = math.max(self.timer - dt, 0)

	if self.timer == 0 and self.owner.samples.calmCount > 0 then
		self.timer = self.minTimeUntilNextSamplePlay + math.random() * (self.maxTimeUntilNextSamplePlay - self.minTimeUntilNextSamplePlay)
		local birdsOnGround, soundPosX, soundPosY, soundPosZ = self.owner:getAverageLocationOfIdleAnimals()

		if birdsOnGround then
			setWorldTranslation(self.owner.soundsNode, soundPosX, soundPosY, soundPosZ)

			self.currentIdx = math.floor(math.random(1, self.owner.samples.calmCount))

			g_soundManager:playSample(self.owner.samples.calmGround[self.currentIdx])
		end
	end
end

CrowSoundStateCalmAir = {}
local CrowSoundStateCalmAir_mt = Class(CrowSoundStateCalmAir, SimpleState)

function CrowSoundStateCalmAir.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowSoundStateCalmAir_mt)
	self.minTimeUntilNextSamplePlay = 6000
	self.maxTimeUntilNextSamplePlay = 8000
	self.timer = 0

	return self
end

function CrowSoundStateCalmAir:activate(parms)
	CrowSoundStateCalmAir:superClass().activate(self, parms)
	g_soundManager:playSample(self.owner.samples.calmAir)

	self.timer = self.minTimeUntilNextSamplePlay + math.random() * (self.maxTimeUntilNextSamplePlay - self.minTimeUntilNextSamplePlay)
end

function CrowSoundStateCalmAir:deactivate()
	CrowSoundStateCalmAir:superClass().deactivate(self)
	g_soundManager:stopSample(self.owner.samples.calmAir)
end

function CrowSoundStateCalmAir:update(dt)
	CrowSoundStateCalmAir:superClass().update(self, dt)

	self.timer = math.max(self.timer - dt, 0)

	if self.timer == 0 then
		self.stateMachine:changeState(CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND)
	end
end
