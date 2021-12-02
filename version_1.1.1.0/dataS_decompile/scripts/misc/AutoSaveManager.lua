AutoSaveManager = {
	DEFAULT_INTERVAL = GS_IS_MOBILE_VERSION and 5 or 15,
	INTERVAL_OPTIONS = {}
}
AutoSaveManager.INTERVAL_OPTIONS[1] = 0
AutoSaveManager.INTERVAL_OPTIONS[2] = 5
AutoSaveManager.INTERVAL_OPTIONS[3] = 10
AutoSaveManager.INTERVAL_OPTIONS[4] = 15
local AutoSaveManager_mt = Class(AutoSaveManager, AbstractManager)

function AutoSaveManager.new(customMt)
	local self = AbstractManager.new(customMt or AutoSaveManager_mt)
	self.interval = 60000 * AutoSaveManager.DEFAULT_INTERVAL
	self.time = self.interval
	self.isPending = false
	self.isActive = true
	self.saveNextFrame = false

	return self
end

function AutoSaveManager:loadFinished()
	g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.onOpenIngameMenu, self)
	g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)

	if g_currentMission:getIsServer() then
		addConsoleCommand("gsAutoSave", "Enables/disables auto save", "consoleCommandAutoSave", self)
		addConsoleCommand("gsAutoSaveInterval", "Sets the auto save interval", "consoleCommandAutoSaveInterval", self)
	end
end

function AutoSaveManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)

	if g_currentMission:getIsServer() then
		removeConsoleCommand("gsAutoSaveInterval")
		removeConsoleCommand("gsAutoSave")
	end
end

function AutoSaveManager:update(dt)
	if self:getIsAutoSaveAllowed() and g_currentMission:getIsServer() and g_currentMission.gameStarted and self.time < g_time then
		self.isPending = true

		if g_dedicatedServer ~= nil then
			self:runAutoSaveIfPending(true)
		end
	end

	if self.saveNextFrame then
		self:runAutoSaveIfPending()

		self.saveNextFrame = false
	end
end

function AutoSaveManager:runAutoSaveIfPending(hideVisuals)
	if self.isPending then
		self.isPending = false

		g_currentMission:startSaveCurrentGame(hideVisuals)

		self.time = g_time + self.interval
	end
end

function AutoSaveManager:onMissionStarted()
	self.time = g_time + self.interval
	self.isPending = false
end

function AutoSaveManager:onOpenIngameMenu()
	self.saveNextFrame = true
end

function AutoSaveManager:onSavegameLoaded()
	if g_dedicatedServer == nil then
		local interval = 0

		if g_currentMission ~= nil then
			if g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.autoSaveInterval ~= nil then
				interval = g_currentMission.missionInfo.autoSaveInterval
			end

			g_currentMission:registerObjectToCallOnMissionStart(self)
		end

		if not GS_IS_MOBILE_VERSION then
			self:setInterval(interval)
		end
	end
end

function AutoSaveManager:setInterval(interval)
	if interval > 0 then
		self.interval = interval * 60 * 1000
		self.time = g_time + self.interval

		self:setIsActive(true)
	else
		self:setIsActive(false)
	end
end

function AutoSaveManager:getInterval()
	if not self.isActive then
		return 0
	end

	return self.interval / 60 / 1000
end

function AutoSaveManager:getIntervalFromIndex(index)
	local interval = AutoSaveManager.INTERVAL_OPTIONS[index]

	if interval ~= nil then
		return interval
	end

	return 0
end

function AutoSaveManager:getIndexFromInterval(interval)
	for i, v in ipairs(AutoSaveManager.INTERVAL_OPTIONS) do
		if v == interval then
			return i
		end
	end

	return 1
end

function AutoSaveManager:getIntervalOptions()
	return AutoSaveManager.INTERVAL_OPTIONS
end

function AutoSaveManager:setIsActive(state)
	self.isActive = state

	if state then
		self.time = g_time + self.interval
	end
end

function AutoSaveManager:getIsActive()
	return self.isActive
end

function AutoSaveManager:resetTime()
	self.time = g_time + self.interval
end

function AutoSaveManager:getIsAutoSaveAllowed()
	if g_currentMission == nil or not g_currentMission:getIsAutoSaveSupported() then
		return false
	end

	if g_appIsSuspended then
		return false
	end

	return self.isActive
end

function AutoSaveManager:consoleCommandAutoSaveInterval(interval)
	if g_currentMission:getIsServer() then
		interval = tonumber(interval)

		if interval == nil then
			return "AutoSaveInterval = " .. string.format("%1.3f", g_autoSaveManager:getInterval() / 60 / 1000) .. ". Arguments: interval[minutes]"
		end

		g_autoSaveManager:setInterval(math.max(interval, 1) * 60 * 1000)

		return "AutoSaveInterval = " .. interval
	end
end

function AutoSaveManager:consoleCommandAutoSave(enabled)
	if g_currentMission:getIsServer() then
		if enabled == nil or enabled == "" then
			return "AutoSave = " .. tostring(g_autoSaveManager:getIsActive()) .. ". Arguments: enabled[true|false]"
		end

		enabled = tostring(enabled):lower()

		g_autoSaveManager:setIsActive(enabled == "true")

		return "AutoSave = " .. tostring(g_autoSaveManager:getIsActive())
	end
end
