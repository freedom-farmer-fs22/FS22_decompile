source("dataS/scripts/vehicles/specializations/events/SetTurnedOnEvent.lua")

TurnOnVehicle = {
	TURNED_ON_ANIMATION_XML_PATH = "vehicle.turnOnVehicle.turnedOnAnimation(?)",
	prerequisitesPresent = function (specializations)
		return true
	end
}

function TurnOnVehicle.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("TurnOnVehicle")
	schema:register(XMLValueType.STRING, "vehicle.turnOnVehicle#toggleButton", "Input action name", "IMPLEMENT_EXTRA")
	schema:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOffText", "Turn off text", "action_turnOffOBJECT")
	schema:register(XMLValueType.L10N_STRING, "vehicle.turnOnVehicle#turnOnText", "Turn on text", "action_turnOnOBJECT")
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#isAlwaysTurnedOn", "Always turned on", false)
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnedOnByAttacherVehicle", "Turned on by attacher vehicle", false)
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffIfNotAllowed", "Turn off if not allowed", false)
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#turnOffOnDeactivate", "Turn off if the vehicle is deactivated", true)
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#aiRequiresTurnOn", "AI requires turned on vehicle", true)
	schema:register(XMLValueType.BOOL, "vehicle.turnOnVehicle#requiresTurnOn", "(Mobile only) Vehicle requires turn on", true)
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.turnOnVehicle.animationNodes")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "start(?)")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "stop(?)")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.turnOnVehicle.sounds", "work(?)")
	schema:register(XMLValueType.STRING, "vehicle.turnOnVehicle.turnedAnimation#name", "Turned animation name (Animation played while activating and deactivating)")
	schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", "Turn on speed scale", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", "Turn off speed scale", "Inversed turnOnSpeedScale")
	schema:register(XMLValueType.STRING, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#name", "Turned on animation name (Animation played while turn on)")
	schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOnFadeTime", "Turn on fade time", 1)
	schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#turnOffFadeTime", "Turn off fade time", 1)
	schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.INT, "vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(?)#index", "Activateable fill unit index")
	schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
	schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#canBeTurnedOn", "Attacher joint can turn on implement", true)
	schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
	schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#needsSetIsTurnedOn", "Work area needs turned on vehicle to work", true)
	schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsTurnOn", "Needs turned on vehicle", false)
	schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#turnOffInTrigger", "Turn vehicle off when triggered", false)
	schema:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. "#needsActivation", "Needs activation", false)
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#needsSetIsTurnedOn", "Vehicle needs to be turned on to activate discharge node", false)
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#turnOnActivateNode", "Discharge node is set active when vehicle is turned on", false)
	schema:register(XMLValueType.FLOAT, BunkerSiloCompacter.XML_PATH .. "#turnedOnCompactingScale", "Compacting scale which is used while vehicle is turned on", "normal scale")
	schema:setXMLSpecializationType()
end

function TurnOnVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onTurnedOn")
	SpecializationUtil.registerEvent(vehicleType, "onTurnedOff")
end

function TurnOnVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsTurnedOn", TurnOnVehicle.setIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOn", TurnOnVehicle.getIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOn", TurnOnVehicle.getCanBeTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOnAll", TurnOnVehicle.getCanBeTurnedOnAll)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleTurnedOn", TurnOnVehicle.getCanToggleTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getTurnedOnNotAllowedWarning", TurnOnVehicle.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOn", TurnOnVehicle.getAIRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresTurnOn", TurnOnVehicle.getRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", TurnOnVehicle.getAIRequiresTurnOffOnHeadland)
	SpecializationUtil.registerFunction(vehicleType, "loadTurnedOnAnimationFromXML", TurnOnVehicle.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOnAnimationActive", TurnOnVehicle.getIsTurnedOnAnimationActive)
end

function TurnOnVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", TurnOnVehicle.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", TurnOnVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TurnOnVehicle.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", TurnOnVehicle.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", TurnOnVehicle.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", TurnOnVehicle.getAlarmTriggerIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", TurnOnVehicle.loadAlarmTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFillUnitActive", TurnOnVehicle.getIsFillUnitActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", TurnOnVehicle.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", TurnOnVehicle.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSeedChangeAllowed", TurnOnVehicle.getIsSeedChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TurnOnVehicle.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", TurnOnVehicle.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", TurnOnVehicle.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", TurnOnVehicle.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBunkerSiloCompactorFromXML", TurnOnVehicle.loadBunkerSiloCompactorFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBunkerSiloCompacterScale", TurnOnVehicle.getBunkerSiloCompacterScale)
end

function TurnOnVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onAlarmTriggerChanged", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", TurnOnVehicle)
end

