FeedingRobotStateFilling = {}
local FeedingRobotStateFilling_mt = Class(FeedingRobotStateFilling, FeedingRobotState)

function FeedingRobotStateFilling.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#deltaFillLevel", "Delta fill level")
end

function FeedingRobotStateFilling.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFilling_mt)
	self.deltaFillLevel = nil

	return self
end

function FeedingRobotStateFilling:load(xmlFile, key)
	FeedingRobotStateFilling:superClass().load(self, xmlFile, key)

	self.deltaFillLevel = xmlFile:getValue(key .. "#deltaFillLevel")
end

function FeedingRobotStateFilling:deactivate()
	if self.deltaFillLevel ~= nil then
		local fillPlane = self.feedingRobot.robot.fillPlane
		local fillScale = (fillPlane.fillLevel + self.deltaFillLevel) / fillPlane.capacity

		self.feedingRobot:setFillScale(fillScale)
	end
end
