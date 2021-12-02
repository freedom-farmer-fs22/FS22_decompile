SleepDialog = {
	CONTROLS = {
		"targetTimeElement"
	},
	MIN_TARGET_TIME = 5,
	MAX_TARGET_TIME = 9,
	DEFAULT_TARGET_TIME = 8
}
local SleepDialog_mt = Class(SleepDialog, YesNoDialog)

function SleepDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or SleepDialog_mt)
	self.selectedTargetTime = SleepDialog.DEFAULT_TARGET_TIME
	self.maxDuration = SleepDialog.DEFAULT_MAX_DURATION

	self:registerControls(SleepDialog.CONTROLS)

	return self
end

function SleepDialog:onOpen()
	SleepDialog:superClass().onOpen(self)
	self:updateOptions()
end

function SleepDialog:onClose()
	SleepDialog:superClass().onClose(self)
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
end

function SleepDialog:sendCallback(value)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value, self.selectedTargetTime)
			else
				self.callbackFunc(value, self.selectedTargetTime)
			end
		end
	end
end

function SleepDialog:updateOptions()
	self.targetTimes = {}

	for i = SleepDialog.MIN_TARGET_TIME, SleepDialog.MAX_TARGET_TIME do
		table.insert(self.targetTimes, string.format("%d:00", i))
	end

	self.targetTimeElement:setTexts(self.targetTimes)
	self.targetTimeElement:setState(self.selectedTargetTime - SleepDialog.MIN_TARGET_TIME + 1)
end

function SleepDialog:onClickTargetTime(state)
	self.selectedTargetTime = state - 1 + SleepDialog.MIN_TARGET_TIME
end
