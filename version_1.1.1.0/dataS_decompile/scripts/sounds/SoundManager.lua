SoundModifierType = nil
SoundManager = {
	DEFAULT_REVERB_EFFECT = 0,
	MAX_SAMPLES_PER_FRAME = 5,
	DEFAULT_SOUND_TEMPLATES = "data/sounds/soundTemplates.xml",
	SAMPLE_ATTRIBUTES = {
		"volume",
		"pitch",
		"lowpassGain"
	},
	SAMPLE_RANDOMIZATIONS = {
		"randomizationsIn",
		"randomizationsOut"
	},
	GLOBAL_DEBUG_ENABLED = false
}
local SoundManager_mt = Class(SoundManager, AbstractManager)

function SoundManager.new(customMt)
	local self = AbstractManager.new(customMt or SoundManager_mt)

	addConsoleCommand("gsSoundManagerDebug", "Toggle SoundManager global debug mode", "consoleCommandToggleDebug", self)

	return self
end

function SoundManager:initDataStructures()
	self.samples = {}
	self.orderedSamples = {}
	self.activeSamples = {}
	self.activeSamplesSet = {}
	self.debugSamplesFlagged = {}
	self.debugSamples = {}
	self.debugSamplesLinkNodes = {}
	self.currentSampleIndex = 1
	self.oldRandomizationIndex = 1
	self.isIndoor = false
	self.isInsideBuilding = false
	self.soundTemplates = {}
	self.soundTemplateXMLFile = nil

	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)

	self.modifierTypeNameToIndex = {}
	self.modifierTypeIndexToDesc = {}
	SoundModifierType = self.modifierTypeNameToIndex

	setReverbEffect(0, Reverb.GENERIC, Reverb.GENERIC, 1)

	self.indoorStateChangedListeners = {}
end

function SoundManager:delete()
	if self.soundTemplateXMLFile ~= nil then
		delete(self.soundTemplateXMLFile)

		self.soundTemplateXMLFile = nil
	end
end

function SoundManager:registerModifierType(typeName, func, minFunc, maxFunc)
	typeName = typeName:upper()

	if SoundModifierType[typeName] == nil then
		if type(func) ~= "function" then
			Logging.error("SoundManager.registerModifierType: parameter 'func' is of type '%s'. Possibly the registerModifierType is called before the definition of the function?", type(func))
			printCallstack()

			return
		end

		local desc = {
			name = typeName,
			index = #self.modifierTypeIndexToDesc + 1,
			func = func,
			minFunc = minFunc,
			maxFunc = maxFunc
		}
		SoundModifierType[typeName] = desc.index

		table.insert(self.modifierTypeIndexToDesc, desc)
	end

	return SoundModifierType[typeName]
end

