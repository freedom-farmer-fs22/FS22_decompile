BeehiveSystem = {
	DEBUG_ENABLED = false
}
local BeehiveSystem_mt = Class(BeehiveSystem)

function BeehiveSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or BeehiveSystem_mt)
	self.mission = mission
	self.beehives = {}
	self.beehivesSortedRadius = {}
	self.beehivePalletSpawners = {}
	self.isFxActive = false
	self.isProductionActive = false

	if self.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsBeehiveDebug", "Toggles beehive debug mode", "consoleCommandBeehiveDebug", self)
	end

	self.lastTimeNoSpawnerWarningDisplayed = 0

	return self
end

function BeehiveSystem:delete()
	removeConsoleCommand("gsBeehiveDebug")
end

function BeehiveSystem:addBeehive(beehiveToAdd)
	if #self.beehivesSortedRadius == 0 then
		self:updateState()
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
		g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.updateBeehivesState, self)
	end

	table.insert(self.beehivesSortedRadius, beehiveToAdd)

	if self.mission.isMissionStarted then
		self:showNoSpawnerWarning(beehiveToAdd)
	end

	table.sort(self.beehivesSortedRadius, function (a, b)
		return b.spec_beehive.actionRadius < a.spec_beehive.actionRadius
	end)
end

function BeehiveSystem:removeBeehive(beehive)
	table.removeElement(self.beehivesSortedRadius, beehive)

	if #self.beehivesSortedRadius == 0 then
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
		g_messageCenter:unsubscribe(MessageType.WEATHER_CHANGED, self)
	end
end

function BeehiveSystem:onHourChanged()
	self:updateBeehivesOutput()
	self:updateBeehivesState()
end

function BeehiveSystem:updateBeehivesOutput(farmId)
	if self.mission:getIsServer() then
		local palletSpawnersToUpdate = {}

		for i = 1, #self.beehivesSortedRadius do
			local beehive = self.beehivesSortedRadius[i]
			local beehiveOwner = beehive:getOwnerFarmId()

			if farmId == nil or farmId == beehiveOwner then
				local palletSpawner = self:getFarmBeehivePalletSpawner(beehiveOwner)

				if palletSpawner ~= nil then
					local honeyAmount = beehive:getHoneyAmountToSpawn()

					if honeyAmount > 0 then
						palletSpawnersToUpdate[palletSpawner] = true

						palletSpawner:addFillLevel(honeyAmount)
					end
				end
			end
		end

		for palletSpawner in pairs(palletSpawnersToUpdate) do
			palletSpawner:updatePallets()
		end
	end
end

function BeehiveSystem:updateState()
	local environment = g_currentMission.environment
	self.isFxActive = true
	self.isProductionActive = true

	if not environment.isSunOn then
		self.isFxActive = false
	elseif environment.currentSeason == Environment.SEASON.WINTER then
		self.isFxActive = false
		self.isProductionActive = false
	elseif environment.weather:getIsRaining() then
		self.isFxActive = false
	end
end

function BeehiveSystem:updateBeehivesState()
	self:updateState()

	for i = 1, #self.beehivesSortedRadius do
		self.beehivesSortedRadius[i]:updateBeehiveState()
	end
end

function BeehiveSystem:getFarmHasBeehive(farmId)
	for _, beehive in ipairs(self.beehivesSortedRadius) do
		if beehive:getOwnerFarmId() == farmId then
			return true
		end
	end

	return false
end

function BeehiveSystem:getBeehives()
	return self.beehivesSortedRadius
end

function BeehiveSystem:getBeehiveInfluenceFactorAt(wx, wz)
	local beehiveInfluenceFactor = 0

	for i = 1, #self.beehivesSortedRadius do
		local beehive = self.beehivesSortedRadius[i]
		beehiveInfluenceFactor = beehiveInfluenceFactor + beehive:getBeehiveInfluenceFactor(wx, wz)

		if beehiveInfluenceFactor >= 1 then
			break
		end
	end

	return math.min(beehiveInfluenceFactor, 1)
end

function BeehiveSystem:addBeehivePalletSpawner(beehivePalletSpawner)
	table.addElement(self.beehivePalletSpawners, beehivePalletSpawner)
	self:updateBeehivesOutput(beehivePalletSpawner:getOwnerFarmId())
end

function BeehiveSystem:removeBeehivePalletSpawner(beehivePalletSpawner)
	table.removeElement(self.beehivePalletSpawners, beehivePalletSpawner)
	self:showNoSpawnerWarning(beehivePalletSpawner)
end

function BeehiveSystem:showNoSpawnerWarning(placeable)
	if self.mission:getIsClient() and g_time - self.lastTimeNoSpawnerWarningDisplayed > 5000 then
		local placeableFarmId = placeable:getOwnerFarmId()
		local farmId = self.mission:getFarmId()

		if self:getFarmHasBeehive(farmId) and farmId == placeableFarmId and self:getFarmBeehivePalletSpawner(farmId) == nil then
			local text = g_i18n:getText("ingameNotification_noPalletLocationAvailable") .. string.format(" (%s)", g_i18n:getText("category_beeHives"))

			self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)

			self.lastTimeNoSpawnerWarningDisplayed = g_time
		end
	end
end

function BeehiveSystem:getFarmBeehivePalletSpawner(farmId)
	for _, beehivePalletSpawner in ipairs(self.beehivePalletSpawners) do
		if beehivePalletSpawner:getOwnerFarmId() == farmId then
			return beehivePalletSpawner
		end
	end

	return nil
end

function BeehiveSystem:consoleCommandBeehiveDebug()
	BeehiveSystem.DEBUG_ENABLED = not BeehiveSystem.DEBUG_ENABLED

	return "BeehiveSystem.DEBUG_ENABLED=" .. tostring(BeehiveSystem.DEBUG_ENABLED)
end
