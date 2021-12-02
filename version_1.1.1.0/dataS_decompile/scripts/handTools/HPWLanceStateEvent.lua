HPWLanceStateEvent = {}
local HPWLanceStateEvent_mt = Class(HPWLanceStateEvent, Event)

InitStaticEventClass(HPWLanceStateEvent, "HPWLanceStateEvent", EventIds.EVENT_HIGHPRESSURE_WASHER_LANCE_STATE)

function HPWLanceStateEvent.emptyNew()
	local self = Event.new(HPWLanceStateEvent_mt)

	return self
end

function HPWLanceStateEvent.new(player, doWashing)
	local self = HPWLanceStateEvent.emptyNew()
	self.player = player
	self.doWashing = doWashing

	return self
end

function HPWLanceStateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.doWashing = streamReadBool(streamId)

	self:run(connection)
end

function HPWLanceStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.doWashing)
end

function HPWLanceStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsWashing ~= nil then
		currentTool:setIsWashing(self.doWashing, false, true)
	end
end

function HPWLanceStateEvent.sendEvent(player, doWashing, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setIsWashing ~= nil and doWashing ~= currentTool.doWashing and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(HPWLanceStateEvent.new(player, doWashing), nil, , player)
		else
			g_client:getServerConnection():sendEvent(HPWLanceStateEvent.new(player, doWashing))
		end
	end
end
