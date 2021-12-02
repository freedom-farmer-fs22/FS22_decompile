SoundMixer = {}
local SoundMixer_mt = Class(SoundMixer)

function SoundMixer.new(customMt)
	local self = {}

	setmetatable(self, customMt or SoundMixer_mt)
	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)

	local xmlFilename = "dataS/soundMixer.xml"
	local xmlFile = loadXMLFile("soundMixerXML", xmlFilename)
	self.volumeFactors = {}

	for _, groupIndex in pairs(AudioGroup) do
		self.volumeFactors[groupIndex] = 1
	end

	self.masterVolume = 1
	self.gameStates = {}

	if xmlFile ~= nil and xmlFile ~= 0 then
		local i = 0

		while true do
			local key = string.format("soundMixer.gameState(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local gameStateName = getXMLString(xmlFile, key .. "#name")
			local gameStateIndex = g_gameStateManager:getGameStateIndexByName(gameStateName)

			if gameStateIndex ~= nil then
				local gameState = {
					audioGroups = {}
				}
				local j = 0

				while true do
					local audioGroupKey = string.format("%s.audioGroup(%d)", key, j)

					if not hasXMLProperty(xmlFile, audioGroupKey) then
						break
					end

					local name = getXMLString(xmlFile, audioGroupKey .. "#name")
					local volume = getXMLFloat(xmlFile, audioGroupKey .. "#volume") or 1
					local audioGroupIndex = AudioGroup.getAudioGroupIndexByName(name)

					if audioGroupIndex ~= nil then
						local group = {
							index = audioGroupIndex,
							volume = volume
						}
						gameState.audioGroups[audioGroupIndex] = group
					else
						print(string.format("Warning: Audio-Group '%s' is not defined for audio-group '%s'!", tostring(name), key))
					end

					j = j + 1
				end

				self.gameStates[gameStateIndex] = gameState
			else
				print(string.format("Warning: Game-State '%s' is not defined for state '%s'!", tostring(gameStateName), key))
			end

			i = i + 1
		end
	else
		print("Error: SoundMixer could not load configuration file!")
	end

	delete(xmlFile)

	self.volumes = {}
	local gameState = self.gameStates[GameState.LOADING]

	for _, groupIndex in ipairs(AudioGroup.groups) do
		local volume = gameState.audioGroups[groupIndex].volume or 1
		self.volumes[groupIndex] = {
			volume = volume,
			listeners = {}
		}

		setAudioGroupVolume(groupIndex, volume)
	end

	return self
end

function SoundMixer:delete()
	g_messageCenter:unsubscribeAll(self)
end

function SoundMixer:update(dt)
	if self.isDirty then
		local gameStateIndex = g_gameStateManager:getGameState()
		local gameState = self.gameStates[gameStateIndex]

		if gameState ~= nil then
			local isDone = true

			for audioGroupIndex, audioGroup in pairs(gameState.audioGroups) do
				local currentVolume = self.volumes[audioGroupIndex].volume
				local target = audioGroup.volume * self.volumeFactors[audioGroupIndex]

				if currentVolume ~= target then
					isDone = false
					local dir = 1
					local func = math.min

					if target < currentVolume then
						dir = -1
						func = math.max
					end

					currentVolume = func(currentVolume + dir * dt / 500, target)

					setAudioGroupVolume(audioGroupIndex, currentVolume)

					self.volumes[audioGroupIndex].volume = currentVolume

					for _, listener in ipairs(self.volumes[audioGroupIndex].listeners) do
						listener.func(listener.target, audioGroupIndex, currentVolume)
					end
				end
			end

			if isDone then
				self.isDirty = false
			end
		end
	end
end

function SoundMixer:setAudioGroupVolumeFactor(audioGroupIndex, factor)
	if audioGroupIndex ~= nil and self.volumeFactors[audioGroupIndex] ~= nil then
		self.volumeFactors[audioGroupIndex] = factor
		self.isDirty = true
	end
end

function SoundMixer:setMasterVolume(masterVolume)
	self.masterVolume = masterVolume

	setMasterVolume(masterVolume)
end

function SoundMixer:onGameStateChanged(gameStateId, oldGameState)
	local gameState = self.gameStates[gameStateId]

	if gameState ~= nil then
		self.isDirty = true
	end
end

function SoundMixer:addVolumeChangedListener(audioGroupIndex, func, target)
	table.addElement(self.volumes[audioGroupIndex].listeners, {
		func = func,
		target = target
	})
end
