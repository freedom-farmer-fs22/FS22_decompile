AIParameterPositionAngle = {}
local AIParameterPositionAngle_mt = Class(AIParameterPositionAngle, AIParameterPosition)

function AIParameterPositionAngle.new(snappingAngle, customMt)
	local self = AIParameterPosition.new(customMt or AIParameterPositionAngle_mt)
	self.type = AIParameterType.POSITION_ANGLE
	self.angle = nil
	self.snappingAngle = math.abs(snappingAngle or math.rad(5))

	return self
end

function AIParameterPositionAngle:saveToXMLFile(xmlFile, key, usedModNames)
	AIParameterPositionAngle:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	if self.angle ~= nil then
		xmlFile:setFloat(key .. "#angle", self.angle)
	end
end

function AIParameterPositionAngle:loadFromXMLFile(xmlFile, key)
	AIParameterPositionAngle:superClass().loadFromXMLFile(self, xmlFile, key)

	self.angle = xmlFile:getFloat(key .. "#angle", self.angle)
end

function AIParameterPositionAngle:readStream(streamId, connection)
	AIParameterPositionAngle:superClass().readStream(self, streamId, connection)

	if streamReadBool(streamId) then
		local angle = streamReadUIntN(streamId, 9)

		self:setAngle(math.rad(angle))
	end
end

function AIParameterPositionAngle:writeStream(streamId, connection)
	AIParameterPositionAngle:superClass().writeStream(self, streamId, connection)

	if streamWriteBool(streamId, self.angle ~= nil) then
		local angle = math.deg(self.angle)

		streamWriteUIntN(streamId, angle, 9)
	end
end

function AIParameterPositionAngle:setAngle(angleRad)
	angleRad = angleRad % (2 * math.pi)

	if angleRad < 0 then
		angleRad = angleRad + 2 * math.pi
	end

	if self.snappingAngle > 0 then
		local numSteps = MathUtil.round(angleRad / self.snappingAngle, 0)
		angleRad = numSteps * self.snappingAngle
	end

	self.angle = angleRad
end

function AIParameterPositionAngle:getAngle()
	return self.angle
end

function AIParameterPositionAngle:getDirection()
	if self.angle == nil then
		return nil, 
	end

	local xDir, zDir = MathUtil.getDirectionFromYRotation(self.angle)

	return xDir, zDir
end

function AIParameterPositionAngle:setSnappingAngle(angle)
	self.snappingAngle = math.abs(angle)
end

function AIParameterPositionAngle:getSnappingAngle()
	return self.snappingAngle
end

function AIParameterPositionAngle:getString()
	return string.format("< %.1f , %.1f | %d° >", self.x, self.z, math.deg(self.angle))
end

function AIParameterPositionAngle:validate(fillTypeIndex, farmId)
	local isValid, errorMessage = AIParameterPositionAngle:superClass().validate(self, fillTypeIndex, farmId)

	if not isValid then
		return false, errorMessage
	end

	if self.angle == nil then
		return false, g_i18n:getText("ai_validationErrorNoAngle")
	end

	return true, nil
end
