AIParameterGroup = {}
local AIParameterGroup_mt = Class(AIParameterGroup)

function AIParameterGroup.new(title, customMt)
	local self = setmetatable({}, customMt or AIParameterGroup_mt)
	self.parameters = {}
	self.title = title

	return self
end

function AIParameterGroup:getTitle()
	return self.title
end

function AIParameterGroup:addParameter(parameter)
	table.insert(self.parameters, parameter)
end

function AIParameterGroup:getParameters()
	return self.parameters
end
