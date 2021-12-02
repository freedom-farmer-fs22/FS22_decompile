PlaceableBeehive = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableBeehive.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getBeehiveInfluenceFactor", PlaceableBeehive.getBeehiveInfluenceFactor)
	SpecializationUtil.registerFunction(placeableType, "updateBeehiveState", PlaceableBeehive.updateBeehiveState)
	SpecializationUtil.registerFunction(placeableType, "getHoneyAmountToSpawn", PlaceableBeehive.getHoneyAmountToSpawn)
end

function PlaceableBeehive.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBeehive.updateInfo)
end

function PlaceableBeehive.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehive)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehive)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehive)
end

function PlaceableBeehive.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Beehive")
	schema:register(XMLValueType.FLOAT, basePath .. ".beehive#actionRadius", "Bees action radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".beehive#litersHoneyPerDay", "Beehive honey production per active day")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".beehive.effects")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".beehive.sounds", "idle")
	schema:setXMLSpecializationType()
end

function PlaceableBeehive:onLoad(savegame)
	local spec = self.spec_beehive
	local xmlFile = self.xmlFile
	spec.environment = g_currentMission.environment
	spec.isFxActive = false
	spec.isProductionActive = false
	spec.actionRadius = xmlFile:getFloat("placeable.beehive#actionRadius", 25)
	spec.honeyPerHour = xmlFile:getFloat("placeable.beehive#litersHoneyPerDay", 10) / 24
	spec.infoTableRange = {
		title = g_i18n:getText("infohud_range"),
		text = g_i18n:formatNumber(spec.actionRadius, 0) .. "m"
	}
	spec.infoTableNoSpawnerA = {
		accentuate = true,
		title = g_i18n:getText("infohud_beehive_noPalletLocationA")
	}
	spec.infoTableNoSpawnerB = {
		accentuate = true,
		title = g_i18n:getText("infohud_beehive_noPalletLocationB")
	}
	spec.honeyAtPalletLocation = {
		title = "",
		text = g_i18n:getText("infohud_beehive_honeyAtPalletLocation")
	}
	spec.actionRadiusSquared = spec.actionRadius^2
	local wx, _, wz = getWorldTranslation(self.rootNode)
	spec.wz = wz
	spec.wx = wx

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(xmlFile, "placeable.beehive.effects", self.components, self, self.i3dMappings)

		g_effectManager:setFillType(spec.effects, FillType.UNKNOWN)

		spec.samples = {
			idle = g_soundManager:loadSampleFromXML(xmlFile, "placeable.beehive.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
		}
	end

	spec.lastDayTimeHoneySpawned = -1
end

function PlaceableBeehive:onDelete()
	local spec = self.spec_beehive

	g_effectManager:deleteEffects(spec.effects)
	g_soundManager:deleteSamples(spec.samples)
	g_currentMission.beehiveSystem:removeBeehive(self)
end

function PlaceableBeehive:onFinalizePlacement()
	local spec = self.spec_beehive
	spec.lastDayTimeHoneySpawned = spec.environment.dayTime

	g_currentMission.beehiveSystem:addBeehive(self)
	self:updateBeehiveState()
end

function PlaceableBeehive:getBeehiveInfluenceFactor(wx, wz)
	local spec = self.spec_beehive
	local distanceToPointSquared = MathUtil.getPointPointDistanceSquared(spec.wx, spec.wz, wx, wz)

	if distanceToPointSquared <= spec.actionRadiusSquared then
		return 1 - distanceToPointSquared * 0.85 / spec.actionRadiusSquared
	end

	return 0
end

function PlaceableBeehive:updateBeehiveState()
	local spec = self.spec_beehive
	local beehiveSystem = g_currentMission.beehiveSystem
	spec.isProductionActive = beehiveSystem.isProductionActive

	if spec.isFxActive ~= beehiveSystem.isFxActive then
		spec.isFxActive = beehiveSystem.isFxActive

		if self.isClient then
			if beehiveSystem.isFxActive then
				g_effectManager:startEffects(spec.effects)
				g_soundManager:playSample(spec.samples.idle, 0)
			else
				g_effectManager:stopEffects(spec.effects)
				g_soundManager:stopSample(spec.samples.idle)
			end
		end
	end
end

function PlaceableBeehive:getHoneyAmountToSpawn()
	local spec = self.spec_beehive

	if spec.isProductionActive then
		local hours = math.min(math.abs((spec.environment.dayTime - spec.lastDayTimeHoneySpawned) / 1000 / 60 / 60), 1)
		local amount = spec.honeyPerHour * hours * g_currentMission.environment.timeAdjustment
		spec.lastDayTimeHoneySpawned = spec.environment.dayTime

		return amount
	end

	return 0
end

function PlaceableBeehive:updateInfo(superFunc, infoTable)
	local spec = self.spec_beehive

	table.insert(infoTable, spec.infoTableRange)

	local owner = self:getOwnerFarmId()

	if owner == g_currentMission:getFarmId() then
		local spawner = g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(owner)

		if spawner == nil then
			table.insert(infoTable, spec.infoTableNoSpawnerA)
			table.insert(infoTable, spec.infoTableNoSpawnerB)
		else
			table.insert(infoTable, spec.honeyAtPalletLocation)
		end
	end
end
