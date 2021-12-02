VehicleEnterResponseEvent = {}
local VehicleEnterResponseEvent_mt = Class(VehicleEnterResponseEvent, Event)

InitStaticEventClass(VehicleEnterResponseEvent, "VehicleEnterResponseEvent", EventIds.EVENT_VEHICLE_ENTER_RESPONSE)

function VehicleEnterResponseEvent.emptyNew()
	local self = Event.new(VehicleEnterResponseEvent_mt)

	return self
end

function VehicleEnterResponseEvent.new(id, isOwner, playerStyle, farmId)
	local self = VehicleEnterResponseEvent.emptyNew()
	self.id = id
	self.isOwner = isOwner
	self.playerStyle = playerStyle
	self.farmId = farmId

	return self
end

function VehicleEnterResponseEvent:readStream(streamId, connection)
	self.id = NetworkUtil.readNodeObjectId(streamId)
	self.isOwner = streamReadBool(streamId)

	if self.playerStyle == nil then
		self.playerStyle = PlayerStyle.new()
	end

	self.playerStyle:readStream(streamId, connection)

	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function VehicleEnterResponseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.id)
	streamWriteBool(streamId, self.isOwner)
	self.playerStyle:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function VehicleEnterResponseEvent:run(connection)
	local object = NetworkUtil.getObject(self.id)

	if object ~= nil and object:getIsSynchronized() then
		if self.isOwner then
			g_currentMission:onEnterVehicle(object, self.playerStyle, self.farmId)
		else
			local enterableSpec = object.spec_enterable

			if enterableSpec ~= nil and not enterableSpec.isEntered then
				object:enterVehicle(false, self.playerStyle, self.farmId)
			end
		end
	end
end
