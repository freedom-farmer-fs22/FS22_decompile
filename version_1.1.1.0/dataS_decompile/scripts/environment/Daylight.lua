Daylight = {}
local Daylight_mt = Class(Daylight)

function Daylight.new(environment, customMt)
	local self = setmetatable({}, customMt or Daylight_mt)
	self.environment = environment
	self.dayStart = 6
	self.dayEnd = 20
	self.nightEnd = 8
	self.nightStart = 18
	self.logicalNightStart = 6
	self.logicalNightEnd = 18
	self.logicalNightStartMinutes = self.logicalNightStart * 60
	self.logicalNightEndMinutes = self.logicalNightEnd * 60

	return self
end

function Daylight:delete()
end

function Daylight:load(xmlFile, baseKey)
	self.latitude = xmlFile:getFloat(baseKey .. ".latitude", 50)
	self.latitudeInRadians = self.latitude * math.pi / 180
end

function Daylight:saveToXMLFile(xmlFile, key)
end

function Daylight:loadFromXMLFile(xmlFile, key)
end

function Daylight:setEnvironment(environment)
	self.environment = environment
end

function Daylight:setJulianDay(julianDay)
	if self.julianDay ~= julianDay then
		self.julianDay = julianDay
		self.dayStart, self.dayEnd, self.nightEnd, self.nightStart = self:calculateStartEndOfDay()
		self.logicalNightStart = MathUtil.lerp(self.dayEnd, self.nightStart, 0.3)
		self.logicalNightEnd = MathUtil.lerp(self.nightEnd, self.dayStart, 0.8)
		self.logicalNightStartMinutes = self.logicalNightStart * 60
		self.logicalNightEndMinutes = self.logicalNightEnd * 60

		g_messageCenter:publishDelayed(MessageType.DAYLIGHT_CHANGED)
	end
end

function Daylight:getDaylightTimes()
	return self.dayStart, self.dayEnd, self.nightEnd, self.nightStart
end

function Daylight:getLogicalNightTime()
	return self.logicalNightStart, self.logicalNightEnd
end

function Daylight:getSunHeightAngle()
	return self.latitudeInRadians - self:calculateSunDeclination() - math.pi / 2
end

function Daylight:calculateStartEndOfDay()
	local dayStart, dayEnd, nightEnd, nightStart = nil
	local sunDeclination = self:calculateSunDeclination()
	dayStart = self:calculateTime(-12, true, sunDeclination)
	dayEnd = self:calculateTime(-5, false, sunDeclination)
	nightStart = self:calculateTime(14, false, sunDeclination)
	nightEnd = self:calculateTime(5, true, sunDeclination)
	nightEnd = math.max(nightEnd, 1.01)

	if dayStart == dayEnd then
		dayEnd = dayEnd + 0.01
	end

	nightStart = math.min(nightStart, 22.99)
	dayEnd = math.min(dayEnd, nightStart - 0.01)

	return dayStart, dayEnd, nightEnd, nightStart
end

function Daylight:calculateTime(position, isDawn, sunDeclination)
	local denom = nil
	position = position * math.pi / 180
	local latitudeInRadians = self.latitudeInRadians
	local gamma = (math.sin(position) + math.sin(latitudeInRadians) * math.sin(sunDeclination)) / (math.cos(latitudeInRadians) * math.cos(sunDeclination))

	if gamma < -1 then
		denom = 0
	elseif gamma > 1 then
		denom = 24
	else
		denom = 24 - 24 / math.pi * math.acos(gamma)
	end

	if isDawn then
		return math.max(12 - denom / 2, 0.01)
	else
		return math.min(12 + denom / 2, 23.99)
	end
end

function Daylight:calculateSunDeclination()
	local theta = 0.216 + 2 * math.atan(0.967 * math.tan(0.0086 * (self.julianDay - 186)))

	return math.asin(0.4 * math.cos(theta))
end