function TurnOnVehicle:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffText", "vehicle.turnOnVehicle#turnOffText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnText", "vehicle.turnOnVehicle#turnOnText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#needsSelection")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#isAlwaysTurnedOn", "vehicle.turnOnVehicle#isAlwaysTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#toggleButton", "vehicle.turnOnVehicle#toggleButton")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#animationName", "vehicle.turnOnVehicle.turnedAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOnSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnOnSettings#turnOffSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.animationNodes.animationNode", "turnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#turnOffOnFold", "vehicle.turnOnVehicle#turnOffIfNotAllowed")

	local spec = self.spec_turnOnVehicle
	local turnOnButtonStr = self.xmlFile:getValue("vehicle.turnOnVehicle#toggleButton")

	if turnOnButtonStr ~= nil then
		spec.toggleTurnOnInputBinding = InputAction[turnOnButtonStr]
	end

	spec.toggleTurnOnInputBinding = Utils.getNoNil(spec.toggleTurnOnInputBinding, InputAction.IMPLEMENT_EXTRA)
	spec.turnOffText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffText", "action_turnOffOBJECT", self.customEnvironment), self.typeDesc)
	spec.turnOnText = string.format(self.xmlFile:getValue("vehicle.turnOnVehicle#turnOnText", "action_turnOnOBJECT", self.customEnvironment), self.typeDesc)
	spec.isTurnedOn = false
	spec.isAlwaysTurnedOn = self.xmlFile:getValue("vehicle.turnOnVehicle#isAlwaysTurnedOn", false)
	spec.turnedOnByAttacherVehicle = self.xmlFile:getValue("vehicle.turnOnVehicle#turnedOnByAttacherVehicle", false)
	spec.turnOffIfNotAllowed = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffIfNotAllowed", true)
	spec.turnOffOnDeactivate = self.xmlFile:getValue("vehicle.turnOnVehicle#turnOffOnDeactivate", not GS_IS_MOBILE_VERSION)
	spec.aiRequiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#aiRequiresTurnOn", true)
	spec.requiresTurnOn = self.xmlFile:getValue("vehicle.turnOnVehicle#requiresTurnOn", true)

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.turnOnVehicle.animationNodes", self.components, self, self.i3dMappings)
		local allowsAnimations = SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations)

		if allowsAnimations then
			local turnOnAnimation = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#name")

			if turnOnAnimation ~= nil then
				spec.turnOnAnimation = {
					name = turnOnAnimation,
					turnOnSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale", 1)
				}
				spec.turnOnAnimation.turnOffSpeedScale = self.xmlFile:getValue("vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale", -spec.turnOnAnimation.turnOnSpeedScale)
			end
		end

		spec.turnedOnAnimations = {}

		if allowsAnimations then
			self.xmlFile:iterate("vehicle.turnOnVehicle.turnedOnAnimation", function (index, key)
				local entry = {}

				if self:loadTurnedOnAnimationFromXML(self.xmlFile, key, entry) then
					table.insert(spec.turnedOnAnimations, entry)
				end
			end)
		end

		spec.activatableFillUnits = {}
		local i = 0

		while true do
			local key = string.format("vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local fillUnitIndex = self.xmlFile:getValue(key .. "#index")

			if fillUnitIndex ~= nil then
				spec.activatableFillUnits[fillUnitIndex] = true
			end

			i = i + 1
		end

		spec.samples = {
			start = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", TurnOnVehicle)
		SpecializationUtil.removeEventListener(self, "onUpdate", TurnOnVehicle)
	end
end

function TurnOnVehicle:onDelete()
	local spec = self.spec_turnOnVehicle

	if spec.samples ~= nil then
		g_soundManager:deleteSamples(spec.samples.start)
		g_soundManager:deleteSamples(spec.samples.stop)
		g_soundManager:deleteSamples(spec.samples.work)
	end

	g_animationManager:deleteAnimations(spec.animationNodes)
end

function TurnOnVehicle:onReadStream(streamId, connection)
	local turnedOn = streamReadBool(streamId)

	self:setIsTurnedOn(turnedOn, true)
end

function TurnOnVehicle:onWriteStream(streamId, connection)
	local spec = self.spec_turnOnVehicle

	streamWriteBool(streamId, spec.isTurnedOn)
end

function TurnOnVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_turnOnVehicle

	for i = 1, #spec.turnedOnAnimations do
		local turnedOnAnimation = spec.turnedOnAnimations[i]
		local isTurnedOn = self:getIsTurnedOnAnimationActive(turnedOnAnimation)

		if turnedOnAnimation.isTurnedOn ~= isTurnedOn then
			if isTurnedOn then
				turnedOnAnimation.speedDirection = 1

				self:playAnimation(turnedOnAnimation.name, math.max(turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale, 0.001), self:getAnimationTime(turnedOnAnimation.name), true)
			else
				turnedOnAnimation.speedDirection = -1
			end

			turnedOnAnimation.isTurnedOn = isTurnedOn
		end

		if turnedOnAnimation.speedDirection ~= 0 then
			local duration = turnedOnAnimation.turnOnFadeTime

			if turnedOnAnimation.speedDirection == -1 then
				duration = turnedOnAnimation.turnOffFadeTime
			end

			turnedOnAnimation.currentSpeed = MathUtil.clamp(turnedOnAnimation.currentSpeed + turnedOnAnimation.speedDirection * dt / duration, 0, 1)

			self:setAnimationSpeed(turnedOnAnimation.name, turnedOnAnimation.currentSpeed * turnedOnAnimation.speedScale)

			if turnedOnAnimation.speedDirection == -1 and turnedOnAnimation.currentSpeed == 0 then
				self:stopAnimation(turnedOnAnimation.name, true)
			end

			if turnedOnAnimation.currentSpeed == 1 or turnedOnAnimation.currentSpeed == 0 then
				turnedOnAnimation.speedDirection = 0
			end
		end
	end
end

function TurnOnVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_turnOnVehicle

	if self.isClient and not spec.isAlwaysTurnedOn and not spec.turnedOnByAttacherVehicle then
		TurnOnVehicle.updateActionEvents(self)
	end

	if self.isServer and spec.turnOffIfNotAllowed and not self:getCanBeTurnedOn() then
		if self:getIsTurnedOn() then
			self:setIsTurnedOn(false)
		elseif self.getAttacherVehicle ~= nil then
			local attacherVehicle = self:getAttacherVehicle()

			if attacherVehicle ~= nil and attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
				attacherVehicle:setIsTurnedOn(false)
			end
		end
	end
end

function TurnOnVehicle:setIsTurnedOn(isTurnedOn, noEventSend)
	local spec = self.spec_turnOnVehicle

	if isTurnedOn ~= spec.isTurnedOn then
		SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)

		spec.isTurnedOn = isTurnedOn
		local actionEvent = spec.actionEvents[InputAction.TOGGLE_COVER]
		local text = nil

		if spec.isTurnedOn then
			SpecializationUtil.raiseEvent(self, "onTurnedOn")

			text = string.format(spec.turnOffText, self.typeDesc)
		else
			SpecializationUtil.raiseEvent(self, "onTurnedOff")

			text = string.format(spec.turnOnText, self.typeDesc)
		end

		if actionEvent ~= nil then
			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function TurnOnVehicle:onTurnedOn()
	local spec = self.spec_turnOnVehicle

	if self.isClient then
		if spec.turnOnAnimation ~= nil then
			self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOnSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
		end

		g_soundManager:stopSamples(spec.samples.start)
		g_soundManager:stopSamples(spec.samples.work)
		g_soundManager:stopSamples(spec.samples.stop)
		g_soundManager:playSamples(spec.samples.start)

		for i = 1, #spec.samples.work do
			g_soundManager:playSample(spec.samples.work[i], 0, spec.samples.start[i])
		end

		g_animationManager:startAnimations(spec.animationNodes)
	end

	if spec.activateableDischargeNode ~= nil and spec.activateableDischargeNode.index ~= nil then
		spec.activateableDischargeNodePrev = self:getCurrentDischargeNode()

		self:setCurrentDischargeNodeIndex(spec.activateableDischargeNode.index)
	end
end

function TurnOnVehicle:onTurnedOff()
	local spec = self.spec_turnOnVehicle

	if self.isClient then
		if spec.turnOnAnimation ~= nil then
			self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOffSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
		end

		g_soundManager:stopSamples(spec.samples.start)
		g_soundManager:stopSamples(spec.samples.work)
		g_soundManager:stopSamples(spec.samples.stop)
		g_soundManager:playSamples(spec.samples.stop)
		g_animationManager:stopAnimations(spec.animationNodes)
	end

	if spec.activateableDischargeNodePrev ~= nil and spec.activateableDischargeNodePrev.index ~= nil then
		self:setCurrentDischargeNodeIndex(spec.activateableDischargeNodePrev.index)

		spec.activateableDischargeNodePrev = nil
	end
end

function TurnOnVehicle:getIsTurnedOn()
	local spec = self.spec_turnOnVehicle

	return spec.isAlwaysTurnedOn or spec.isTurnedOn
end

function TurnOnVehicle:getCanBeTurnedOn()
	local spec = self.spec_turnOnVehicle

	if spec.isAlwaysTurnedOn then
		return false
	end

	if self.getInputAttacherJoint ~= nil then
		local inputAttacherJoint = self:getInputAttacherJoint()

		if inputAttacherJoint ~= nil and inputAttacherJoint.canBeTurnedOn ~= nil and not inputAttacherJoint.canBeTurnedOn then
			return false
		end
	end

	if not self:getIsPowered() then
		return false
	end

	return true
end

function TurnOnVehicle:getCanBeTurnedOnAll()
	local vehicles = self.rootVehicle:getChildVehicles()

	for i = 1, #vehicles do
		local vehicle = vehicles[i]

		if vehicle.getCanBeTurnedOn ~= nil and not vehicle:getCanBeTurnedOn() then
			return false
		end
	end

	return true
end

function TurnOnVehicle:getCanToggleTurnedOn()
	local spec = self.spec_turnOnVehicle

	if spec.isAlwaysTurnedOn then
		return false
	end

	if spec.turnedOnByAttacherVehicle then
		return false
	end

	return true
end

function TurnOnVehicle:getTurnedOnNotAllowedWarning()
	return nil
end

function TurnOnVehicle:getAIRequiresTurnOn()
	return self.spec_turnOnVehicle.aiRequiresTurnOn
end

function TurnOnVehicle:getRequiresTurnOn()
	return self.spec_turnOnVehicle.requiresTurnOn
end

function TurnOnVehicle:getAIRequiresTurnOffOnHeadland()
	return false
end

function TurnOnVehicle:loadTurnedOnAnimationFromXML(xmlFile, key, turnedOnAnimation)
	local name = self.xmlFile:getValue(key .. "#name")

	if name == nil then
		Logging.xmlWarning(xmlFile, "Missing animation name in '%s'", key)

		return false
	end

	turnedOnAnimation.name = name
	turnedOnAnimation.turnOnFadeTime = self.xmlFile:getValue(key .. "#turnOnFadeTime", 1) * 1000
	turnedOnAnimation.turnOffFadeTime = self.xmlFile:getValue(key .. "#turnOffFadeTime", 1) * 1000
	turnedOnAnimation.speedScale = self.xmlFile:getValue(key .. "#speedScale", 1)
	turnedOnAnimation.speedDirection = 0
	turnedOnAnimation.currentSpeed = 0
	turnedOnAnimation.isTurnedOn = false

	return true
end

function TurnOnVehicle:getIsTurnedOnAnimationActive(turnedOnAnimation)
	if not self:getIsTurnedOn() then
		return false
	end

	return true
end

function TurnOnVehicle:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end

	inputAttacherJoint.canBeTurnedOn = xmlFile:getValue(key .. "#canBeTurnedOn", true)

	return true
end

function TurnOnVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)
	workArea.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", true)

	return retValue
