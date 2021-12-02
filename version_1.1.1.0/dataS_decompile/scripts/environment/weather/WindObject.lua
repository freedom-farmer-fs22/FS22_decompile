WindObject = {}
local WindObject_mt = Class(WindObject)

function WindObject.new(customMt)
	local self = setmetatable({}, customMt or WindObject_mt)
	self.windDirectionX = 1
	self.windDirectionZ = 1
	self.windVelocity = 1
	self.cirrusSpeedFactor = 1

	return self
end

function WindObject:load(xmlFile, key)
	local windAngle = xmlFile:getFloat(key .. "#angle", 0)
	local xDir, zDir = MathUtil.getDirectionFromYRotation(math.rad(windAngle))
	self.windDirectionX = xDir
	self.windDirectionZ = zDir
	self.windAngle = windAngle
	self.windVelocity = MathUtil.kmhToMps(xmlFile:getFloat(key .. "#speed", 30))
	self.cirrusSpeedFactor = xmlFile:getFloat(key .. "#cirrusSpeedFactor", 1)

	return true
end

function WindObject:delete()
end

function WindObject:getValues()
	return self.windDirectionX, self.windDirectionZ, self.windVelocity, self.cirrusSpeedFactor
end
