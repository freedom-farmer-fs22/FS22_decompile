FeedingRobotStateStarting = {}
local FeedingRobotStateStarting_mt = Class(FeedingRobotStateStarting, FeedingRobotState)

function FeedingRobotStateStarting.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateStarting_mt)

	return self
end
