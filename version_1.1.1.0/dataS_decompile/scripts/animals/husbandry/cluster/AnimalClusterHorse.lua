AnimalClusterHorse = {}
local AnimalClusterHorse_mt = Class(AnimalClusterHorse, AnimalCluster)
AnimalClusterHorse.NUM_BITS_FITNESS = 7
AnimalClusterHorse.NUM_BITS_RIDING = 7
AnimalClusterHorse.NUM_BITS_DIRT = 7
AnimalClusterHorse.DAILY_RIDING_TIME = 300000
AnimalClusterHorse.BRUSH_DELTA = -20

function AnimalClusterHorse.new(customMt)
	local self = AnimalCluster.new(customMt or AnimalClusterHorse_mt)
	self.fitness = 0
	self.riding = 0
	self.dirt = 0
	self.name = g_currentMission.animalNameSystem:getRandomName()
	self.infoCleanliness = {
		text = "",
		title = g_i18n:getText("statistic_cleanliness")
	}
	self.infoFitness = {
		text = "",
		title = g_i18n:getText("ui_horseFitness")
	}
	self.infoRiding = {
		text = "",
		title = g_i18n:getText("ui_horseDailyRiding")
	}

	return self
end

function AnimalClusterHorse:saveToXMLFile(xmlFile, key, usedModNames)
	AnimalClusterHorse:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	xmlFile:setString(key .. "#name", self.name)
	xmlFile:setInt(key .. "#fitness", self.fitness)
	xmlFile:setInt(key .. "#riding", self.riding)
	xmlFile:setInt(key .. "#dirt", self.dirt)
end

function AnimalClusterHorse:loadFromXMLFile(xmlFile, key)
	if not AnimalClusterHorse:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	self.fitness = MathUtil.clamp(xmlFile:getInt(key .. "#fitness", self.fitness), 0, 100)
	self.name = xmlFile:getString(key .. "#name", self.name)
	self.riding = MathUtil.clamp(xmlFile:getInt(key .. "#riding", self.riding), 0, 100)
	self.dirt = MathUtil.clamp(xmlFile:getInt(key .. "#dirt", self.dirt), 0, 100)

	return true
end

