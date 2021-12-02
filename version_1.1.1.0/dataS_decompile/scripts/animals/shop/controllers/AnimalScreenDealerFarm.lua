AnimalScreenDealerFarm = {}
local AnimalScreenDealerFarm_mt = Class(AnimalScreenDealerFarm, AnimalScreenBase)

function AnimalScreenDealerFarm.new(husbandry, customMt)
	local self = AnimalScreenBase.new(customMt or AnimalScreenDealerFarm_mt)
	self.husbandry = husbandry
	self.sourceActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUY)
	self.targetActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELL)
	self.sourceTitle = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.DEALER)

	return self
end

function AnimalScreenDealerFarm:initSourceItems()
	self.sourceItems = {}
	local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
	local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)

	if animalType ~= nil then
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

function AnimalScreenDealerFarm:initTargetItems()
	self.targetItems = {}
	local clusters = self.husbandry:getClusters()

	if clusters ~= nil then
		for _, cluster in ipairs(clusters) do
			local item = AnimalItemStock.new(cluster)

			table.insert(self.targetItems, item)
		end
	end
end

function AnimalScreenDealerFarm:getTargetName()
	local name = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.FARM)
	local used = self.husbandry:getNumOfAnimals()
	local total = self.husbandry:getMaxNumOfAnimals()

	return string.format("%s (%d / %d)", name, used, total)
end

function AnimalScreenDealerFarm:applySource(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local subTypeIndex = item:getSubTypeIndex()
	local age = item:getAge()
	local singlePrice = -item:getPrice()
	local transportFee = -item:getTranportationFee(numItems)
	local buyPrice = singlePrice * numItems
	local errorCode = AnimalBuyEvent.validate(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee, self.husbandry:getOwnerFarmId())

	if errorCode ~= nil then
		local data = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, text)
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee))

	return true
end

function AnimalScreenDealerFarm:onAnimalBought(errorCode)
	g_messageCenter:unsubscribe(AnimalBuyEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]

	self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenDealerFarm:applyTarget(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local singlePrice = item:getPrice()
	local feePrice = -item:getTranportationFee(numItems)
	local sellPrice = singlePrice * numItems
	local clusterId = item:getClusterId()
	local errorCode = AnimalSellEvent.validate(self.husbandry, clusterId, numItems, sellPrice, feePrice)

	if errorCode ~= nil then
		local data = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]

		self.errorCallback(g_i18n:getText(data.text))

		return false
	end

	local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELLING)

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, text)
	g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.husbandry, clusterId, numItems, sellPrice, feePrice))

	return true
end

function AnimalScreenDealerFarm:onAnimalSold(errorCode)
	g_messageCenter:unsubscribe(AnimalSellEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)

	local data = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]

	self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end

function AnimalScreenDealerFarm:getSourcePrice(itemIndex, numItems)
	local item = self.sourceItems[itemIndex]
	local singlePrice = -item:getPrice()
	local transportFee = -item:getTranportationFee(numItems)
	local buyPrice = singlePrice * numItems

	return true, buyPrice, transportFee, buyPrice + transportFee
end

function AnimalScreenDealerFarm:getTargetPrice(itemIndex, numItems)
	local item = self.targetItems[itemIndex]
	local singlePrice = item:getPrice()
	local transportFee = -item:getTranportationFee(numItems)
	local sellPrice = singlePrice * numItems

	return true, sellPrice, transportFee, sellPrice + transportFee
end

function AnimalScreenDealerFarm:getApplySourceConfirmationText(itemIndex, numItems)
	local _, _, _, totalPrice = self:getSourcePrice(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_BUY)
	local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
	local item = self.sourceItems[itemIndex]

	return string.format(text, numItems, item:getName(), price)
end

function AnimalScreenDealerFarm:getApplyTargetConfirmationText(itemIndex, numItems)
	local _, _, _, totalPrice = self:getTargetPrice(itemIndex, numItems)
	local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_SELL)
	local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
	local item = self.targetItems[itemIndex]

	return string.format(text, numItems, item:getName(), price)
end

function AnimalScreenDealerFarm:getSourceMaxNumAnimals(itemIndex)
	local maxNumAnimals = self:getMaxNumAnimals()

	return math.min(maxNumAnimals, self.husbandry:getNumOfFreeAnimalSlots())
end

function AnimalScreenDealerFarm:getTargetMaxNumAnimals(itemIndex)
	local item = self.targetItems[itemIndex]

	return item:getNumAnimals()
end

function AnimalScreenDealerFarm:onAnimalsChanged(husbandry, clusters)
	if husbandry == self.husbandry then
		self:initItems()
		self.animalsChangedCallback()
	end
end

AnimalScreenDealerFarm.L10N_SYMBOL = {
	FARM = "ui_farm",
	BUY = "button_buy",
	CONFIRM_BUY = "shop_doYouWantToBuyAnimals",
	DEALER = "animals_dealer",
	SELLING = "shop_messageSellingAnimals",
	CONFIRM_SELL = "shop_doYouWantToSellAnimals",
	SELL = "button_sell",
	BUYING = "shop_messageBuyingAnimals"
}
AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING = {
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
		text = "shop_messageNotEnoughSpaceAnimals",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
		text = "shop_messageAnimalTypeNotSupported",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
		text = "shop_messageAnimalGlobalLimitReached",
		warning = true
	},
	[AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
		text = "shop_messageHusbandryDoesNotExist",
		warning = true
	}
}
AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING = {
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
		text = "shop_messageHusbandryDoesNotExist",
		warning = true
	}
}
