TransferMoneyDialog = {
	CONTROLS = {
		CONSOLE_AMOUNT = "consoleAmountText",
		HEADER_TEXT = "headerText"
	}
}
local TransferMoneyDialog_mt = Class(TransferMoneyDialog, DialogElement)

function TransferMoneyDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or TransferMoneyDialog_mt)
	self.isBackAllowed = false
	self.inputDelay = 250
	self.amount = 0
	self.optionElements = {}

	self:registerControls(TransferMoneyDialog.CONTROLS)

	return self
end

function TransferMoneyDialog:onOpen()
	TransferMoneyDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250

	for element, amount in pairs(self.optionElements) do
		element.elements[3]:setText(g_i18n:formatMoney(amount))
	end

	self.farm = g_farmManager:getFarmById(g_currentMission:getFarmId())

	self:updateAmount(0)
end

function TransferMoneyDialog:onClickActivate()
	if self.inputDelay < self.time then
		self:sendCallback(self.amount)

		return false
	end

	return true
end

function TransferMoneyDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end

function TransferMoneyDialog:setTargetFarm(farm)
	self.headerText:setText(string.format(g_i18n:getText("button_mp_transferMoney_dialogTitle"), farm.name))
end

function TransferMoneyDialog:onClickBack(forceBack)
	if self.inputDelay < self.time then
		self:sendCallback(0)

		return false
	else
		return true
	end
end

function TransferMoneyDialog:sendCallback(value)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value)
			else
				self.callbackFunc(value)
			end
		end
	end
end

function TransferMoneyDialog:onClickLeft(element)
	local amount = -1 * self.optionElements[element.parent]

	self:updateAmount(amount)
end

function TransferMoneyDialog:onClickRight(element)
	local amount = self.optionElements[element.parent]

	self:updateAmount(amount)
end

function TransferMoneyDialog:updateAmount(diff)
	self.amount = math.min(math.max(self.amount + diff, 0), self.farm:getBalance())

	self.consoleAmountText:setText(g_i18n:formatMoney(self.amount))
end

function TransferMoneyDialog:onCreateScroller(element, amount)
	local amount = tonumber(amount)
	self.optionElements[element] = amount
end
