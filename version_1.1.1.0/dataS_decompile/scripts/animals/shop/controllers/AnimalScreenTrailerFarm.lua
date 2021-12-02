AnimalScreenTrailerFarm = {}
local AnimalScreenTrailerFarm_mt = Class(AnimalScreenTrailerFarm, AnimalScreenBase)

function AnimalScreenTrailerFarm.new(husbandry, trailer, customMt)
	local self = AnimalScreenBase.new(customMt or AnimalScreenTrailerFarm_mt)
	self.husbandry = husbandry
	self.trailer = trailer

	return self
end

function AnimalScreenTrailerFarm:initSourceItems()
	self.sourceItems = {}
	local clusters = self.trailer:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.sourceItems, item)
		end
	end
end

function AnimalScreenTrailerFarm:initTargetItems()
	self.targetItems = {}
	local clusters = self.husbandry:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.targetItems, item)
		end
	end
end

function AnimalScreenTrailerFarm:getSourceName()
	local name = self.trailer:getName()
	local currentAnimalType = self.trailer:getCurrentAnimalType()

	if currentAnimalType == nil then
		return name
	end

	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenTrailerFarm:getTargetName()
	local name = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.FARM)
	local used = self.husbandry:getNumOfAnimals()
	local total = self.husbandry:getMaxNumOfAnimals()

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenTrailerFarm:getSourceActionText()
	return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)
end

function AnimalScreenTrailerFarm:getTargetActionText()
	return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)
end

function AnimalScreenTrailerFarm:getApplySourceConfirmationText(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_FARM)
	local item = self.sourceItems[itemIndex]

	return string.format(text, numItems, item:getName())
end

function AnimalScreenTrailerFarm:getApplyTargetConfirmationText(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
	local item = self.targetItems[itemIndex]

	return string.format(text, numItems, item:getName())
end

function AnimalScreenTrailerFarm:getSourcePrice(itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailerFarm:getTargetPrice(itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailerFarm:getSourceMaxNumAnimals(itemIndex)
	local item = self.sourceItems[itemIndex]
	local maxNumAnimals = self:getMaxNumAnimals()

	return math.min(maxNumAnimals, item:getNumAnimals(), self.husbandry:getNumOfFreeAnimalSlots())
end

function AnimalScreenTrailerFarm:getTargetMaxNumAnimals(itemIndex)
	local item = self.targetItems[itemIndex]
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
	local animalType = animalSystem:getTypeByIndex(subType.typeIndex)
	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(animalType)
	local free = total - used
	local maxNumAnimals = self:getMaxNumAnimals()

	return math.min(maxNumAnimals, free, item:getNumAnimals())
end

function AnimalScreenTrailerFarm:applySource(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local clusterId = item:getClusterId()
	local errorCode = AnimalMoveEvent.validate(self.trailer, self.husbandry, clusterId, numItems, self.trailer:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, text)
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToFarm, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.trailer, self.husbandry, clusterId, numItems))

	return true
end

function AnimalScreenTrailerFarm:onAnimalMovedToFarm(errorCode)
	g_messageCenter:unsubscribe(AnimalMoveEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode]

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenTrailerFarm:applyTarget(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local clusterId = item:getClusterId()
	local errorCode = AnimalMoveEvent.validate(self.husbandry, self.trailer, clusterId, numItems, self.trailer:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, text)
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.husbandry, self.trailer, clusterId, numItems))

	return true
end

function AnimalScreenTrailerFarm:onAnimalMovedToTrailer(errorCode)
	g_messageCenter:unsubscribe(AnimalMoveEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode]

	self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenTrailerFarm:onAnimalsChanged(obj, clusters)
	if obj == self.trailer or obj == self.husbandry then
		self:initItems()
		self.animalsChangedCallback()
	end
end

AnimalScreenTrailerFarm.L10N_SYMBOL = {
	FARM = "ui_farm",
	CONFIRM_MOVE_TO_TRAILER = "shop_doYouWantToMoveAnimalsToTrailer",
	MOVE_TO_FARM = "shop_moveToFarm",
	CONFIRM_MOVE_TO_FARM = "shop_doYouWantToMoveAnimalsToFarm",
	MOVE_TO_TRAILER = "shop_moveToTrailer"
}
AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING = {
	[AnimalMoveEvent.MOVE_SUCCESS] = {
		text = "shop_movedToTrailer",
		warning = false
	},
	[AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageHusbandryDoesNotExist",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageTrailerDoesNotExist",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
		text = "shop_messageInvalidCluster",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
		text = "shop_messageAnimalTypeNotSupportedByTrailer",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
		text = "shop_messageNotEnoughSpaceAnimalsTrailer",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
		text = "shop_messageNotEnoughAnimals",
		warning = true
	}
}
AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING = {
	[AnimalMoveEvent.MOVE_SUCCESS] = {
		text = "shop_movedToFarm",
		warning = false
	},
	[AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageTrailerDoesNotExist",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageHusbandryDoesNotExist",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
		text = "shop_messageInvalidCluster",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
		text = "shop_messageAnimalTypeNotSupported",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
		text = "shop_messageNotEnoughSpaceAnimals",
		warning = true
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
		text = "shop_messageNotEnoughAnimals",
		warning = true
	}
}
