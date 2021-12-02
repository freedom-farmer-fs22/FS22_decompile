FeedingRobotStateDriving = {}
local FeedingRobotStateDriving_mt = Class(FeedingRobotStateDriving, FeedingRobotState)

function FeedingRobotStateDriving.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateDriving_mt)
	self.startFillScale = 0

	return self
end

function FeedingRobotStateDriving:isDone()
	return self.feedingRobot.spline.time == 1
end

function FeedingRobotStateDriving:update(dt)
	if self.feedingRobot.isServer then
		local robot = self.feedingRobot.robot
		local acc = robot.acceleration

		if robot.isBlocked then
			acc = robot.deceleration
		end

		robot.speed = MathUtil.clamp(robot.speed + acc * g_physicsDt / 1000, 0, robot.maxSpeed)

		if robot.speed > 0 then
			self.feedingRobot:addSplineDelta(dt * robot.speed)
		end
	end

	local feedingFactor = self.feedingRobot:getFeedingFactor()
	local fillScale = self.startFillScale - self.startFillScale * feedingFactor

	self.feedingRobot:setFillScale(fillScale)
end

function FeedingRobotStateDriving:activate()
	g_animationManager:startAnimations(self.feedingRobot.robot.mixerAnimationNodes)
	self.feedingRobot:resetRobot()

	self.startFillScale = self.feedingRobot.robot.fillPlane.fillLevel / self.feedingRobot.robot.fillPlane.capacity
end

function FeedingRobotStateDriving:deactivate()
	g_animationManager:stopAnimations(self.feedingRobot.robot.mixerAnimationNodes)
	self.feedingRobot:resetRobot()
	self.feedingRobot:setFillScale(0)

	self.startFillScale = 0
end