function SoundManager:loadSoundTemplates(xmlFilename)
	local xmlFile = loadXMLFile("soundTemplates", xmlFilename)

	if xmlFile ~= nil then
		local i = 0

		while true do
			local key = string.format("soundTemplates.template(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local name = getXMLString(xmlFile, key .. "#name")

			if name ~= nil then
				if self.soundTemplates[name] == nil then
					self.soundTemplates[name] = key
				else
					print(string.format("Warning: Sound template '%s' already exists!", name))
				end
			end

			i = i + 1
		end

		self.soundTemplateXMLFile = xmlFile

		return true
	end

	return false
end

function SoundManager:reloadSoundTemplates()
	for k, _ in pairs(self.soundTemplates) do
		self.soundTemplates[k] = nil
	end

	if entityExists(self.soundTemplateXMLFile) then
		delete(self.soundTemplateXMLFile)

		self.soundTemplateXMLFile = nil
	end

	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
end

function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
	local newSample = table.copy(sample)
	newSample.modifiers = table.copy(sample.modifiers)

	if not sample.is2D then
		newSample.soundNode = createAudioSource(newSample.sampleName, newSample.filename, newSample.outerRadius, newSample.innerRadius, newSample.current.volume, newSample.loops)
		newSample.soundSample = getAudioSourceSample(newSample.soundNode)

		setAudioSourceAutoPlay(newSample.soundNode, false)
		link(linkNode, newSample.soundNode)

		newSample.linkNode = linkNode

		setTranslation(newSample.soundNode, 0, 0, 0)
	end

	setSampleGroup(newSample.soundSample, sample.audioGroup)

	newSample.audioGroup = sample.audioGroup

	if sample.supportsReverb then
		addSampleEffect(newSample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
	else
		removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
	end

	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end

	newSample.sourceRandomizations = {}

	for i = 1, #sample.sourceRandomizations do
		local randomSample = sample.sourceRandomizations[i]
		local newRandomSample = self:getRandomSample(sample, randomSample.filename)

		table.insert(newSample.sourceRandomizations, newRandomSample)
	end

	self.samples[newSample] = newSample

	table.insert(self.orderedSamples, newSample)

	return newSample
end

function SoundManager:cloneSample2D(sample, linkNode, modifierTargetObject)
	local newSample = table.copy(sample)
	newSample.modifiers = table.copy(sample.modifiers)
	newSample.audioGroup = sample.audioGroup
	newSample.linkNode = nil
	newSample.soundNode = nil
	newSample.is2D = true
	newSample.soundSample = createSample(newSample.sampleName)
	newSample.orgSoundSample = newSample.soundSample

	loadSample(newSample.soundSample, newSample.filename, false)

	newSample.duration = getSampleDuration(newSample.soundSample)

	setSampleGroup(newSample.soundSample, sample.audioGroup)

	newSample.audioGroup = sample.audioGroup

	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end

	newSample.sourceRandomizations = {}

	for i = 1, #sample.sourceRandomizations do
		local randomSample = sample.sourceRandomizations[i]
		local newRandomSample = {
			filename = randomSample.filename,
			isEmpty = randomSample.isEmpty,
			is2D = true
		}

		if not randomSample.isEmpty then
			newRandomSample.soundSample = createSample(newSample.sampleName)

			loadSample(newRandomSample.soundSample, newRandomSample.filename, false)
		end

		table.insert(newSample.sourceRandomizations, newRandomSample)
	end

	self.samples[newSample] = newSample

	table.insert(self.orderedSamples, newSample)

	return newSample
end

function SoundManager:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, is2D, components, i3dMappings, externalSoundsFile)
	local isValid = false
	local usedExternal = false
	local actualXMLFile = xmlFile
	local sampleKey = ""
	local linkNode = nil

	if sampleName ~= nil then
		if not AudioGroup.getIsValidAudioGroup(audioGroup) then
			print("Warning: Invalid audioGroup index '" .. tostring(audioGroup) .. "'.")
		end

		sampleKey = baseKey .. "." .. sampleName

		if externalSoundsFile ~= nil and not hasXMLProperty(actualXMLFile, sampleKey) then
			sampleKey = Vehicle.xmlSchemaSounds:replaceRootName(sampleKey)
			actualXMLFile = externalSoundsFile.handle
			usedExternal = true
		end

		local xmlFileObject = g_xmlManager:getFileByHandle(xmlFile)

		if xmlFileObject ~= nil then
			XMLUtil.checkDeprecatedXMLElements(g_xmlManager:getFileByHandle(xmlFile), baseKey .. "#externalSoundFile", "vehicle.base.sounds#filename")
		end

		if actualXMLFile ~= nil then
			if hasXMLProperty(actualXMLFile, sampleKey) then
				isValid = true

				if not is2D then
					linkNode = I3DUtil.indexToObject(components, getXMLString(actualXMLFile, sampleKey .. "#linkNode"), i3dMappings)

					if linkNode == nil then
						if type(components) == "number" then
							linkNode = components
						elseif type(components) == "table" then
							linkNode = components[1].node
						else
							print("Warning: Could not find linkNode (" .. tostring(getXMLString(actualXMLFile, sampleKey .. "#linkNode")) .. ") for sample '" .. tostring(sampleName) .. "'. Ignoring it!")

							isValid = false
						end
					end
				end
			end
		else
			Logging.warning("Unable to load sample '%s' from internal or given external sound file '%s'!", sampleName, externalSoundsFile)
		end
	end

	return isValid, usedExternal, actualXMLFile, sampleKey, linkNode
end

function SoundManager:loadSample2DFromXML(xmlFile, baseKey, sampleName, baseDir, loops, audioGroup)
	local sample = nil
	local isValid, usedExternal, definitionXmlFile, sampleKey = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, true)

	if isValid then
		sample = {
			is2D = true,
			sampleName = sampleName
		}
		local template = getXMLString(definitionXmlFile, sampleKey .. "#template")

		if template ~= nil then
			sample = self:loadSampleAttributesFromTemplate(sample, template, baseDir, loops, definitionXmlFile, sampleKey)
		end

		if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops) then
			return nil
		end

		sample.filename = Utils.getFilename(sample.filename, baseDir)
		sample.linkNode = nil
		sample.current = sample.outdoorAttributes
		sample.audioGroup = audioGroup
		sample.supportsReverb = Utils.getNoNil(getXMLBool(xmlFile, sampleKey .. "#supportsReverb"), true)
		sample.soundSample = createSample(sample.sampleName)
		sample.orgSoundSample = sample.soundSample

		loadSample(sample.soundSample, sample.filename, false)

		sample.duration = getSampleDuration(sample.soundSample)

		setSampleGroup(sample.soundSample, sample.audioGroup)
		setSampleVolume(sample.soundSample, sample.current.volume)
		setSamplePitch(sample.soundSample, sample.current.pitch)
		setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)

		if sample.supportsReverb then
			addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		else
			removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		end

		sample.offsets = {
			lowpassGain = 0,
			pitch = 0,
			volume = 0
		}
		self.samples[sample] = sample

		table.insert(self.orderedSamples, sample)
	end

	if usedExternal then
		delete(definitionXmlFile)
	end

	return sample
end

