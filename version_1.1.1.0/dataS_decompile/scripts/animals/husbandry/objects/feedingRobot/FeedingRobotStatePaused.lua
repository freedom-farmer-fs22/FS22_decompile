FeedingRobotStatePaused = {}
local FeedingRobotStatePaused_mt = Class(FeedingRobotStatePaused, FeedingRobotState)

function FeedingRobotStatePaused.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStatePaused_mt)
	self.feedingRobot = feedingRobot

	return self
end

function FeedingRobotStatePaused:isDone()
	return self.feedingRobot.requestedStart
end

function FeedingRobotStatePaused:deactivate()
	self.feedingRobot.requestedStart = false
end

function FeedingRobotStatePaused:raiseActive()
	return false
end