function AnimalClusterHorse:readStream(streamId, connection)
	AnimalClusterHorse:superClass().readStream(self, streamId, connection)

	self.name = streamReadString(streamId)
	self.fitness = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_FITNESS)
	self.riding = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_RIDING)
	self.dirt = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:writeStream(streamId, connection)
	AnimalClusterHorse:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, self.name)
	streamWriteUIntN(streamId, math.floor(self.fitness), AnimalClusterHorse.NUM_BITS_FITNESS)
	streamWriteUIntN(streamId, math.floor(self.riding), AnimalClusterHorse.NUM_BITS_RIDING)
	streamWriteUIntN(streamId, math.floor(self.dirt), AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:readUpdateStream(streamId, connection)
	AnimalClusterHorse:superClass().readUpdateStream(self, streamId, connection)

	self.fitness = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_FITNESS)
	self.riding = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_RIDING)
	self.dirt = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:writeUpdateStream(streamId, connection)
	AnimalClusterHorse:superClass().writeUpdateStream(self, streamId, connection)
	streamWriteUIntN(streamId, math.floor(self.fitness), AnimalClusterHorse.NUM_BITS_FITNESS)
	streamWriteUIntN(streamId, math.floor(self.riding), AnimalClusterHorse.NUM_BITS_RIDING)
	streamWriteUIntN(streamId, math.floor(self.dirt), AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:clone()
	local ret = AnimalClusterHorse:superClass().clone(self)
	ret.fitness = self.fitness
	ret.name = self.name
	ret.riding = self.riding
	ret.dirt = self.dirt

	return ret
end

function AnimalClusterHorse:onDayChanged()
	AnimalClusterHorse:superClass().onDayChanged(self)

	local ridingFactor = self:getRidingFactor()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	local minRidingFactor = subType.ridingThresholdFactor
	local factor, delta = nil

	if minRidingFactor < ridingFactor then
		factor = (ridingFactor - minRidingFactor) / (1 - minRidingFactor)
		delta = 25
	else
		factor = ridingFactor / minRidingFactor - 1
		delta = 10
	end

	local deltaFitness = delta * factor * g_currentMission.environment.timeAdjustment

	self:changeFitness(deltaFitness)
	self:resetRiding()
	self:changeDirt(10)
end

function AnimalClusterHorse:getName()
	return self.name
end

function AnimalClusterHorse:getHealthChangeFactor(foodFactor)
	local cleanlinessFactor = 1 - self:getDirtFactor()
	local fitnessFactor = self:getFitnessFactor()

	return 0.5 * foodFactor + 0.4 * fitnessFactor + 0.1 * cleanlinessFactor
end

function AnimalClusterHorse:setName(name)
	self.name = name
end

function AnimalClusterHorse:getFitnessFactor()
	return self.fitness / 100
end

function AnimalClusterHorse:changeFitness(delta)
	local old = self.fitness
	self.fitness = MathUtil.clamp(math.floor(self.fitness + delta), 0, 100)

	if math.abs(self.fitness - old) > 0 then
		self:setDirty()
	end
end

function AnimalClusterHorse:getRidingFactor()
	return self.riding / 100
end

function AnimalClusterHorse:setRiding(riding)
	self.riding = riding
end

function AnimalClusterHorse:resetRiding()
	self.riding = 0

	self:setDirty()
end

function AnimalClusterHorse:changeRiding(delta)
	local old = self.riding
	self.riding = MathUtil.clamp(math.floor(self.riding + delta), 0, 100)

	if math.abs(self.riding - old) > 0 then
		self:setDirty()
	end
end

function AnimalClusterHorse:getDirtFactor()
	return self.dirt / 100
end

function AnimalClusterHorse:changeDirt(delta)
	local old = self.dirt
	self.dirt = MathUtil.clamp(math.floor(self.dirt + delta), 0, 100)

	if math.abs(self.dirt - old) > 0 then
		self:setDirty()
	end
end

function AnimalClusterHorse:getSellPrice()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	local sellPrice = subType.sellPrice:get(self.age)
	local healthFactor = self:getHealthFactor()
	local fitnessFactor = self:getFitnessFactor()

	return sellPrice * (0.3 + 0.5 * healthFactor + 0.2 * fitnessFactor)
end

function AnimalClusterHorse:getDailyRidingTime()
	return AnimalClusterHorse.DAILY_RIDING_TIME
end

function AnimalClusterHorse:getSupportsMerging()
	return false
end

function AnimalClusterHorse:getHash()
	local hash = AnimalClusterHorse:superClass().getHash(self)
	local fitness = 1000000000000.0 * (100 + self.fitness)
	local dirt = 1000000000000000.0 * (100 + self.dirt)
	local riding = 1e+18 * (100 + self.riding)

	return hash + fitness + dirt + riding
end

function AnimalClusterHorse:showInfo(box)
	box:addLine(g_i18n:getText("infohud_name"), self.name)
	AnimalClusterHorse:superClass().showInfo(self, box)
	box:addLine(g_i18n:getText("infohud_riding"), string.format("%d %%", self.riding))
	box:addLine(g_i18n:getText("infohud_fitness"), string.format("%d %%", self.fitness))
	box:addLine(g_i18n:getText("statistic_cleanliness"), string.format("%d %%", 100 - self.dirt))
end

function AnimalClusterHorse:addInfos(infos)
	AnimalClusterHorse:superClass().addInfos(self, infos)

	local cleanlinessFactor = 1 - self:getDirtFactor()
	self.infoCleanliness.value = cleanlinessFactor
	self.infoCleanliness.ratio = cleanlinessFactor
	self.infoCleanliness.valueText = string.format("%d %%", g_i18n:formatNumber(cleanlinessFactor * 100, 0))

	table.insert(infos, self.infoCleanliness)

	local fitnessFactor = self:getFitnessFactor()
	self.infoFitness.value = fitnessFactor
	self.infoFitness.ratio = fitnessFactor
	self.infoFitness.valueText = string.format("%d %%", g_i18n:formatNumber(fitnessFactor * 100, 0))

	table.insert(infos, self.infoFitness)

	local ridingFactor = self:getRidingFactor()
	self.infoRiding.value = ridingFactor
	self.infoRiding.ratio = ridingFactor
	self.infoRiding.valueText = string.format("%d %%", g_i18n:formatNumber(ridingFactor * 100, 0))

	table.insert(infos, self.infoRiding)
end
