AIDebugVehicle = {}
local AIDebugVehicle_mt = Class(AIDebugVehicle)

function AIDebugVehicle.new(vehicle, color, customMt)
	local self = setmetatable({}, customMt or AIDebugVehicle_mt)
	self.vehicle = vehicle
	self.agentInfo = vehicle.spec_aiDrivable.agentInfo
	self.color = color
	self.targetFlag = DebugFlag.new(color[1], color[2], color[3])
	self.paths = {}

	return self
end

function AIDebugVehicle:delete()
end

function AIDebugVehicle:setTarget(x, y, z, dirX, dirY, dirZ)
	local path = DebugPath.new({
		1,
		0,
		0
	}, true, 1, false)
	local factor = 0.5 + #self.paths % 2 * 0.5

	path:setColor(self.color[1] * factor, self.color[2] * factor, self.color[3] * factor)
	table.insert(self.paths, path)
	self.targetFlag:create(x, y, z, dirX or 1, dirZ or 0)
	self:addCurrentPosition()
end

function AIDebugVehicle:update(dt)
	self:addCurrentPosition()
end

function AIDebugVehicle:addCurrentPosition()
	local aiRootNode = self.vehicle:getAIRootNode()
	local x, y, z = getWorldTranslation(aiRootNode)

	self.paths[#self.paths]:addPoint(x, y, z)
end

function AIDebugVehicle:draw(forcedY)
	for _, path in ipairs(self.paths) do
		path:draw(forcedY)
	end

	self.targetFlag:draw()
end
