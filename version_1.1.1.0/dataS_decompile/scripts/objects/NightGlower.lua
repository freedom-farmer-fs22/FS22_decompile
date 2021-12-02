NightGlower = {}
local NightGlower_mt = Class(NightGlower)

function NightGlower:onCreate(id)
	g_currentMission:addUpdateable(NightGlower.new(id))
end

function NightGlower.new(id)
	local self = {}

	setmetatable(self, NightGlower_mt)

	self.id = id
	self.isSunOn = true
	self.maxGlow = {
		1,
		6,
		3
	}
	self.minGlow = {
		1,
		3,
		1
	}
	self.timer = 0

	setShaderParameter(self.id, "colorTint", 1, 1, 1, 1, false)
	g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.onWeatherChanged, self)

	return self
end

function NightGlower:delete()
	g_messageCenter:unsubscribeAll(self)
end

function NightGlower:update(dt)
	if not self.isSunOn then
		self.timer = (self.timer + dt * 0.001) % (2 * math.pi)
		local glowValue = (math.sin(self.timer) + 1) / 2
		local currentGlow = {
			0,
			0,
			0
		}
		currentGlow[1] = glowValue * self.maxGlow[1] + (1 - glowValue) * self.minGlow[1]
		currentGlow[2] = glowValue * self.maxGlow[2] + (1 - glowValue) * self.minGlow[2]
		currentGlow[3] = glowValue * self.maxGlow[3] + (1 - glowValue) * self.minGlow[3]

		setShaderParameter(self.id, "colorTint", currentGlow[1], currentGlow[2], currentGlow[3], 1, false)
	end
end

function NightGlower:onWeatherChanged()
	self.isSunOn = g_currentMission.environment.isSunOn

	if self.isSunOn then
		setShaderParameter(self.id, "colorTint", 1, 1, 1, 1, false)
	end
end
