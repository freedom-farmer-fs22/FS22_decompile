UnbanEvent = {}
local UnbanEvent_mt = Class(UnbanEvent, Event)

InitStaticEventClass(UnbanEvent, "UnbanEvent", EventIds.EVENT_UNBAN)

function UnbanEvent.emptyNew()
	local self = Event.new(UnbanEvent_mt)

	return self
end

function UnbanEvent.new(uniqueUserId)
	local self = UnbanEvent.emptyNew()
	self.uniqueUserId = uniqueUserId

	return self
end

function UnbanEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer(), "UnbanEvent is a client to server only event")

	self.uniqueUserId = streamReadString(streamId)

	self:run(connection)
end

function UnbanEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.uniqueUserId)
end

function UnbanEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")

			return
		end

		for i = 0, getNumOfBlockedUsers() - 1 do
			local uniqueUserId, platformUserId, platformId, _ = getBlockedUser(i)

			if uniqueUserId == self.uniqueUserId then
				setIsUserBlocked(uniqueUserId, platformUserId, platformId, false, "")

				break
			end
		end
	else
		print("Error: UnbanEvent is a client to server only event")
	end
end
