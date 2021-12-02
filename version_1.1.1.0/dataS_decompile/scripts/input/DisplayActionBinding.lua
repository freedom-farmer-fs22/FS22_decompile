DisplayActionBinding = {}
local DisplayActionBinding_mt = Class(DisplayActionBinding)

function DisplayActionBinding.new(action, displayName, isPositive, bindings)
	local self = setmetatable({}, DisplayActionBinding_mt)
	self.action = action
	self.displayName = displayName
	self.isPositive = isPositive
	self.columnTexts = {}
	self.columnBindings = {}

	return self
end

function DisplayActionBinding:setBindingDisplay(binding, text, column)
	self.columnTexts[column] = text
	self.columnBindings[column] = binding
end

function DisplayActionBinding:toString()
	local bindingsText = ""

	for col, binding in pairs(self.columnBindings) do
		bindingsText = bindingsText .. "(" .. tostring(col) .. ": " .. tostring(binding) .. ")"
	end

	return string.format("[DisplayActionBinding: displayName=%s, action=%s, isPositive=%s, columnTexts=%s, columnBindings=%s]", tostring(self.displayName), tostring(self.action), tostring(self.isPositive), table.concat(self.columnTexts, "|"), bindingsText)
end

DisplayActionBinding_mt.__tostring = DisplayActionBinding.toString
