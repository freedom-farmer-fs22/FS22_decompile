AIParameterVehicle = {}
local AIParameterVehicle_mt = Class(AIParameterVehicle, AIParameter)

function AIParameterVehicle.new(customMt)
	local self = AIParameter.new(customMt or AIParameterVehicle_mt)
	self.type = AIParameterType.TEXT
	self.vehicleId = nil

	return self
end

function AIParameterVehicle:saveToXMLFile(xmlFile, key, usedModNames)
	local vehicle = self:getVehicle()

	if vehicle ~= nil and vehicle.currentSavegameId ~= nil then
		xmlFile:setInt(key .. "#vehicleId", vehicle.currentSavegameId)
	end
end

function AIParameterVehicle:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.vehicleId = NetworkUtil.readNodeObjectId(streamId)
	end
end

function AIParameterVehicle:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.vehicleId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.vehicleId)
	end
end

function AIParameterVehicle:getCanBeChanged()
	return false
end

function AIParameterVehicle:getString()
	local vehicle = NetworkUtil.getObject(self.vehicleId)

	if vehicle ~= nil then
		return vehicle:getName()
	end

	return ""
end

function AIParameterVehicle:setVehicle(vehicle)
	self.vehicleId = NetworkUtil.getObjectId(vehicle)
end

function AIParameterVehicle:getVehicle()
	local vehicle = NetworkUtil.getObject(self.vehicleId)

	if vehicle ~= nil and vehicle:getIsSynchronized() then
		return vehicle
	end

	return nil
end

function AIParameterVehicle:validate(needsAITarget)
	if self.vehicleId == nil then
		return false, g_i18n:getText("ai_validationErrorNoVehicle")
	end

	local vehicle = self:getVehicle()

	if vehicle == nil then
		return false, g_i18n:getText("ai_validationErrorVehicleDoesNotExistAnymore")
	elseif vehicle.setAITarget == nil and (needsAITarget == nil or needsAITarget == true) then
		return false, g_i18n:getText("ai_validationErrorVehicleDoesNotSupportAI")
	end

	return true, nil
end
