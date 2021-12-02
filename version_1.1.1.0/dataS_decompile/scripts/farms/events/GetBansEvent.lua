GetBansEvent = {}
local GetBansEvent_mt = Class(GetBansEvent, Event)

InitStaticEventClass(GetBansEvent, "GetBansEvent", EventIds.EVENT_GET_BANS)

function GetBansEvent.emptyNew()
	return Event.new(GetBansEvent_mt)
end

function GetBansEvent.new(bans)
	local self = GetBansEvent.emptyNew()
	self.bans = bans or {}

	return self
end

function GetBansEvent:readStream(streamId, connection)
	local num = streamReadUInt16(streamId)
	self.bans = {}

	for _ = 1, num do
		local ban = {
			displayName = streamReadString(streamId),
			uniqueUserId = streamReadString(streamId)
		}

		table.insert(self.bans, ban)
	end

	self:run(connection)
end

function GetBansEvent:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.bans)

	for i, ban in ipairs(self.bans) do
		streamWriteString(streamId, ban.displayName)
		streamWriteString(streamId, ban.uniqueUserId)
	end
end

function GetBansEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")

			return
		end

		local bans = {}

		for i = 0, getNumOfBlockedUsers() - 1 do
			local uniqueUserId, platformUserId, platformId, displayName = getBlockedUser(i)

			table.insert(bans, {
				uniqueUserId = uniqueUserId,
				displayName = displayName
			})
		end

		connection:sendEvent(GetBansEvent.new(bans))
	else
		g_messageCenter:publish(GetBansEvent, self.bans)
	end
end
