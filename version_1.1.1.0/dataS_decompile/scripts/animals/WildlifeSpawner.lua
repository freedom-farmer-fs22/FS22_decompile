WildlifeSpawner = {}
local WildlifeSpawner_mt = Class(WildlifeSpawner)
WildlifeSpawner.DEBUGSHOWIDSTATES = {
	ALL = 2,
	SINGLE = 3,
	MAX = 3,
	NONE = 1
}
WildlifeSpawner.RULE = {
	DONT_CARE = 3,
	NOT_ALLOWED = 2,
	REQUIRED = 1
}

function WildlifeSpawner.new(customMt)
	local self = setmetatable({}, customMt or WildlifeSpawner_mt)
	self.isEnabled = true
	self.collisionDetectionMask = 4096
	self.maxCost = 0
	self.checkTimeInterval = 0
	self.nextCheckTime = 0
	self.areas = {}
	self.areasOfInterest = {}
	self.totalCost = 0
	self.treeCount = 0
	self.playerNode = nil
	self.avoidDistance = 20
	self.debugAnimalList = {}
	self.debugShow = false
	self.debugShowId = WildlifeSpawner.DEBUGSHOWIDSTATES.NONE
	self.debugShowSteering = false
	self.debugShowAnimation = false

	addConsoleCommand("gsWildlifeToggle", "Toggle wildlife on map", "consoleCommandToggleEnabled", self)
	addConsoleCommand("gsWildlifeDebug", "Toggle shows/hide all wildlife debug information.", "consoleCommandToggleShowWildlife", self)
	addConsoleCommand("gsWildlifeDebugId", "Toggle shows/hide all wildlife animal id.", "consoleCommandToggleShowWildlifeId", self)
	addConsoleCommand("gsWildlifeDebugSteering", "Toggle shows/hide animal steering information.", "consoleCommandToggleShowWildlifeSteering", self)
	addConsoleCommand("gsWildlifeDebugAnimation", "Toggle shows/hide animal animation information.", "consoleCommandToggleShowWildlifeAnimation", self)
	addConsoleCommand("gsWildlifeDebugAnimalAdd", "Adds an animal to a debug list.", "consoleCommandAddWildlifeAnimalToDebug", self)
	addConsoleCommand("gsWildlifeDebugAnimalRemove", "Removes an animal to a debug list.", "consoleCommandRemoveWildlifeAnimalToDebug", self)

	return self
end

function WildlifeSpawner:delete()
	self:removeAllAnimals()

	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.lightWildlife ~= nil then
				species.lightWildlife:delete()
			end
		end
	end

	self.areas = {}

	removeConsoleCommand("gsWildlifeToggle")
	removeConsoleCommand("gsWildlifeDebug")
	removeConsoleCommand("gsWildlifeDebugId")
	removeConsoleCommand("gsWildlifeDebugSteering")
	removeConsoleCommand("gsWildlifeDebugAnimation")
	removeConsoleCommand("gsWildlifeDebugAnimalAdd")
	removeConsoleCommand("gsWildlifeDebugAnimalRemove")
end

function WildlifeSpawner:onConnectionClosed()
	self:removeAllAnimals()
end

function WildlifeSpawner:removeAllAnimals()
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			for i = #species.spawned, 1, -1 do
				if species.classType == "companionAnimal" then
					local spawn = species.spawned[i]

					if spawn.spawnId ~= nil then
						delete(spawn.spawnId)

						spawn.spawnId = nil
					end
				elseif species.classType == "lightWildlife" and species.lightWildlife ~= nil then
					species.lightWildlife:removeAllAnimals()
				end

				table.remove(species.spawned, i)
			end
		end
	end

	self.totalCost = 0
end

