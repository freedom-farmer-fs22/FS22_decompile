RefillDialog = {
	CONTROLS = {
		FILL_TYPES_ELEMENT = "fillTypesElement",
		FILL_AMOUNT_TEXT = "fillAmountText",
		MESSAGE_BACKGROUND = "messageBackground",
		FILL_TYPE_TEXT = "fillTypeText",
		FILL_AMOUNTS_ELEMENT = "fillAmountsElement",
		FILL_TYPE_ICON = "fillTypeIcon"
	}
}
local RefillDialog_mt = Class(RefillDialog, YesNoDialog)
RefillDialog.FILL_AMOUNTS = {
	1,
	2,
	5,
	10,
	20,
	50,
	100,
	200,
	500,
	1000,
	2000,
	5000,
	10000,
	50000,
	100000
}

function RefillDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or RefillDialog_mt)
	self.selectedFillAmount = nil
	self.fillTypeAmountMapping = {}
	self.amountMapping = {}
	self.priceMapping = {}
	self.selectedPrice = 0
	self.priceFactor = 2
	self.fillTypeMapping = {}
	self.selectedFillType = nil
	self.lastSelectedFillType = nil
	self.areButtonsDisabled = false

	self:registerControls(RefillDialog.CONTROLS)

	return self
end

function RefillDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	else
		local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)
		local amount = self.selectedFillAmount
		local price = self.selectedPrice
		local formattedPrice = g_i18n:formatMoney(price)
		local text = string.format(g_i18n:getText("ui_buyProductAmount"), amount, fillType.title, formattedPrice)

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onBuyYesNo,
			target = self
		})

		return false
	end
end

function RefillDialog:onBuyYesNo(yes)
	if yes then
		local enoughMoney = self.selectedPrice <= g_currentMission:getMoney()

		if enoughMoney then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

			self.callbackArgs = self.selectedFillAmount
			self.lastSelectedFillType = self.selectedFillType

			self:sendCallback(self.selectedFillType, self.selectedFillAmount, self.selectedPrice)
		else
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
			g_gui:showInfoDialog({
				text = g_i18n:getText("shop_messageNotEnoughMoneyToBuy")
			})
		end
	end
end

function RefillDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil, , )

	return false
end

function RefillDialog:sendCallback(fillTypeIndex, amount, price)
	self:close()

	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, fillTypeIndex, amount, price)
		else
			self.callbackFunc(fillTypeIndex, amount, price)
		end
	end
end

function RefillDialog:onClickFillTypes(state)
	self.selectedFillType = self.fillTypeMapping[state]

	self:updateFillAmounts()

	local width = self.fillTypeText:getTextWidth()

	self.fillTypeIcon:setPosition(self.fillTypeText.position[1] - width * 0.5 - self.fillTypeIcon.margin[3], nil)

	local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)

	self.fillTypeIcon:setImageFilename(fillType.hudOverlayFilename)
end

function RefillDialog:onClickFillAmount(state)
	self.selectedFillAmount = self.amountMapping[state]
	self.selectedPrice = self.priceMapping[state]
end

function RefillDialog:setData(data, priceFactor)
	self.fillTypeMapping = {}
	self.fillTypeAmountMapping = {}
	self.priceFactor = priceFactor or self.priceFactor
	local fillTypesTable = {}
	local selectedId = 1
	local numFillLevels = 1

	for fillTypeIndex, freeCapacity in pairs(data) do
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

		if fillTypeIndex == self.lastSelectedFillType then
			selectedId = numFillLevels
		end

		table.insert(fillTypesTable, fillType.title)
		table.insert(self.fillTypeMapping, fillTypeIndex)

		local fillAmounts = {}

		for i = #RefillDialog.FILL_AMOUNTS, 1, -1 do
			local fillAmount = RefillDialog.FILL_AMOUNTS[i]

			if fillAmount < freeCapacity then
				table.insert(fillAmounts, 1, fillAmount)
			end
		end

		if freeCapacity > 0 and freeCapacity ~= math.huge and freeCapacity ~= fillAmounts[#fillAmounts] then
			table.insert(fillAmounts, freeCapacity)
		end

		self.fillTypeAmountMapping[fillTypeIndex] = fillAmounts
		numFillLevels = numFillLevels + 1
	end

	self.fillTypesElement:setDisabled(#fillTypesTable <= 1)

	if not self.fillTypesElement.disabled then
		FocusManager:unsetFocus(self.fillTypesElement)
		FocusManager:setFocus(self.fillTypesElement)
	end

	self.fillTypesElement:setTexts(fillTypesTable)
	self.fillTypesElement:setState(selectedId, true)
end

function RefillDialog:updateFillAmounts()
	local fillAmountTexts = {}
	local fillAmounts = self.fillTypeAmountMapping[self.selectedFillType]
	self.amountMapping = {}
	self.priceMapping = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)

	for _, fillAmount in ipairs(fillAmounts) do
		local pricePerLiter = fillType.pricePerLiter * self.priceFactor
		local price = pricePerLiter * fillAmount
		local priceStr = g_i18n:formatMoney(price)
		local text = string.format("%d Liter (%s)", fillAmount, priceStr)

		table.insert(fillAmountTexts, text)
		table.insert(self.amountMapping, fillAmount)
		table.insert(self.priceMapping, price)
	end

	self.fillAmountsElement:setTexts(fillAmountTexts)
	self.fillAmountsElement:setState(#fillAmountTexts, true)
	self:setButtonDisabled(#fillAmounts == 0)
	self.fillAmountsElement:setDisabled(#fillAmounts == 0)

	if #fillAmounts == 0 then
		self.fillAmountText:setText("-")
	end

	if self.fillTypesElement.disabled and not self.fillAmountsElement.disabled then
		FocusManager:unsetFocus(self.fillAmountsElement)
		FocusManager:setFocus(self.fillAmountsElement)
	end
end

function RefillDialog:setButtonDisabled(disabled)
	self.messageBackground:setVisible(disabled)

	self.areButtonsDisabled = disabled

	self.yesButton:setDisabled(disabled)
end
