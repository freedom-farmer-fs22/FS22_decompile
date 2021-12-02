InGameMenuFinancesFrame = {}
local InGameMenuFinancesFrame_mt = Class(InGameMenuFinancesFrame, TabbedMenuFrameElement)
InGameMenuFinancesFrame.CONTROLS = {
	PAST_DAY_HEADERS = "pastDayHeader",
	TOTAL_TEXTS = "totalText",
	MAIN_BOX = "mainBox",
	TABLE_SLIDER = "tableSlider",
	BALANCE_FOOTER = "balanceFooter",
	HEADER_BOX = "tableHeaderBox",
	TABLE = "financesTable",
	BALANCE_TEXT = "balanceText",
	LOAN_TEXT = "loanText"
}
InGameMenuFinancesFrame.PAST_PERIOD_COUNT = GS_IS_MOBILE_VERSION and 3 or 4
InGameMenuFinancesFrame.MAX_ITEMS = GS_IS_MOBILE_VERSION and 4 or 10
InGameMenuFinancesFrame.LOAN_STEP = 5000

function InGameMenuFinancesFrame.new(customMt, messageCenter, l10n, inputManager)
	local self = InGameMenuFinancesFrame:superClass().new(nil, customMt or InGameMenuFinancesFrame_mt)

	self:registerControls(InGameMenuFinancesFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.client = nil
	self.environment = nil
	self.playerFarm = nil
	self.dataBindings = {}
	self.currentMoneyUnitText = ""
	self.updateTimeFinancesStats = 0
	self.updateTimeFinances = 0
	self.hasMasterRights = false
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.borrowButtonInfo = {
		text = "",
		inputAction = InputAction.MENU_ACTIVATE,
		callback = function ()
			self:onButtonBorrow()
		end
	}
	self.repayButtonInfo = {
		text = "",
		inputAction = InputAction.MENU_CANCEL,
		callback = function ()
			self:onButtonRepay()
		end
	}

	if not GS_IS_MOBILE_VERSION then
		self.hasCustomMenuButtons = true
		self.menuButtonInfo = {
			self.backButtonInfo,
			self.borrowButtonInfo,
			self.repayButtonInfo
		}
	end

	return self
end

function InGameMenuFinancesFrame:copyAttributes(src)
	InGameMenuFinancesFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.inputManager = src.inputManager
end

function InGameMenuFinancesFrame:initialize(environment)
	self:setupFinancesTable()
end

function InGameMenuFinancesFrame:onFrameOpen(element)
	InGameMenuFinancesFrame:superClass().onFrameOpen(self)
	self.tableHeaderBox:invalidateLayout()
	self.balanceFooter:invalidateLayout()
	self:updateMoneyUnit()
	self:updateFinances()
	self:updateFinancesLoanButtons()
	self.messageCenter:subscribe(PlayerPermissionsEvent, self.updateFinancesLoanButtons, self)
	self.messageCenter:subscribe(ChangeLoanEvent, self.updateFinances, self)
	FocusManager:setFocus(self.tableSlider)
end

function InGameMenuFinancesFrame:onFrameClose()
	InGameMenuFinancesFrame:superClass().onFrameClose(self)
	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuFinancesFrame:onClose()
	InGameMenuFinancesFrame:superClass().onClose(self)
	g_currentMission:showMoneyChange(MoneyType.LOAN)
end

function InGameMenuFinancesFrame:update(dt)
	InGameMenuFinancesFrame:superClass().update(self, dt)

	if not g_currentMission:getIsServer() and self.updateTimeFinancesStats < g_currentMission.time then
		self.updateTimeFinancesStats = g_currentMission.time + 5000
		local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)

		if farm.stats.financesHistoryVersionCounter ~= farm.stats.financesHistoryVersionCounterLocal then
			farm.stats.financesHistoryVersionCounterLocal = farm.stats.financesHistoryVersionCounter

			for i = 1, InGameMenuFinancesFrame.PAST_PERIOD_COUNT do
				self.client:getServerConnection():sendEvent(FinanceStatsEvent.new(i, farm.farmId))
			end
		end
	end
end

function InGameMenuFinancesFrame:setClient(client)
	self.client = client
end

function InGameMenuFinancesFrame:setEnvironment(environment)
	self.environment = environment
end

function InGameMenuFinancesFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end

function InGameMenuFinancesFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights
end

function InGameMenuFinancesFrame:getPastPeriods()
	local periods = {}
	local currentPeriod = self.environment.currentPeriod

	for i = 1, InGameMenuFinancesFrame.PAST_PERIOD_COUNT do
		local pastPeriod = currentPeriod - i

		table.insert(periods, g_i18n:formatPeriod(pastPeriod, false))
	end

	return periods