end

function TurnOnVehicle:getIsWorkAreaActive(superFunc, workArea)
	if not self:getIsTurnedOn() and workArea.needsSetIsTurnedOn then
		return false
	end

	return superFunc(self, workArea)
end

function TurnOnVehicle:getCanAIImplementContinueWork(superFunc)
	local canContinue, stopAI, stopReason = superFunc(self)

	if not canContinue then
		return false, stopAI, stopReason
	end

	local ret = false

	if self:getCanBeTurnedOn() and self:getIsTurnedOn() then
		ret = true
	end

	if not self:getAIRequiresTurnOn() then
		ret = true
	end

	if not self:getIsAIImplementInLine() then
		ret = true
	end

	return ret
end

function TurnOnVehicle:getIsOperating(superFunc)
	if self:getIsTurnedOn() then
		return true
	end

	return superFunc(self)
end

function TurnOnVehicle:getAlarmTriggerIsActive(superFunc, alarmTrigger)
	local ret = superFunc(self, alarmTrigger)

	if alarmTrigger.needsTurnOn and not self:getIsTurnedOn() then
		ret = false
	end

	return ret
end

function TurnOnVehicle:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
	local ret = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.needsTurnOn = xmlFile:getValue(key .. "#needsTurnOn", false)
	alarmTrigger.turnOffInTrigger = xmlFile:getValue(key .. "#turnOffInTrigger", false)

	return ret
