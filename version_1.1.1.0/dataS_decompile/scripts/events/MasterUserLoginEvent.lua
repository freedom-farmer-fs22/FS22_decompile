MasterUserLoginEvent = {}
local MasterUserLoginEvent_mt = Class(MasterUserLoginEvent, Event)

InitStaticEventClass(MasterUserLoginEvent, "MasterUserLoginEvent", EventIds.EVENT_MASTER_USER_LOGIN)

function MasterUserLoginEvent.emptyNew()
	local self = Event.new(MasterUserLoginEvent_mt)

	return self
end

function MasterUserLoginEvent.new(userId)
	local self = MasterUserLoginEvent.emptyNew()
	self.userId = userId

	return self
end

function MasterUserLoginEvent:readStream(streamId, connection)
	self.userId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function MasterUserLoginEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function MasterUserLoginEvent:run(connection)
	local user = g_currentMission:getUserByUserId(self.userId)
	user.isMasterUser = true
end
