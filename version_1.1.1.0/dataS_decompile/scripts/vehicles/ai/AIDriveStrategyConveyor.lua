AIDriveStrategyConveyor = {}
local AIDriveStrategyConveyor_mt = Class(AIDriveStrategyConveyor, AIDriveStrategy)

function AIDriveStrategyConveyor.new(customMt)
	if customMt == nil then
		customMt = AIDriveStrategyConveyor_mt
	end

	local self = AIDriveStrategy.new(customMt)

	return self
end

function AIDriveStrategyConveyor:setAIVehicle(vehicle)
	AIDriveStrategyConveyor:superClass().setAIVehicle(self, vehicle)

	local _, y, z = localToLocal(self.vehicle.wheels[self.vehicle.aiConveyorBelt.backWheelIndex].repr, self.vehicle.components[1].node, 0, 0, 0)
	local x1, y1, z1 = localToWorld(self.vehicle.components[1].node, 0, y, z)
	local x2, y2, z2 = getWorldTranslation(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr)
	local length = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)
	local width = length * math.sin(math.rad(self.vehicle.aiConveyorBelt.currentAngle / 2))
	local length2 = math.sqrt(math.pow(length, 2) - math.pow(width, 2))
	self.distanceToMove = math.rad(self.vehicle.aiConveyorBelt.currentAngle) * length / 2
	self.currentTarget = 1
	self.worldTarget = {
		{
			localToWorld(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr, width, 0, -length2)
		},
		{
			localToWorld(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr, -width, 0, -length2)
		}
	}
	self.lastPos = {
		x1,
		y1,
		z1
	}
	self.distanceMoved = 0
	self.fistTimeChange = true
end

function AIDriveStrategyConveyor:update(dt)
end

function AIDriveStrategyConveyor:getDriveData(dt, vX, vY, vZ)
	local _, y, z = localToLocal(self.vehicle.wheels[self.vehicle.aiConveyorBelt.backWheelIndex].repr, self.vehicle.components[1].node, 0, 0, 0)
	local worldCX, worldCY, worldCZ = localToWorld(self.vehicle.components[1].node, 0, y, z)
	local distanceMoved = MathUtil.vector2Length(worldCX - self.lastPos[1], worldCZ - self.lastPos[3])
	self.distanceMoved = self.distanceMoved + distanceMoved
	self.lastPos = {
		worldCX,
		worldCY,
		worldCZ
	}

	if self.distanceToMove <= self.distanceMoved then
		if self.fistTimeChange then
			self.distanceToMove = self.distanceToMove * 2
			self.fistTimeChange = false
		end

		self.distanceMoved = 0

		if self.currentTarget == 1 then
			self.currentTarget = 2
		else
			self.currentTarget = 1
		end
	end

	local speedFactor = MathUtil.clamp(math.sin(self.distanceMoved / self.distanceToMove * 3.14), 0.1, 0.5) * 2
	local dir = true

	if self.currentTarget == 2 then
		dir = not dir
	end

	return self.worldTarget[self.currentTarget][1], self.worldTarget[self.currentTarget][3], dir, self.vehicle.aiConveyorBelt.speed * speedFactor, 100
end