end

function TurnOnVehicle:getIsFillUnitActive(superFunc, fillUnitIndex)
	local spec = self.spec_turnOnVehicle

	if spec.activatableFillUnits[fillUnitIndex] == true and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, fillUnitIndex)
end

function TurnOnVehicle:loadShovelNode(superFunc, xmlFile, key, shovelNode)
	superFunc(self, xmlFile, key, shovelNode)

	shovelNode.needsActiveVehicle = xmlFile:getValue(key .. "#needsActivation", false)

	return true
end

function TurnOnVehicle:getShovelNodeIsActive(superFunc, shovelNode)
	if shovelNode.needsActiveVehicle and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, shovelNode)
end

function TurnOnVehicle:getIsSeedChangeAllowed(superFunc)
	return superFunc(self) and not self:getIsTurnedOn()
end

function TurnOnVehicle:getCanBeSelected(superFunc)
	return true
end

function TurnOnVehicle:getIsPowerTakeOffActive(superFunc)
	return self:getIsTurnedOn() or superFunc(self)
end

function TurnOnVehicle:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
	entry.turnOnActivateNode = xmlFile:getValue(key .. "#turnOnActivateNode", false)

	if entry.turnOnActivateNode then
		local spec = self.spec_turnOnVehicle
		spec.activateableDischargeNode = entry
	end

	return true
