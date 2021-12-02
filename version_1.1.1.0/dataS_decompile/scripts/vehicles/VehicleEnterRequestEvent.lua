VehicleEnterRequestEvent = {}
local VehicleEnterRequestEvent_mt = Class(VehicleEnterRequestEvent, Event)

InitStaticEventClass(VehicleEnterRequestEvent, "VehicleEnterRequestEvent", EventIds.EVENT_VEHICLE_ENTER_REQUEST)

function VehicleEnterRequestEvent.emptyNew()
	local self = Event.new(VehicleEnterRequestEvent_mt)

	return self
end

function VehicleEnterRequestEvent.new(object, playerStyle, farmId)
	local self = VehicleEnterRequestEvent.emptyNew()
	self.object = object
	self.objectId = NetworkUtil.getObjectId(self.object)
	self.farmId = farmId
	self.playerStyle = playerStyle

	return self
end

function VehicleEnterRequestEvent:readStream(streamId, connection)
	self.objectId = NetworkUtil.readNodeObjectId(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if self.playerStyle == nil then
		self.playerStyle = PlayerStyle.new()
	end

	self.playerStyle:readStream(streamId, connection)

	self.object = NetworkUtil.getObject(self.objectId)

	self:run(connection)
end

function VehicleEnterRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.objectId)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.playerStyle:writeStream(streamId, connection)
end

function VehicleEnterRequestEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		local enterableSpec = self.object.spec_enterable

		if enterableSpec ~= nil and enterableSpec.isControlled == false then
			self.object:setOwner(connection)

			self.object.controllerFarmId = self.farmId

			g_server:broadcastEvent(VehicleEnterResponseEvent.new(self.objectId, false, self.playerStyle, self.farmId), true, connection, self.object, false, nil, true)
			connection:sendEvent(VehicleEnterResponseEvent.new(self.objectId, true, self.playerStyle, self.farmId))
		end
	end
end
