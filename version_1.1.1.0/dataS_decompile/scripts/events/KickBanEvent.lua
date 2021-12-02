KickBanEvent = {}
local KickBanEvent_mt = Class(KickBanEvent, Event)

InitStaticEventClass(KickBanEvent, "KickBanEvent", EventIds.EVENT_KICK_BAN)

function KickBanEvent.emptyNew()
	local self = Event.new(KickBanEvent_mt)

	return self
end

function KickBanEvent.new(doKick, userId)
	local self = KickBanEvent.emptyNew()
	self.doKick = doKick
	self.userId = userId

	return self
end

function KickBanEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer(), "KickBanEvent is a client to server only event")

	self.doKick = streamReadBool(streamId)
	self.userId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function KickBanEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.doKick)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function KickBanEvent:run(connection)
	if not connection:getIsServer() then
		if self.userId == g_currentMission:getServerUserId() then
			print("The server cannot be kicked or banned")

			return
		end

		if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")

			return
		end

		local user = g_currentMission.userManager:getUserByUserId(self.userId)

		if user ~= nil then
			if self.doKick then
				g_currentMission:kickUser(user)
			else
				g_currentMission:banUser(user)
			end
		else
			print("User(" .. tostring(self.userId) .. ") not found")
		end
	else
		print("Error: KickBanEvent is a client to server only event")
	end
end
