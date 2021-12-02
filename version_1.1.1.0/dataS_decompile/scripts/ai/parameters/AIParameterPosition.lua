AIParameterPosition = {}
local AIParameterPosition_mt = Class(AIParameterPosition, AIParameter)

function AIParameterPosition.new(customMt)
	local self = AIParameter.new(customMt or AIParameterPosition_mt)
	self.type = AIParameterType.POSITION
	self.x = nil
	self.z = nil

	return self
end

function AIParameterPosition:saveToXMLFile(xmlFile, key, usedModNames)
	if self.x ~= nil then
		xmlFile:setFloat(key .. "#x", self.x)
		xmlFile:setFloat(key .. "#z", self.z)
	end
end

function AIParameterPosition:loadFromXMLFile(xmlFile, key)
	self.x = xmlFile:getFloat(key .. "#x", self.x)
	self.z = xmlFile:getFloat(key .. "#z", self.z)
end

function AIParameterPosition:readStream(streamId, connection)
	if streamReadBool(streamId) then
		local x = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)

		self:setPosition(x, z)
	end
end

function AIParameterPosition:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.x ~= nil) then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.z)
	end
end

function AIParameterPosition:setPosition(x, z)
	self.x = x
	self.z = z
end

function AIParameterPosition:getPosition()
	return self.x, self.z
end

function AIParameterPosition:getString()
	return string.format("< %.1f , %.1f >", self.x, self.z)
end

function AIParameterPosition:validate()
	if self.x == nil or self.z == nil then
		return false, g_i18n:getText("ai_validationErrorNoPosition")
	end

	return true, nil
end
