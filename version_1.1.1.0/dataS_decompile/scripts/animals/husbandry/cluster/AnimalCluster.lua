AnimalCluster = {}
local AnimalCluster_mt = Class(AnimalCluster)
AnimalCluster.NUM_BITS_NUM_ANIMALS = 16
AnimalCluster.NUM_BITS_AGE = 6
AnimalCluster.NUM_BITS_HEALTH = 7
AnimalCluster.NUM_BITS_REPRODUCTION = 7
AnimalCluster.NUM_BITS_SUB_TYPE = 7
AnimalCluster.CLUSTER_ID = 1

function AnimalCluster.getNextClusterId()
	AnimalCluster.CLUSTER_ID = AnimalCluster.CLUSTER_ID + 1

	return AnimalCluster.CLUSTER_ID
end

function AnimalCluster.resetClusterIds()
	assert(g_server == nil or next(g_server.objects) == nil)

	AnimalCluster.CLUSTER_ID = 1
end

function AnimalCluster.new(customMt)
	local self = setmetatable({}, customMt or AnimalCluster_mt)
	self.id = AnimalCluster.getNextClusterId()

	if g_isDevelopmentVersion and not g_currentMission:getIsServer() then
		self.id = math.random(1, 99999999)
	end

	self.clusterSystem = nil
	self.numAnimals = 0
	self.maxNumAnimals = 2^AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
	self.age = 0
	self.health = 0
	self.reproduction = 0
	self.subTypeIndex = 1
	self.isDirty = false
	local reproductionText = g_i18n:getText("statistic_reproduction")
	self.infoReproduction = {
		text = "",
		title = reproductionText,
		titleOrg = reproductionText
	}
	self.infoHealth = {
		text = "",
		title = g_i18n:getText("ui_horseHealth")
	}

	return self
end

function AnimalCluster:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setInt(key .. "#numAnimals", self.numAnimals)
	xmlFile:setInt(key .. "#age", self.age)
	xmlFile:setInt(key .. "#health", self.health)
	xmlFile:setInt(key .. "#reproduction", self.reproduction)
end

function AnimalCluster:loadFromXMLFile(xmlFile, key)
	self.numAnimals = MathUtil.clamp(xmlFile:getInt(key .. "#numAnimals", self.numAnimals), 0, self.maxNumAnimals)
	self.age = MathUtil.clamp(xmlFile:getInt(key .. "#age", self.age), 0, 60)
	self.health = MathUtil.clamp(xmlFile:getInt(key .. "#health", self.health), 0, 100)
	self.reproduction = MathUtil.clamp(xmlFile:getInt(key .. "#reproduction", self.reproduction), 0, 100)

	return true
end

function AnimalCluster:readStream(streamId, connection)
	self.numAnimals = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_NUM_ANIMALS)
	self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
	self.health = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_HEALTH)
	self.reproduction = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_REPRODUCTION)
end

function AnimalCluster:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.numAnimals, AnimalCluster.NUM_BITS_NUM_ANIMALS)
	streamWriteUIntN(streamId, math.floor(self.age), AnimalCluster.NUM_BITS_AGE)
	streamWriteUIntN(streamId, math.floor(self.health), AnimalCluster.NUM_BITS_HEALTH)
	streamWriteUIntN(streamId, math.floor(self.reproduction), AnimalCluster.NUM_BITS_REPRODUCTION)
end

function AnimalCluster:readUpdateStream(streamId, connection)
end

function AnimalCluster:writeUpdateStream(streamId, connection)
end

function AnimalCluster:onDayChanged()
end

function AnimalCluster:onPeriodChanged()
	self:changeAge(1)
end

function AnimalCluster:clone()
	local ret = self.new()
	self.maxNumAnimals = 2^AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
	ret.age = self.age
	ret.health = self.health
	ret.reproduction = self.reproduction
	ret.subTypeIndex = self.subTypeIndex

	return ret
end

function AnimalCluster:setClusterSystem(clusterSystem)
	self.clusterSystem = clusterSystem
end

function AnimalCluster:getNumAnimals()
	return self.numAnimals
end

function AnimalCluster:changeNumAnimals(delta)
	local old = self.numAnimals
	self.numAnimals = MathUtil.clamp(math.floor(self.numAnimals + delta), 0, self.maxNumAnimals)

	if math.abs(self.numAnimals - old) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:getSubTypeIndex()
	return self.subTypeIndex
end

function AnimalCluster:getAge()
	return self.age
end

function AnimalCluster:getAgeFactor()
	return MathUtil.clamp(self.age / 60, 0, 1)
end

function AnimalCluster:changeAge(delta)
	local old = self.age
	self.age = MathUtil.clamp(math.floor(self.age + delta), 0, 60)

	if math.abs(self.age - old) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:updateHealth(foodFactor)
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	local healthFactor = self:getHealthChangeFactor(foodFactor)
	local healthThresholdFactor = subType.healthThresholdFactor
	local factor, delta = nil

	if healthThresholdFactor < healthFactor then
		factor = (healthFactor - healthThresholdFactor) / (1 - healthThresholdFactor)
		delta = subType.healthIncreaseHour
	else
		factor = healthFactor / healthThresholdFactor - 1
		delta = subType.healthDecreaseHour
	end

	local healthDelta = delta * factor

	if healthDelta ~= 0 then
		self:changeHealth(healthDelta)
	end
end

function AnimalCluster:getHealthChangeFactor(foodFactor)
	return foodFactor
