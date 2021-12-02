SleepManager = {
	SLEEPING_TIME_SCALE = 5000,
	TIME_TO_ANSWER_REQUEST = 20000
}
local SleepManager_mt = Class(SleepManager, AbstractManager)

function SleepManager.new(customMt)
	local self = AbstractManager.new(customMt or SleepManager_mt)
	self.isSleeping = false
	self.wakeUpTime = 0
	self.previousCamera = nil
	self.previousInputContext = nil
	self.fallbackCamera = nil
	self.requestedSleep = false
	self.requestedTime = 0
	self.requestCounter = 0
	self.responseCounter = 0
	self.requestedTargetTime = 0

	return self
end

function SleepManager:unloadMapData()
	if self.fallbackCamera ~= nil then
		delete(self.fallbackCamera)

		self.fallbackCamera = nil
	end
end

function SleepManager:update(dt)
	if g_currentMission:getIsServer() and self.wakeUpTime < g_time and self.isSleeping then
		self:stopSleep()
	end

	if self.requestedSleep then
		if self.responseCounter == self.requestCounter then
			self:startSleep(self.requestedTargetTime)

			self.responseCounter = 0
			self.requestedSleep = false
		end

		if self.requestedTime + SleepManager.TIME_TO_ANSWER_REQUEST < g_time then
			self.responseCounter = 0
			self.requestedSleep = false
		end
	end
end

function SleepManager:startSleep(targetTime, noEventSend)
	if g_currentMission:getIsServer() then
		targetTime = targetTime * 1000 * 60 * 60
		local currentHour = g_currentMission.environment.dayTime + 1
		local duration = (targetTime - currentHour) % 86400000
		self.wakeUpTime = g_time + duration / SleepManager.SLEEPING_TIME_SCALE
		self.startTimeScale = g_currentMission.missionInfo.timeScale

		g_currentMission:setTimeScale(SleepManager.SLEEPING_TIME_SCALE)
	end

	self.isSleeping = true

	g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(true)
	g_currentMission.hud:setIsVisible(false)

	g_currentMission.isPlayerFrozen = true

	g_inputBinding:setContext("SLEEPING", true)

	self.previousCamera = getCamera()
	local sleepCamera = self:getCamera()

	if sleepCamera ~= nil then
		local x, y, z = getWorldTranslation(sleepCamera)
		y = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z) + 60, y)

		setWorldTranslation(sleepCamera, x, y, z)
		setWorldRotation(sleepCamera, math.rad(80), 0, 0)
		setCamera(sleepCamera)
	end

	StartSleepStateEvent.sendEvent(targetTime, noEventSend)
end

function SleepManager:stopSleep(noEventSend)
	if g_currentMission:getIsServer() then
		g_currentMission:setTimeScale(self.startTimeScale)
	end

	if self.previousCamera ~= nil and entityExists(self.previousCamera) then
		setCamera(self.previousCamera)
	elseif g_currentMission.controlPlayer and g_currentMission.player ~= nil then
		setCamera(g_currentMission.player.cameraNode)
	elseif g_currentMission.controlledVehicle ~= nil then
		local vehicleCamera = g_currentMission.controlledVehicle:getActiveCamera()

		if vehicleCamera ~= nil and vehicleCamera.cameraNode ~= nil then
			setCamera(vehicleCamera.cameraNode)
		end
	end

	self.previousCamera = nil

	if g_inputBinding:getContextName() == "SLEEPING" then
		g_inputBinding:revertContext(true)
	end

	g_currentMission.isPlayerFrozen = false

	g_currentMission.hud:setIsVisible(true)
	g_currentMission.environment.weather.cloudUpdater:setSlowModeEnabled(false)

	self.isSleeping = false

	StopSleepStateEvent.sendEvent(noEventSend)
end

function SleepManager:getCanSleep()
	return not self.isSleeping
end

function SleepManager:getIsSleeping()
	return self.isSleeping
end

function SleepManager:showDialog()
	if self:getCanSleep() then
		g_gui:showSleepDialog({
			text = g_i18n:getText("ui_inGameSleepTargetTime"),
			callback = self.sleepDialogYesNo,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_inGameSleepWrongTime"),
			dialogType = DialogElement.TYPE_WARNING,
			target = self
		})
	end
end

function SleepManager:sleepDialogYesNo(yesNo, targetTime)
	if yesNo then
		SleepRequestEvent.sendEvent(g_currentMission.playerUserId)

		self.requestedSleep = true
		self.requestedTime = g_time
		self.responseCounter = 0
		self.requestCounter = table.getn(g_currentMission.userManager:getUsers()) - 1
		self.requestedTargetTime = targetTime

		if g_currentMission.connectedToDedicatedServer then
			self.requestCounter = self.requestCounter - 1
		end
	end
end

function SleepManager:showSleepRequest(userId)
	if userId ~= g_currentMission.playerUserId then
		local user = g_currentMission.userManager:getUserByUserId(userId)

		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_inGameSleepRequest"), user:getNickname()),
			callback = self.sleepRequestYesNo,
			target = self
		})
	end
end

function SleepManager:sleepRequestYesNo(yesNo)
	SleepResponseEvent.sendEvent(g_currentMission.playerUserId, yesNo)
end

function SleepManager:sleepResponse(userId, answer)
	if answer then
		self.responseCounter = self.responseCounter + 1
	else
		if userId ~= g_currentMission.playerUserId then
			local user = g_currentMission.userManager:getUserByUserId(userId)

			g_gui:showInfoDialog({
				text = string.format(g_i18n:getText("ui_inGameSleepRequestDenied"), user:getNickname()),
				dialogType = DialogElement.TYPE_WARNING,
				target = self
			})
		end

		self.responseCounter = 0
		self.requestedSleep = false
	end
end

function SleepManager:getCamera()
	return g_farmManager:getSleepCamera(g_currentMission.player.farmId) or self:getFallbackCamera()
end

function SleepManager:getFallbackCamera()
	if self.fallbackCamera == nil then
		self.fallbackCamera = createCamera("sleepingFallbackCamera", math.rad(60), 1, 10000)

		link(getRootNode(), self.fallbackCamera)
	end

	return self.fallbackCamera
end

g_sleepManager = SleepManager.new()
