ChainsawSoundStateStart = {}
local ChainsawSoundStateStart_mt = Class(ChainsawSoundStateStart, SimpleState)

function ChainsawSoundStateStart.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateStart_mt)

	return self
end

function ChainsawSoundStateStart:activate(parms)
	ChainsawSoundStateStart:superClass().activate(self, parms)
	g_soundManager:playSample(self.owner.samples.start)
	self.stateMachine:changeState(Chainsaw.SOUND_STATES.IDLE)
end

ChainsawSoundStateStop = {}
local ChainsawSoundStateStop_mt = Class(ChainsawSoundStateStop, SimpleState)

function ChainsawSoundStateStop.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateStop_mt)

	return self
end

function ChainsawSoundStateStop:activate(parms)
	ChainsawSoundStateStop:superClass().activate(self, parms)
	g_soundManager:stopSample(self.owner.samples.stop)
end

ChainsawSoundStateIdle = {}
local ChainsawSoundStateIdle_mt = Class(ChainsawSoundStateIdle, SimpleState)

function ChainsawSoundStateIdle.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateIdle_mt)

	return self
end

function ChainsawSoundStateIdle:deactivate()
	ChainsawSoundStateIdle:superClass().deactivate(self)
	g_soundManager:stopSample(self.owner.samples.idle)
end

function ChainsawSoundStateIdle:update(dt)
	ChainsawSoundStateIdle:superClass().update(self, dt)

	if not g_soundManager:getIsSamplePlaying(self.owner.samples.start) and not g_soundManager:getIsSamplePlaying(self.owner.samples.idle) then
		g_soundManager:playSample(self.owner.samples.idle)
	end

	if self.owner.isCutting then
		self.stateMachine:changeState(Chainsaw.SOUND_STATES.CUT)
	elseif self.owner.activatePressed then
		self.stateMachine:changeState(Chainsaw.SOUND_STATES.ACTIVE)
	end
end

ChainsawSoundStateActive = {}
local ChainsawSoundStateActive_mt = Class(ChainsawSoundStateActive, SimpleState)

function ChainsawSoundStateActive.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateActive_mt)
	self.activeTimer = 0

	return self
end

function ChainsawSoundStateActive:activate(parms)
	ChainsawSoundStateActive:superClass().activate(self, parms)

	local shouldInitiateStart = parms == nil or not parms.alreadyActive

	if shouldInitiateStart then
		g_soundManager:stopSample(self.owner.samples.activeStart)
		g_soundManager:stopSample(self.owner.samples.activeLoop)
		g_soundManager:playSample(self.owner.samples.activeStart)
		g_soundManager:playSample(self.owner.samples.activeLoop, 0, self.owner.samples.activeStart)
	end

	self.activeTimer = 0
end

function ChainsawSoundStateActive:deactivate()
	ChainsawSoundStateActive:superClass().deactivate(self)

	if getSamplePlayTimeLeft(self.owner.samples.activeStart.soundSample) == 0 then
		g_soundManager:playSample(self.owner.samples.activeStop)
	end

	g_soundManager:stopSample(self.owner.samples.activeStart)
	g_soundManager:stopSample(self.owner.samples.activeLoop)

	self.activeTimer = 0
end

function ChainsawSoundStateActive:update(dt)
	ChainsawSoundStateActive:superClass().update(self, dt)

	if self.owner.isCutting then
		self.stateMachine:changeState(Chainsaw.SOUND_STATES.CUT)
	elseif self.owner.activatePressed then
		self.activeTimer = self.activeTimer + dt
	elseif not self.owner.activatePressed then
		local isPlayingQuickTap = false

		for _, sample in pairs(self.owner.samplesQuicktap) do
			if g_soundManager:getIsSamplePlaying(sample) then
				isPlayingQuickTap = true

				break
			end
		end

		if self.activeTimer < self.owner.quicktapThreshold and not isPlayingQuickTap then
			self.stateMachine:changeState(Chainsaw.SOUND_STATES.QUICKTAP)
		else
			self.stateMachine:changeState(Chainsaw.SOUND_STATES.IDLE)
		end
	end
end

ChainsawSoundStateCut = {}
local ChainsawSoundStateCut_mt = Class(ChainsawSoundStateCut, SimpleState)

function ChainsawSoundStateCut.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateCut_mt)

	return self
end

function ChainsawSoundStateCut:activate(parms)
	ChainsawSoundStateCut:superClass().activate(self, parms)
	g_soundManager:stopSample(self.owner.samples.cutStart)
	g_soundManager:stopSample(self.owner.samples.cutLoop)
	g_soundManager:playSample(self.owner.samples.cutStart)
	g_soundManager:playSample(self.owner.samples.cutLoop, 0, self.owner.samples.cutStart)
end

function ChainsawSoundStateCut:deactivate()
	ChainsawSoundStateCut:superClass().deactivate(self)
	g_soundManager:stopSample(self.owner.samples.cutStart)
	g_soundManager:stopSample(self.owner.samples.cutLoop)
end

function ChainsawSoundStateCut:update(dt)
	ChainsawSoundStateCut:superClass().update(self, dt)

	if not self.owner.isCutting then
		if self.owner.activatePressed then
			self.stateMachine:changeState(Chainsaw.SOUND_STATES.ACTIVE)
			g_soundManager:playSample(self.owner.samples.cutStop)
		else
			self.stateMachine:changeState(Chainsaw.SOUND_STATES.IDLE)
			g_soundManager:playSample(self.owner.samples.cutStop)
		end
	end
end

ChainsawSoundStateQuicktap = {}
local ChainsawSoundStateQuicktap_mt = Class(ChainsawSoundStateQuicktap, SimpleState)

function ChainsawSoundStateQuicktap.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, ChainsawSoundStateQuicktap_mt)

	return self
end

function ChainsawSoundStateQuicktap:activate(parms)
	ChainsawSoundStateQuicktap:superClass().activate(self, parms)

	if self.owner.samplesQuicktapCount > 0 then
		local idx = math.floor(math.random(1, self.owner.samplesQuicktapCount))
		local sample = self.owner.samplesQuicktap[idx]

		g_soundManager:playSample(sample)
	end

	self.stateMachine:changeState(Chainsaw.SOUND_STATES.IDLE)
end
