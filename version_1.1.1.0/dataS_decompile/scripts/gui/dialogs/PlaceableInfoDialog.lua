PlaceableInfoDialog = {
	CONTROLS = {
		"icon",
		"titleText",
		"priceText",
		"ageText",
		"sellButton",
		"renameButton"
	}
}
local PlaceableInfoDialog_mt = Class(PlaceableInfoDialog, DialogElement)

function PlaceableInfoDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or PlaceableInfoDialog_mt)

	self:registerControls(PlaceableInfoDialog.CONTROLS)

	self.inputDelay = 0

	return self
end

function PlaceableInfoDialog:onOpen()
	PlaceableInfoDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250
end

function PlaceableInfoDialog:onClose()
	g_messageCenter:unsubscribe(SellPlaceableEvent, self)
	PlaceableInfoDialog:superClass().onClose(self)
end

function PlaceableInfoDialog:setPlaceable(placeable)
	local name = placeable:getName()
	local sellPrice = g_i18n:formatMoney(placeable:getSellPrice())
	local canRename = placeable:getCanBeRenamedByFarm(g_currentMission:getFarmId())
	local imageFilename = placeable.storeItem.imageFilename
	local canSell = placeable:canBeSold() and placeable.storeItem.canBeSold and g_currentMission:getFarmId() == placeable:getOwnerFarmId()
	local allowedToSell = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
	self.placeable = placeable

	if imageFilename ~= nil then
		self.icon:setImageFilename(imageFilename)
	else
		self.icon:setVisible(false)
	end

	self.titleText:setText(name)
	self.priceText:setText(sellPrice)
	self.ageText:setText(string.format(g_i18n:getText("shop_age"), string.format("%d", placeable.age)))
	self.renameButton:setVisible(canRename)
	self.sellButton:setVisible(canSell)
	self.sellButton:setDisabled(not allowedToSell)
	self.sellButton.parent:invalidateLayout()
	g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
end

function PlaceableInfoDialog:setCallback(callbackFunc, target, args)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = args
end

function PlaceableInfoDialog:onClickBack()
	if self.inputDelay < self.time then
		self:sendCallback(false)
		self:close()

		return false
	else
		return true
	end
end

function PlaceableInfoDialog:sendCallback(didSell)
	g_messageCenter:unsubscribe(SellPlaceableEvent, self)

	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, didSell, self.callbackArgs)
		else
			self.callbackFunc(didSell, self.callbackArgs)
		end
	end
end

function PlaceableInfoDialog:onClickSell()
	local price = g_currentMission.economyManager:getSellPrice(self.placeable)

	g_gui:showYesNoDialog({
		text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), self.placeable:getName(), g_i18n:formatMoney(price, 0, true, true)),
		callback = function (yes)
			if yes then
				g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.placeable))
			end
		end
	})
end

function PlaceableInfoDialog:onClickRename()
	local text = g_i18n:getText("button_changeName")

	g_gui:showTextInputDialog({
		text = text,
		defaultText = self.placeable:getName(),
		callback = function (result, yes)
			if yes then
				if result:len() == 0 then
					result = nil
				end

				self.placeable:setName(result)
				g_messageCenter:unsubscribe(SellPlaceableEvent, self)
				self:setPlaceable(self.placeable)
			end
		end,
		dialogPrompt = g_i18n:getText("ui_enterName"),
		imePrompt = g_i18n:getText("ui_enterName"),
		confirmText = g_i18n:getText("button_change")
	})
end

function PlaceableInfoDialog:onPlaceableDestroyed()
	self:sendCallback(true)
	self:close()
end
