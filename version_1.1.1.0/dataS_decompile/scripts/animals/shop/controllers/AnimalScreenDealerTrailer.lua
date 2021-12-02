AnimalScreenDealerTrailer = {}
local AnimalScreenDealerTrailer_mt = Class(AnimalScreenDealerTrailer, AnimalScreenBase)

function AnimalScreenDealerTrailer.new(trailer, customMt)
	local self = AnimalScreenBase.new(customMt or AnimalScreenDealerTrailer_mt)
	self.trailer = trailer
	self.sourceActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUY)
	self.targetActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELL)
	self.sourceTitle = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.DEALER)

	return self
end

function AnimalScreenDealerTrailer:initSourceItems()
	self.sourceItems = {}
	local currentAnimalType = self.trailer:getCurrentAnimalType()
	local animalTypes = g_currentMission.animalSystem:getTypes()

	for _, animalType in ipairs(animalTypes) do
		if (currentAnimalType == nil or animalType == currentAnimalType) and self.trailer:getSupportsAnimalType(animalType.typeIndex) then
			for _, subTypeIndex in ipairs(animalType.subTypes) do
				local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)

				for _, visual in ipairs(subType.visuals) do
					if visual.store.canBeBought then
						local item = AnimalItemNew.new(subType.subTypeIndex, visual.minAge)

						table.insert(self.sourceItems, item)
					end
				end
			end
		end
	end
end

function AnimalScreenDealerTrailer:initTargetItems()
	self.targetItems = {}
	local clusters = self.trailer:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.targetItems, item)
		end
	end
end

function AnimalScreenDealerTrailer:getTargetName()
	local name = self.trailer:getName()
	local currentAnimalType = self.trailer:getCurrentAnimalType()

	if currentAnimalType == nil then
		return name
	end

	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenDealerTrailer:getSourcePrice(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local singlePrice = -item:getPrice()
	local buyPrice = singlePrice * numItems

	return true, buyPrice, 0, buyPrice
end

function AnimalScreenDealerTrailer:getTargetPrice(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local singlePrice = item:getPrice()
	local sellPrice = singlePrice * numItems

	return true, sellPrice, 0, sellPrice
end

function AnimalScreenDealerTrailer:getSourceMaxNumAnimals(itemIndex)
	local item = self.sourceItems[itemIndex]
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(item:getSubTypeIndex())
	local animalType = animalSystem:getTypeByIndex(subType.typeIndex)
	local used = self.trailer:getNumOfAnimals()
	local total = self.trailer:getMaxNumOfAnimals(animalType)
	local free = total - used
	local maxNumAnimals = self:getMaxNumAnimals()

	return math.min(maxNumAnimals, free)
end

function AnimalScreenDealerTrailer:getTargetMaxNumAnimals(itemIndex)
	local item = self.targetItems[itemIndex]

	return item:getNumAnimals()
end

function AnimalScreenDealerTrailer:getApplySourceConfirmationText(itemIndex, numItems)
	local _, _, _, totalPrice = self:getSourcePrice(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_BUY)
	local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
	local item = self.sourceItems[itemIndex]

	return string.format(text, numItems, item:getName(), price)
end

function AnimalScreenDealerTrailer:getApplyTargetConfirmationText(itemIndex, numItems)
	local _, _, _, totalPrice = self:getTargetPrice(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_SELL)
	local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
	local item = self.targetItems[itemIndex]

	return string.format(text, numItems, item:getName(), price)
end

function AnimalScreenDealerTrailer:applySource(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local subTypeIndex = item:getSubTypeIndex()
	local age = item:getAge()
	local singlePrice = -item:getPrice()
	local buyPrice = singlePrice * numItems
	local errorCode = AnimalBuyEvent.validate(self.trailer, subTypeIndex, age, numItems, buyPrice, 0, self.trailer:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUYING)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, text)
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.trailer, subTypeIndex, age, numItems, buyPrice, 0))

	return true
end

function AnimalScreenDealerTrailer:onAnimalBought(errorCode)
	g_messageCenter:unsubscribe(AnimalBuyEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenDealerTrailer:applyTarget(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local singlePrice = item:getPrice()
	local sellPrice = singlePrice * numItems
	local clusterId = item:getClusterId()
	local errorCode = AnimalSellEvent.validate(self.trailer, clusterId, numItems, sellPrice, 0)

	if errorCode ~= nil then
		local data = AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELLING)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, text)
	g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.trailer, clusterId, numItems, sellPrice, 0))

	return true
end

function AnimalScreenDealerTrailer:onAnimalSold(errorCode)
	g_messageCenter:unsubscribe(AnimalSellEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[errorCode]

	self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenDealerTrailer:onAnimalsChanged(trailer, clusters)
	if trailer == self.trailer then
		self:initItems()
		self.animalsChangedCallback()
	end
end

AnimalScreenDealerTrailer.L10N_SYMBOL = {
	CONFIRM_SELL = "shop_doYouWantToSellAnimals",
	BUY = "button_buy",
	CONFIRM_BUY = "shop_doYouWantToBuyAnimals",
	DEALER = "animals_dealer",
	SELLING = "shop_messageSellingAnimals",
	SELL = "button_sell",
	BUYING = "shop_messageBuyingAnimals"
}
AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING = {
	[AnimalBuyEvent.BUY_SUCCESS] = {
		text = "shop_messageBoughtAnimals",
		warning = false
	},
	[AnimalBuyEvent.BUY_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY] = {
		text = "shop_messageNotEnoughMoneyToBuy",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE] = {
		text = "shop_messageNotEnoughSpaceAnimalsTrailer",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
		text = "shop_messageAnimalTypeNotSupportedByTrailer",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
		text = "shop_messageAnimalGlobalLimitReached",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageTrailerDoesNotExist",
		warning = true
	}
}
AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING = {
	[AnimalSellEvent.SELL_SUCCESS] = {
		text = "shop_messageSoldAnimals",
		warning = false
	},
	[AnimalSellEvent.SELL_ERROR_NO_PERMISSION] = {
		text = "shop_messageNoPermissionToTradeAnimals",
		warning = true
	},
	[AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER] = {
		text = "shop_messageInvalidCluster",
		warning = true
	},
	[AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS] = {
		text = "shop_messageNotEnoughAnimals",
		warning = true
	},
	[AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD] = {
		text = "shop_messageCannotSellAnimal",
		warning = true
	},
	[AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageTrailerDoesNotExist",
		warning = true
	}
}
