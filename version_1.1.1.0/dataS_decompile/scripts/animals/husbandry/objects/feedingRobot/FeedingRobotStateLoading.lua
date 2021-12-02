FeedingRobotStateLoading = {}
local FeedingRobotStateLoading_mt = Class(FeedingRobotStateLoading, FeedingRobotState)

function FeedingRobotStateLoading.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateLoading_mt)
	self.feedingRobot = feedingRobot

	return self
end

function FeedingRobotStateLoading:isDone()
	return self.feedingRobot.isLoadingFinished
end

function FeedingRobotStateLoading:raiseActive()
	return false
end