end

function TurnOnVehicle:getIsDischargeNodeActive(superFunc, dischargeNode)
	if dischargeNode.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, dischargeNode)
end

function TurnOnVehicle:loadBunkerSiloCompactorFromXML(superFunc, xmlFile, key)
	superFunc(self, xmlFile, key)

	local spec = self.spec_bunkerSiloCompacter
	spec.turnedOnCompactingScale = xmlFile:getValue(key .. "#turnedOnCompactingScale")
end

function TurnOnVehicle:getBunkerSiloCompacterScale(superFunc)
	local spec = self.spec_bunkerSiloCompacter

	if spec.turnedOnCompactingScale ~= nil and self:getIsTurnedOn() then
		return spec.turnedOnCompactingScale
	end

	return superFunc(self)
end

function TurnOnVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_turnOnVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and self:getCanToggleTurnedOn() then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.toggleTurnOnInputBinding, self, TurnOnVehicle.actionEventTurnOn, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			TurnOnVehicle.updateActionEvents(self)

			_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TURN_ON_ALL_IMPLEMENTS, self, TurnOnVehicle.actionEventTurnOnAll, false, true, false, true, nil)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
		end
	end
end

function TurnOnVehicle:onAlarmTriggerChanged(alarmTrigger, state)
	if state and alarmTrigger.turnOffInTrigger then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onSetBroken()
	self:setIsTurnedOn(false, true)
