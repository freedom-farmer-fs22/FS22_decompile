source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStartEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStopEvent.lua")
source("dataS/scripts/vehicles/AnimationValueFloat.lua")
source("dataS/scripts/vehicles/AnimationValueBool.lua")

AnimatedVehicle = {
	ANIMATION_PART_XML_KEY = "vehicle.animations.animation(?).part(?)",
	prerequisitesPresent = function (specializations)
		return true
	end
}

function AnimatedVehicle.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AnimatedVehicle")
	AnimatedVehicle.registerAnimationXMLPaths(schema, "vehicle.animations.animation(?)")
	schema:register(XMLValueType.STRING, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animName", "Animation name")
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animOuterRange", "Anim limit outer range", false)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animMinLimit", "Min. anim limit", 0)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	schema:register(XMLValueType.STRING, WorkArea.WORK_AREA_XML_KEY .. "#animName", "Animation name")
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. "#animMinLimit", "Min. anim limit", 0)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	schema:register(XMLValueType.STRING, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animName", "Animation name")
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animMinLimit", "Min. anim limit", 0)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	schema:setXMLSpecializationType()
end

function AnimatedVehicle.registerAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of animation")
	schema:register(XMLValueType.BOOL, basePath .. "#looping", "Animation is looping", false)
	schema:register(XMLValueType.BOOL, basePath .. "#resetOnStart", "Animation is reseted while loading the vehicle", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#startAnimTime", "Animation is set to this time if resetOnStart is set", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#soundVolumeFactor", "Sound volume factor that is applied for all sounds in this animation", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#isKeyframe", "Is static keyframe animation instead of dynamically interpolating animation (Keyframe animations only support trans/rot/scale!)", false)
	schema:addDelayedRegistrationPath(basePath .. ".part(?)", "AnimatedVehicle:part")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".part(?)#node", "Part node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startTime", "Start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#duration", "Duration")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endTime", "End time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#time", "Keyframe time (only for keyframe animations)")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#direction", "Part direction", 0)
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#tangentType", "Type of tangent to be used (linear, spline, step)", "linear")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRot", "Start rotation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRot", "End rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTrans", "Start translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTrans", "End translation")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#startScale", "Start scale")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#endScale", "End scale")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#visibility", "Visibility")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#startVisibility", "Visibility at start time (switched in the middle)")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#endVisibility", "Visibility at end time (switched in the middle)")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#componentJointIndex", "Component joint index")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#rotation", "Rotation  (only for keyframe animations)")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#translation", "Translation  (only for keyframe animations)")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#scale", "Scale  (only for keyframe animations)")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#requiredAnimation", "Required animation needs to be in a specific range to play part")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".part(?)#requiredAnimationRange", "Animation range of required animation")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#requiredConfigurationName", "This configuration needs to bet set to #requiredConfigurationIndex")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#requiredConfigurationIndex", "Required configuration needs to be in this state to activate the animation part")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotLimit", "Start rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotMinLimit", "Start rotation min limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotMaxLimit", "Start rotation max limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotLimit", "End rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotMinLimit", "End rotation min limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotMaxLimit", "End rotation max limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransLimit", "Start translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransMinLimit", "Start translation min limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransMaxLimit", "Start translation max limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransLimit", "End translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransMinLimit", "End translation min limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransMaxLimit", "End translation max limit")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#componentIndex", "Component index")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startMass", "Start mass of component")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startCenterOfMass", "Start center of mass")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endMass", "End mass of component")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endCenterOfMass", "End center of mass")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startFrictionVelocity", "Start friction velocity applied to node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endFrictionVelocity", "End friction velocity applied to node")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#shaderParameter", "Shader parameter")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#shaderParameterPrev", "Shader parameter (prev)")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".part(?)#shaderStartValues", "Start shader values")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".part(?)#shaderEndValues", "End shader values")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#animationClip", "Animation clip name")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#clipStartTime", "Animation clip start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#clipEndTime", "Animation clip end time")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#dependentAnimation", "Dependent animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#dependentAnimationStartTime", "Dependent animation start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#dependentAnimationEndTime", "Dependent animation end time")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".part(?)#spline", "Spline node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startSplinePos", "Start spline position")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endSplinePos", "End spline position")
	SoundManager.registerSampleXMLPaths(schema, basePath, "sound(?)")
	schema:register(XMLValueType.TIME, basePath .. ".sound(?)#startTime", "Start play time", 0)
	schema:register(XMLValueType.TIME, basePath .. ".sound(?)#endTime", "End play time for loops or used on oposite direction")
	schema:register(XMLValueType.INT, basePath .. ".sound(?)#direction", "Direction to play the sound (0 = any direction)", 0)
	SoundManager.registerSampleXMLPaths(schema, basePath, "stopTimePosSound(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath, "stopTimeNegSound(?)")
end

function AnimatedVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onRegisterAnimationValueTypes")
	SpecializationUtil.registerEvent(vehicleType, "onPlayAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onStartAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onFinishAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onStopAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onAnimationPartChanged")
end

function AnimatedVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "registerAnimationValueType", AnimatedVehicle.registerAnimationValueType)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimation", AnimatedVehicle.loadAnimation)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimationPart", AnimatedVehicle.loadAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticAnimationPart", AnimatedVehicle.loadStaticAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticAnimationPartValues", AnimatedVehicle.loadStaticAnimationPartValues)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationParts", AnimatedVehicle.initializeAnimationParts)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationPart", AnimatedVehicle.initializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "postInitializeAnimationPart", AnimatedVehicle.postInitializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "playAnimation", AnimatedVehicle.playAnimation)
	SpecializationUtil.registerFunction(vehicleType, "stopAnimation", AnimatedVehicle.stopAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationExists", AnimatedVehicle.getAnimationExists)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationByName", AnimatedVehicle.getAnimationByName)
	SpecializationUtil.registerFunction(vehicleType, "getIsAnimationPlaying", AnimatedVehicle.getIsAnimationPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getRealAnimationTime", AnimatedVehicle.getRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setRealAnimationTime", AnimatedVehicle.setRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationTime", AnimatedVehicle.getAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationTime", AnimatedVehicle.setAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationDuration", AnimatedVehicle.getAnimationDuration)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationSpeed", AnimatedVehicle.setAnimationSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationSpeed", AnimatedVehicle.getAnimationSpeed)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationStopTime", AnimatedVehicle.setAnimationStopTime)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationValues", AnimatedVehicle.resetAnimationValues)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationPartValues", AnimatedVehicle.resetAnimationPartValues)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimationPart", AnimatedVehicle.updateAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfActiveAnimations", AnimatedVehicle.getNumOfActiveAnimations)
end

function AnimatedVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", AnimatedVehicle.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", AnimatedVehicle.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", AnimatedVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", AnimatedVehicle.getIsWorkAreaActive)
end

function AnimatedVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", AnimatedVehicle)
end

function AnimatedVehicle:onPreLoad(savegame)
	local spec = self.spec_animatedVehicle
	spec.animationValueTypes = {}

	SpecializationUtil.raiseEvent(self, "onRegisterAnimationValueTypes")
