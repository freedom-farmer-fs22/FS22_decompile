AnimalScreen = {
	TRANSPORTATION_FEE = 200,
	SELECTION_NONE = 0,
	SELECTION_SOURCE = 1,
	SELECTION_TARGET = 2,
	CONTROLS = {
		INFO_TOTAL = "infoTotal",
		BALANCE_TITLE = "balanceTitleElement",
		INFO_BOX = "infoBox",
		INFO_ICON = "infoIcon",
		INFO_PRICE_TITLE = "infoPriceTitle",
		INFO_VALUES = "infoValue",
		BUTTON_SELECT = "buttonSelect",
		INFO_TITLE = "infoName",
		HEADER_TARGET = "headerTarget",
		HEADER_SOURCE = "headerSource",
		NUM_ANIMALS = "numAnimalsElement",
		ITEM_TEMPLATE_SOURCE = "itemTemplateSource",
		ITEM_TEMPLATE_TARGET = "itemTemplateTarget",
		BUTTON_APPLY = "buttonApply",
		LIST_TARGET = "listTarget",
		INFO_DESCRIPTION = "infoDescription",
		INFO_PRICE = "infoPrice",
		BALANCE_TEXT = "balanceElement",
		LIST_SOURCE = "listSource",
		INFO_TITLES = "infoTitle",
		INFO_FEE = "infoFee"
	}
}
local AnimalScreen_mt = Class(AnimalScreen, ScreenElement)

function AnimalScreen.new(custom_mt)
	local self = ScreenElement.new(nil, custom_mt or AnimalScreen_mt)

	self:registerControls(AnimalScreen.CONTROLS)

	self.isSourceSelected = true
	self.isOpen = false
	self.lastBalance = 0
	self.selectionState = AnimalScreen.SELECTION_NONE

	return self
end

function AnimalScreen.createFromExistingGui(gui)
	local controller = gui:getController()
	local newGui = AnimalScreen.new()

	newGui:setController(controller)

	return newGui
end

function AnimalScreen:setController(controller)
	self.controller = controller

	self.controller:setAnimalsChangedCallback(self.onAnimalsChanged, self)
	self.controller:setActionTypeCallback(self.onActionTypeChanged, self)
	self.controller:setSourceActionFinishedCallback(self.onSourceActionFinished, self)
	self.controller:setTargetActionFinishedCallback(self.onTargetActionFinished, self)
	self.controller:setErrorCallback(self.onError, self)
end

function AnimalScreen:getController()
	return self.controller
end

function AnimalScreen:onGuiSetupFinished()
	AnimalScreen:superClass().onGuiSetupFinished(self)
	self.numAnimalsElement:setTexts({
		"1"
	})

	local orig = self.listSource.onFocusEnter

	function self.listSource.onFocusEnter(...)
		orig(...)

		return self:onFocusEnterList(true, self.listSource, self.listTarget)
	end

	orig = self.listTarget.onFocusEnter

	function self.listTarget.onFocusEnter(...)
		orig(...)

		return self:onFocusEnterList(false, self.listTarget, self.listSource)
	end
end

function AnimalScreen:onOpen()
	AnimalScreen:superClass().onOpen(self)

	self.isOpen = true
	self.isUpdating = false

	g_gameStateManager:setGameState(GameState.MENU_ANIMAL_SHOP)
	g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	self:updateScreen()
	self:setSelectionState(AnimalScreen.SELECTION_NONE)

	if self.listSource:getItemCount() > 0 then
		FocusManager:setFocus(self.listSource)
	elseif self.listTarget:getItemCount() > 0 then
		FocusManager:setFocus(self.listTarget)
	end
end

function AnimalScreen:onClose(element)
	AnimalScreen:superClass().onClose(self)
	self.controller:reset()

	self.isOpen = false

	g_currentMission:resetGameState()
	g_currentMission:showMoneyChange(MoneyType.NEW_ANIMALS_COST)
	g_currentMission:showMoneyChange(MoneyType.SOLD_ANIMALS)
	g_messageCenter:unsubscribeAll(self)
	g_depthOfFieldManager:popArea()