function SoundManager:loadSampleFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject)
	local sample = nil

	if type(xmlFile) == "table" then
		xmlFile = xmlFile.handle
	end

	local externalSoundsFile, volumeFactor = nil

	if modifierTargetObject ~= nil then
		externalSoundsFile = modifierTargetObject.externalSoundsFile
		volumeFactor = modifierTargetObject.soundVolumeFactor
	end

	local isValid, _, definitionXmlFile, sampleKey, linkNode = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, false, components, i3dMappings, externalSoundsFile)

	if isValid then
		sample = {
			is2D = false,
			sampleName = sampleName
		}
		local template = getXMLString(definitionXmlFile, sampleKey .. "#template")

		if template ~= nil then
			sample = self:loadSampleAttributesFromTemplate(sample, template, baseDir, loops, definitionXmlFile, sampleKey)
		end

		if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops) then
			return nil
		end

		sample.filename = Utils.getFilename(sample.filename, baseDir)
		sample.isGlsFile = sample.filename:find(".gls") ~= nil
		sample.linkNode = linkNode
		sample.modifierTargetObject = modifierTargetObject
		sample.current = sample.outdoorAttributes
		sample.audioGroup = audioGroup

		if volumeFactor ~= nil then
			sample.volumeScale = sample.volumeScale * volumeFactor
		end

		self:createAudioSource(sample, sample.filename)

		sample.offsets = {
			lowpassGain = 0,
			pitch = 0,
			volume = 0
		}
		self.samples[sample] = sample

		table.insert(self.orderedSamples, sample)
	end

	return sample
end

function SoundManager:loadSamplesFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject, samples)
	samples = samples or {}
	local i = 0

	while true do
		local sample = g_soundManager:loadSampleFromXML(xmlFile, baseKey, string.format("%s(%d)", sampleName, i), baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject)

		if sample == nil then
			break
		end

		table.insert(samples, sample)

		i = i + 1
	end

	return samples
end

function SoundManager:createAudioSource(sample, filename)
	if sample.soundNode ~= nil then
		delete(sample.soundNode)
	end

	sample.soundNode = createAudioSource(sample.sampleName, filename, sample.outerRadius, sample.innerRadius, sample.current.volume, sample.loops)
	sample.soundSample = getAudioSourceSample(sample.soundNode)

	self:onCreateAudioSource(sample)
end

function SoundManager:onCreateAudioSource(sample, ignoreReverb)
	sample.soundSample = getAudioSourceSample(sample.soundNode)
	sample.duration = getSampleDuration(sample.soundSample)
	sample.outerRange = getAudioSourceRange(sample.soundNode)
	sample.innerRange = getAudioSourceInnerRange(sample.soundNode)
	sample.isDirty = true

	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)

	if not ignoreReverb then
		if sample.supportsReverb then
			addSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		else
			removeSampleEffect(sample.soundSample, SoundManager.DEFAULT_REVERB_EFFECT)
		end
	end

	setAudioSourceAutoPlay(sample.soundNode, false)
	link(sample.linkNode, sample.soundNode)
	setTranslation(sample.soundNode, 0, 0, 0)
end

function SoundManager:createAudio2d(sample, filename)
	if sample.soundSample ~= nil then
		delete(sample.soundSample)
	end

	sample.soundSample = createSample(sample.sampleName)
	sample.orgSoundSample = sample.soundSample

	loadSample(sample.soundSample, filename, false)
	self:onCreateAudio2d(sample)
end

function SoundManager:onCreateAudio2d(sample)
	sample.duration = getSampleDuration(sample.soundSample)

	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain, 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
end

function SoundManager:loadSampleAttributesFromTemplate(sample, templateName, baseDir, defaultLoops, xmlFile, sampleKey)
	local xmlKey = self.soundTemplates[templateName]

	if xmlKey ~= nil then
		if self.soundTemplateXMLFile ~= nil then
			local templateSample = {
				is2D = sample.is2D,
				sampleName = sample.sampleName,
				templateName = templateName
			}

			if not self:loadSampleAttributesFromXML(templateSample, self.soundTemplateXMLFile, xmlKey, baseDir, defaultLoops, false) then
				return sample
			end

			return templateSample
		end
	else
		local xmlFileObject = g_xmlManager:getFileByHandle(xmlFile)

		if xmlFileObject ~= nil then
			Logging.xmlError(xmlFileObject, "Sound template '%s' was not found in %s", templateName, sampleKey)
		else
			Logging.error("Sound template '%s' was not found in %s", templateName, sampleKey)
		end
	end

	return sample
end

