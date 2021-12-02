source("dataS/scripts/vehicles/specializations/events/HonkEvent.lua")

Honk = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Honk")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.honk", "sound")
		schema:setXMLSpecializationType()
	end
}

function Honk.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsHonkAvailable", Honk.getIsHonkAvailable)
	SpecializationUtil.registerFunction(vehicleType, "setHonkInput", Honk.setHonkInput)
	SpecializationUtil.registerFunction(vehicleType, "playHonk", Honk.playHonk)
end

function Honk.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Honk)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Honk)
end

function Honk:onLoad(savegame)
	local spec = self.spec_honk
	spec.inputPressed = false
	spec.isPlaying = false

	if self.isClient then
		spec.sample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.honk", "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdate", Honk)
	end
end

function Honk:onDelete()
	local spec = self.spec_honk

	g_soundManager:deleteSample(spec.sample)
end

function Honk:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and isActiveForInputIgnoreSelection then
		local spec = self.spec_honk

		if spec.inputPressed then
			if not g_soundManager:getIsSamplePlaying(spec.sample) then
				self:playHonk(true)
			end
		elseif spec.isPlaying then
			self:playHonk(false)
		end

		spec.inputPressed = false
	end
end

function Honk:onLeaveVehicle()
	self:playHonk(false, true)
end

function Honk:getIsHonkAvailable()
	return true
end

function Honk:setHonkInput()
	local spec = self.spec_honk
	spec.inputPressed = true
end

function Honk:playHonk(isPlaying, noEventSend)
	HonkEvent.sendEvent(self, isPlaying, noEventSend)

	local spec = self.spec_honk
	spec.isPlaying = isPlaying

	if spec.sample ~= nil then
		if isPlaying then
			if self:getIsActive() and self.isClient then
				g_soundManager:playSample(spec.sample)
			end
		else
			g_soundManager:stopSample(spec.sample)
		end
	end
end

function Honk:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_honk

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.sample ~= nil then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.HONK, self, Honk.actionEventHonk, false, true, true, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventActive(actionEventId, true)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_honk"))
		end
	end
end

function Honk:actionEventHonk(actionName, inputValue, callbackState, isAnalog)
	self:setHonkInput()
end
