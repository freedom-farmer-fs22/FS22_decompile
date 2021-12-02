source("dataS/scripts/vehicles/specializations/events/AIJobVehicleStateEvent.lua")

AIJobVehicle = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("AIJobVehicle")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.steeringNode#node", "Steering node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ai.reverserNode#node", "Reverser node")
		schema:register(XMLValueType.FLOAT, "vehicle.ai.steeringSpeed", "Speed of steering", 1)
		schema:register(XMLValueType.BOOL, "vehicle.ai#supportsAIJobs", "If true vehicle supports ai jobs", true)
		schema:setXMLSpecializationType()
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onAIJobStarted")
		SpecializationUtil.registerEvent(vehicleType, "onAIJobFinished")
	end
}

function AIJobVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getShowAIToggleActionEvent", AIJobVehicle.getShowAIToggleActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "stopCurrentAIJob", AIJobVehicle.stopCurrentAIJob)
	SpecializationUtil.registerFunction(vehicleType, "skipCurrentTask", AIJobVehicle.skipCurrentTask)
	SpecializationUtil.registerFunction(vehicleType, "aiJobStarted", AIJobVehicle.aiJobStarted)
	SpecializationUtil.registerFunction(vehicleType, "aiJobFinished", AIJobVehicle.aiJobFinished)
	SpecializationUtil.registerFunction(vehicleType, "toggleAIVehicle", AIJobVehicle.toggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAIVehicle", AIJobVehicle.getCanToggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartAIVehicle", AIJobVehicle.getCanStartAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotBlinking", AIJobVehicle.setAIMapHotspotBlinking)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentHelper", AIJobVehicle.getCurrentHelper)
	SpecializationUtil.registerFunction(vehicleType, "aiBlock", AIJobVehicle.aiBlock)
	SpecializationUtil.registerFunction(vehicleType, "aiContinue", AIJobVehicle.aiContinue)
	SpecializationUtil.registerFunction(vehicleType, "getAIDirectionNode", AIJobVehicle.getAIDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAISteeringNode", AIJobVehicle.getAISteeringNode)
	SpecializationUtil.registerFunction(vehicleType, "getAIReverserNode", AIJobVehicle.getAIReverserNode)
	SpecializationUtil.registerFunction(vehicleType, "getAISteeringSpeed", AIJobVehicle.getAISteeringSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getAIJobFarmId", AIJobVehicle.getAIJobFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getStartableAIJob", AIJobVehicle.getStartableAIJob)
	SpecializationUtil.registerFunction(vehicleType, "getHasStartableAIJob", AIJobVehicle.getHasStartableAIJob)
	SpecializationUtil.registerFunction(vehicleType, "getStartAIJobText", AIJobVehicle.getStartAIJobText)
	SpecializationUtil.registerFunction(vehicleType, "getJob", AIJobVehicle.getJob)
	SpecializationUtil.registerFunction(vehicleType, "getLastJob", AIJobVehicle.getLastJob)
end

function AIJobVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", AIJobVehicle.getIsVehicleControlledByPlayer)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", AIJobVehicle.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive", AIJobVehicle.getIsAIActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIJobVehicle.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", AIJobVehicle.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", AIJobVehicle.getStopMotorOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDisableVehicleCharacterOnLeave", AIJobVehicle.getDisableVehicleCharacterOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", AIJobVehicle.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", AIJobVehicle.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", AIJobVehicle.getIsMapHotspotVisible)
end

function AIJobVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIJobVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIJobVehicle)
end