end

function AnimatedVehicle:onLoad(savegame)
	local spec = self.spec_animatedVehicle
	spec.animations = {}
	local i = 0

	while true do
		local key = string.format("vehicle.animations.animation(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local animation = {}

		if self:loadAnimation(self.xmlFile, key, animation) then
			spec.animations[animation.name] = animation
		end

		i = i + 1
	end

	spec.activeAnimations = {}
	spec.numActiveAnimations = 0
	spec.fixedTimeSamplesDirtyDelay = 0
end

function AnimatedVehicle:onPostLoad(savegame)
	local spec = self.spec_animatedVehicle

	for name, animation in pairs(spec.animations) do
		if animation.resetOnStart then
			self:setAnimationTime(name, 1, true, false)
			self:setAnimationStopTime(name, animation.startTime)
			self:playAnimation(name, -1, 1, true, false)
			AnimatedVehicle.updateAnimationByName(self, name, 9999999, true)
		end
	end

	if next(spec.animations) == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", AnimatedVehicle)
	end
end

function AnimatedVehicle:onDelete()
	local spec = self.spec_animatedVehicle

	if self.isClient and spec.animations ~= nil then
		for _, animation in pairs(spec.animations) do
			g_soundManager:deleteSamples(animation.samples)
			g_soundManager:deleteSamples(animation.eventSamples.stopTimePos)
			g_soundManager:deleteSamples(animation.eventSamples.stopTimeNeg)
		end
	end
end

function AnimatedVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	AnimatedVehicle.updateAnimations(self, dt)

	local spec = self.spec_animatedVehicle

	if spec.fixedTimeSamplesDirtyDelay > 0 then
		spec.fixedTimeSamplesDirtyDelay = spec.fixedTimeSamplesDirtyDelay - 1

		if spec.fixedTimeSamplesDirtyDelay <= 0 then
			for _, animation in pairs(spec.animations) do
				if spec.activeAnimations[animation.name] == nil and self.isClient then
					for i = 1, #animation.samples do
						local sample = animation.samples[i]

						if g_soundManager:getIsSamplePlaying(sample) and sample.loops == 0 then
							g_soundManager:stopSample(sample)
						end
					end
				end
			end

			spec.fixedTimeSamplesDirtyDelay = 0
		end
	end

	if spec.numActiveAnimations > 0 then
		self:raiseActive()
	end
end

function AnimatedVehicle:registerAnimationValueType(name, startName, endName, initialUpdate, classObject, load, get, set)
	local spec = self.spec_animatedVehicle

	if spec.animationValueTypes[name] == nil then
		local animationValueType = {
			classObject = classObject,
			name = name,
			startName = startName,
			endName = endName,
			initialUpdate = initialUpdate,
			load = load,
			get = get,
			set = set
		}
		spec.animationValueTypes[name] = animationValueType
	end
end

function AnimatedVehicle:loadAnimation(xmlFile, key, animation, components)
	local name = xmlFile:getValue(key .. "#name")

	if name ~= nil then
		animation.name = name
		animation.parts = {}
		animation.currentTime = 0
		animation.previousTime = 0
		animation.currentSpeed = 1
		animation.looping = xmlFile:getValue(key .. "#looping", false)
		animation.resetOnStart = xmlFile:getValue(key .. "#resetOnStart", true)
		animation.soundVolumeFactor = xmlFile:getValue(key .. "#soundVolumeFactor", 1)
		animation.isKeyframe = xmlFile:getValue(key .. "#isKeyframe", false)

		if animation.isKeyframe then
			animation.curvesByNode = {}
		end

		local partI = 0

		while true do
			local partKey = key .. string.format(".part(%d)", partI)

			if not xmlFile:hasProperty(partKey) then
				break
			end

			local animationPart = {}

			if not animation.isKeyframe then
				if self:loadAnimationPart(xmlFile, partKey, animationPart, animation, components) then
					table.insert(animation.parts, animationPart)
				end
			else
				self:loadStaticAnimationPart(xmlFile, partKey, animationPart, animation, components)
			end

			partI = partI + 1
		end

		animation.partsReverse = {}

		for _, part in ipairs(animation.parts) do
			table.insert(animation.partsReverse, part)
		end

		table.sort(animation.parts, AnimatedVehicle.animPartSorter)
		table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse)
		self:initializeAnimationParts(animation)

		animation.currentPartIndex = 1
		animation.duration = 0

		for _, part in ipairs(animation.parts) do
			animation.duration = math.max(animation.duration, part.startTime + part.duration)
		end

		if animation.isKeyframe then
			for node, curve in pairs(animation.curvesByNode) do
				animation.duration = math.max(animation.duration, curve.maxTime)
			end
		end

		animation.startTime = xmlFile:getValue(key .. "#startAnimTime", 0)
		animation.currentTime = animation.startTime * animation.duration

		if self.isClient then
			animation.samples = {}
			local i = 0

			while true do
				local soundKey = string.format("sound(%d)", i)
				local baseKey = key .. "." .. soundKey

				if not xmlFile:hasProperty(baseKey) then
					break
				end

				local sample = g_soundManager:loadSampleFromXML(xmlFile, key, soundKey, self.baseDirectory, components or self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

				if sample ~= nil then
					sample.startTime = xmlFile:getValue(baseKey .. "#startTime", 0)
					sample.endTime = xmlFile:getValue(baseKey .. "#endTime")
					sample.direction = xmlFile:getValue(baseKey .. "#direction", 0)

					if sample.endTime == nil and sample.loops == 0 then
						sample.loops = 1
					end

					sample.volumeScale = sample.volumeScale * animation.soundVolumeFactor

					table.insert(animation.samples, sample)
				end

				i = i + 1
			end

			animation.eventSamples = {
				stopTimePos = {},
				stopTimeNeg = {}
			}

			xmlFile:iterate(key .. ".stopTimePosSound", function (index, _)
				local sample = g_soundManager:loadSampleFromXML(xmlFile, key, string.format("stopTimePosSound(%d)", index - 1), self.baseDirectory, components or self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

				if sample ~= nil then
					table.insert(animation.eventSamples.stopTimePos, sample)
				end
			end)
			xmlFile:iterate(key .. ".stopTimeNegSound", function (index, _)
				local sample = g_soundManager:loadSampleFromXML(xmlFile, key, string.format("stopTimeNegSound(%d)", index - 1), self.baseDirectory, components or self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

				if sample ~= nil then
					table.insert(animation.eventSamples.stopTimeNeg, sample)
				end
			end)
		end

		return true
	end

	return false
end

function AnimatedVehicle:loadAnimationPart(xmlFile, partKey, part, animation, components)
	local startTime = xmlFile:getValue(partKey .. "#startTime")
	local duration = xmlFile:getValue(partKey .. "#duration")
	local endTime = xmlFile:getValue(partKey .. "#endTime")
	local direction = MathUtil.sign(xmlFile:getValue(partKey .. "#direction", 0))
	part.components = components or self.components
	part.i3dMappings = self.i3dMappings
	part.animationValues = {}
	local spec = self.spec_animatedVehicle

	for _, animationValueType in pairs(spec.animationValueTypes) do
		local animationValueObject = animationValueType.classObject.new(self, animation, part, animationValueType.startName, animationValueType.endName, animationValueType.name, animationValueType.initialUpdate, animationValueType.get, animationValueType.set, animationValueType.load)

		if animationValueObject:load(xmlFile, partKey) then
			table.insert(part.animationValues, animationValueObject)
		end
	end

	local requiredAnimation = xmlFile:getValue(partKey .. "#requiredAnimation")
	local requiredAnimationRange = xmlFile:getValue(partKey .. "#requiredAnimationRange", nil, true)
	local requiredConfigurationName = xmlFile:getValue(partKey .. "#requiredConfigurationName")
	local requiredConfigurationIndex = xmlFile:getValue(partKey .. "#requiredConfigurationIndex")

	for i = 1, #part.animationValues do
		part.animationValues[i].requiredAnimation = requiredAnimation

		part.animationValues[i]:addCompareParameters("requiredAnimation")

		if requiredAnimationRange ~= nil then
			part.animationValues[i].requiredAnimationRange = string.format("%.2f %.2f", requiredAnimationRange[1], requiredAnimationRange[2])

			part.animationValues[i]:addCompareParameters("requiredAnimationRange")
		end
	end

	if #part.animationValues == 0 then
		return false
	end

	if startTime ~= nil and (duration ~= nil or endTime ~= nil) then
		if endTime ~= nil then
			duration = endTime - startTime
		end

		part.startTime = startTime * 1000
		part.duration = duration * 1000
		part.direction = direction
		part.requiredAnimation = requiredAnimation
		part.requiredAnimationRange = requiredAnimationRange
		part.requiredConfigurationName = requiredConfigurationName
		part.requiredConfigurationIndex = requiredConfigurationIndex

		return true
	end

	return false
end

function AnimatedVehicle:loadStaticAnimationPart(xmlFile, partKey, part, animation, components)
	local node = xmlFile:getValue(partKey .. "#node", nil, self.components, self.i3dMappings)

	if node ~= nil then
		local time = xmlFile:getValue(partKey .. "#time")
		local startTime = xmlFile:getValue(partKey .. "#startTime")
		local endTime = xmlFile:getValue(partKey .. "#endTime")

		if animation.curvesByNode[node] == nil then
			animation.curvesByNode[node] = AnimCurve.new(linearInterpolatorTransRotScale)
		end

		local curve = animation.curvesByNode[node]

		if time ~= nil then
			self:loadStaticAnimationPartValues(xmlFile, partKey, curve, node, "translation", "rotation", "scale", time * 1000)
		elseif startTime ~= nil or endTime ~= nil then
			if startTime ~= nil then
				startTime = startTime * 1000

				if curve.maxTime == 0 or curve.maxTime ~= startTime then
					self:loadStaticAnimationPartValues(xmlFile, partKey, curve, node, "startTrans", "startRot", "startScale", startTime)
				end
			end

			if endTime ~= nil then
				endTime = endTime * 1000

				if curve.maxTime == 0 or curve.maxTime ~= endTime then
					self:loadStaticAnimationPartValues(xmlFile, partKey, curve, node, "endTrans", "endRot", "endScale", endTime)
				end
			end
		end

		return true
	end

	return false
end

function AnimatedVehicle:loadStaticAnimationPartValues(xmlFile, partKey, curve, node, transName, rotName, scaleName, time)
	local x, y, z = xmlFile:getValue(partKey .. "#" .. transName)

	if x == nil then
		x, y, z = getTranslation(node)
	else
		curve.hasTranslation = true
	end

	local rx, ry, rz = xmlFile:getValue(partKey .. "#" .. rotName)

	if rx == nil then
		rx, ry, rz = getRotation(node)
	else
		curve.hasRotation = true
	end

	local sx, sy, sz = xmlFile:getValue(partKey .. "#" .. scaleName)

	if sx == nil then
		sx, sy, sz = getScale(node)
	else
		curve.hasScale = true
	end

	curve:addKeyframe({
		x = x,
		y = y,
		z = z,
		rx = rx,
		ry = ry,
		rz = rz,
		sx = sx,
		sy = sy,
		sz = sz,
		time = time
	})
end

function AnimatedVehicle:initializeAnimationParts(animation)
	local numParts = #animation.parts

	for i, part in ipairs(animation.parts) do
		self:initializeAnimationPart(animation, part, i, numParts)
	end

	for i, part in ipairs(animation.parts) do
		self:postInitializeAnimationPart(animation, part, i, numParts)
	end
end

function AnimatedVehicle:initializeAnimationPart(animation, part, i, numParts)
	for index = 1, #part.animationValues do
		part.animationValues[index]:init(i, numParts)
	end
end

function AnimatedVehicle:postInitializeAnimationPart(animation, part, i, numParts)
	for index = 1, #part.animationValues do
		part.animationValues[index]:postInit()
	end
end

function AnimatedVehicle:playAnimation(name, speed, animTime, noEventSend, allowSounds)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onPlayAnimation", name)

		if speed == nil then
			speed = animation.currentSpeed
		end

		if speed == nil or speed == 0 then
			return
		end

		if animTime == nil then
			if self:getIsAnimationPlaying(name) then
				animTime = self:getAnimationTime(name)
			elseif speed > 0 then
				animTime = 0
			else
				animTime = 1
			end
		end

		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(AnimatedVehicleStartEvent.new(self, name, speed, animTime), nil, , self)
			else
				g_client:getServerConnection():sendEvent(AnimatedVehicleStartEvent.new(self, name, speed, animTime))
			end
		end

		if spec.activeAnimations[name] == nil then
			spec.activeAnimations[name] = animation
			spec.numActiveAnimations = spec.numActiveAnimations + 1

			SpecializationUtil.raiseEvent(self, "onStartAnimation", name)
		end

		animation.currentSpeed = speed
		animation.currentTime = animTime * animation.duration

		self:resetAnimationValues(animation)
		self:raiseActive()
	end
end

function AnimatedVehicle:stopAnimation(name, noEventSend)
	local spec = self.spec_animatedVehicle

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(AnimatedVehicleStopEvent.new(self, name), nil, , self)
		else
			g_client:getServerConnection():sendEvent(AnimatedVehicleStopEvent.new(self, name))
		end
	end

	local animation = spec.animations[name]

	if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onStopAnimation", name)

		animation.stopTime = nil

		if self.isClient then
			for i = 1, #animation.samples do
				local sample = animation.samples[i]

				if sample.loops == 0 then
					g_soundManager:stopSample(sample)
				end
			end
		end
	end

	if spec.activeAnimations[name] ~= nil then
		spec.numActiveAnimations = spec.numActiveAnimations - 1
		spec.activeAnimations[name] = nil

		SpecializationUtil.raiseEvent(self, "onFinishAnimation", name)
	end
end

function AnimatedVehicle:getAnimationExists(name)
	local spec = self.spec_animatedVehicle

	return spec.animations[name] ~= nil
end

function AnimatedVehicle:getAnimationByName(name)
	return self.spec_animatedVehicle.animations[name]
end

function AnimatedVehicle:getIsAnimationPlaying(name)
	local spec = self.spec_animatedVehicle

	return spec.activeAnimations[name] ~= nil
end

function AnimatedVehicle:getRealAnimationTime(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.currentTime
	end

	return 0
end

function AnimatedVehicle:setRealAnimationTime(name, animTime, update, playSounds)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		if update == nil or update then
			local currentSpeed = animation.currentSpeed
			animation.currentSpeed = 1

			if animTime < animation.currentTime then
				animation.currentSpeed = -1
			end

			self:resetAnimationValues(animation)

			local dtToUse, _ = AnimatedVehicle.updateAnimationCurrentTime(self, animation, 99999999, animTime)

			AnimatedVehicle.updateAnimation(self, animation, dtToUse, true, true, playSounds)

			animation.currentSpeed = currentSpeed
		else
			animation.currentTime = animTime
		end
	end
end

function AnimatedVehicle:getAnimationTime(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.currentTime / animation.duration
	end

	return 0
end

function AnimatedVehicle:setAnimationTime(name, animTime, update, playSounds)
	local spec = self.spec_animatedVehicle

	if spec.animations == nil then
		printCallstack()
	end

	local animation = spec.animations[name]

	if animation ~= nil then
		self:setRealAnimationTime(name, animTime * animation.duration, update, playSounds)
	end
end

function AnimatedVehicle:getAnimationDuration(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.duration
	end

	return 1
end

function AnimatedVehicle:setAnimationSpeed(name, speed)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		local speedReversed = false

		if animation.currentSpeed > 0 ~= (speed > 0) then
			speedReversed = true
		end

		animation.currentSpeed = speed

		if self:getIsAnimationPlaying(name) and speedReversed then
			self:resetAnimationValues(animation)
		end
	end
end

function AnimatedVehicle:getAnimationSpeed(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.currentSpeed
	end

	return 0
end

function AnimatedVehicle:setAnimationStopTime(name, stopTime)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		animation.stopTime = stopTime * animation.duration
	end
end

function AnimatedVehicle:resetAnimationValues(animation)
	AnimatedVehicle.findCurrentPartIndex(animation)

	for _, part in ipairs(animation.parts) do
		self:resetAnimationPartValues(part)
	end
end

function AnimatedVehicle:resetAnimationPartValues(part)
	for index = 1, #part.animationValues do
		part.animationValues[index]:reset()
	end
end

function AnimatedVehicle:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.animName = xmlFile:getValue(key .. "#animName")
	speedRotatingPart.animOuterRange = xmlFile:getValue(key .. "#animOuterRange", false)
	speedRotatingPart.animMinLimit = xmlFile:getValue(key .. "#animMinLimit", 0)
	speedRotatingPart.animMaxLimit = xmlFile:getValue(key .. "#animMaxLimit", 1)

	return true
end

function AnimatedVehicle:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.animName ~= nil then
		local animTime = self:getAnimationTime(speedRotatingPart.animName)

		if speedRotatingPart.animOuterRange then
			if speedRotatingPart.animMinLimit < animTime or animTime < speedRotatingPart.animMaxLimit then
				return false
			end
		elseif speedRotatingPart.animMaxLimit < animTime or animTime < speedRotatingPart.animMinLimit then
			return false
		end
	end

	return superFunc(self, speedRotatingPart)
end

function AnimatedVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.animName = xmlFile:getValue(key .. "#animName")
	workArea.animMinLimit = xmlFile:getValue(key .. "#animMinLimit", 0)
	workArea.animMaxLimit = xmlFile:getValue(key .. "#animMaxLimit", 1)

	return superFunc(self, workArea, xmlFile, key)
end

function AnimatedVehicle:getIsWorkAreaActive(superFunc, workArea)
	if workArea.animName ~= nil then
		local animTime = self:getAnimationTime(workArea.animName)

		if workArea.animMaxLimit < animTime or animTime < workArea.animMinLimit then
			return false
		end
	end

	return superFunc(self, workArea)
end

function AnimatedVehicle:initializeAnimationPartAttribute(animation, part, i, numParts, nextName, prevName, startName, endName, warningName, startName2, endName2, additionalCompareParam)
	if part[endName] ~= nil then
		for j = i + 1, numParts do
			local part2 = animation.parts[j]
			local additionalCompare = true

			if additionalCompareParam ~= nil and part[additionalCompareParam] ~= part2[additionalCompareParam] then
				additionalCompare = false
			end

			local sameRequiredRange = true

			if part.requiredAnimation ~= nil and part.requiredAnimation == part2.requiredAnimation then
				for n, v in ipairs(part.requiredAnimationRange) do
					if part2.requiredAnimationRange[n] ~= v then
						sameRequiredRange = false
					end
				end
			end

			local sameConfiguration = true

			if part.requiredConfigurationName ~= nil and part.requiredConfigurationName == part2.requiredConfigurationName and part.requiredConfigurationIndex ~= part2.requiredConfigurationIndex then
				sameConfiguration = false
			end

			if part.direction == part2.direction and part.node == part2.node and part2[endName] ~= nil and additionalCompare and sameRequiredRange and sameConfiguration then
				if part.direction == part2.direction and part.startTime + part.duration > part2.startTime + 0.001 then
					Logging.xmlWarning(self.xmlFile, "Overlapping %s parts for node '%s' in animation '%s'", warningName, getName(part.node), animation.name)
				end

				part[nextName] = part2
				part2[prevName] = part

				if part2[startName] == nil then
					part2[startName] = {
						unpack(part[endName])
					}
				end

				if startName2 ~= nil and endName2 ~= nil and part2[startName2] == nil then
					part2[startName2] = {
						unpack(part[endName2])
					}
				end

				break
			end
		end
	end
end

function AnimatedVehicle.animPartSorter(a, b)
	if a.startTime < b.startTime then
		return true
	elseif a.startTime == b.startTime then
		return a.duration < b.duration
	end

	return false
end

function AnimatedVehicle.animPartSorterReverse(a, b)
	local endTimeA = a.startTime + a.duration
	local endTimeB = b.startTime + b.duration

	if endTimeA > endTimeB then
		return true
	elseif endTimeA == endTimeB then
		return b.startTime < a.startTime
	end

	return false
end

function AnimatedVehicle.getMovedLimitedValue(currentValue, destValue, speed, dt)
	if destValue == currentValue then
		return currentValue
	end

	local limitF = destValue < currentValue and math.max or math.min

	return limitF(currentValue + speed * dt, destValue)
end

function AnimatedVehicle.setMovedLimitedValuesN(n, currentValues, destValues, speeds, dt)
	local hasChanged = false

	for i = 1, n do
		local newValue = AnimatedVehicle.getMovedLimitedValue(currentValues[i], destValues[i], speeds[i], dt)

		if currentValues[i] ~= newValue then
			hasChanged = true
			currentValues[i] = newValue
		end
	end

	return hasChanged
end

function AnimatedVehicle.setMovedLimitedValues3(currentValues, destValues, speeds, dt)
	return AnimatedVehicle.setMovedLimitedValuesN(3, currentValues, destValues, speeds, dt)
end

function AnimatedVehicle.setMovedLimitedValues4(currentValues, destValues, speeds, dt)
	return AnimatedVehicle.setMovedLimitedValuesN(4, currentValues, destValues, speeds, dt)
end

function AnimatedVehicle.findCurrentPartIndex(animation)
	if animation.currentSpeed > 0 then
		animation.currentPartIndex = #animation.parts + 1

		for i, part in ipairs(animation.parts) do
			if animation.currentTime <= part.startTime + part.duration then
				animation.currentPartIndex = i

				break
			end
		end
	else
		animation.currentPartIndex = #animation.partsReverse + 1

		for i, part in ipairs(animation.partsReverse) do
			if part.startTime <= animation.currentTime then
				animation.currentPartIndex = i

				break
			end
		end
	end
end

function AnimatedVehicle.getDurationToEndOfPart(part, anim)
	if anim.currentSpeed > 0 then
		return part.startTime + part.duration - anim.currentTime
	else
		return anim.currentTime - part.startTime
	end
end

function AnimatedVehicle.getNextPartIsPlaying(nextPart, prevPart, anim, default)
	if anim.currentSpeed > 0 then
		if nextPart ~= nil then
			return anim.currentTime < nextPart.startTime
		end
	elseif prevPart ~= nil then
		return prevPart.startTime + prevPart.duration < anim.currentTime
	end

	return default
end

function AnimatedVehicle:updateAnimations(dt, fixedTimeUpdate)
	local spec = self.spec_animatedVehicle

	for _, anim in pairs(spec.activeAnimations) do
		local dtToUse, stopAnim = AnimatedVehicle.updateAnimationCurrentTime(self, anim, dt, anim.stopTime)

		AnimatedVehicle.updateAnimation(self, anim, dtToUse, stopAnim, fixedTimeUpdate)
	end
end

function AnimatedVehicle:updateAnimationByName(animName, dt, fixedTimeUpdate)
	local spec = self.spec_animatedVehicle
	local anim = spec.animations[animName]

	if anim ~= nil then
		local dtToUse, stopAnim = AnimatedVehicle.updateAnimationCurrentTime(self, anim, dt, anim.stopTime)

		AnimatedVehicle.updateAnimation(self, anim, dtToUse, stopAnim, fixedTimeUpdate)
	end
end

function AnimatedVehicle:updateAnimationCurrentTime(anim, dt, stopTime)
	anim.previousTime = anim.currentTime
	anim.currentTime = anim.currentTime + dt * anim.currentSpeed
	local absSpeed = math.abs(anim.currentSpeed)
	local dtToUse = dt * absSpeed
	local stopAnim = false

	if stopTime ~= nil then
		if anim.currentSpeed > 0 then
			if stopTime <= anim.currentTime then
				dtToUse = dtToUse - (anim.currentTime - stopTime)
				anim.currentTime = stopTime
				stopAnim = true
			end
		elseif anim.currentTime <= stopTime then
			dtToUse = dtToUse - (stopTime - anim.currentTime)
			anim.currentTime = stopTime
			stopAnim = true
		end
	end

	return dtToUse, stopAnim
end

function AnimatedVehicle:updateAnimation(anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds)
	local spec = self.spec_animatedVehicle
	local isStopTimeStop = stopAnim
	local numParts = #anim.parts
	local parts = anim.parts

	if anim.currentSpeed < 0 then
		parts = anim.partsReverse
	end

	if dtToUse > 0 then
		local hasChanged = false
		local nothingToChangeYet = false

		if not anim.isKeyframe then
			for partI = anim.currentPartIndex, numParts do
				local part = parts[partI]
				local isInRange = true

				if part.requiredAnimation ~= nil then
					local time = self:getAnimationTime(part.requiredAnimation)

					if time < part.requiredAnimationRange[1] or part.requiredAnimationRange[2] < time then
						isInRange = false
					end
				end

				local sameConfiguration = true

				if part.requiredConfigurationName ~= nil and self.configurations[part.requiredConfigurationName] ~= nil and self.configurations[part.requiredConfigurationName] ~= part.requiredConfigurationIndex then
					sameConfiguration = false
				end

				if (part.direction == 0 or part.direction > 0 == (anim.currentSpeed >= 0)) and isInRange and sameConfiguration then
					local durationToEnd = AnimatedVehicle.getDurationToEndOfPart(part, anim)

					if part.duration < durationToEnd then
						nothingToChangeYet = true

						break
					end

					local realDt = dtToUse

					if anim.currentSpeed > 0 then
						local startT = anim.currentTime - dtToUse

						if startT < part.startTime then
							realDt = dtToUse - part.startTime + startT
						end
					else
						local startT = anim.currentTime + dtToUse
						local endTime = part.startTime + part.duration

						if startT > endTime then
							realDt = dtToUse - (startT - endTime)
						end
					end

					durationToEnd = durationToEnd + realDt

					if self:updateAnimationPart(anim, part, durationToEnd, dtToUse, realDt, fixedTimeUpdate) then
						hasChanged = true
					end
				end

				if partI == anim.currentPartIndex and (anim.currentSpeed > 0 and part.startTime + part.duration < anim.currentTime or anim.currentSpeed <= 0 and anim.currentTime < part.startTime) then
					self:resetAnimationPartValues(part)

					anim.currentPartIndex = anim.currentPartIndex + 1
				end
			end

			if not nothingToChangeYet and not hasChanged and numParts <= anim.currentPartIndex then
				anim.previousTime = anim.currentTime

				if anim.currentSpeed > 0 then
					anim.currentTime = anim.duration
				else
					anim.currentTime = 0
				end

				stopAnim = true
			end
		else
			for node, curve in pairs(anim.curvesByNode) do
				local x, y, z, rx, ry, rz, sx, sy, sz = curve:get(anim.currentTime)

				if curve.hasTranslation then
					setTranslation(node, x, y, z)
				end

				if curve.hasRotation then
					setRotation(node, rx, ry, rz)
				end

				if curve.hasScale then
					setScale(node, sx, sy, sz)
				end

				SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", node)
			end

			stopAnim = anim.currentTime <= 0 or anim.duration <= anim.currentTime
		end

		if spec.activeAnimations[anim.name] ~= nil or playSounds == true then
			if fixedTimeUpdate ~= true or playSounds == true then
				for i = 1, #anim.samples do
					local sample = anim.samples[i]

					if g_soundManager:getIsSamplePlaying(sample) then
						if sample.endTime ~= nil then
							if anim.currentSpeed > 0 then
								if sample.endTime < anim.currentTime then
									g_soundManager:stopSample(sample)
								end
							elseif anim.currentTime < sample.startTime then
								g_soundManager:stopSample(sample)
							end
						end
					elseif sample.direction == 0 or sample.direction >= 0 == (anim.currentSpeed >= 0) then
						if sample.loops ~= 0 then
							if sample.endTime ~= nil then
								sample.readyToStart = anim.previousTime < sample.startTime or sample.endTime < anim.previousTime
							elseif anim.currentSpeed < 0 then
								sample.readyToStart = sample.startTime < anim.previousTime
							else
								sample.readyToStart = anim.previousTime < sample.startTime
							end
						else
							sample.readyToStart = true
						end

						local inRange = sample.startTime <= anim.currentTime

						if sample.endTime ~= nil then
							inRange = sample.startTime <= anim.currentTime and anim.currentTime <= sample.endTime
						elseif anim.currentSpeed < 0 then
							inRange = anim.currentTime <= sample.startTime
						end

						if sample.readyToStart and inRange then
							g_soundManager:playSample(sample)
						end
					end
				end
			end

			if spec.activeAnimations[anim.name] == nil then
				spec.fixedTimeSamplesDirtyDelay = 2
			end
		end
	end

	if stopAnim or numParts > 0 and (numParts < anim.currentPartIndex or anim.currentPartIndex < 1) then
		anim.previousTime = anim.currentTime

		if not stopAnim then
			if anim.currentSpeed > 0 then
				anim.currentTime = anim.duration
			else
				anim.currentTime = 0
			end
		end

		anim.currentTime = math.min(math.max(anim.currentTime, 0), anim.duration)
		local allowLooping = anim.stopTime ~= anim.currentTime
		anim.stopTime = nil

		if spec.activeAnimations[anim.name] ~= nil then
			spec.numActiveAnimations = spec.numActiveAnimations - 1

			if self.isClient then
				local animation = spec.activeAnimations[anim.name]

				for i = 1, #animation.samples do
					local sample = animation.samples[i]

					if sample.loops == 0 then
						g_soundManager:stopSample(sample)
					end
				end

				if isStopTimeStop then
					if anim.currentSpeed > 0 then
						for i = 1, #animation.eventSamples.stopTimePos do
							g_soundManager:playSample(animation.eventSamples.stopTimePos[i])
						end
					else
						for i = 1, #animation.eventSamples.stopTimeNeg do
							g_soundManager:playSample(animation.eventSamples.stopTimeNeg[i])
						end
					end
				end
			end

			spec.activeAnimations[anim.name] = nil

			SpecializationUtil.raiseEvent(self, "onFinishAnimation", anim.name)
		end

		if allowLooping and fixedTimeUpdate ~= true and anim.looping then
			self:setAnimationTime(anim.name, math.abs(anim.currentTime / anim.duration - 1), true)
			self:playAnimation(anim.name, anim.currentSpeed, nil, true)
		end
	end
end

function AnimatedVehicle:updateAnimationPart(animation, part, durationToEnd, dtToUse, realDt, fixedTimeUpdate)
	local hasPartChanged = false

	for index = 1, #part.animationValues do
		local valueChanged = part.animationValues[index]:update(durationToEnd, dtToUse, realDt, fixedTimeUpdate)
		hasPartChanged = hasPartChanged or valueChanged
	end

	return hasPartChanged
end

function AnimatedVehicle:getNumOfActiveAnimations()
	return self.spec_animatedVehicle.numActiveAnimations
end

function AnimatedVehicle:onRegisterAnimationValueTypes()
	local function loadNodeFunction(value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)

		if value.node ~= nil then
			value:setWarningInformation("node: " .. getName(value.node))
			value:addCompareParameters("node")

			return true
		end

		return false
	end

	self:registerAnimationValueType("rotation", "startRot", "endRot", false, AnimationValueFloat, loadNodeFunction, function (value)
		return getRotation(value.node)
	end, function (value, ...)
		setRotation(value.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", value.node)
	end)
	self:registerAnimationValueType("translation", "startTrans", "endTrans", false, AnimationValueFloat, loadNodeFunction, function (value)
		return getTranslation(value.node)
	end, function (value, ...)
		setTranslation(value.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", value.node)
	end)
	self:registerAnimationValueType("scale", "startScale", "endScale", false, AnimationValueFloat, loadNodeFunction, function (value)
		return getScale(value.node)
	end, function (value, ...)
		setScale(value.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", value.node)
	end)

	local function updateShaderParameterMask(xmlFile, xmlKey, mask)
		local customMask = false
		local rawValuesStr = xmlFile:getString(xmlKey)

		if rawValuesStr ~= nil then
			local rawValues = rawValuesStr:split(" ")

			for i = 1, #rawValues do
				if rawValues[i] == "-" then
					mask[i] = 0
					customMask = true
				end
			end
		end

		return customMask
	end

	self:registerAnimationValueType("shaderParameter", "shaderStartValues", "shaderEndValues", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)
		value.shaderParameter = xmlFile:getValue(xmlKey .. "#shaderParameter")
		value.shaderParameterPrev = xmlFile:getValue(xmlKey .. "#shaderParameterPrev")

		if value.node ~= nil and value.shaderParameter ~= nil then
			if getHasClassId(value.node, ClassIds.SHAPE) and getHasShaderParameter(value.node, value.shaderParameter) then
				value:setWarningInformation("node: " .. getName(value.node) .. "with shaderParam: " .. value.shaderParameter)
				value:addCompareParameters("node", "shaderParameter")

				value.shaderParameterMask = {
					1,
					1,
					1,
					1
				}
				value.customShaderParameterMask = updateShaderParameterMask(xmlFile, xmlKey .. "#shaderStartValues", value.shaderParameterMask)
				value.customShaderParameterMask = updateShaderParameterMask(xmlFile, xmlKey .. "#shaderEndValues", value.shaderParameterMask) or value.customShaderParameterMask

				if value.shaderParameterPrev ~= nil then
					if not getHasShaderParameter(value.node, value.shaderParameterPrev) then
						Logging.xmlWarning(xmlFile, "Node '%s' has no shaderParameterPrev '%s' for animation part '%s'!", getName(value.node), value.shaderParameterPrev, xmlKey)

						return false
					end
				else
					local prevName = "prev" .. value.shaderParameter:sub(1, 1):upper() .. value.shaderParameter:sub(2)

					if getHasShaderParameter(value.node, prevName) then
						value.shaderParameterPrev = prevName
					end
				end

				return true
			else
				Logging.xmlWarning(xmlFile, "Node '%s' has no shaderParameter '%s' for animation part '%s'!", getName(value.node), value.shaderParameter, xmlKey)
			end
		end

		return false
	end, function (value)
		return getShaderParameter(value.node, value.shaderParameter)
	end, function (value, x, y, z, w)
		if value.customShaderParameterMask then
			local sx, sy, sz, sw = getShaderParameter(value.node, value.shaderParameter)

			if value.shaderParameterMask[1] == 0 then
				x = sx
			end

			if value.shaderParameterMask[2] == 0 then
				y = sy
			end

			if value.shaderParameterMask[3] == 0 then
				z = sz
			end

			if value.shaderParameterMask[4] == 0 then
				w = sw
			end
		end

		if value.shaderParameterPrev ~= nil then
			g_animationManager:setPrevShaderParameter(value.node, value.shaderParameter, x, y, z, w, false, value.shaderParameterPrev)
		else
			setShaderParameter(value.node, value.shaderParameter, x, y, z, w, false)
		end
	end)
	self:registerAnimationValueType("visibility", "visibility", "", false, AnimationValueBool, loadNodeFunction, function (value)
		return getVisibility(value.node)
	end, function (value, ...)
		setVisibility(value.node, ...)
	end)
	self:registerAnimationValueType("visibilityInter", "startVisibility", "endVisibility", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)

		if value.node ~= nil and value.startValue ~= nil and value.endValue ~= nil then
			value:setWarningInformation("node: " .. getName(value.node))
			value:addCompareParameters("node")

			return true
		end

		return false
	end, function (value)
		if value.lastVisibilityValue ~= nil then
			return value.lastVisibilityValue
		end

		return getVisibility(value.node) and 1 or 0
	end, function (value, visibility)
		value.lastVisibilityValue = visibility

		setVisibility(value.node, visibility >= 0.5)
	end)
	self:registerAnimationValueType("animationClip", "clipStartTime", "clipEndTime", true, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)
		value.animationClip = xmlFile:getValue(xmlKey .. "#animationClip")

		if value.node ~= nil and value.animationClip ~= nil then
			value.animationCharSet = getAnimCharacterSet(value.node)
			value.animationClipIndex = getAnimClipIndex(value.animationCharSet, value.animationClip)

			value:setWarningInformation("node: " .. getName(value.node) .. "with animationClip: " .. value.animationClip)
			value:addCompareParameters("node", "animationClip")

			return true
		end

		return false
	end, function (value)
		local oldClipIndex = getAnimTrackAssignedClip(value.animationCharSet, 0)

		clearAnimTrackClip(value.animationCharSet, 0)
		assignAnimTrackClip(value.animationCharSet, 0, value.animationClipIndex)

		if oldClipIndex == value.animationClipIndex then
			return getAnimTrackTime(value.animationCharSet, 0)
		end

		local startTime = value.startValue or value.endValue

		if value.animation.currentSpeed < 0 then
			startTime = value.endValue or value.startValue
		end

		return startTime[1]
	end, function (value, time)
		local oldClipIndex = getAnimTrackAssignedClip(value.animationCharSet, 0)

		if oldClipIndex ~= value.animationClipIndex then
			clearAnimTrackClip(value.animationCharSet, 0)
			assignAnimTrackClip(value.animationCharSet, 0, value.animationClipIndex)
		end

		enableAnimTrack(value.animationCharSet, 0)
		setAnimTrackTime(value.animationCharSet, 0, time, true)
		disableAnimTrack(value.animationCharSet, 0)
	end)
	self:registerAnimationValueType("dependentAnimation", "dependentAnimationStartTime", "dependentAnimationEndTime", true, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.dependentAnimation = xmlFile:getValue(xmlKey .. "#dependentAnimation")

		if value.dependentAnimation ~= nil then
			value:setWarningInformation("dependentAnimation: " .. value.dependentAnimation)
			value:addCompareParameters("dependentAnimation")

			return true
		end

		return false
	end, function (value)
		return value.vehicle:getAnimationTime(value.dependentAnimation)
	end, function (value, time)
		value.vehicle:setAnimationTime(value.dependentAnimation, time, true)
	end)

	if self.isServer then
		self:registerAnimationValueType("rotLimit", "", "", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
			value.startRotLimit = xmlFile:getValue(xmlKey .. "#startRotLimit", nil, true)
			value.startRotMinLimit = xmlFile:getValue(xmlKey .. "#startRotMinLimit", nil, true)
			value.startRotMaxLimit = xmlFile:getValue(xmlKey .. "#startRotMaxLimit", nil, true)

			if value.startRotLimit ~= nil then
				value.startRotMinLimit = {
					-value.startRotLimit[1],
					-value.startRotLimit[2],
					-value.startRotLimit[3]
				}
				value.startRotMaxLimit = {
					value.startRotLimit[1],
					value.startRotLimit[2],
					value.startRotLimit[3]
				}
			end

			value.endRotLimit = xmlFile:getValue(xmlKey .. "#endRotLimit", nil, true)
			value.endRotMinLimit = xmlFile:getValue(xmlKey .. "#endRotMinLimit", nil, true)
			value.endRotMaxLimit = xmlFile:getValue(xmlKey .. "#endRotMaxLimit", nil, true)

			if value.endRotLimit ~= nil then
				value.endRotMinLimit = {
					-value.endRotLimit[1],
					-value.endRotLimit[2],
					-value.endRotLimit[3]
				}
				value.endRotMaxLimit = {
					value.endRotLimit[1],
					value.endRotLimit[2],
					value.endRotLimit[3]
				}
			end

			local componentJointIndex = xmlFile:getValue(xmlKey .. "#componentJointIndex")

			if componentJointIndex ~= nil then
				if componentJointIndex >= 1 then
					value.componentJoint = value.vehicle.componentJoints[componentJointIndex]
				end

				if value.componentJoint == nil then
					Logging.xmlWarning(xmlFile, "Invalid componentJointIndex for animation part '%s'. Indexing starts with 1!", xmlKey)

					return false
				end
			end

			if value.endRotMinLimit ~= nil and value.endRotMaxLimit == nil or value.endRotMinLimit == nil and value.endRotMaxLimit ~= nil then
				Logging.xmlWarning(xmlFile, "Incomplete end trans limit for animation part '%s'.", xmlKey)

				return false
			end

			if value.componentJoint ~= nil and value.endRotMinLimit ~= nil and value.endRotMaxLimit ~= nil then
				if value.startRotMinLimit ~= nil and value.startRotMaxLimit ~= nil then
					value.startValue = {
						value.startRotMinLimit[1],
						value.startRotMinLimit[2],
						value.startRotMinLimit[3],
						value.startRotMaxLimit[1],
						value.startRotMaxLimit[2],
						value.startRotMaxLimit[3]
					}
				end

				if value.endRotMinLimit ~= nil and value.endRotMaxLimit ~= nil then
					value.endValue = {
						value.endRotMinLimit[1],
						value.endRotMinLimit[2],
						value.endRotMinLimit[3],
						value.endRotMaxLimit[1],
						value.endRotMaxLimit[2],
						value.endRotMaxLimit[3]
					}
				end

				if value.endValue == nil then
					Logging.xmlWarning(xmlFile, "Missing end rot limit for animation part '%s'.", xmlKey)

					return false
				end

				value.endName = "rotLimit"

				value:setWarningInformation("componentJointIndex: " .. componentJointIndex)
				value:addCompareParameters("componentJoint")

				return true
			end

			return false
		end, function (value)
			return value.componentJoint.rotMinLimit[1], value.componentJoint.rotMinLimit[2], value.componentJoint.rotMinLimit[3], value.componentJoint.rotLimit[1], value.componentJoint.rotLimit[2], value.componentJoint.rotLimit[3]
		end, function (value, minX, minY, minZ, maxX, maxY, maxZ)
			value.vehicle:setComponentJointRotLimit(value.componentJoint, 1, minX, maxX)
			value.vehicle:setComponentJointRotLimit(value.componentJoint, 2, minY, maxY)
			value.vehicle:setComponentJointRotLimit(value.componentJoint, 3, minZ, maxZ)
		end)
		self:registerAnimationValueType("transLimit", "", "", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
			value.startTransLimit = xmlFile:getValue(xmlKey .. "#startTransLimit", nil, true)
			value.startTransMinLimit = xmlFile:getValue(xmlKey .. "#startTransMinLimit", nil, true)
			value.startTransMaxLimit = xmlFile:getValue(xmlKey .. "#startTransMaxLimit", nil, true)

			if value.startTransLimit ~= nil then
				value.startTransMinLimit = {
					-value.startTransLimit[1],
					-value.startTransLimit[2],
					-value.startTransLimit[3]
				}
				value.startTransMaxLimit = {
					value.startTransLimit[1],
					value.startTransLimit[2],
					value.startTransLimit[3]
				}
			end

			value.endTransLimit = xmlFile:getValue(xmlKey .. "#endTransLimit", nil, true)
			value.endTransMinLimit = xmlFile:getValue(xmlKey .. "#endTransMinLimit", nil, true)
			value.endTransMaxLimit = xmlFile:getValue(xmlKey .. "#endTransMaxLimit", nil, true)

			if value.endTransLimit ~= nil then
				value.endTransMinLimit = {
					-value.endTransLimit[1],
					-value.endTransLimit[2],
					-value.endTransLimit[3]
				}
				value.endTransMaxLimit = {
					value.endTransLimit[1],
					value.endTransLimit[2],
					value.endTransLimit[3]
				}
			end

			local componentJointIndex = xmlFile:getValue(xmlKey .. "#componentJointIndex")

			if componentJointIndex ~= nil then
				if componentJointIndex >= 1 then
					value.componentJoint = value.vehicle.componentJoints[componentJointIndex]
				end

				if value.componentJoint == nil then
					Logging.xmlWarning(xmlFile, "Invalid componentJointIndex for animation part '%s'. Indexing starts with 1!", xmlKey)

					return false
				end
			end

			if value.endTransMinLimit ~= nil and value.endTransMaxLimit == nil or value.endTransMinLimit == nil and value.endTransMaxLimit ~= nil then
				Logging.xmlWarning(xmlFile, "Incomplete end trans limit for animation part '%s'.", xmlKey)

				return false
			end

			if value.componentJoint ~= nil and value.endTransMinLimit ~= nil and value.endTransMaxLimit ~= nil then
				if value.startTransMinLimit ~= nil and value.startTransMaxLimit ~= nil then
					value.startValue = {
						value.startTransMinLimit[1],
						value.startTransMinLimit[2],
						value.startTransMinLimit[3],
						value.startTransMaxLimit[1],
						value.startTransMaxLimit[2],
						value.startTransMaxLimit[3]
					}
				end

				if value.endTransMinLimit ~= nil and value.endTransMaxLimit ~= nil then
					value.endValue = {
						value.endTransMinLimit[1],
						value.endTransMinLimit[2],
						value.endTransMinLimit[3],
						value.endTransMaxLimit[1],
						value.endTransMaxLimit[2],
						value.endTransMaxLimit[3]
					}
				end

				if value.endValue == nil then
					Logging.xmlWarning(xmlFile, "Missing end trans limit for animation part '%s'.", xmlKey)

					return false
				end

				value.endName = "transLimit"

				value:setWarningInformation("componentJointIndex: " .. componentJointIndex)
				value:addCompareParameters("componentJoint")

				return true
			end

			return false
		end, function (value)
			return value.componentJoint.transMinLimit[1], value.componentJoint.transMinLimit[2], value.componentJoint.transMinLimit[3], value.componentJoint.transLimit[1], value.componentJoint.transLimit[2], value.componentJoint.transLimit[3]
		end, function (value, minX, minY, minZ, maxX, maxY, maxZ)
			value.vehicle:setComponentJointTransLimit(value.componentJoint, 1, minX, maxX)
			value.vehicle:setComponentJointTransLimit(value.componentJoint, 2, minY, maxY)
			value.vehicle:setComponentJointTransLimit(value.componentJoint, 3, minZ, maxZ)
		end)
		self:registerAnimationValueType("componentMass", "startMass", "endMass", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
			local componentIndex = xmlFile:getValue(xmlKey .. "#componentIndex")

			if componentIndex ~= nil then
				if componentIndex >= 1 then
					value.component = value.vehicle.components[componentIndex]
				end

				if value.component == nil then
					Logging.xmlWarning(xmlFile, "Invalid component for animation part '%s'. Indexing starts with 1!", xmlKey)

					return false
				end
			end

			if value.component ~= nil then
				value:setWarningInformation("componentIndex: " .. componentIndex)
				value:addCompareParameters("component")

				return true
			end

			return false
		end, function (value)
			return getMass(value.component.node) * 1000
		end, function (value, mass)
			setMass(value.component.node, mass * 0.001)
		end)
		self:registerAnimationValueType("centerOfMass", "startCenterOfMass", "endCenterOfMass", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
			local componentIndex = xmlFile:getValue(xmlKey .. "#componentIndex")

			if componentIndex ~= nil then
				if componentIndex >= 1 then
					value.component = value.vehicle.components[componentIndex]
				end

				if value.component == nil then
					Logging.xmlWarning(xmlFile, "Invalid component for animation part '%s'. Indexing starts with 1!", xmlKey)

					return false
				end
			end

			if value.component ~= nil then
				value:setWarningInformation("componentIndex: " .. componentIndex)
				value:addCompareParameters("component")

				return true
			end

			return false
		end, function (value)
			return getCenterOfMass(value.component.node)
		end, function (value, x, y, z)
			setCenterOfMass(value.component.node, x, y, z)
		end)
		self:registerAnimationValueType("frictionVelocity", "startFrictionVelocity", "endFrictionVelocity", false, AnimationValueFloat, loadNodeFunction, function (value)
			return value.lastFrictionVelocity or 0
		end, function (value, velocity)
			setFrictionVelocity(value.node, velocity)

			value.lastFrictionVelocity = velocity

			if value.origTransX == nil then
				value.origTransX, value.origTransY, value.origTransZ = getTranslation(value.node)
			end

			setTranslation(value.node, value.origTransX + math.random() * 0.001, value.origTransY, value.origTransZ)
		end)
	end

	self:registerAnimationValueType("spline", "startSplinePos", "endSplinePos", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.node = xmlFile:getValue(xmlKey .. "#node", nil, value.part.components, value.part.i3dMappings)
		value.spline = xmlFile:getValue(xmlKey .. "#spline", nil, value.part.components, value.part.i3dMappings)

		if value.node ~= nil and value.spline ~= nil then
			value:setWarningInformation("node:" .. getName(value.node) .. " with spline: " .. getName(value.spline))
			value:addCompareParameters("node", "spline")

			return true
		end

		return false
	end, function (value)
		if value.lastSplineTime ~= nil then
			return value.lastSplineTime
		end

		local startTime = value.startValue or value.endValue

		if value.animation.currentSpeed < 0 then
			startTime = value.endValue or value.startValue
		end

		return startTime[1]
	end, function (value, splineTime)
		local x, y, z = getSplinePosition(value.spline, splineTime % 1)
		x, y, z = worldToLocal(getParent(value.node), x, y, z)

		setTranslation(value.node, x, y, z)

		value.lastSplineTime = splineTime

		for _, part2 in ipairs(value.animation.parts) do
			for index = 1, #part2.animationValues do
				local value2 = part2.animationValues[index]

				if value2.node == value.node and value2.name == value.name then
					value2.lastSplineTime = splineTime
				end
			end
		end
	end)
end
