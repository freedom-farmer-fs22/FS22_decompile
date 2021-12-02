ChainsawStateEvent = {}
local ChainsawStateEvent_mt = Class(ChainsawStateEvent, Event)

InitStaticEventClass(ChainsawStateEvent, "ChainsawStateEvent", EventIds.EVENT_CHAINSAW_STATE)

function ChainsawStateEvent.emptyNew()
	local self = Event.new(ChainsawStateEvent_mt)

	return self
end

function ChainsawStateEvent.new(player, isCutting, isHorizontalCut, hasBeencut)
	local self = ChainsawStateEvent.emptyNew()
	self.player = player
	self.isCutting = isCutting
	self.isHorizontalCut = isHorizontalCut
	self.hasBeenCut = hasBeencut

	return self
end

function ChainsawStateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.isCutting = streamReadBool(streamId)
	self.isHorizontalCut = streamReadBool(streamId)
	self.hasBeenCut = streamReadBool(streamId)

	self:run(connection)
end

function ChainsawStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.isCutting)
	streamWriteBool(streamId, self.isHorizontalCut)
	streamWriteBool(streamId, self.hasBeenCut)
end

function ChainsawStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setCutting ~= nil then
		currentTool:setCutting(self.isCutting, self.isHorizontalCut, self.hasBeenCut, true)
	end
end

function ChainsawStateEvent.sendEvent(player, isCutting, isHorizontalCut, hasBeenCut, noEventSend)
	local currentTool = player.baseInformation.currentHandtool

	if currentTool ~= nil and currentTool.setCutting ~= nil and (currentTool.isCutting ~= isCutting or currentTool.hasBeenCut ~= hasBeenCut) and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(ChainsawStateEvent.new(player, isCutting, isHorizontalCut, hasBeenCut), nil, , player)
		else
			g_client:getServerConnection():sendEvent(ChainsawStateEvent.new(player, isCutting, isHorizontalCut, hasBeenCut))
		end
	end
end