function SoundManager:loadSampleAttributesFromXML(sample, xmlFile, key, baseDir, defaultLoops, requiresFile)
	local parent = getXMLString(xmlFile, key .. "#parent")

	if parent ~= nil then
		local templateKey = self.soundTemplates[parent]

		if templateKey ~= nil then
			self:loadSampleAttributesFromXML(sample, self.soundTemplateXMLFile, templateKey, baseDir, defaultLoops, false)
		end
	end

	sample.filename = Utils.getNoNil(getXMLString(xmlFile, key .. "#file"), sample.filename)

	if sample.filename == nil and (requiresFile == nil or requiresFile) then
		print("Warning: Filename not defined in '" .. tostring(key) .. "'. Ignoring it!")

		return false
	end

	sample.innerRadius = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#innerRadius"), sample.innerRadius), 5)
	sample.outerRadius = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#outerRadius"), sample.outerRadius), 80)
	sample.volumeScale = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#volumeScale"), sample.volumeScale), 1)
	sample.pitchScale = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#pitchScale"), sample.pitchScale), 1)
	sample.lowpassGainScale = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#lowpassGainScale"), sample.lowpassGainScale), 1)
	sample.indoorAttributes = Utils.getNoNil(sample.indoorAttributes, {})
	sample.indoorAttributes.volume = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".volume#indoor"), sample.indoorAttributes.volume), 0.8)
	sample.indoorAttributes.pitch = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".pitch#indoor"), sample.indoorAttributes.pitch), 1)
	sample.indoorAttributes.lowpassGain = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassGain#indoor"), sample.indoorAttributes.lowpassGain), 0.8)
	sample.indoorAttributes.lowpassCutoffFrequency = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#indoor"), sample.indoorAttributes.lowpassCutoffFrequency), 0)
	sample.indoorAttributes.lowpassResonance = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassResonance#indoor"), sample.indoorAttributes.lowpassResonance), 0)
	sample.outdoorAttributes = Utils.getNoNil(sample.outdoorAttributes, {})
	sample.outdoorAttributes.volume = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".volume#outdoor"), sample.outdoorAttributes.volume), 1)
	sample.outdoorAttributes.pitch = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".pitch#outdoor"), sample.outdoorAttributes.pitch), 1)
	sample.outdoorAttributes.lowpassGain = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassGain#outdoor"), sample.outdoorAttributes.lowpassGain), 1)
	sample.outdoorAttributes.lowpassCutoffFrequency = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassCutoffFrequency#outdoor"), sample.outdoorAttributes.lowpassCutoffFrequency), 0)
	sample.outdoorAttributes.lowpassResonance = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassResonance#outdoor"), sample.outdoorAttributes.lowpassResonance), 0)
	sample.loops = Utils.getNoNil(Utils.getNoNil(getXMLInt(xmlFile, key .. "#loops"), sample.loops), Utils.getNoNil(defaultLoops, 1))
	sample.supportsReverb = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsReverb"), sample.supportsReverb), true)
	sample.debug = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#debug"), sample.debug), false)

	if sample.debug or SoundManager.GLOBAL_DEBUG_ENABLED then
		if sample.debug then
			table.insert(self.debugSamplesFlagged, sample)
		end

		self.debugSamples[sample] = true
		sample.debug = nil
	end

	local fadeIn = getXMLFloat(xmlFile, key .. "#fadeIn")

	if fadeIn ~= nil then
		fadeIn = fadeIn * 1000
	end

	sample.fadeIn = Utils.getNoNil(Utils.getNoNil(fadeIn, sample.fadeIn), 0)
	local fadeOut = getXMLFloat(xmlFile, key .. "#fadeOut")

	if fadeOut ~= nil then
		fadeOut = fadeOut * 1000
	end

	sample.fadeOut = Utils.getNoNil(Utils.getNoNil(fadeOut, sample.fadeOut), 0)
	sample.fade = 0
	sample.isIndoor = false

	self:loadModifiersFromXML(sample, xmlFile, key)
	self:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)

	return true
end

function SoundManager:loadModifiersFromXML(sample, xmlFile, key)
	sample.modifiers = Utils.getNoNil(sample.modifiers, {})

	for _, attribute in pairs(SoundManager.SAMPLE_ATTRIBUTES) do
		local modifier = Utils.getNoNil(sample.modifiers[attribute], {})
		local i = 0

		while true do
			local modKey = string.format("%s.%s.modifier(%d)", key, attribute, i)

			if not hasXMLProperty(xmlFile, modKey) then
				break
			end

			local type = getXMLString(xmlFile, modKey .. "#type")
			local typeIndex = SoundModifierType[type]

			if typeIndex ~= nil then
				if modifier[typeIndex] == nil then
					modifier[typeIndex] = AnimCurve.new(linearInterpolator1)
				end

				local value = getXMLFloat(xmlFile, modKey .. "#value")
				local modifiedValue = getXMLFloat(xmlFile, modKey .. "#modifiedValue")

				modifier[typeIndex]:addKeyframe({
					modifiedValue,
					time = value
				}, xmlFile, modKey)
			end

			i = i + 1
		end

		modifier.currentValue = nil
		sample.modifiers[attribute] = modifier
	end
end

