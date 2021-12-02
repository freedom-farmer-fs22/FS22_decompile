FeedingRobotStateFinished = {}
local FeedingRobotStateFinished_mt = Class(FeedingRobotStateFinished, FeedingRobotState)

function FeedingRobotStateFinished.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFinished_mt)

	return self
end