end

local function alwaysOverride()
	return true
end

function InGameMenuFinancesFrame:setupFinancesTable()
	self.financesTable:initialize()
	self.financesTable:setProfileOverrideFilterFunction(alwaysOverride)
end

function InGameMenuFinancesFrame:updateBalance()
	local currentBalance = self.playerFarm:getBalance()
	local balanceMoneyText = self.l10n:formatMoney(currentBalance, 0, false)
	local balanceProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEUTRAL

	if math.floor(currentBalance) <= -1 then
		balanceProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEGATIVE
	end

	self.balanceText:applyProfile(balanceProfile)
	self.balanceText:setText(balanceMoneyText .. " " .. self.currentMoneyUnitText)
end

function InGameMenuFinancesFrame:updateLoan()
	local currentLoan = self.playerFarm:getLoan()
	local loanMoneyText = self.l10n:formatMoney(-currentLoan, 0, false)
	local loanProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEUTRAL

	if currentLoan > 0 then
		loanProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEGATIVE
	end

	self.loanText:applyProfile(loanProfile)
	self.loanText:setText(loanMoneyText .. " " .. self.currentMoneyUnitText)
end

function InGameMenuFinancesFrame:updateDayTotals(currentFinances, pastFinances)
	for i = 1, InGameMenuFinancesFrame.PAST_PERIOD_COUNT + 1 do
		local dayFinances = currentFinances

		if i > 1 then
			local pastIndex = #pastFinances - (i - 2)
			dayFinances = pastFinances[pastIndex]
		end

		local dayTotalProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEUTRAL

		if dayFinances ~= nil then
			local dayTotal = 0

			for _, statName in pairs(dayFinances.statNames) do
				dayTotal = dayTotal + dayFinances[statName]
			end

			local totalMoneyText = self.l10n:formatMoney(dayTotal, 0, false)

			if math.floor(dayTotal) <= -1 then
				dayTotalProfile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEGATIVE
			end

			self.totalText[i]:setText(totalMoneyText .. " " .. self.currentMoneyUnitText)
		else
			self.totalText[i]:setText("")
		end

		self.totalText[i]:applyProfile(dayTotalProfile)
	end
end

function InGameMenuFinancesFrame:updateFinancesFooter(currentFinances, pastFinances)
	self:updateBalance()

	if not GS_IS_MOBILE_VERSION then
		self:updateLoan()
	end

	self:updateDayTotals(currentFinances, pastFinances)
end