function AIJobVehicle:onLoad(savegame)
	local spec = self.spec_aiJobVehicle
	spec.actionEvents = {}
	spec.job = nil
	spec.lastJob = nil
	spec.startedFarmId = nil
	spec.aiSteeringSpeed = self.xmlFile:getValue("vehicle.ai.steeringSpeed", 1) * 0.001
	spec.steeringNode = self.xmlFile:getValue("vehicle.ai.steeringNode#node", nil, self.components, self.i3dMappings)
	spec.reverserNode = self.xmlFile:getValue("vehicle.ai.reverserNode#node", nil, self.components, self.i3dMappings)
	spec.supportsAIJobs = self.xmlFile:getValue("vehicle.ai#supportsAIJobs", true)
	spec.texts = {
		dismissEmployee = g_i18n:getText("action_dismissEmployee"),
		openHelperMenu = g_i18n:getText("action_openHelperMenu"),
		hireEmployee = g_i18n:getText("action_hireEmployee")
	}

	if savegame ~= nil then
		local aiJobTypeManager = g_currentMission.aiJobTypeManager
		local savegameKey = savegame.key .. ".aiJobVehicle.lastJob"
		local jobTypeName = savegame.xmlFile:getString(savegameKey .. "#type")
		local jobTypeIndex = aiJobTypeManager:getJobTypeIndexByName(jobTypeName)

		if jobTypeIndex ~= nil then
			local job = aiJobTypeManager:createJob(jobTypeIndex)

			if job ~= nil and job.loadFromXMLFile ~= nil then
				job:loadFromXMLFile(savegame.xmlFile, savegameKey)

				spec.lastJob = job
			end
		end
	end
end

function AIJobVehicle:onDelete()
	local spec = self.spec_aiJobVehicle

	if spec.job ~= nil then
		self:stopCurrentAIJob()
	end

	if spec.mapAIHotspot ~= nil then
		spec.mapAIHotspot:delete()

		spec.mapAIHotspot = nil
	end
end

function AIJobVehicle:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local jobId = streamReadInt32(streamId)
		local startedFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local helperIndex = streamReadUInt8(streamId)
		local job = g_currentMission.aiSystem:getJobById(jobId)

		self:aiJobStarted(job, helperIndex, startedFarmId)
	elseif streamReadBool(streamId) then
		local jobTypeIndex = streamReadInt32(streamId)
		local spec = self.spec_aiJobVehicle
		spec.lastJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)

		spec.lastJob:readStream(streamId, connection)
	end
end

function AIJobVehicle:onWriteStream(streamId, connection)
	local spec = self.spec_aiJobVehicle

	if streamWriteBool(streamId, spec.job ~= nil) then
		streamWriteInt32(streamId, spec.job.jobId)
		streamWriteUIntN(streamId, spec.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteUInt8(streamId, spec.currentHelper.index)
	elseif streamWriteBool(streamId, spec.lastJob ~= nil) then
		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(spec.lastJob)

		streamWriteInt32(streamId, jobTypeIndex)
		spec.lastJob:writeStream(streamId, connection)
	end
end

function AIJobVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsAIActive() then
		self:raiseActive()
	end
end

function AIJobVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	AIJobVehicle.updateActionEvents(self)
end

function AIJobVehicle:getShowAIToggleActionEvent()
	if self:getAIDirectionNode() == nil then
		return false
	end

	if g_currentMission.disableAIVehicle then
		return false
	end

	if not g_currentMission:getHasPlayerPermission("hireAssistant") then
		return false
	end

	return true
end

function AIJobVehicle:stopCurrentAIJob(aiMessage)
	local spec = self.spec_aiJobVehicle

	if spec.job ~= nil then
		g_currentMission.aiSystem:stopJob(spec.job, aiMessage)
	end
end

function AIJobVehicle:skipCurrentTask()
	local spec = self.spec_aiJobVehicle

	if spec.job ~= nil then
		g_currentMission.aiSystem:skipCurrentTask(spec.job)
	end
end

function AIJobVehicle:aiJobStarted(job, helperIndex, startedFarmId)
	local spec = self.spec_aiJobVehicle

	if not self:getIsAIActive() then
		if self.isServer then
			g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, job, helperIndex, startedFarmId))
			g_currentMission.aiSystem:addJobVehicle(self)
		end

		spec.job = job
		spec.lastJob = job
		spec.startedFarmId = startedFarmId
		spec.currentHelperIndex = helperIndex
		spec.currentHelper = g_helperManager:getHelperByIndex(helperIndex)

		g_helperManager:useHelper(spec.currentHelper)

		if self.isServer then
			g_farmManager:updateFarmStats(startedFarmId, "workersHired", 1)
		end

		if self.setRandomVehicleCharacter ~= nil then
			self:setRandomVehicleCharacter(spec.currentHelper)
		end

		if spec.mapAIHotspot == nil then
			spec.mapAIHotspot = AIHotspot.new()

			spec.mapAIHotspot:setVehicle(self)
		end

		spec.mapAIHotspot:setAIHelperName(spec.currentHelper.name)
		g_currentMission:addMapHotspot(spec.mapAIHotspot)
		SpecializationUtil.raiseEvent(self, "onAIJobStarted", job)
		self:requestActionEventUpdate()
		self:raiseActive()
	end

	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, true, self)
