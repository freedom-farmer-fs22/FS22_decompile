SetPipeDischargeToGroundEvent = {}
local SetPipeDischargeToGroundEvent_mt = Class(SetPipeDischargeToGroundEvent, Event)

InitStaticEventClass(SetPipeDischargeToGroundEvent, "SetPipeDischargeToGroundEvent", EventIds.EVENT_SET_PIPE_DISCHARGE_TO_GROUND)

function SetPipeDischargeToGroundEvent.emptyNew()
	local self = Event.new(SetPipeDischargeToGroundEvent_mt)

	return self
end

function SetPipeDischargeToGroundEvent.new(object, dischargeState)
	local self = SetPipeDischargeToGroundEvent.emptyNew()
	self.object = object
	self.dischargeState = dischargeState

	return self
end

function SetPipeDischargeToGroundEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.dischargeState = streamReadBool(streamId)

	self:run(connection)
end

function SetPipeDischargeToGroundEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.dischargeState)
end

function SetPipeDischargeToGroundEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPipeDischargeToGround(self.dischargeState, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SetPipeDischargeToGroundEvent.new(self.object, self.dischargeState), nil, connection, self.object)
	end
end

function SetPipeDischargeToGroundEvent.sendEvent(object, dischargeState, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetPipeDischargeToGroundEvent.new(object, dischargeState), nil, , object)
		else
			g_client:getServerConnection():sendEvent(SetPipeDischargeToGroundEvent.new(object, dischargeState))
		end
	end
end