function WildlifeSpawner:loadMapData(xmlFile)
	local filename = getXMLString(xmlFile, "map.wildlife#filename")

	if filename == nil or filename == "" then
		Logging.xmlInfo(xmlFile, "No wildlife config file defined")

		return false
	end

	filename = Utils.getFilename(filename, g_currentMission.baseDirectory)
	local wildlifeXmlFile = loadXMLFile("wildlife", filename)

	if wildlifeXmlFile == 0 or wildlifeXmlFile == nil then
		Logging.xmlError(xmlFile, "Could not load wildlife config file '%s'", filename)

		return false
	end

	self.maxCost = Utils.getNoNil(getXMLInt(wildlifeXmlFile, "wildlifeSpawner#maxCost"), 0)
	self.checkTimeInterval = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#checkTimeInterval"), 1) * 1000
	self.maxAreaOfInterest = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#maxAreaOfInterest"), 1)
	self.areaOfInterestliveTime = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#areaOfInterestliveTime"), 1) * 1000
	local i = 0

	while true do
		local areaBaseString = string.format("wildlifeSpawner.area(%d)", i)

		if not hasXMLProperty(wildlifeXmlFile, areaBaseString) then
			break
		end

		local newArea = {
			areaSpawnRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#areaSpawnRadius"), 1),
			areaMaxRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#areaMaxRadius"), 1),
			spawnCircleRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#spawnCircleRadius"), 1),
			species = {}
		}
		local j = 0

		while true do
			local speciesBaseString = string.format("%s.species(%d)", areaBaseString, j)

			if not hasXMLProperty(wildlifeXmlFile, speciesBaseString) then
				break
			end

			local classTypeString = getXMLString(wildlifeXmlFile, speciesBaseString .. "#classType")
			local classType = nil

			if classTypeString ~= nil then
				if string.lower(classTypeString) == "companionanimal" then
					classType = "companionAnimal"
				elseif string.lower(classTypeString) == "lightwildlife" then
					classType = "lightWildlife"
				end
			end

			if classType ~= nil then
				local newSpecies = {
					classType = classType,
					name = getXMLString(wildlifeXmlFile, speciesBaseString .. "#name"),
					configFilename = getXMLString(wildlifeXmlFile, speciesBaseString .. "#config"),
					cost = getXMLFloat(wildlifeXmlFile, speciesBaseString .. ".cost"),
					minCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".minCount"),
					maxCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".maxCount"),
					currentCount = 0,
					spawnCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".spawnCount"),
					groupSpawnRadius = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".groupSpawnRadius"),
					spawned = {},
					lightWildlife = nil
				}

				if classType == "lightWildlife" and newSpecies.name == "crow" then
					newSpecies.lightWildlife = CrowsWildlife.new()

					newSpecies.lightWildlife:load(Utils.getNoNil(getXMLString(wildlifeXmlFile, speciesBaseString .. "#config"), ""))
				end

				newSpecies.spawnRules = {}
				local k = 0

				while true do
					local spawnRuleBaseString = string.format("%s.spawnRules.rule(%d)", speciesBaseString, k)

					if not hasXMLProperty(wildlifeXmlFile, spawnRuleBaseString) then
						break
					end

					local newRule = {
						hourFrom = getXMLInt(wildlifeXmlFile, spawnRuleBaseString .. "#hourFrom"),
						hourTo = getXMLInt(wildlifeXmlFile, spawnRuleBaseString .. "#hourTo"),
						onField = self:parseSpawnRule(getXMLString(wildlifeXmlFile, spawnRuleBaseString .. "#onField")),
						hasTrees = self:parseSpawnRule(getXMLString(wildlifeXmlFile, spawnRuleBaseString .. "#hasTrees")),
						inWater = self:parseSpawnRule(getXMLString(wildlifeXmlFile, spawnRuleBaseString .. "#inWater"))
					}

					table.insert(newSpecies.spawnRules, newRule)

					k = k + 1
				end

				table.insert(newArea.species, newSpecies)
			end

			j = j + 1
		end

		table.insert(self.areas, newArea)

		i = i + 1
	end

	delete(wildlifeXmlFile)

	return true
end