end

function AnimalScreen:onVehicleLeftTrigger()
	if self.isOpen then
		g_gui:showInfoDialog({
			text = g_i18n:getText(AnimalScreen.SYMBOL_L10N.ERROR_TRAILER_LEFT),
			callback = self.onClickOkVehicleLeft,
			target = self
		})
	end
end

function AnimalScreen:onClickOkVehicleLeft()
	self:onClickBack()
end

function AnimalScreen:setSelectionState(state)
	self.listSource:setDisabled(state ~= AnimalScreen.SELECTION_NONE)
	self.listTarget:setDisabled(state ~= AnimalScreen.SELECTION_NONE)
	self.numAnimalsElement:setDisabled(state == AnimalScreen.SELECTION_NONE)

	for _, element in ipairs(self.listSource.elements) do
		element:getAttribute("highlight"):setVisible(state == AnimalScreen.SELECTION_SOURCE and self.listSource:getSelectedElement() == element)
	end

	for _, element in ipairs(self.listTarget.elements) do
		element:getAttribute("highlight"):setVisible(state == AnimalScreen.SELECTION_TARGET and self.listTarget:getSelectedElement() == element)
	end

	if state ~= AnimalScreen.SELECTION_NONE then
		local maxElements = self.controller:getMaxNumAnimals()

		if state == AnimalScreen.SELECTION_SOURCE then
			self.buttonApply:setText(self.controller:getSourceActionText())

			local animalIndex = self.listSource.selectedIndex
			maxElements = math.max(1, math.min(maxElements, self.controller:getSourceMaxNumAnimals(animalIndex)))
		elseif state == AnimalScreen.SELECTION_TARGET then
			self.buttonApply:setText(self.controller:getTargetActionText())

			local animalIndex = self.listTarget.selectedIndex
			maxElements = math.max(1, math.min(maxElements, self.controller:getTargetMaxNumAnimals(animalIndex)))
		end

		local texts = {}

		for i = 1, maxElements do
			table.insert(texts, tostring(i))
		end

		self.numAnimalsElement:setTexts(texts)
		FocusManager:setFocus(self.numAnimalsElement)
	elseif self.selectionState == AnimalScreen.SELECTION_SOURCE then
		FocusManager:setFocus(self.listSource)
	elseif self.selectionState == AnimalScreen.SELECTION_TARGET then
		FocusManager:setFocus(self.listTarget)
	end

	self.buttonSelect:setVisible(state == AnimalScreen.SELECTION_NONE and (self.listSource:getItemCount() > 0 or self.listTarget:getItemCount() > 0))
	self.buttonApply:setVisible(state ~= AnimalScreen.SELECTION_NONE)

	self.selectionState = state

	self:updatePrice()
end

function AnimalScreen:updateBalanceText()
	local balance = 0

	if g_currentMission ~= nil then
		balance = g_currentMission:getMoney()
	end

	if self.lastBalance ~= balance then
		self.lastBalance = balance

		self.balanceElement:setValue(balance)

		if balance > 0 then
			self.balanceElement:applyProfile(AnimalScreen.PROFILE.POSITIVE_BALANCE)
		else
			self.balanceElement:applyProfile(AnimalScreen.PROFILE.NEGATIVE_BALANCE)
		end
	end
end

