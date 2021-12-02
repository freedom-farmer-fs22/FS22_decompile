DrivableToggleLowerAllEvent = {}
local DrivableToggleLowerAllEvent_mt = Class(DrivableToggleLowerAllEvent, Event)

InitStaticEventClass(DrivableToggleLowerAllEvent, "DrivableToggleLowerAllEvent", EventIds.EVENT_VEHICLE_LOWER_ALL_IMPLEMENT)

function DrivableToggleLowerAllEvent.emptyNew()
	local self = Event.new(DrivableToggleLowerAllEvent_mt)

	return self
end

function DrivableToggleLowerAllEvent.new(vehicle)
	local self = DrivableToggleLowerAllEvent.emptyNew()
	self.vehicle = vehicle

	return self
end

function DrivableToggleLowerAllEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function DrivableToggleLowerAllEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function DrivableToggleLowerAllEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:toggleLowerAllImplements(true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(DrivableToggleLowerAllEvent.new(self.vehicle), nil, connection, self.object)
	end
end

function DrivableToggleLowerAllEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(DrivableToggleLowerAllEvent.new(vehicle), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(DrivableToggleLowerAllEvent.new(vehicle))
		end
	end
end