end

function AIJobVehicle:aiJobFinished()
	local spec = self.spec_aiJobVehicle

	if self:getIsAIActive() then
		if self.isServer then
			g_server:broadcastEvent(AIJobVehicleStateEvent.new(self, nil, , ))
			g_currentMission.aiSystem:removeJobVehicle(self)
		end

		g_helperManager:releaseHelper(spec.currentHelper)

		spec.currentHelperIndex = nil
		spec.currentHelper = nil

		if self.isServer then
			g_farmManager:updateFarmStats(spec.startedFarmId, "workersHired", -1)
		end

		if self.restoreVehicleCharacter ~= nil then
			self:restoreVehicleCharacter()
		end

		if spec.mapAIHotspot ~= nil then
			g_currentMission:removeMapHotspot(spec.mapAIHotspot)
		end

		SpecializationUtil.raiseEvent(self, "onAIJobFinished", spec.job)

		spec.job = nil

		self:requestActionEventUpdate()
	end

	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, false, self)
end

function AIJobVehicle:getIsVehicleControlledByPlayer(superFunc)
	if not superFunc(self) then
		return false
	end

	return self.spec_aiJobVehicle.job == nil
end

function AIJobVehicle:getIsInUse(superFunc, connection)
	if self:getIsAIActive() then
		return true
	end

	return superFunc(self, connection)
end

function AIJobVehicle:getIsActive(superFunc)
	if self:getIsAIActive() then
		return true
	end

	return superFunc(self)
end

function AIJobVehicle:getAIJobFarmId()
	return self.spec_aiJobVehicle.startedFarmId
end

function AIJobVehicle:getIsAIActive(superFunc)
	return superFunc(self) or self.spec_aiJobVehicle.job ~= nil
end

function AIJobVehicle:getStartableAIJob()
	return nil
end

function AIJobVehicle:getHasStartableAIJob()
	return false
end

function AIJobVehicle:getStartAIJobText()
	local spec = self.spec_aiJobVehicle
	local hasJob = self:getHasStartableAIJob()

	if hasJob then
		return spec.texts.hireEmployee
	end

	return spec.texts.openHelperMenu
end

function AIJobVehicle:getJob()
	return self.spec_aiJobVehicle.job
end

function AIJobVehicle:getLastJob()
	return self.spec_aiJobVehicle.lastJob
end

function AIJobVehicle:toggleAIVehicle()
	if self:getIsAIActive() then
		self:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	else
		local startableJob = self:getStartableAIJob()

		if startableJob ~= nil then
			g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(startableJob, self:getOwnerFarmId()))

			return
		end

		g_gui:showGui("InGameMenu")
		g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self)
	end
end

function AIJobVehicle:getCanToggleAIVehicle()
	return self:getCanStartAIVehicle() or self:getIsAIActive()
end

function AIJobVehicle:getCanStartAIVehicle()
	if g_currentMission.disableAIVehicle then
		return false
	end

	if not self.spec_aiJobVehicle.supportsAIJobs then
		return false
	end

	if self:getAIDirectionNode() == nil then
		return false
	end

	if g_currentMission.aiSystem:getAILimitedReached() then
		return false
	end

	if self:getIsAIActive() then
		return false
	end

	if self.isBroken then
		return false
	end

	return true