function AnimalScreen:updatePrice()
	local hasCosts, price, fee, total = self:getPrice()

	self.infoPrice:setValue(0)
	self.infoFee:setValue(0)
	self.infoTotal:setValue(0)
	self.infoPrice:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoFee:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoTotal:setFormat(hasCosts and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoPrice:setValue(hasCosts and price or "-")
	self.infoFee:setValue(hasCosts and fee or "-")
	self.infoTotal:setValue(hasCosts and total or "-")
end

function AnimalScreen:updateInfoBox(isSourceSelected)
	if isSourceSelected == nil then
		isSourceSelected = self.isSourceSelected
	end

	local item = nil

	if isSourceSelected then
		item = self.controller:getSourceItems()[self.listSource.selectedIndex]
	else
		item = self.controller:getTargetItems()[self.listTarget.selectedIndex]
	end

	self.infoIcon:setVisible(item ~= nil)
	self.infoName:setVisible(item ~= nil)

	if item ~= nil then
		self.infoIcon:setImageFilename(item:getFilename())
		self.infoName:setText(item:getName())
		self.infoDescription:setText(item:getDescription())

		local infos = item:getInfos()

		for k, infoTitle in ipairs(self.infoTitle) do
			local info = infos[k]
			local infoValue = self.infoValue[k]

			infoTitle:setVisible(info ~= nil)
			infoValue:setVisible(info ~= nil)

			if info ~= nil then
				infoTitle:setText(infos[k].title)
				infoValue:setText(infos[k].value)
			end
		end

		self:updatePrice()
	end
end

function AnimalScreen:getPrice()
	local hasCosts, price, fee, total = nil

	if self.isSourceSelected then
		local animalIndex = self.listSource.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()
		hasCosts, price, fee, total = self.controller:getSourcePrice(animalIndex, numAnimals)
	else
		local animalIndex = self.listTarget.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()
		hasCosts, price, fee, total = self.controller:getTargetPrice(animalIndex, numAnimals)
	end

	return hasCosts, price, fee, total
end

function AnimalScreen:updateScreen()
	self:updateBalanceText()
	self.listSource:reloadData()
	self.listTarget:reloadData()
	self.headerSource:setText(self.controller:getSourceName())
	self.headerTarget:setText(self.controller:getTargetName())
	self:updatePrice()
	self:updateInfoBox()
end

function AnimalScreen:onAnimalsChanged()
	if not self.isUpdating then
		self:updateScreen()
	end
end

function AnimalScreen:onActionTypeChanged(actionType, text)
	if text ~= nil then
		g_gui:showMessageDialog({
			visible = true,
			text = text
		})
	else
		g_gui:showMessageDialog({
			visible = false
		})
	end
end

function AnimalScreen:onSourceActionFinished(isWarning, text)
	local msgType = DialogElement.TYPE_INFO

	if isWarning then
		msgType = DialogElement.TYPE_WARNING
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = msgType
	})
	self:setSelectionState(AnimalScreen.SELECTION_NONE)
end

function AnimalScreen:onTargetActionFinished(isWarning, text)
	local msgType = DialogElement.TYPE_INFO

	if isWarning then
		msgType = DialogElement.TYPE_WARNING
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = msgType
	})
	self:setSelectionState(AnimalScreen.SELECTION_NONE)
	self:setSelectionState(AnimalScreen.SELECTION_NONE)
end

function AnimalScreen:onError(text)
	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onSourceListSelectionChanged(list, section, index)
	if not self.isSourceSelected then
		self:onFocusEnterList(true, list, self.listTarget)
	end

	self:updateInfoBox(true)
end

function AnimalScreen:onTargetListSelectionChanged(list, section, index)
	if self.isSourceSelected then
		self:onFocusEnterList(false, list, self.listSource)
	end

	self:updateInfoBox(false)
end

function AnimalScreen:onClickBack()
	AnimalScreen:superClass().onClickBack(self)

	if self.selectionState == AnimalScreen.SELECTION_NONE then
		self:changeScreen(nil)
	else
		self:setSelectionState(AnimalScreen.SELECTION_NONE)
	end
end

function AnimalScreen:onClickSelect()
	if self.isSourceSelected then
		self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
	else
		self:setSelectionState(AnimalScreen.SELECTION_TARGET)
	end

	return true
end