function WildlifeSpawner:parseSpawnRule(ruleValue)
	if string.lower(ruleValue) == "required" then
		return WildlifeSpawner.RULE.REQUIRED
	elseif string.lower(ruleValue) == "notallowed" then
		return WildlifeSpawner.RULE.NOT_ALLOWED
	elseif string.lower(ruleValue) == "dontcare" then
		return WildlifeSpawner.RULE.DONT_CARE
	else
		return WildlifeSpawner.RULE.DONT_CARE
	end
end

function WildlifeSpawner:update(dt)
	self:updateAreaOfInterest(dt)

	if self.isEnabled then
		self.nextCheckTime = self.nextCheckTime - dt

		if self.nextCheckTime < 0 then
			self.nextCheckTime = self.checkTimeInterval

			self:updateSpawner()
		end

		self:removeFarAwayAnimals()

		self.playerNode = nil

		if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
			self.playerNode = g_currentMission.player.rootNode
		elseif g_currentMission.controlledVehicle ~= nil then
			self.playerNode = g_currentMission.controlledVehicle.rootNode
		end

		for _, area in pairs(self.areas) do
			for _, species in pairs(area.species) do
				if species.classType == "companionAnimal" then
					for _, spawn in pairs(species.spawned) do
						if spawn.spawnId ~= nil then
							setCompanionDaytime(spawn.spawnId, g_currentMission.environment.dayTime)

							if spawn.avoidNode ~= self.playerNode then
								setCompanionAvoidPlayer(spawn.spawnId, self.playerNode, self.avoidDistance)

								spawn.avoidNode = self.playerNode
							end
						end
					end
				elseif species.classType == "lightWildlife" then
					species.lightWildlife:update(dt)
				end
			end
		end

		if self.debugShow then
			self:debugDraw()
		end
	end
end

function WildlifeSpawner:removeFarAwayAnimals()
	local passedTest, originX, originY, originZ = self:getPlayerCenter()

	if passedTest then
		for _, area in pairs(self.areas) do
			for _, species in pairs(area.species) do
				if species.classType == "companionAnimal" then
					for i = #species.spawned, 1, -1 do
						local spawn = species.spawned[i]

						if spawn.spawnId ~= nil then
							local distance, _ = getCompanionClosestDistance(spawn.spawnId, originX, originY, originZ)

							if area.areaMaxRadius < distance then
								delete(spawn.spawnId)

								spawn.spawnId = nil
								species.currentCount = species.currentCount - spawn.count
								self.totalCost = self.totalCost - species.cost * spawn.count

								table.remove(species.spawned, i)
							end
						end
					end
				elseif species.classType == "lightWildlife" and species.lightWildlife ~= nil then
					local removedAnimalsCount = species.lightWildlife:removeFarAwayAnimals(area.areaMaxRadius, originX, originY, originZ)

					if removedAnimalsCount > 0 then
						species.currentCount = species.currentCount - removedAnimalsCount
						self.totalCost = self.totalCost - species.cost * removedAnimalsCount

						for i = #species.spawned, 1, -1 do
							if species.lightWildlife:countSpawned() == 0 then
								table.remove(species.spawned, i)
							end
						end
					end
				end
			end
		end
	end
end

function WildlifeSpawner:getPlayerCenter()
	if self.playerNode ~= nil and entityExists(self.playerNode) then
		local x, y, z = getWorldTranslation(self.playerNode)

		return true, x, y, z
	end

	return false, 0, 0, 0
end

function WildlifeSpawner:updateSpawner()
	local passedTest, x, y, z = self:getPlayerCenter()

	if passedTest then
		self:checkAreas(x, y, z)
	end
end

function WildlifeSpawner:trySpawnAtArea(species, spawnCircleRadius, testX, testY, testZ, isInWater)
	for _, animalType in pairs(species) do
		if self:checkArea(testX, testY, testZ, animalType.spawnRules, spawnCircleRadius, isInWater) then
			local spawnPosX = testX + math.random() * spawnCircleRadius
			local spawnPosZ = testZ + math.random() * spawnCircleRadius
			local spawnPosY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, spawnPosX, 0, spawnPosZ) + 0.5

			if self:spawnAnimals(animalType, spawnPosX, spawnPosY, spawnPosZ) then
				return true
			end
		end
	end

	return false
