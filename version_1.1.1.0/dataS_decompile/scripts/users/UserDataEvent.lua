UserDataEvent = {
	SEND_NUM_BITS = 5
}
local UserDataEvent_mt = Class(UserDataEvent, Event)

InitStaticEventClass(UserDataEvent, "UserDataEvent", EventIds.EVENT_USER_DATA)

function UserDataEvent.emptyNew()
	local self = Event.new(UserDataEvent_mt)

	return self
end

function UserDataEvent.new(changedUsers)
	local self = UserDataEvent.emptyNew()
	self.changedUsers = changedUsers

	return self
end

function UserDataEvent:readStream(streamId, connection)
	self.changedUsers = {}
	local numUsers = streamReadUIntN(streamId, UserDataEvent.SEND_NUM_BITS)

	for _ = 1, numUsers do
		local userId = streamReadInt32(streamId)
		local user = g_currentMission.userManager:getUserByUserId(userId)

		user:readStream(streamId, connection)

		if user:getIsMasterUser() then
			g_currentMission.userManager:addMasterUser(user)
		end
	end
end

function UserDataEvent:writeStream(streamId, connection)
	local numUsers = #self.changedUsers

	streamWriteUIntN(streamId, numUsers, UserDataEvent.SEND_NUM_BITS)

	for _, user in ipairs(self.changedUsers) do
		streamWriteInt32(streamId, user:getId())
		user:writeStream(streamId, connection)
	end
end
