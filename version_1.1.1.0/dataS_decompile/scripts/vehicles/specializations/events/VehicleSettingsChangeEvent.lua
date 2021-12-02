VehicleSettingsChangeEvent = {}
local VehicleSettingsChangeEvent_mt = Class(VehicleSettingsChangeEvent, Event)

InitStaticEventClass(VehicleSettingsChangeEvent, "VehicleSettingsChangeEvent", EventIds.EVENT_VEHICLE_SETTING_CHANGED)

function VehicleSettingsChangeEvent.emptyNew()
	local self = Event.new(VehicleSettingsChangeEvent_mt)

	return self
end

function VehicleSettingsChangeEvent.new(vehicle, settings, state)
	local self = VehicleSettingsChangeEvent.emptyNew()
	self.vehicle = vehicle
	self.settings = settings

	return self
end

function VehicleSettingsChangeEvent:readStream(streamId, connection)
	local vehicle = NetworkUtil.readNodeObject(streamId)
	local numSettings = streamReadUInt8(streamId)
	local isValid = vehicle ~= nil and vehicle:getIsSynchronized()

	for i = 1, numSettings do
		local index = streamReadUInt8(streamId)
		local state = nil

		if streamReadBool(streamId) then
			state = streamReadBool(streamId)
		else
			state = streamReadUInt8(streamId)
		end

		if isValid then
			vehicle:setVehicleSettingState(index, state, true)
		end
	end
end

function VehicleSettingsChangeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)

	local numSettingsToSend = 0

	for i = 1, #self.settings do
		if self.settings[i].isDirty then
			numSettingsToSend = numSettingsToSend + 1
		end
	end

	streamWriteUInt8(streamId, numSettingsToSend)

	for i = 1, #self.settings do
		local setting = self.settings[i]

		if setting.isDirty then
			streamWriteUInt8(streamId, setting.index)

			if streamWriteBool(streamId, setting.isBool) then
				streamWriteBool(streamId, setting.state)
			else
				streamWriteUInt8(streamId, setting.state)
			end

			setting.isDirty = false
		end
	end
end

function VehicleSettingsChangeEvent:run(connection)
end