end

function WildlifeSpawner:checkAreas(x, y, z)
	local testX = x
	local testZ = z
	local testY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, testX, 0, testZ) + 0.5
	local isInWater = self:getIsInWater(testX, testY, testZ)

	for _, area in pairs(self.areas) do
		local hasSpawned = false

		for _, interestArea in pairs(self.areasOfInterest) do
			local distSq = (testX - interestArea.positionX) * (testX - interestArea.positionX) + (testZ - interestArea.positionZ) * (testZ - interestArea.positionZ)

			if distSq < area.areaSpawnRadius * area.areaSpawnRadius then
				hasSpawned = self:trySpawnAtArea(area.species, interestArea.radius, testX, testY, testZ, isInWater)

				if hasSpawned then
					break
				end
			end
		end

		if not hasSpawned then
			local angle = math.rad(math.random(0, 360))
			testX = x + area.areaSpawnRadius * math.cos(angle) - area.areaSpawnRadius * math.sin(angle)
			testZ = z + area.areaSpawnRadius * math.cos(angle) + area.areaSpawnRadius * math.sin(angle)
			testY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, testX, 0, testZ) + 0.5

			self:trySpawnAtArea(area.species, area.spawnCircleRadius, testX, testY, testZ, isInWater)
		end
	end
end

function WildlifeSpawner:checkArea(x, y, z, rules, radius, isInWater)
	local validArea = false
	local currentHour = math.floor(g_currentMission.environment.dayTime / 3600000)
	local isOnField, hasTrees = nil

	for _, rule in pairs(rules) do
		if rule.hourFrom <= currentHour or currentHour <= rule.hourTo then
			local validRule = true

			if rule.onField ~= WildlifeSpawner.RULE.DONT_CARE then
				if isOnField == nil then
					isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
				end

				validRule = rule.onField == WildlifeSpawner.RULE.REQUIRED and isOnField or rule.onField == WildlifeSpawner.RULE.NOT_ALLOWED and not isOnField
			end

			if validRule and rule.hasTrees ~= WildlifeSpawner.RULE.DONT_CARE then
				if hasTrees == nil then
					hasTrees = self:countTrees(x, y, z, radius) > 3
				end

				validRule = rule.hasTrees == WildlifeSpawner.RULE.REQUIRED and hasTrees or rule.hasTrees == WildlifeSpawner.RULE.NOT_ALLOWED and not hasTrees
			end

			if validRule and rule.inWater ~= WildlifeSpawner.RULE.DONT_CARE then
				validRule = rule.inWater == WildlifeSpawner.RULE.REQUIRED and isInWater or rule.inWater == WildlifeSpawner.RULE.NOT_ALLOWED and not isInWater
			end

			if validRule then
				validArea = true

				break
			end
		end
	end

	return validArea
end

function WildlifeSpawner:countTrees(x, y, z, radius)
	self.treeCount = 0

	overlapSphere(x, y, z, radius, "treeCountTestCallback", self, CollisionFlag.TREE, false, true, false)

	return self.treeCount
end

function WildlifeSpawner:treeCountTestCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local object = getParent(transformId)

		if object ~= nil and getSplitType(transformId) ~= 0 then
			self.treeCount = self.treeCount + 1
		end
	end

	return true
end

function WildlifeSpawner:getIsInWater(x, y, z)
	local waterY = g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(x, y, z) or -2000

	return y < waterY
end

function WildlifeSpawner:countAnimalsTobeSpawned(species)
	local remainingAnimal = math.floor((self.maxCost - self.totalCost) / species.cost)

	if remainingAnimal < species.minCount then
		return 0
	end

	local deltaNbAnimals = species.maxCount - species.minCount
	local nbAnimals = species.minCount + math.random(1, deltaNbAnimals)
	nbAnimals = math.min(remainingAnimal, nbAnimals)

	return nbAnimals