function InGameMenuFinancesFrame:updateFinancesTable(currentFinances, pastFinances)
	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(math.ceil(#currentFinances.statNames / InGameMenuFinancesFrame.MAX_ITEMS))
	end

	self.financesTable:clearData()

	for _, statName in ipairs(currentFinances.statNames) do
		local dataRow = self:buildDataRow(statName, currentFinances, pastFinances)

		self.financesTable:addRow(dataRow)
	end

	self.financesTable:updateView(false)
end

function InGameMenuFinancesFrame:updateFinances()
	local pastDayLabels = self:getPastPeriods()

	for i, dayLabel in ipairs(pastDayLabels) do
		self.pastDayHeader[i]:setText(dayLabel)
	end

	self.pastDayHeader[0]:setText(g_i18n:formatPeriod(g_currentMission.environment.currentPeriod, false))

	local finances = self.playerFarm.stats.finances
	local pastFinances = self.playerFarm.stats.financesHistory
	local sliderValue = nil

	if self.tableSlider ~= nil then
		sliderValue = self.tableSlider:getValue()
	end

	self:updateFinancesTable(finances, pastFinances)
	self:updateFinancesFooter(finances, pastFinances)
	self:updateFinancesLoanButtons()

	if self.tableSlider ~= nil then
		self.tableSlider:setValue(sliderValue)
	end
end

function InGameMenuFinancesFrame:updateFinancesLoanButtons()
	if not GS_IS_MOBILE_VERSION then
		local allowChangeLoan = self:hasPlayerLoanPermission()
		local isBorrowEnabled = self.playerFarm.loan < self.playerFarm.loanMax and allowChangeLoan
		local isRepayEnabled = self.playerFarm.loan > 0 and InGameMenuFinancesFrame.LOAN_STEP <= self.playerFarm.money and allowChangeLoan
		self.borrowButtonInfo.disabled = not isBorrowEnabled
		self.repayButtonInfo.disabled = not isRepayEnabled

		self:setMenuButtonInfoDirty()
	end
end

function InGameMenuFinancesFrame:updateMoneyUnit()
	self.currentMoneyUnitText = self.l10n:getCurrencySymbol(true)
	local borrowTemplate = self.l10n:getText(InGameMenuFinancesFrame.L10N_SYMBOL.BUTTON_BORROW)
	local text = string.gsub(borrowTemplate, InGameMenuFinancesFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
	self.borrowButtonInfo.text = text
	local repayTemplate = self.l10n:getText(InGameMenuFinancesFrame.L10N_SYMBOL.BUTTON_REPAY)
	text = string.gsub(repayTemplate, InGameMenuFinancesFrame.L10N_SYMBOL.CURRENCY, self.currentMoneyUnitText)
	self.repayButtonInfo.text = text
end

function InGameMenuFinancesFrame:hasPlayerLoanPermission()
	return g_currentMission:getHasPlayerPermission("farmManager")
end

function InGameMenuFinancesFrame:getMainElementSize()
	return self.mainBox.size
end

function InGameMenuFinancesFrame:getMainElementPosition()
	return self.mainBox.absPosition
end

InGameMenuFinancesFrame.DATA_BINDING = {
	DAY_TEMPLATE = "day%s",
	TYPE = "costType"
}

function InGameMenuFinancesFrame:onDataBindType(element)
	self.dataBindings[InGameMenuFinancesFrame.DATA_BINDING.TYPE] = element.name
end

function InGameMenuFinancesFrame:onDataBindDay(element, index)
	local dbKey = string.format(InGameMenuFinancesFrame.DATA_BINDING.DAY_TEMPLATE, index)
	self.dataBindings[dbKey] = element.name
end

function InGameMenuFinancesFrame:buildDataRow(statName, currentFinances, pastFinances)
	local dataRow = TableElement.DataRow.new(statName, self.dataBindings)
	local statNameCell = dataRow.columnCells[self.dataBindings[InGameMenuFinancesFrame.DATA_BINDING.TYPE]]
	local statDisplayText = FinanceStats.statNamesI18n[statName]
	statNameCell.text = statDisplayText

	for i = 1, InGameMenuFinancesFrame.PAST_PERIOD_COUNT + 1 do
		local dbKey = string.format(InGameMenuFinancesFrame.DATA_BINDING.DAY_TEMPLATE, tostring(i))
		local dayCell = dataRow.columnCells[self.dataBindings[dbKey]]
		local dayFinances = currentFinances

		if i > 1 then
			local pastIndex = #pastFinances - (i - 2)
			dayFinances = pastFinances[pastIndex]
		end

		local profile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEUTRAL

		if dayFinances ~= nil then
			local moneyValue = dayFinances[statName]
			dayCell.value = moneyValue

			if math.floor(moneyValue) <= -1 then
				profile = InGameMenuFinancesFrame.PROFILE.VALUE_CELL_NEGATIVE
			end

			local moneyText = self.l10n:formatMoney(moneyValue, 0, false)
			dayCell.text = moneyText .. " " .. self.currentMoneyUnitText
		else
			dayCell.value = 0
			dayCell.text = "-"
		end

		dayCell.overrideProfileName = profile
	end

	return dataRow
end

function InGameMenuFinancesFrame:onButtonBorrow()
	if self:hasPlayerLoanPermission() then
		self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(InGameMenuFinancesFrame.LOAN_STEP, self.playerFarm.farmId))
	end
end

function InGameMenuFinancesFrame:onButtonRepay()
	if self:hasPlayerLoanPermission() then
		self.client:getServerConnection():sendEvent(ChangeLoanEvent.new(-InGameMenuFinancesFrame.LOAN_STEP, self.playerFarm.farmId))
	end
end

function InGameMenuFinancesFrame:onPageChanged(page, fromPage)
	InGameMenuFinancesFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * InGameMenuFinancesFrame.MAX_ITEMS + 1

	self.financesTable:scrollTo(firstIndex)
end

InGameMenuFinancesFrame.L10N_SYMBOL = {
	WEEK_DAY_TEMPLATE = "ui_financesDay",
	BUTTON_REPAY = "button_repay5000",
	BUTTON_BORROW = "button_borrow5000",
	CURRENCY = "$CURRENCY_SYMBOL"
}
InGameMenuFinancesFrame.PROFILE = {
	VALUE_CELL_NEGATIVE = "ingameMenuFinancesRowCellNegative",
	VALUE_CELL_NEUTRAL = "ingameMenuFinancesRowCell"
}
