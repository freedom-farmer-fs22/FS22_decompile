AnimalScreenTrailer = {}
local AnimalScreenTrailer_mt = Class(AnimalScreenTrailer, AnimalScreenBase)

function AnimalScreenTrailer.new(trailer, customMt)
	local self = AnimalScreenBase.new(customMt or AnimalScreenTrailer_mt)
	self.trailer = trailer

	self.trailer:setAnimalScreenController(self)

	return self
end

function AnimalScreenTrailer:reset()
	self.trailer:setAnimalScreenController(nil)
	AnimalScreenTrailer:superClass().reset(self)
end

function AnimalScreenTrailer:initSourceItems()
	self.sourceItems = {}
	local clusters = self.trailer:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.sourceItems, item)
		end
	end
end

function AnimalScreenTrailer:initTargetItems()
	self.targetItems = {}
	self.clusterToVehicle = {}
	local rideables = self.trailer:getRideablesInTrigger()

	if rideables ~= nil then
		for _, rideable in ipairs(rideables) do
			local cluster = rideable:getCluster()
			local item = AnimalItemStock.new(cluster)

			table.insert(self.targetItems, item)

			self.clusterToVehicle[cluster] = rideable
		end
	end
end

function AnimalScreenTrailer:getSourceName()
	local name = self.trailer:getName()
	local currentAnimalType = self.trailer:getCurrentAnimalType()

	if currentAnimalType == nil then
		return name
	end

	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenTrailer:getTargetName()
	return ""
end

function AnimalScreenTrailer:getSourceActionText()
	return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)
end

function AnimalScreenTrailer:getTargetActionText()
	return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)
end

function AnimalScreenTrailer:getApplySourceConfirmationText(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_SPAWN_PLACE)
	local item = self.sourceItems[itemIndex]

	return string.format(text, item:getName())
end

function AnimalScreenTrailer:getApplyTargetConfirmationText(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
	local item = self.targetItems[itemIndex]

	return string.format(text, item:getName())
end

function AnimalScreenTrailer:getSourcePrice(itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailer:getTargetPrice(itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailer:getSourceMaxNumAnimals(itemIndex)
	return 1
end

function AnimalScreenTrailer:getTargetMaxNumAnimals(itemIndex)
	return 1
end

function AnimalScreenTrailer:applySource(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local clusterId = item:getClusterId()
	local errorCode = AnimalUnloadEvent.validate(self.trailer, clusterId)

	if errorCode ~= nil then
		local data = AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, text)
	g_messageCenter:subscribe(AnimalUnloadEvent, self.onAnimalMovedToSpawnPlace, self)
	g_client:getServerConnection():sendEvent(AnimalUnloadEvent.new(self.trailer, clusterId))

	return true
end

function AnimalScreenTrailer:onAnimalMovedToSpawnPlace(errorCode)
	g_messageCenter:unsubscribe(AnimalUnloadEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[errorCode]

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenTrailer:applyTarget(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local cluster = item:getCluster()
	local rideable = self.clusterToVehicle[cluster]
	local errorCode = AnimalLoadEvent.validate(self.trailer, rideable, self.trailer:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, text)
	g_messageCenter:subscribe(AnimalLoadEvent, self.onAnimalLoadedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalLoadEvent.new(self.trailer, rideable))

	return true
end

function AnimalScreenTrailer:onAnimalLoadedToTrailer(errorCode)
	g_messageCenter:unsubscribe(AnimalLoadEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[errorCode]

	self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenTrailer:onAnimalsChanged(obj, clusters)
	if obj == self.trailer then
		self:initItems()
		self.animalsChangedCallback()
	end
end

AnimalScreenTrailer.L10N_SYMBOL = {
	CONFIRM_MOVE_TO_SPAWN_PLACE = "shop_doYouWantToMoveAnimalToSpawnPlace",
	MOVE_TO_TRAILER = "shop_moveToTrailer",
	CONFIRM_MOVE_TO_TRAILER = "shop_doYouWantToMoveAnimalToTrailer",
	MOVE_TO_SPAWN_PLACE = "shop_moveToSpawnPlace"
}
AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING = {
	[AnimalLoadEvent.LOAD_SUCCESS] = {
		text = "shop_movedToTrailer",
		warning = false
	},
	[AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST] = {
		text = "shop_messageTrailerDoesNotExist",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST] = {
		text = "shop_messageRideableDoesNotExist",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER] = {
		text = "shop_messageInvalidCluster",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED] = {
		text = "shop_messageAnimalTypeNotSupportedByTrailer",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
		text = "shop_messageNotEnoughAnimals",
		warning = true
	},
	[AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE] = {
		text = "shop_messageNotEnoughSpaceAnimalsTrailer",
		warning = true
	}
}
AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING = {
	[AnimalUnloadEvent.UNLOAD_SUCCESS] = {
		text = "shop_movedToSpawnPlace",
		warning = false
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER] = {
		text = "shop_messageInvalidCluster",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED] = {
		text = "shop_messageAnimalCouldNotBeUnloaded",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING] = {
		text = "shop_messageAnimalDoesNotSupportUnloading",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE] = {
		text = "shop_messageNotEnoughSpaceAnimalsArea",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
		text = "shop_messageNotEnoughAnimals",
		warning = true
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED] = {
		text = "shop_messageAnimalRideableLimitReached",
		warning = true
	}
}