end

function WildlifeSpawner:spawnAnimals(species, spawnPosX, spawnPosY, spawnPosZ)
	local xmlFilename = Utils.getFilename(species.configFilename, g_currentMission.loadingMapBaseDirectory)

	if species.name == nil or xmlFilename == nil or g_currentMission.terrainRootNode == nil or species.maxCount <= species.currentCount then
		return false
	end

	local nbAnimals = self:countAnimalsTobeSpawned(species)

	if nbAnimals == 0 then
		return false
	end

	local id = nil

	if species.classType == "companionAnimal" then
		id = createAnimalCompanionManager(species.name, xmlFilename, "wildlifeAnimal", spawnPosX, spawnPosY, spawnPosZ, g_currentMission.terrainRootNode, g_currentMission:getIsServer(), g_currentMission:getIsClient(), nbAnimals)

		setCompanionAvoidPlayer(id, self.playerNode, self.avoidDistance)

		local groundMask = CollisionFlag.TERRAIN + CollisionFlag.STATIC_WORLD
		local obstacleMask = CollisionFlag.STATIC_OBJECTS + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE

		setCompanionCollisionMask(id, groundMask, obstacleMask, CollisionFlag.WATER)
	elseif species.classType == "lightWildlife" then
		id = species.lightWildlife:createAnimals(species.name, spawnPosX, spawnPosY, spawnPosZ, nbAnimals)
	end

	if id ~= nil and id ~= 0 then
		table.insert(species.spawned, {
			spawnId = id,
			posX = spawnPosX,
			posY = spawnPosY,
			posZ = spawnPosZ,
			count = nbAnimals,
			avoidNode = self.playerNode
		})

		species.currentCount = species.currentCount + nbAnimals
		self.totalCost = self.totalCost + species.cost * nbAnimals

		return true
	end

	return false
end

function WildlifeSpawner:debugDraw()
	renderText(0.02, 0.95, 0.02, string.format("Wildlife Info\nCost(%d / %d)", self.totalCost, self.maxCost))

	local passedTest, originX, originY, originZ = self:getPlayerCenter()

	if passedTest then
		for _, area in pairs(self.areas) do
			for _, species in pairs(area.species) do
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId ~= nil then
						local distance = 0

						if species.classType == "companionAnimal" then
							distance, _ = getCompanionClosestDistance(spawn.spawnId, originX, originY, originZ)
						elseif species.classType == "lightWildlife" then
							distance = species.lightWildlife:getClosestDistance(originX, originY, originZ)
							distance = math.sqrt(distance)
						end

						local text = string.format("[%s][%d]\n- nearest player distance (%.3f)", species.name, spawn.spawnId, distance)

						Utils.renderTextAtWorldPosition(spawn.posX, spawn.posY + 0.12, spawn.posZ, text, getCorrectTextSize(0.012), 0)
						DebugUtil.drawDebugCubeAtWorldPos(spawn.posX, spawn.posY, spawn.posZ, 1, 0, 0, 0, 1, 0, 0.05, 0.05, 0.05, 1, 1, 0)
						DebugUtil.drawDebugCircle(spawn.posX, spawn.posY, spawn.posZ, species.groupSpawnRadius, 10, {
							1,
							1,
							0
						})
					end
				end
			end
		end
	end

	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					for animalId = 0, spawn.count - 1 do
						local showAdditionalInfo = self:isInDebugList(spawn.spawnId, animalId)
						local showId = self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.SINGLE and showAdditionalInfo or self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.ALL

						companionDebugDraw(spawn.spawnId, animalId, showId, showAdditionalInfo and self.debugShowSteering, showAdditionalInfo and self.debugShowAnimation)
					end
				end
			end
		end
	end
end