function SoundManager:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
	sample.randomizationsIn = sample.randomizationsIn or {}
	sample.randomizationsOut = sample.randomizationsOut or {}
	local i = 0

	while true do
		local baseKey = string.format("%s.randomization(%d)", key, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local randomization = {
			minVolume = getXMLFloat(xmlFile, baseKey .. "#minVolume"),
			maxVolume = getXMLFloat(xmlFile, baseKey .. "#maxVolume"),
			minPitch = getXMLFloat(xmlFile, baseKey .. "#minPitch"),
			maxPitch = getXMLFloat(xmlFile, baseKey .. "#maxPitch"),
			minLowpassGain = getXMLFloat(xmlFile, baseKey .. "#minLowpassGain"),
			maxLowpassGain = getXMLFloat(xmlFile, baseKey .. "#maxLowpassGain"),
			isInside = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInside"), true),
			isOutside = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isOutside"), true)
		}

		if randomization.isInside then
			table.insert(sample.randomizationsIn, randomization)
		end

		if randomization.isOutside then
			table.insert(sample.randomizationsOut, randomization)
		end

		i = i + 1
	end

	sample.sourceRandomizations = sample.sourceRandomizations or {}
	i = 0

	while true do
		local baseKey = string.format("%s.sourceRandomization(%d)", key, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local filename = getXMLString(xmlFile, baseKey .. "#file")

		if filename ~= nil then
			if filename ~= "-" then
				filename = Utils.getFilename(filename, baseDir)
			end

			local randomSample = self:getRandomSample(sample, filename)

			table.insert(sample.sourceRandomizations, randomSample)
		end

		i = i + 1
	end

	if #sample.sourceRandomizations > 0 and not sample.addedBaseFileToRandomizations then
		local filename = Utils.getFilename(sample.filename, baseDir)
		local randomSample = self:getRandomSample(sample, filename)

		table.insert(sample.sourceRandomizations, randomSample)

		sample.addedBaseFileToRandomizations = true
	end
end

function SoundManager:getRandomSample(sample, filename)
	local randomSample = {
		filename = filename
	}

	if filename ~= "-" then
		if not sample.is2D then
			local audioSource = createAudioSource(sample.sampleName, filename, sample.outerRadius, sample.innerRadius, 1, sample.loops)

			if audioSource ~= 0 then
				randomSample.soundNode = audioSource
				local sampleId = getAudioSourceSample(randomSample.soundNode)

				if sample.supportsReverb then
					addSampleEffect(sampleId, SoundManager.DEFAULT_REVERB_EFFECT)
				else
					removeSampleEffect(sampleId, SoundManager.DEFAULT_REVERB_EFFECT)
				end
			end
		else
			local sample2D = createSample(sample.sampleName)

			if sample2D ~= 0 and loadSample(sample2D, filename, false) then
				randomSample.soundSample = sample2D
				randomSample.is2D = true
			end
		end
	else
		randomSample.isEmpty = true
	end

	return randomSample
end

function SoundManager:update(dt)
	for i = 0, SoundManager.MAX_SAMPLES_PER_FRAME do
		local index = self.currentSampleIndex

		if index > #self.activeSamples then
			self.currentSampleIndex = 1

			break
		end

		local sample = self.activeSamples[index]

		if self:getIsSamplePlaying(sample) then
			self:updateSampleFade(sample, dt)
			self:updateSampleModifiers(sample)
			self:updateSampleAttributes(sample)
		else
			table.removeElement(self.activeSamples, sample)

			sample.fade = 0
		end

		self.currentSampleIndex = self.currentSampleIndex + 1
	end

	table.clear(self.debugSamplesLinkNodes)

	for sample in pairs(self.debugSamples) do
		if sample.linkNode ~= nil and entityExists(sample.linkNode) then
			local distanceToCam = calcDistanceFrom(getCamera(), sample.linkNode)

			if distanceToCam < 15 or distanceToCam < sample.outerRadius * 1.5 then
				if self.debugSamplesLinkNodes[sample.linkNode] == nil then
					self.debugSamplesLinkNodes[sample.linkNode] = {}
				end

				table.insert(self.debugSamplesLinkNodes[sample.linkNode], sample)
			end
		end
	end
end

function SoundManager:draw()
	for linkNode, linkNodeSamples in pairs(self.debugSamplesLinkNodes) do
		local x, y, z = getWorldTranslation(linkNode)
		local debugNode = createTransformGroup("sampleDebugNode")

		setTranslation(debugNode, x, y, z)

		local linkNodeText = string.format("LinkNode '%s' (visible=%s)", getName(linkNode), getEffectiveVisibility(linkNode))

		DebugUtil.drawDebugNode(linkNode, linkNodeText, false)

		for i = 1, #linkNodeSamples do
			local sample = linkNodeSamples[i]
			local name = sample.sampleName or i
			local rotOffset = i / 100
			local text = string.format("AudioSample '%s'  IR=%d  OR=%d  isPlaying=%s  tmpl=%s", name, sample.innerRadius, sample.outerRadius, self:getIsSamplePlaying(sample), sample.templateName)
			local color = DebugUtil.tableToColor(sample)

			setRotation(debugNode, 0, rotOffset, 0)
			Utils.renderTextAtWorldPosition(x, y, z, text, getCorrectTextSize(0.016), i * getCorrectTextSize(0.016), color)
			DebugUtil.drawDebugCircleAtNode(debugNode, sample.innerRadius, 20, color, true)
			DebugUtil.drawDebugCircleAtNode(debugNode, sample.outerRadius, 20, color, true)
			setRotation(debugNode, 0, math.rad(90) + rotOffset, 0)
			DebugUtil.drawDebugCircleAtNode(debugNode, sample.innerRadius, 20, color, true)
			DebugUtil.drawDebugCircleAtNode(debugNode, sample.outerRadius, 20, color, true)
		end

		delete(debugNode)
	end
end

function SoundManager:updateSampleFade(sample, dt)
	if sample ~= nil and sample.fadeIn ~= 0 then
		sample.fade = math.min(sample.fade + dt, sample.fadeIn)
	end
end

function SoundManager:updateSampleModifiers(sample)
	if sample == nil or sample.modifiers == nil then
		return
	end

	for attributeIndex, attribute in pairs(SoundManager.SAMPLE_ATTRIBUTES) do
		local modifier = sample.modifiers[attribute]

		if modifier ~= nil then
			local value = 1

			for name, typeIndex in pairs(SoundModifierType) do
				local changeValue, _, available = self:getSampleModifierValue(sample, attribute, typeIndex)

				if available then
					value = value * changeValue
				end
			end

			modifier.currentValue = value
		end
	end
end

function SoundManager:updateSampleAttributes(sample, force)
	if sample ~= nil then
		if sample.isIndoor ~= self.isIndoor or force then
			self:setCurrentSampleAttributes(sample, self.isIndoor)

			sample.isIndoor = self.isIndoor
		end

		local volumeFactor = self:getModifierFactor(sample, "volume")
		local pitchFactor = self:getModifierFactor(sample, "pitch")
		local lowpassGainFactor = self:getModifierFactor(sample, "lowpassGain")

		setSampleVolume(sample.soundSample, volumeFactor * self:getCurrentSampleVolume(sample))
		setSamplePitch(sample.soundSample, pitchFactor * self:getCurrentSamplePitch(sample))
		setSampleFrequencyFilter(sample.soundSample, 1, lowpassGainFactor * self:getCurrentSampleLowpassGain(sample), 0, sample.current.lowpassCutoffFrequency, 0, sample.current.lowpassResonance)
	end
end

function SoundManager:updateSampleRandomizations(sample)
	if sample ~= nil then
		for _, name in ipairs(SoundManager.SAMPLE_RANDOMIZATIONS) do
			if name == "randomizationsIn" == sample.isIndoor then
				local numRandomizations = #sample[name]

				if numRandomizations > 0 then
					local randomizationIndexToUse = math.max(math.floor(math.random(numRandomizations)), 1)
					local randomizationToUse = sample[name][randomizationIndexToUse]

					if randomizationToUse.minVolume ~= nil and randomizationToUse.maxVolume then
						sample[name].volume = math.random() * (randomizationToUse.maxVolume - randomizationToUse.minVolume) + randomizationToUse.minVolume
					end

					if randomizationToUse.minPitch ~= nil and randomizationToUse.maxPitch then
						sample[name].pitch = math.random() * (randomizationToUse.maxPitch - randomizationToUse.minPitch) + randomizationToUse.minPitch
					end

					if randomizationToUse.minLowpassGain ~= nil and randomizationToUse.maxLowpassGain then
						sample[name].lowpassGain = math.random() * (randomizationToUse.maxLowpassGain - randomizationToUse.minLowpassGain) + randomizationToUse.minLowpassGain
					end
				end
			end
		end

		local numRandomizations = #sample.sourceRandomizations

		if numRandomizations > 0 then
			local randomizationIndexToUse = 1

			for i = 1, 3 do
				randomizationIndexToUse = math.max(math.floor(math.random(numRandomizations)), 1)

				if self.oldRandomizationIndex ~= randomizationIndexToUse then
					break
				end
			end

			self.oldRandomizationIndex = randomizationIndexToUse
			local randomSample = sample.sourceRandomizations[randomizationIndexToUse]

			if not sample.is2D then
				if sample.soundSample ~= nil then
					stopSample(sample.soundSample, 0, sample.fadeOut)
				end

				if not randomSample.isEmpty then
					sample.soundNode = randomSample.soundNode

					self:onCreateAudioSource(sample, true)

					sample.isEmptySample = false
				else
					sample.isEmptySample = true
				end
			else
				if sample.soundSample ~= nil then
					stopSample(sample.soundSample, 0, sample.fadeOut)
				end

				if not randomSample.isEmpty then
					sample.soundSample = randomSample.soundSample

					self:onCreateAudio2d(sample)

					sample.isEmptySample = false
				else
					sample.isEmptySample = true
				end
			end
		end
	end
end

function SoundManager:getSampleModifierValue(sample, attribute, typeIndex)
	local modifier = sample.modifiers[attribute]

	if modifier ~= nil then
		local curve = modifier[typeIndex]

		if curve ~= nil then
			local typeData = self.modifierTypeIndexToDesc[typeIndex]
			local t = typeData.func(sample.modifierTargetObject)

			if typeData.maxFunc ~= nil and typeData.minFunc ~= nil then
				local min = typeData.minFunc(sample.modifierTargetObject)
				t = MathUtil.clamp((t - min) / (typeData.maxFunc(sample.modifierTargetObject) - min), 0, 1)
			end

			return curve:get(t), t, true
		end
	end

	return 0, 0, false
end

function SoundManager:deleteSample(sample)
	if sample ~= nil and sample.filename ~= nil then
		self.samples[sample] = nil

		table.removeElement(self.activeSamples, sample)
		table.removeElement(self.orderedSamples, sample)

		self.debugSamples[sample] = nil

		table.removeElement(self.debugSamplesFlagged, sample)

		if sample.soundNode ~= nil then
			delete(sample.soundNode)
		end

		if sample.is2D and sample.orgSoundSample ~= nil then
			delete(sample.orgSoundSample)
		end

		for i = 1, #sample.sourceRandomizations do
			local randomSample = sample.sourceRandomizations[i]

			if not randomSample.isEmpty then
				if randomSample.soundNode ~= nil and randomSample.soundNode ~= sample.soundNode then
					delete(randomSample.soundNode)
				end

				if randomSample.is2D then
					delete(randomSample.soundSample)
				end
			end
		end

		sample.sourceRandomizations = {}
		sample.soundSample = nil
		sample.soundNode = nil
	end
end

function SoundManager:deleteSamples(samples, delay, afterSample)
	if samples ~= nil then
		for _, sample in pairs(samples) do
			self:deleteSample(sample, delay, afterSample)
		end
	end
end

function SoundManager:playSample(sample, delay, afterSample)
	if sample ~= nil then
		self:updateSampleRandomizations(sample)
		self:updateSampleModifiers(sample)
		self:updateSampleAttributes(sample, true)

		if not sample.isEmptySample then
			delay = delay or 0
			local afterSampleId = 0

			if afterSample ~= nil then
				afterSampleId = afterSample.soundSample
			end

			playSample(sample.soundSample, sample.loops, self:getModifierFactor(sample, "volume") * self:getCurrentSampleVolume(sample), 0, delay, afterSampleId)
			table.addElement(self.activeSamples, sample)
		end
	end
end

function SoundManager:playSamples(samples, delay, afterSample)
	for _, sample in pairs(samples) do
		self:playSample(sample, delay, afterSample)
	end
end

function SoundManager:stopSample(sample, delay, fadeOut)
	if sample ~= nil and sample.soundSample ~= nil then
		stopSample(sample.soundSample, delay or getSampleLoopSynthesisStopDuration(sample.soundSample), fadeOut or sample.fadeOut)
	end
end

function SoundManager:stopSamples(samples)
	for _, sample in pairs(samples) do
		self:stopSample(sample)
	end
end

function SoundManager:setSampleVolumeOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.volume = offset
	end
end

function SoundManager:setSamplePitchOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.pitch = offset
	end
end

function SoundManager:setSampleLowpassGainOffset(sample, offset)
	if sample ~= nil then
		sample.offsets.lowpassGain = offset
	end
end

function SoundManager:setSampleVolume(sample, volume)
	if sample ~= nil then
		setSampleVolume(sample.soundSample, volume)
	end
end

function SoundManager:setSamplePitch(sample, pitch)
	if sample ~= nil then
		setSamplePitch(sample.soundSample, pitch)
	end
end

function SoundManager:getIsSamplePlaying(sample, offset)
	if sample ~= nil then
		return isSamplePlaying(sample.soundSample)
	end

	return false
end

function SoundManager:setSampleLoopSynthesisParameters(sample, rpm, loadFactor)
	if sample ~= nil then
		if rpm ~= nil then
			setSampleLoopSynthesisRPM(sample.soundSample, rpm, true)
		end

		if loadFactor ~= nil then
			setSampleLoopSynthesisLoadFactor(sample.soundSample, loadFactor)
		end
	end
end

function SoundManager:setSamplesLoopSynthesisParameters(samples, rpm, loadFactor)
	for _, sample in pairs(samples) do
		self:setSampleLoopSynthesisParameters(sample, rpm, loadFactor)
	end
end

function SoundManager:setCurrentSampleAttributes(sample, isIndoor)
	if isIndoor then
		sample.current = sample.indoorAttributes
		sample.randomizations = sample.randomizationsIn
	else
		sample.current = sample.outdoorAttributes
		sample.randomizations = sample.randomizationsOut
	end
end

function SoundManager:getCurrentSampleVolume(sample)
	return math.max((sample.current.volume + self:getCurrentRandomizationValue(sample, "volume")) * self:getCurrentFadeFactor(sample) * sample.volumeScale + sample.offsets.volume, 0)
end

function SoundManager:getCurrentSamplePitch(sample)
	return (sample.current.pitch + self:getCurrentRandomizationValue(sample, "pitch")) * sample.pitchScale + sample.offsets.pitch
end

function SoundManager:getCurrentSampleLowpassGain(sample)
	return (sample.current.lowpassGain + self:getCurrentRandomizationValue(sample, "lowpassGain")) * sample.lowpassGainScale + sample.offsets.lowpassGain
end

function SoundManager:getCurrentRandomizationValue(sample, attribute)
	if sample.randomizations ~= nil and sample.randomizations[attribute] ~= nil then
		return sample.randomizations[attribute]
	end

	return 0
end

function SoundManager:getCurrentFadeFactor(sample)
	local fadeFactor = 1

	if sample.fadeIn ~= 0 then
		fadeFactor = sample.fade / sample.fadeIn
	end

	return fadeFactor
end

function SoundManager:setIsIndoor(isIndoor)
	if self.isIndoor ~= isIndoor then
		self.isIndoor = isIndoor

		for _, target in ipairs(self.indoorStateChangedListeners) do
			target:onIndoorStateChanged(isIndoor)
		end
	end
end

function SoundManager:addIndoorStateChangedListener(target)
	table.addElement(self.indoorStateChangedListeners, target)
end

function SoundManager:removeIndoorStateChangedListener(target)
	table.removeElement(self.indoorStateChangedListeners, target)
end

function SoundManager:getIsIndoor()
	return self.isIndoor
end

function SoundManager:setIsInsideBuilding(isInsideBuilding)
	if self.isInsideBuilding ~= isInsideBuilding then
		self.isInsideBuilding = isInsideBuilding
	end
end

function SoundManager:getIsInsideBuilding()
	return self.isInsideBuilding
end

function SoundManager:getModifierFactor(sample, modifierName)
	if sample.modifiers ~= nil then
		local modifier = sample.modifiers[modifierName]

		if modifier ~= nil and modifier.currentValue ~= nil then
			return modifier.currentValue
		end
	end

	return 1
end

function SoundManager:consoleCommandToggleDebug()
	SoundManager.GLOBAL_DEBUG_ENABLED = not SoundManager.GLOBAL_DEBUG_ENABLED

	if SoundManager.GLOBAL_DEBUG_ENABLED then
		for _, sample in pairs(self.orderedSamples) do
			if sample.linkNode ~= nil then
				self.debugSamples[sample] = true
			end
		end
	else
		table.clear(self.debugSamples)

		for _, sample in pairs(self.debugSamplesFlagged) do
			self.debugSamples[sample] = true
		end
	end

	return string.format("SoundManager.GLOBAL_DEBUG_ENABLED=%s", SoundManager.GLOBAL_DEBUG_ENABLED)
end

function SoundManager.registerModifierXMLPaths(schema, path)
	schema:register(XMLValueType.STRING, path .. ".modifier(?)#type", "Modifier type")
	schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#value", "Source value of modifier type")
	schema:register(XMLValueType.FLOAT, path .. ".modifier(?)#modifiedValue", "Change that is applied on sample value")
end

function SoundManager.registerSampleXMLPaths(schema, basePath, name)
	schema:setSubSchemaIdentifier("sounds")

	if name == nil then
		Logging.error("Failed to register sound sample xml paths! No sound name given.")
		printCallstack()
	end

	schema:setXMLSharedRegistration("SoundManager_sound", basePath)

	local soundPath = basePath .. "." .. name

	schema:register(XMLValueType.NODE_INDEX, soundPath .. "#linkNode", "Link node for 3d sound")
	schema:register(XMLValueType.STRING, soundPath .. "#template", "Sound template name")
	schema:register(XMLValueType.STRING, soundPath .. "#parent", "Parent sample for heredity")
	schema:register(XMLValueType.STRING, soundPath .. "#file", "Path to sound sample")
	schema:register(XMLValueType.FLOAT, soundPath .. "#outerRadius", "Outer radius", 5)
	schema:register(XMLValueType.FLOAT, soundPath .. "#innerRadius", "Inner radius", 80)
	schema:register(XMLValueType.INT, soundPath .. "#loops", "Number of loops (0 = infinite)", 1)
	schema:register(XMLValueType.BOOL, soundPath .. "#supportsReverb", "Flag to disable reverb", true)
	schema:register(XMLValueType.BOOL, soundPath .. "#debug", "Flag to enable debug rendering", false)
	schema:register(XMLValueType.FLOAT, soundPath .. "#fadeIn", "Fade in time in seconds", 0)
	schema:register(XMLValueType.FLOAT, soundPath .. "#fadeOut", "Fade out time in seconds", 0)
	schema:register(XMLValueType.FLOAT, soundPath .. ".volume#indoor", "Indoor volume", 0.8)
	schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#indoor", "Indoor pitch", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#indoor", "Indoor lowpass gain", 0.8)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#indoor", "Indoor lowpass cutoff frequency", 5000)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#indoor", "Indoor lowpass resonance", 2)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassCutoffFrequency#outdoor", "Outdoor lowpass cutoff frequency", 5000)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassResonance#outdoor", "Outdoor lowpass resonance", 2)
	schema:register(XMLValueType.FLOAT, soundPath .. ".volume#outdoor", "Outdoor volume", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".pitch#outdoor", "Outdoor pitch", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. ".lowpassGain#outdoor", "Outdoor lowpass gain", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#volumeScale", "Additional scale that is applied on the volume attributes", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#pitchScale", "Additional pitch that is applied on the volume attributes", 1)
	schema:register(XMLValueType.FLOAT, soundPath .. "#lowpassGainScale", "Additional lowpass gain that is applied on the volume attributes", 1)
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".volume")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".pitch")
	SoundManager.registerModifierXMLPaths(schema, soundPath .. ".lowpassGain")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minVolume", "Min volume")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxVolume", "Max volume")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minPitch", "Max pitch")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxPitch", "Max pitch")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#minLowpassGain", "Max lowpass gain")
	schema:register(XMLValueType.FLOAT, soundPath .. ".randomization(?)#maxLowpassGain", "Max lowpass gain")
	schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isInside", "Randomization is applied inside", true)
	schema:register(XMLValueType.BOOL, soundPath .. ".randomization(?)#isOutside", "Randomization is applied outside", true)
	schema:register(XMLValueType.STRING, soundPath .. ".sourceRandomization(?)#file", "Path to sound sample")
	schema:setXMLSharedRegistration()
	schema:setSubSchemaIdentifier()
end

g_soundManager = SoundManager.new()
