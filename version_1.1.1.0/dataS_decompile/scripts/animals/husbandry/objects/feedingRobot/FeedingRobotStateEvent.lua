FeedingRobotStateEvent = {}
local FeedingRobotStateEvent_mt = Class(FeedingRobotStateEvent, Event)

InitStaticEventClass(FeedingRobotStateEvent, "FeedingRobotStateEvent", EventIds.EVENT_FEEDING_ROBOT_STATE)

function FeedingRobotStateEvent.emptyNew()
	local self = Event.new(FeedingRobotStateEvent_mt)

	return self
end

function FeedingRobotStateEvent.new(feedingRobot, state)
	local self = FeedingRobotStateEvent.emptyNew()
	self.feedingRobot = feedingRobot
	self.state = state

	return self
end

function FeedingRobotStateEvent:readStream(streamId, connection)
	self.feedingRobot = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUInt8(streamId)

	self:run(connection)
end

function FeedingRobotStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.feedingRobot)
	streamWriteUInt8(streamId, self.state)
end

function FeedingRobotStateEvent:run(connection)
	if self.feedingRobot ~= nil then
		self.feedingRobot:setState(self.state)
	end
end