end

function TurnOnVehicle:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_MOTOR_TURN_OFF and not self:getCanBeTurnedOn() then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onDeactivate()
	local spec = self.spec_turnOnVehicle

	if spec.turnOffOnDeactivate then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_turnOnVehicle

	if spec.turnedOnByAttacherVehicle and attacherVehicle.getIsTurnedOn ~= nil then
		self:setIsTurnedOn(attacherVehicle:getIsTurnedOn(), true)
	end
end

function TurnOnVehicle:onPreDetach(attacherVehicle, implement)
	self:setIsTurnedOn(false, true)
end

function TurnOnVehicle:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_turnOnVehicle
	local actionController = rootVehicle.actionController

	if actionController ~= nil then
		if spec.controlledAction ~= nil then
			spec.controlledAction:updateParent(actionController)

			return
		end

		spec.controlledAction = actionController:registerAction("turnOn", spec.toggleTurnOnInputBinding, 1)

		spec.controlledAction:setCallback(self, TurnOnVehicle.actionControllerTurnOnEvent)
		spec.controlledAction:setFinishedFunctions(self, self.getIsTurnedOn, true, false)

		if self:getRequiresTurnOn() then
			spec.controlledAction:setDeactivateFunction(self, self.getCanBeTurnedOn, true)
		end

		spec.controlledAction:setIsSaved(true)

		if self:getAIRequiresTurnOn() then
			spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerStart", 1, true)
			spec.controlledAction:addAIEventListener(self, "onAIImplementStart", 1, true)
			spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1, true)
			spec.controlledAction:addAIEventListener(self, "onAIImplementContinue", 1)
			spec.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
			spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)

			if self:getAIRequiresTurnOffOnHeadland() then
				spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
			end

			spec.controlledAction:addAIEventListener(self, "onAIImplementBlock", -1)
			spec.controlledAction:addAIEventListener(self, "onAIImplementPrepare", -1)
		end
	elseif spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function TurnOnVehicle:actionControllerTurnOnEvent(direction)
	if direction > 0 then
		if self:getCanBeTurnedOn() then
			self:setIsTurnedOn(true)

			return true
		else
			return false
		end
	else
		self:setIsTurnedOn(false)

		return not self:getIsTurnedOn()
	end
end

function TurnOnVehicle:actionEventTurnOn(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleTurnedOn() and self:getCanBeTurnedOn() then
		self:setIsTurnedOn(not self:getIsTurnedOn())
	elseif not self:getIsTurnedOn() then
		local warning = self:getTurnedOnNotAllowedWarning()

		if warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	end
end

function TurnOnVehicle:actionEventTurnOnAll(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleTurnedOn() then
		local canBeTurnedOn, warning = self:getCanBeTurnedOnAll()

		if canBeTurnedOn then
			local vehicles = self.rootVehicle:getChildVehicles()

			for i = 1, #vehicles do
				local vehicle = vehicles[i]

				if vehicle.setIsTurnedOn ~= nil then
					vehicle:setIsTurnedOn(not vehicle:getIsTurnedOn())
				end
			end
		elseif not self:getIsTurnedOn() and warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	end
end

function TurnOnVehicle:updateActionEvents()
	local spec = self.spec_turnOnVehicle
	local actionEvent = spec.actionEvents[spec.toggleTurnOnInputBinding]

	if actionEvent ~= nil then
		local state = self:getCanToggleTurnedOn()

		if state then
			local text = nil

			if self:getIsTurnedOn() then
				text = spec.turnOffText
			else
				text = spec.turnOnText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)
	end
end
