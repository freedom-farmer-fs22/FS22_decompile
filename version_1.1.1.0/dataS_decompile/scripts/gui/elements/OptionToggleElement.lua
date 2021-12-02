OptionToggleElement = {}
local OptionToggleElement_mt = Class(OptionToggleElement, MultiTextOptionElement)

function OptionToggleElement.new(target, custom_mt)
	local self = MultiTextOptionElement.new(target, custom_mt or OptionToggleElement_mt)
	self.dataSouce = nil

	return self
end

function OptionToggleElement:delete()
	self.dataSource = nil

	OptionToggleElement:superClass().delete(self)
end

function OptionToggleElement:setDataSource(dataSource)
	self.dataSource = dataSource

	self:updateTitle()
end

function OptionToggleElement:updateTitle()
	self.texts = {
		self.dataSource:getString()
	}

	self:setState(1)
end

function OptionToggleElement:onRightButtonClicked(steps, noFocus)
	if self.dataSource ~= nil then
		self.dataSource:setNextItem()

		self.texts[1] = self.dataSource:getString()
	end

	OptionToggleElement:superClass().onRightButtonClicked(self, steps, noFocus)
end

function OptionToggleElement:onLeftButtonClicked(steps, noFocus)
	if self.dataSource ~= nil then
		self.dataSource:setPreviousItem()

		self.texts[1] = self.dataSource:getString()
	end

	OptionToggleElement:superClass().onLeftButtonClicked(self, steps, noFocus)
end
