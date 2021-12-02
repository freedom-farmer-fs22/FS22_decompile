AIParameter = {}
local AIParameter_mt = Class(AIParameter)

function AIParameter.new(customMt)
	local self = setmetatable({}, customMt or AIParameter_mt)
	self.type = AIParameterType.TEXT
	self.isValid = true

	return self
end

function AIParameter:readStream(streamId, connection)
end

function AIParameter:writeStream(streamId, connection)
end

function AIParameter:getType()
	return self.type
end

function AIParameter:getIsValid()
	return self.isValid
end

function AIParameter:setIsValid(isValid)
	self.isValid = isValid
end

function AIParameter:getCanBeChanged()
	return true
end

function AIParameter:getString()
	return ""
end