end

function AIJobVehicle:setAIMapHotspotBlinking(isBlinking)
	local spec = self.spec_aiJobVehicle

	if spec.mapAIHotspot ~= nil then
		spec.mapAIHotspot:setBlinking(isBlinking)
	end
end

function AIJobVehicle:onSetBroken()
	if self:getIsAIActive() then
		self:stopCurrentAIJob(AIMessageErrorVehicleBroken.new())
	end
end

function AIJobVehicle:getDeactivateOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIJobVehicle:getStopMotorOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIJobVehicle:getDisableVehicleCharacterOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIJobVehicle:getAllowTireTracks(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIJobVehicle:getCurrentHelper()
	return self.spec_aiJobVehicle.currentHelper
end

function AIJobVehicle:getFullName(superFunc)
	local name = superFunc(self)

	if self:getIsAIActive() then
		local currentHelper = self:getCurrentHelper()
		name = name .. " (" .. g_i18n:getText("ui_helper") .. " " .. currentHelper.name .. ")"
	end

	return name
end

function AIJobVehicle:aiBlock()
	if self.isClient and g_currentMission.player.farmId == self:getAIJobFarmId() then
		local currentHelper = self:getCurrentHelper()
		local text = string.format(g_i18n:getText("ai_messageErrorBlockedByObject"), currentHelper.name)

		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
	end
end

function AIJobVehicle:aiContinue()
end

function AIJobVehicle:getAIDirectionNode()
	return self.components[1].node
end

function AIJobVehicle:getAISteeringNode()
	return self.spec_aiJobVehicle.steeringNode or self:getAIDirectionNode()
end

function AIJobVehicle:getAIReverserNode()
	return self.spec_aiJobVehicle.reverserNode
end

function AIJobVehicle:getAISteeringSpeed()
	return self.spec_aiJobVehicle.aiSteeringSpeed
end

function AIJobVehicle:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_aiJobVehicle

	if spec.lastJob ~= nil then
		local jobTypeIndex = spec.lastJob.jobTypeIndex
		local jobType = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex)

		xmlFile:setString(key .. ".lastJob#type", jobType.name)
		spec.lastJob:saveToXMLFile(xmlFile, key .. ".lastJob", usedModNames)
	end
end

function AIJobVehicle:saveStatsToXMLFile(xmlFile, key)
	setXMLBool(xmlFile, key .. "#isAIActive", self:getIsAIActive())
end

function AIJobVehicle:getActiveFarm(superFunc)
	local starter = self:getAIJobFarmId()

	if starter ~= nil then
		return starter
	else
		return superFunc(self)
	end
end

function AIJobVehicle:getIsMapHotspotVisible(superFunc)
	if not superFunc(self) then
		return false
	end

	return not self:getIsAIActive()
end

function AIJobVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_aiJobVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if spec.supportsAIJobs and self:getIsActiveForInput(true, true) and (not g_isPresentationVersion or g_isPresentationVersionAIEnabled) then
			local _, eventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI, self, AIJobVehicle.actionEventToggleAIState, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
			AIJobVehicle.updateActionEvents(self)
		end
	end
end

function AIJobVehicle:actionEventToggleAIState(actionName, inputValue, callbackState, isAnalog)
	if g_currentMission:getHasPlayerPermission("hireAssistant") then
		self:toggleAIVehicle()
	end
end

function AIJobVehicle:updateActionEvents()
	local spec = self.spec_aiJobVehicle
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_AI]

	if actionEvent ~= nil and self.isActiveForInputIgnoreSelectionIgnoreAI then
		if self:getShowAIToggleActionEvent() then
			if self:getIsAIActive() then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.dismissEmployee)
			else
				local text = self:getStartAIJobText()

				g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
		else
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
		end
	end
end
