AmbientSoundSystem = {}
local AmbientSoundSystem_mt = Class(AmbientSoundSystem)

g_xmlManager:addCreateSchemaFunction(function ()
	AmbientSoundSystem.xmlSchema = XMLSchema.new("ambientSounds")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = AmbientSoundSystem.xmlSchema
	local basePath = "sound.ambient.sample(?)"

	schema:register(XMLValueType.STRING, basePath .. "#filename", "Sample filename")
	schema:register(XMLValueType.FLOAT, basePath .. "#probability", "Sample probability", 1)
	schema:register(XMLValueType.STRING, basePath .. ".settings#audioGroup", "The audio group the sound will be assigned to", "ENVIRONMENT")
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#fadeInTime", "The fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#fadeOutTime", "The fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#minVolume", "The minVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#maxVolume", "The maxVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	schema:register(XMLValueType.INT, basePath .. ".settings#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	schema:register(XMLValueType.INT, basePath .. ".settings#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#minRetriggerDelaySeconds", "The minimum number of seconds until sound can be retriggred", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#maxRetriggerDelaySeconds", "The maximum number of seconds until the sound has to be retriggered", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#minPitch", "The min pitch", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#maxPitch", "The max pitch", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#minDelay", "The min delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#maxDelay", "The max delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#minLength", "The min length time in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".settings#maxLength", "The max length time in milliseconds", 0)
	schema:register(XMLValueType.STRING, basePath .. ".variation(?)#filename", "Sample filename")
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#probability", "Sample probability", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#fadeInTime", "The fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#fadeOutTime", "The fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#minVolume", "The minVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#maxVolume", "The maxVolume if the player is outdoor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#indoorVolume", "The volume if the player is indoor or in a vehicle", 0.8)
	schema:register(XMLValueType.INT, basePath .. ".variation(?)#minLoops", "The minimum number of loops played once a sound is triggered (0 means it will play one loop)", 1)
	schema:register(XMLValueType.INT, basePath .. ".variation(?)#maxLoops", "The maximum number of loops played once a sound is triggered", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#minPitch", "The min pitch", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#maxPitch", "The max pitch", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#minDelay", "The min delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#maxDelay", "The max delay in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#minLength", "The min length time in milliseconds", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".variation(?)#maxLength", "The max length time in milliseconds", 0)
	schema:register(XMLValueType.STRING, "sound.ambient3d#filename", "3d Ambient sound file")

	local surfacePath = "sound.surface.material(?)"

	schema:register(XMLValueType.INT, surfacePath .. "#materialId", "Material id")
	schema:register(XMLValueType.STRING, surfacePath .. "#name", "Material name")
	schema:register(XMLValueType.STRING, surfacePath .. "#type", "Sample type")
	schema:register(XMLValueType.INT, surfacePath .. "#loopCount", "Sample loop count")
	schema:register(XMLValueType.STRING, surfacePath .. "#template", "Sample template")
	SoundManager.registerSampleXMLPaths(schema, "sound.cutting", "sample(?)")
	schema:register(XMLValueType.STRING, "sound.cutting.sample(?)#name", "Cutting sample name")
end)

function AmbientSoundSystem.loadFlagFromXML(xmlFile, key, modifier, requiredFlags, preventFlags)
	local preventKey = string.format("%s.prevent#%s", key, modifier.xmlAttributeName)
	local requiredKey = string.format("%s.required#%s", key, modifier.xmlAttributeName)
	local prevent = xmlFile:getBool(preventKey)

	if prevent then
		preventFlags = bitOR(preventFlags, modifier.bitflag)
	end

	local required = xmlFile:getBool(requiredKey)

	if required then
		requiredFlags = bitOR(requiredFlags, modifier.bitflag)
	end

	return requiredFlags, preventFlags
end

function AmbientSoundSystem.new(mission, soundPlayer, customMt)
	local self = setmetatable({}, customMt or AmbientSoundSystem_mt)
	self.mission = mission
	self.soundPlayerId = nil

	if soundPlayer ~= nil then
		self.soundPlayerId = soundPlayer.soundPlayerId
	end

	self.modifiers = {}
	self.samples = {}
	self.worldMask = 0
	self.isDebugViewActive = false
	self.movingSounds = {}
	self.isDeleted = false
	self.setIsIndoorModifier = self:registerModifier("isIndoor", nil)

	return self
end

function AmbientSoundSystem:delete()
	self:unloadAmbientSounds()
	removeConsoleCommand("gsAmbientSoundSystemToggleDebugView")
	removeConsoleCommand("gsAmbientSoundSystemReload")
end

function AmbientSoundSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	if self.soundPlayerId == nil then
		return false
	end

	local xmlFilename = Utils.getFilename(getXMLString(mapXmlFile, "map.sounds#filename"), baseDirectory)

	if xmlFilename == nil then
		return false
	end

	if not fileExists(xmlFilename) then
		Logging.warning("Warning: AmbientSoundSystem could not load configuration xml file!")

		return false
	end

	self.baseDirectory = baseDirectory
	self.xmlFilename = xmlFilename

	addConsoleCommand("gsAmbientSoundSystemToggleDebugView", "Toggles the ambient sound system debug view", "consoleCommandToggleDebugView", self)
	addConsoleCommand("gsAmbientSoundSystemReload", "Reloads the ambient sound system", "consoleCommandReload", self)

	return self:loadFromConfigFile()
end

function AmbientSoundSystem:loadFromConfigFile()
	self.isDeleted = false
	local xmlFile = XMLFile.load("Ambient Sounds", self.xmlFilename, AmbientSoundSystem.xmlSchema)

	if xmlFile == nil then
		Logging.xmlWarning(xmlFile, "Warning: AmbientSoundSystem could not load configuration xml file!")

		return false
	end

	xmlFile:iterate("sound.ambient.sample", function (_, sampleKey)
		local filename = xmlFile:getValue(sampleKey .. "#filename")
		local probability = xmlFile:getValue(sampleKey .. "#probability", 1)
		local audioGroup = xmlFile:getValue(sampleKey .. ".settings#audioGroup", "ENVIRONMENT")
		local fadeInTime = xmlFile:getValue(sampleKey .. ".settings#fadeInTime", 0)
		local fadeOutTime = xmlFile:getValue(sampleKey .. ".settings#fadeOutTime", 0)
		local minVolume = xmlFile:getValue(sampleKey .. ".settings#minVolume", 1)
		local maxVolume = xmlFile:getValue(sampleKey .. ".settings#maxVolume", 1)
		local indoorVolumeFactor = xmlFile:getValue(sampleKey .. ".settings#indoorVolume", 0.8)
		local minLoops = xmlFile:getValue(sampleKey .. ".settings#minLoops", 1)
		local maxLoops = xmlFile:getValue(sampleKey .. ".settings#maxLoops", 1)
		local minRetriggerDelay = xmlFile:getValue(sampleKey .. ".settings#minRetriggerDelaySeconds", 0)
		local maxRetriggerDelay = xmlFile:getValue(sampleKey .. ".settings#maxRetriggerDelaySeconds", 0)
		local minPitch = xmlFile:getValue(sampleKey .. ".settings#minPitch", 1)
		local maxPitch = xmlFile:getValue(sampleKey .. ".settings#maxPitch", 1)
		local minDelay = xmlFile:getValue(sampleKey .. ".settings#minDelay", 0)
		local maxDelay = xmlFile:getValue(sampleKey .. ".settings#maxDelay", 0)
		local minLength = xmlFile:getValue(sampleKey .. ".settings#minLength", 0)
		local maxLength = xmlFile:getValue(sampleKey .. ".settings#maxLength", 0)
		local audioGroupId = AudioGroup.getAudioGroupIndexByName(audioGroup)

		if audioGroupId == nil then
			audioGroupId = AudioGroup.ENVIRONMENT
		end

		filename = Utils.getFilename(filename, self.baseDirectory)
		local requiredFlags = 0
		local preventFlags = 0

		for _, modifier in ipairs(self.modifiers) do
			requiredFlags, preventFlags = modifier.loadFromXMLFunc(xmlFile, sampleKey, modifier, requiredFlags, preventFlags)
		end

		local fadeTimes = {
			fadeInTime,
			fadeOutTime
		}
		local volumes = {
			minVolume,
			maxVolume
		}
		local loops = {
			minLoops,
			maxLoops
		}
		local retriggerDelays = {
			minRetriggerDelay,
			maxRetriggerDelay
		}
		local pitching = {
			minPitch,
			maxPitch
		}
		local delays = {
			minDelay,
			maxDelay
		}
		local offsets = {
			0,
			0
		}
		local lengths = {
			minLength,
			maxLength
		}
		local sampleId = ambientSoundsAddSample(self.soundPlayerId, filename, audioGroupId, probability, fadeTimes, volumes, indoorVolumeFactor, loops, retriggerDelays, pitching, delays, offsets, lengths, requiredFlags, preventFlags)

		xmlFile:iterate(sampleKey .. ".variation", function (_, variationKey)
			local varFilename = xmlFile:getValue(variationKey .. "#filename")
			local varProbability = xmlFile:getValue(variationKey .. "#probability", 1)
			local varFadeInTime = xmlFile:getValue(variationKey .. "#fadeInTime", fadeInTime)
			local varFadeOutTime = xmlFile:getValue(variationKey .. "#fadeOutTime", fadeOutTime)
			local varMinVolume = xmlFile:getValue(variationKey .. "#minVolume", minVolume)
			local varMaxVolume = xmlFile:getValue(variationKey .. "#maxVolume", maxVolume)
			local varIndoorVolumeFactor = xmlFile:getValue(variationKey .. "#indoorVolume", indoorVolumeFactor)
			local varMinLoops = xmlFile:getValue(variationKey .. "#minLoops", minLoops)
			local varMaxLoops = xmlFile:getValue(variationKey .. "#maxLoops", maxLoops)
			local varMinPitch = xmlFile:getValue(variationKey .. "#minPitch", minPitch)
			local varMaxPitch = xmlFile:getValue(variationKey .. "#maxPitch", maxPitch)
			local varMinDelay = xmlFile:getValue(variationKey .. "#minDelay", minDelay)
			local varMaxDelay = xmlFile:getValue(variationKey .. "#maxDelay", maxDelay)
			local varMinLength = xmlFile:getValue(variationKey .. "#minLength", minLength)
			local varMaxLength = xmlFile:getValue(variationKey .. "#maxLength", maxLength)
			local varFadeTimes = {
				varFadeInTime,
				varFadeOutTime
			}
			local varVolumes = {
				varMinVolume,
				varMaxVolume
			}
			local varLoops = {
				varMinLoops,
				varMaxLoops
			}
			local varPitching = {
				varMinPitch,
				varMaxPitch
			}
			local varDelays = {
				varMinDelay,
				varMaxDelay
			}
			local varLengths = {
				varMinLength,
				varMaxLength
			}
			varFilename = Utils.getFilename(varFilename, self.baseDirectory)

			if ambientSoundsAddSampleVariation ~= nil then
				ambientSoundsAddSampleVariation(self.soundPlayerId, sampleId, varFilename, varProbability, varFadeTimes, varVolumes, varIndoorVolumeFactor, varLoops, varPitching, varDelays, offsets, varLengths)
			end
		end)
		table.insert(self.samples, {
			filename = filename,
			audioGroupId = audioGroupId,
			requiredFlags = requiredFlags,
			preventFlags = preventFlags
		})

		return true
	end)

	local filename = xmlFile:getValue("sound.ambient3d#filename")

	if filename ~= nil then
		local sound3DFilename = Utils.getFilename(filename, self.baseDirectory)

		g_i3DManager:loadI3DFileAsync(sound3DFilename, true, false, AmbientSoundSystem.sound3DFileLoaded, self, nil)
	end

	xmlFile:delete()

	return true
end

function AmbientSoundSystem:sound3DFileLoaded(i3dNode, failedReason, args)
	if i3dNode ~= nil and i3dNode ~= 0 then
		if self.isDeleted or self.sound3DRootNode ~= nil then
			delete(i3dNode)

			return
		end

		self.sound3DRootNode = i3dNode

		link(getRootNode(), i3dNode)
	end
end

function AmbientSoundSystem:addMovingSound(node)
	local numChildren = getNumOfChildren(node)

	if numChildren < 2 or numChildren > 3 then
		return
	end

	local spline = getChildAt(node, 0)
	local transformNode = getChildAt(node, 1)

	if not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
		Logging.error("AmbientsoundSystem: Given node '%s' is not a spline!", getName(spline))

		return
	end

	setVisibility(spline, false)

	local splineLength = getSplineLength(spline)
	local eps = 0.01 / splineLength
	local modifiers = {}

	if numChildren == 3 then
		local modifiersNode = getChildAt(node, 2)

		for i = 0, getNumOfChildren(modifiersNode) - 1 do
			local modifierNode = getChildAt(modifiersNode, i)
			local startNode = getChildAt(modifierNode, 0)
			local endNode = getChildAt(modifierNode, 1)
			local sx, sy, sz = getWorldTranslation(startNode)
			local _, _, _, startTime = getLocalClosestSplinePosition(spline, 0.5, 1, sx, sy, sz, eps)
			local ex, ey, ez = getWorldTranslation(endNode)
			local _, _, _, endTime = getLocalClosestSplinePosition(spline, 0.5, 1, ex, ey, ez, eps)

			if endTime < startTime then
				endTime = startTime
				startTime = endTime
				ez = sz
				ey = sy
				ex = sx
				sz = ez
				sy = ey
				sx = ex
			end

			local startDebug = DebugFlag.new(0, 1, 0)

			startDebug:create(sx, sy, sz, 1, 0)

			local endDebug = DebugFlag.new(1, 0, 0)

			endDebug:create(ex, ey, ez, 1, 0)

			local rangeScale = tonumber(getUserAttribute(modifierNode, "rangeScale"))
			local fadeDistance = tonumber(getUserAttribute(modifierNode, "fadeDistance"))
			local fadeDistanceTime = fadeDistance / splineLength
			local startTimeFadeEnd = startTime + fadeDistanceTime
			local endTimeFadeStart = endTime - fadeDistanceTime
			local r, g, b, _ = unpack(DebugUtil.tableToColor(startDebug, 1))
			local startFadeStartDebug = DebugFlag.new(r, g, b)
			local x, y, z = getSplinePosition(spline, startTime)

			startFadeStartDebug:create(x, y, z, 1, 0)

			local startFadeEndDebug = DebugFlag.new(r, g, b)
			x, y, z = getSplinePosition(spline, startTimeFadeEnd)

			startFadeEndDebug:create(x, y, z, 1, 0)

			local endFadeStartDebug = DebugFlag.new(r, g, b)
			x, y, z = getSplinePosition(spline, endTime)

			endFadeStartDebug:create(x, y, z, 1, 0)

			local endFadeEndDebug = DebugFlag.new(r, g, b)
			x, y, z = getSplinePosition(spline, endTimeFadeStart)

			endFadeEndDebug:create(x, y, z, 1, 0)
			table.insert(modifiers, {
				startTime = startTime,
				startTimeFadeEnd = startTimeFadeEnd,
				endTime = endTime,
				endTimeFadeStart = endTimeFadeStart,
				startDebug = startDebug,
				endDebug = endDebug,
				startFadeStartDebug = startFadeStartDebug,
				startFadeEndDebug = startFadeEndDebug,
				endFadeStartDebug = endFadeStartDebug,
				endFadeEndDebug = endFadeEndDebug,
				rangeScale = rangeScale,
				fadeDistance = fadeDistance
			})
		end
	end

	table.sort(modifiers, function (a, b)
		return a.startTime < b.startTime
	end)

	local sounds = {}

	for i = 0, getNumOfChildren(transformNode) - 1 do
		local sound = getChildAt(transformNode, i)
		local innerRange = getAudioSourceInnerRange(sound)
		local outerRange = getAudioSourceRange(sound)

		table.insert(sounds, {
			node = sound,
			innerRange = innerRange,
			outerRange = outerRange
		})
	end

	table.insert(self.movingSounds, {
		spline = spline,
		node = transformNode,
		eps = eps,
		sounds = sounds,
		modifiers = modifiers
	})
end

function AmbientSoundSystem:registerModifier(xmlAttributeName, loadFromXMLFunc)
	local name = string.upper(xmlAttributeName)

	for _, modifier in ipairs(self.modifiers) do
		if modifier.xmlAttributeName == xmlAttributeName then
			Logging.error("Given ambient sound modifier xml attribute name '%s' already used", xmlAttributeName)

			return false
		end
	end

	local modifier = {
		name = name,
		xmlAttributeName = xmlAttributeName,
		bitflag = 2^(#self.modifiers + 1),
		loadFromXMLFunc = loadFromXMLFunc or AmbientSoundSystem.loadFlagFromXML
	}

	function modifier.updateFunc(isActive)
		if isActive then
			self.worldMask = bitOR(self.worldMask, modifier.bitflag)
		else
			self.worldMask = bitAND(self.worldMask, bitNOT(modifier.bitflag))
		end
	end

	if loadFromXMLFunc == nil then
		local schema = AmbientSoundSystem.xmlSchema
		local basePath = "sound.ambient.sample(?)"

		schema:register(XMLValueType.BOOL, basePath .. ".prevent#" .. xmlAttributeName, "Prevent flag " .. xmlAttributeName)
		schema:register(XMLValueType.BOOL, basePath .. ".required#" .. xmlAttributeName, "Required flag " .. xmlAttributeName)
	end

	table.insert(self.modifiers, modifier)

	return modifier.updateFunc
end

function AmbientSoundSystem:unloadAmbientSounds()
	if self.soundPlayerId ~= nil then
		ambientSoundsRemoveAllSamples(self.soundPlayerId)

		self.samples = {}
	end

	if self.sound3DRootNode ~= nil then
		delete(self.sound3DRootNode)

		self.sound3DRootNode = nil
	end

	self.movingSounds = {}
	self.isDeleted = true
end

function AmbientSoundSystem:update(dt)
	if self.soundPlayerId ~= nil then
		ambientSoundsUpdate(self.soundPlayerId, dt, self.worldMask)
	end

	local x, y, z = getWorldTranslation(getCamera())

	for _, movingSound in ipairs(self.movingSounds) do
		local sx, sy, sz, t = getLocalClosestSplinePosition(movingSound.spline, 0.5, 1, x, y, z, movingSound.eps)

		setWorldTranslation(movingSound.node, sx, sy, sz)

		local rangeScale = 1

		for _, modifier in ipairs(movingSound.modifiers) do
			if modifier.startTime <= t and t <= modifier.endTime then
				local alpha = 1

				if t <= modifier.startTimeFadeEnd then
					alpha = 1 - (modifier.startTimeFadeEnd - t) / (modifier.startTimeFadeEnd - modifier.startTime)
				end

				if modifier.endTimeFadeStart < t then
					alpha = (modifier.endTime - t) / (modifier.endTime - modifier.endTimeFadeStart)
				end

				rangeScale = MathUtil.lerp(1, modifier.rangeScale, alpha)

				break
			end
		end

		if movingSound.lastScale ~= rangeScale then
			for _, sound in ipairs(movingSound.sounds) do
				setAudioSourceInnerRange(sound.node, sound.innerRange * rangeScale)
				setAudioSourceRange(sound.node, sound.outerRange * rangeScale)
			end

			movingSound.lastScale = rangeScale
		end

		if self.isDebugViewActive then
			DebugUtil.drawDebugGizmoAtWorldPos(sx, sy, sz, 0, 0, 1, 0, 1, 0, getName(movingSound.node) .. " (RangeScale " .. rangeScale .. ")")

			for _, modifier in ipairs(movingSound.modifiers) do
				g_debugManager:addFrameElement(modifier.startFadeStartDebug)
				g_debugManager:addFrameElement(modifier.startFadeEndDebug)
				g_debugManager:addFrameElement(modifier.endFadeStartDebug)
				g_debugManager:addFrameElement(modifier.endFadeEndDebug)
			end
		end
	end
end

function AmbientSoundSystem:setIsEnabled(isEnabled)
	if self.soundPlayerId ~= nil then
		ambientSoundsSetEnabled(self.soundPlayerId, isEnabled)
	end
end

function AmbientSoundSystem:setIsIndoor(isIndoor)
	self.setIsIndoorModifier(isIndoor)

	if self.soundPlayerId ~= nil then
		ambientSoundsSetIsIndoor(self.soundPlayerId, isIndoor)
	end
end

function AmbientSoundSystem:draw()
	if self.isDebugViewActive then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		renderText(0.1, 0.82, getCorrectTextSize(0.014), "Possible active ambient sounds:")
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.7, 0.82, getCorrectTextSize(0.014), "Modifiers:")
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local posY = 0.8
		local textSize = getCorrectTextSize(0.012)
		local textOffset = getCorrectTextSize(0.001)

		for _, sample in ipairs(self.samples) do
			local match = bitAND(self.worldMask, sample.preventFlags) == 0 and bitAND(self.worldMask, sample.requiredFlags) == sample.requiredFlags

			if match then
				renderText(0.1, posY, textSize, AudioGroup.getAudioGroupNameByIndex(sample.audioGroupId))
				renderText(0.2, posY, textSize, sample.filename)

				posY = posY - textSize - textOffset
			end
		end

		posY = 0.8

		for _, modifier in ipairs(self.modifiers) do
			local isActive = bitAND(self.worldMask, modifier.bitflag) ~= 0

			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.7, posY, textSize, modifier.xmlAttributeName .. ":  ")
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.7, posY, textSize, tostring(isActive))

			posY = posY - textSize - textOffset
		end
	end
end

function AmbientSoundSystem:consoleCommandReload()
	self:unloadAmbientSounds()
	self:loadFromConfigFile()
end

function AmbientSoundSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive

	if self.isDebugViewActive then
		self.mission:addDrawable(self)
	else
		self.mission:removeDrawable(self)
	end

	for _, movingSound in ipairs(self.movingSounds) do
		setVisibility(movingSound.spline, self.isDebugViewActive)
	end
end