function AnimalScreen:onClickApply()
	if self.selectionState == AnimalScreen.SELECTION_SOURCE then
		local animalIndex = self.listSource.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()
		local text = self.controller:getApplySourceConfirmationText(animalIndex, numAnimals)

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoSource,
			target = self
		})
	elseif self.selectionState == AnimalScreen.SELECTION_TARGET then
		local animalIndex = self.listTarget.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()
		local text = self.controller:getApplyTargetConfirmationText(animalIndex, numAnimals)

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoTarget,
			target = self
		})
	else
		return false
	end

	return true
end

function AnimalScreen:onClickNumAnimals()
	self:updatePrice()
end

function AnimalScreen:onYesNoSource(yes)
	if yes then
		local animalIndex = self.listSource.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()

		self.controller:applySource(animalIndex, numAnimals)
	end
end

function AnimalScreen:onYesNoTarget(yes)
	if yes then
		local animalIndex = self.listTarget.selectedIndex
		local numAnimals = self.numAnimalsElement:getState()

		self.controller:applyTarget(animalIndex, numAnimals)
	end
end

function AnimalScreen:onFocusEnterList(isEnteringSourceList, enteredList, previousList)
	if enteredList:getItemCount() == 0 then
		if previousList:getItemCount() > 0 then
			FocusManager:setFocus(previousList)
		end

		return
	end

	FocusManager:unsetFocus(previousList)

	self.isSourceSelected = isEnteringSourceList

	self:updateInfoBox(isEnteringSourceList)

	if enteredList.selectedIndex == 0 then
		enteredList:setSelectedIndex(1)
	end
end

function AnimalScreen:getNumberOfItemsInSection(list, section)
	if not self.isOpen then
		return 0
	end

	if list == self.listSource then
		return #self.controller:getSourceItems()
	else
		return #self.controller:getTargetItems()
	end
end

function AnimalScreen:populateCellForItemInSection(list, section, index, cell)
	local item = nil

	if list == self.listSource then
		item = self.controller:getSourceItems()[index]
	else
		item = self.controller:getTargetItems()[index]
	end

	cell:getAttribute("icon"):setImageFilename(item:getFilename())
	cell:getAttribute("name"):setText(item:getName())
	cell:getAttribute("price"):setValue(item:getPrice())
	cell:getAttribute("highlight"):setVisible(false)
end

function AnimalScreen:onListSelectionChanged(list, section, index)
	if self.isAutoUpdatingList then
		return
	end

	if list == self.listSource then
		self:onSourceListSelectionChanged(list, section, index)
	else
		self:onTargetListSelectionChanged(list, section, index)
	end
end

function AnimalScreen:onSourceListDoubleClick(list, section, index)
	self:setSelectionState(AnimalScreen.SELECTION_SOURCE)
end

function AnimalScreen:onTargetListDoubleClick(list, section, index)
	self:setSelectionState(AnimalScreen.SELECTION_TARGET)
end

function AnimalScreen:updateChangedList(listElement, fallbackListElement, restoreSelection)
	self.isAutoUpdatingList = true

	listElement:reloadData()

	self.isAutoUpdatingList = false

	if listElement:getItemCount() == 0 then
		FocusManager:setFocus(fallbackListElement)
		fallbackListElement:setSelectedIndex(1)
	end

	self:updateInfoBox()
	self:updatePrice()
end

function AnimalScreen:update(dt)
	AnimalScreen:superClass().update(self, dt)
	self:updateBalanceText()
end

AnimalScreen.PROFILE = {
	LIST_ITEM_NEUTRAL = "shopCategoryItem",
	NEGATIVE_BALANCE = "shopMoneyNeg",
	POSITIVE_BALANCE = "shopMoney"
}
AnimalScreen.SYMBOL_L10N = {
	TEXT_SELL = "button_sell",
	TEXT_LOAD = "button_load",
	TEXT_BUY = "button_buy",
	TEXT_PIECES = "unit_pieces",
	ERROR_TRAILER_LEFT = "animals_transportTargetLeftTrigger",
	TEXT_UNLOAD = "button_unload"
}