end

function AnimalCluster:changeHealth(delta)
	local old = self.health
	self.health = MathUtil.clamp(math.floor(self.health + delta), 0, 100)

	if math.abs(self.health - old) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:getHealthFactor()
	return self.health / 100
end

function AnimalCluster:changeReproduction(delta)
	local old = self.reproduction
	self.reproduction = MathUtil.clamp(math.floor(self.reproduction + delta), 0, 100)

	if math.abs(self.reproduction - old) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:getReproductionFactor()
	return self.reproduction / 100
end

function AnimalCluster:getReproductionDelta(duration)
	if duration > 0 then
		return math.floor(100 / duration)
	end

	return 0
end

function AnimalCluster:updateReproduction()
	if self:getCanReproduce() then
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
		local reproductionDelta = self:getReproductionDelta(subType.reproductionDurationMonth)

		if reproductionDelta > 0 then
			self:changeReproduction(reproductionDelta)

			if self.reproduction >= 100 then
				self.reproduction = 0

				self:setDirty()

				return self.numAnimals
			end
		end
	end

	return 0
end

function AnimalCluster:getSupportsReproduction()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())

	return subType.supportsReproduction
end

function AnimalCluster:getCanReproduce()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())

	if subType.supportsReproduction then
		local healthFactor = self:getHealthFactor()

		return subType.reproductionMinHealth <= healthFactor and subType.reproductionMinAgeMonth <= self.age
	end

	return false
end

function AnimalCluster:setDirty()
	self.isDirty = true

	if self.clusterSystem ~= nil then
		self.clusterSystem:setDirty()
	end
end

function AnimalCluster:getSellPrice()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	local sellPrice = subType.sellPrice:get(self.age)
	local healthFactor = self:getHealthFactor()

	return sellPrice * 0.4 + sellPrice * 0.6 * healthFactor
end

function AnimalCluster:getCanBeSold()
	return true
end

function AnimalCluster:getRidableFilename()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex)

	return subType.rideableFilename
end

function AnimalCluster:getTranportationFee()
	return g_currentMission.animalSystem:getAnimalTransportFee(self.subTypeIndex, self.age)
end

function AnimalCluster:getSupportsMerging()
	return true
end

function AnimalCluster:merge(otherCluster)
	if math.abs(self.age - otherCluster.age) > 0.5 or math.abs(self.health - otherCluster.health) > 0.5 or math.abs(self.reproduction - otherCluster.reproduction) > 0.5 then
		Logging.warning("Cluster-Collision detected: Merged (Age: %.4f, Health: %.4f, Reproduction: %.4f) with (Age: %.4f, Health: %.4f, Reproduction: %.4f)", self.health, self.age, self.reproduction, otherCluster.health, otherCluster.age, otherCluster.reproduction)
	end

	self.numAnimals = MathUtil.clamp(self.numAnimals + otherCluster.numAnimals, 0, 65535)

	return true
end

function AnimalCluster:getHash()
	local age = self.age
	local health = self.health
	local reproduction = self.reproduction
	local subTypeIndex = self.subTypeIndex
	age = 100 + age
	health = 1000 * (100 + health)
	reproduction = 1000000 * (100 + reproduction)
	subTypeIndex = 1000000000 * (100 + subTypeIndex)

	return age + health + reproduction + subTypeIndex
end

function AnimalCluster:getMergeSupport()
	return true
end

function AnimalCluster:showInfo(box)
	local visual = g_currentMission.animalSystem:getVisualByAge(self.subTypeIndex, self.age)

	box:addLine(g_i18n:getText("infohud_type"), visual.store.name)
	box:addLine(g_i18n:getText("infohud_age"), g_i18n:formatNumMonth(self.age))

	if self.numAnimals > 1 then
		box:addLine(g_i18n:getText("infohud_numAnimals"), tostring(self.numAnimals))
	end

	box:addLine(g_i18n:getText("infohud_health"), string.format("%d %%", self.health))
	box:addLine(g_i18n:getText("infohud_reproduction"), string.format("%d %%", self.reproduction))
end

function AnimalCluster:addInfos(infos)
	local healthFactor = self:getHealthFactor()
	self.infoHealth.value = healthFactor
	self.infoHealth.ratio = healthFactor
	self.infoHealth.valueText = string.format("%d %%", g_i18n:formatNumber(healthFactor * 100, 0))

	table.insert(infos, self.infoHealth)

	if self:getSupportsReproduction() then
		local reproductionFactor = self:getReproductionFactor()
		self.infoReproduction.value = reproductionFactor
		self.infoReproduction.ratio = reproductionFactor
		self.infoReproduction.valueText = string.format("%d %%", g_i18n:formatNumber(reproductionFactor * 100, 0))
		self.infoReproduction.disabled = not self:getCanReproduce()
		self.infoReproduction.title = self.infoReproduction.titleOrg

		if self.infoReproduction.disabled then
			local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
			local attributeText, valueText = nil

			if self.age < subType.reproductionMinAgeMonth then
				attributeText = g_i18n:getText("ui_age")
				valueText = g_i18n:formatNumMonth(subType.reproductionMinAgeMonth)
			else
				attributeText = g_i18n:getText("infohud_health")
				valueText = string.format("%d %%", subType.reproductionMinHealth)
			end

			self.infoReproduction.title = self.infoReproduction.title .. string.format(" (%s < %s)", attributeText, valueText)
		end

		table.insert(infos, self.infoReproduction)
	end
end