function WildlifeSpawner:updateAreaOfInterest(dt)
	for key, area in pairs(self.areasOfInterest) do
		area.timeToLive = area.timeToLive - dt

		if area.timeToLive <= 0 then
			table.remove(self.areasOfInterest, key)
		end
	end
end

function WildlifeSpawner:addAreaOfInterest(liveTime, posX, posZ, radius)
	if #self.areasOfInterest <= self.maxAreaOfInterest then
		local info = {
			liveTime = liveTime,
			positionX = posX,
			positionZ = posZ,
			radius = radius,
			timeToLive = self.areaOfInterestliveTime
		}

		table.insert(self.areasOfInterest, info)
	end
end

function WildlifeSpawner:animalExists(spawnId, animalId)
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId == spawnId and animalId < spawn.count then
						return true
					end
				end
			end
		end
	end

	return false
end

function WildlifeSpawner:isInDebugList(spawnId, animalId)
	for _, entry in pairs(self.debugAnimalList) do
		if entry.spawnId == spawnId and entry.animalId == animalId then
			return true
		end
	end

	return false
end

function WildlifeSpawner:consoleCommandAddWildlifeAnimalToDebug(spawnId, animalId)
	local argsTest = true
	spawnId = tonumber(spawnId)

	if spawnId == nil then
		argsTest = false
	end

	animalId = tonumber(animalId)

	if animalId == nil then
		argsTest = false
	end

	if argsTest and self:animalExists(spawnId, animalId) then
		table.insert(self.debugAnimalList, {
			spawnId = spawnId,
			animalId = animalId
		})

		return string.format("-- added [spawn(%d)][animal(%d)] to debug list.", spawnId, animalId)
	else
		return string.format("-- gsWildlifeAddAnimalToDebug [spawnId][animalId]")
	end
end

function WildlifeSpawner:consoleCommandRemoveWildlifeAnimalToDebug(spawnId, animalId)
	local argsTest = true
	spawnId = tonumber(spawnId)

	if spawnId == nil then
		argsTest = false
	end

	animalId = tonumber(animalId)

	if animalId == nil then
		argsTest = false
	end

	if argsTest then
		for key, entry in pairs(self.debugAnimalList) do
			if entry.spawnId == spawnId and entry.animalId == animalId then
				table.remove(self.debugAnimalList, key)

				return string.format("-- removed [spawn(%d)][animal(%d)] from debug list.", spawnId, animalId)
			end
		end
	end

	return string.format("-- gsWildlifeRemoveAnimalToDebug [spawnId][animalId]")
end

function WildlifeSpawner:consoleCommandToggleShowWildlife()
	self.debugShow = not self.debugShow

	return string.format("-- show Wildlife debug = %s", tostring(self.debugShow))
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeId()
	self.debugShowId = self.debugShowId + 1

	if WildlifeSpawner.DEBUGSHOWIDSTATES.MAX < self.debugShowId then
		self.debugShowId = WildlifeSpawner.DEBUGSHOWIDSTATES.NONE
	end

	local state = ""

	if self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.NONE then
		state = "NONE"
	elseif self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.SINGLE then
		state = "SINGLE"
	elseif self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.ALL then
		state = "ALL"
	end

	return string.format("-- show Wildlife Id = %s", state)
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeSteering()
	self.debugShowSteering = not self.debugShowSteering

	return string.format("-- show Wildlife Steering = %s", tostring(self.debugShowSteering))
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeAnimation()
	self.debugShowAnimation = not self.debugShowAnimation

	return string.format("-- show Wildlife Animation = %s", tostring(self.debugShowAnimation))
end

function WildlifeSpawner:consoleCommandToggleEnabled(state)
	if state ~= nil then
		state = Utils.stringToBoolean(state)
	end

	self.isEnabled = Utils.getNoNil(state, not self.isEnabled)

	if not self.isEnabled then
		self:removeAllAnimals()
		print("removed all wildlife animals")
	end

	return string.format("Wildlife isEnabled=%s", self.isEnabled)
end
