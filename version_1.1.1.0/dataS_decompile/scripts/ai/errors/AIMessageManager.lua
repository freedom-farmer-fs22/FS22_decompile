AIMessageManager = {}
AIMessageType = {
	OK = 1,
	INFO = 2,
	ERROR = 3
}
local AIMessageManager_mt = Class(AIMessageManager)

function AIMessageManager.new(customMt)
	local self = setmetatable({}, customMt or AIMessageManager_mt)

	return self
end

function AIMessageManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.messages = {}
	self.nameToIndex = {}
	self.classObjectToIndex = {}

	self:registerMessage("ERROR_BLOCKED_BY_OBJECT", AIMessageErrorBlockedByObject)
	self:registerMessage("ERROR_COULD_NOT_PREPARE", AIMessageErrorCouldNotPrepare)
	self:registerMessage("ERROR_FIELD_NOT_OWNED", AIMessageErrorFieldNotOwned)
	self:registerMessage("ERROR_GRAINTANK_IS_FULL", AIMessageErrorGraintankIsFull)
	self:registerMessage("ERROR_IMPLEMENT_WRONG_WAY", AIMessageErrorImplementWrongWay)
	self:registerMessage("ERROR_LOADING_STATION_DELETED", AIMessageErrorLoadingStationDeleted)
	self:registerMessage("ERROR_UNLOADING_STATION_DELETED", AIMessageErrorUnloadingStationDeleted)
	self:registerMessage("ERROR_NO_FIELD_FOUND", AIMessageErrorNoFieldFound)
	self:registerMessage("ERROR_NO_VALID_FILLTYPE_LOADED", AIMessageErrorNoValidFillTypeLoaded)
	self:registerMessage("ERROR_NOT_REACHABLE", AIMessageErrorNotReachable)
	self:registerMessage("ERROR_OUT_OF_FILL", AIMessageErrorOutOfFill)
	self:registerMessage("ERROR_OUT_OF_FUEL", AIMessageErrorOutOfFuel)
	self:registerMessage("ERROR_OUT_OF_MONEY", AIMessageErrorOutOfMoney)
	self:registerMessage("ERROR_THRESHING_NOT_ALLOWED", AIMessageErrorThreshingNotAllowed)
	self:registerMessage("ERROR_UNKNOWN", AIMessageErrorUnknown)
	self:registerMessage("ERROR_UNLOADINGSTATION_FULL", AIMessageErrorUnloadingStationFull)
	self:registerMessage("ERROR_VEHICLE_BROKEN", AIMessageErrorVehicleBroken)
	self:registerMessage("ERROR_VEHICLE_DELETED", AIMessageErrorVehicleDeleted)
	self:registerMessage("ERROR_WRONG_SEASON", AIMessageErrorWrongSeason)
	self:registerMessage("SUCCESS_FINISHED_JOB", AIMessageSuccessFinishedJob)
	self:registerMessage("SUCCESS_SILO_EMPTY", AIMessageSuccessSiloEmpty)
	self:registerMessage("SUCCESS_STOPPED_BY_USER", AIMessageSuccessStoppedByUser)
end

function AIMessageManager:delete()
	self.messages = {}
	self.nameToIndex = {}
	self.classObjectToIndex = {}
end

function AIMessageManager:registerMessage(name, classObject)
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.warning("'%s' is not a valid name for a ai message!", tostring(name))

		return nil
	end

	name = name:upper()

	if self.nameToIndex[name] ~= nil then
		Logging.warning("AI message '%s' already exists!", tostring(name))

		return nil
	end

	if classObject == nil then
		Logging.warning("AI message '%s' class not defined!", tostring(name))

		return nil
	end

	local aiMessage = {
		name = name,
		classObject = classObject
	}

	table.insert(self.messages, aiMessage)

	self.nameToIndex[name] = #self.messages
	self.classObjectToIndex[classObject] = #self.messages

	return aiMessage
end

function AIMessageManager:getMessageIndex(messageObject)
	local classObject = ClassUtil.getClassObjectByObject(messageObject)

	if classObject == nil then
		return nil
	end

	return self.classObjectToIndex[classObject]
end

function AIMessageManager:createMessage(messageIndex)
	if messageIndex == nil then
		return nil
	end

	local aiMessage = self.messages[messageIndex]

	if aiMessage == nil then
		return nil
	end

	local instance = aiMessage.classObject.new()

	return instance
end
