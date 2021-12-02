PlayerSetFarmAnswerEvent = {}
local PlayerSetFarmAnswerEvent_mt = Class(PlayerSetFarmAnswerEvent, Event)

InitStaticEventClass(PlayerSetFarmAnswerEvent, "PlayerSetFarmAnswerEvent", EventIds.EVENT_PLAYER_SET_FARM_ANSWER)

PlayerSetFarmAnswerEvent.STATE = {
	PASSWORD_REQUIRED = 2,
	OK = 1
}
PlayerSetFarmAnswerEvent.SEND_NUM_BITS = 2

function PlayerSetFarmAnswerEvent.emptyNew()
	local self = Event.new(PlayerSetFarmAnswerEvent_mt)

	return self
end

function PlayerSetFarmAnswerEvent.new(answerState, farmId, password)
	local self = PlayerSetFarmAnswerEvent.emptyNew()
	self.answerState = answerState
	self.farmId = farmId
	self.password = password

	return self
end

function PlayerSetFarmAnswerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.answerState, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

	local passwordCorrect = self.answerState == PlayerSetFarmAnswerEvent.STATE.OK
	local passwordSet = self.password ~= nil

	if streamWriteBool(streamId, passwordCorrect and passwordSet) then
		streamWriteString(streamId, self.password)
	end
end

function PlayerSetFarmAnswerEvent:readStream(streamId, connection)
	self.answerState = streamReadUIntN(streamId, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if streamReadBool(streamId) then
		self.password = streamReadString(streamId)
	end

	self:run(connection)
end

function PlayerSetFarmAnswerEvent:run(connection)
	if not connection:getIsServer() then
		Logging.devWarning("PlayerSetFarmAnswerEvent is a server to client only event")
	elseif self.answerState == PlayerSetFarmAnswerEvent.STATE.OK then
		g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId, self.password)
	elseif self.answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
		g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId)
	end
end
