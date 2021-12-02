AnimalItemStock = {}
local AnimalItemStock_mt = Class(AnimalItemStock)

function AnimalItemStock.new(cluster)
	local self = setmetatable({}, AnimalItemStock_mt)
	self.cluster = cluster
	self.visual = g_currentMission.animalSystem:getVisualByAge(cluster.subTypeIndex, cluster:getAge())
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
	self.infos = {
		{
			title = g_i18n:getText("ui_age"),
			value = g_i18n:formatNumMonth(cluster:getAge())
		},
		{
			title = g_i18n:getText("infohud_reproduction"),
			value = g_i18n:formatNumMonth(subType.reproductionDurationMonth)
		},
		{
			title = g_i18n:getText("ui_horseHealth"),
			value = string.format("%.f%%", cluster:getHealthFactor() * 100)
		}
	}

	if cluster.getFitnessFactor ~= nil then
		table.insert(self.infos, {
			title = g_i18n:getText("ui_horseFitness"),
			value = string.format("%.f%%", cluster:getFitnessFactor() * 100)
		})
	end

	if cluster.getRidingFactor ~= nil then
		table.insert(self.infos, {
			title = g_i18n:getText("ui_horseDailyRiding"),
			value = string.format("%.f%%", cluster:getRidingFactor() * 100)
		})
	end

	if cluster.getDirtFactor ~= nil then
		table.insert(self.infos, {
			title = g_i18n:getText("statistic_cleanliness"),
			value = string.format("%.f%%", (1 - cluster:getDirtFactor()) * 100)
		})
	end

	return self
end

function AnimalItemStock:getName()
	if self.cluster.getName ~= nil then
		return self.cluster:getName()
	end

	return self.visual.store.name
end

function AnimalItemStock:getPrice()
	return self.cluster:getSellPrice()
end

function AnimalItemStock:getTranportationFee(numItems)
	return self.cluster:getTranportationFee(numItems)
end

function AnimalItemStock:getDescription()
	return self.visual.store.description
end

function AnimalItemStock:getFilename()
	return self.visual.store.imageFilename
end

function AnimalItemStock:getPrice()
	return self.cluster:getSellPrice()
end

function AnimalItemStock:getSubTypeIndex()
	return self.cluster:getSubTypeIndex()
end

function AnimalItemStock:getInfos()
	return self.infos
end

function AnimalItemStock:getNumAnimals()
	return self.cluster:getNumAnimals()
end

function AnimalItemStock:getClusterId()
	return self.cluster.id
end

function AnimalItemStock:getCluster()
	return self.cluster
end

function AnimalItemStock:getCanBeSold()
	return self.cluster:getCanBeSold()
end
