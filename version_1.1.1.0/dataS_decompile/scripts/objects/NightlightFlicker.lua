NightlightFlicker = {}
local NightlightFlicker_mt = Class(NightlightFlicker)

function NightlightFlicker:onCreate(id)
	g_currentMission:addUpdateable(NightlightFlicker.new(id))
end

function NightlightFlicker.new(id)
	local self = {}

	setmetatable(self, NightlightFlicker_mt)

	self.id = id
	self.isVisible = false
	self.isFlickerActive = false
	self.nextFlicker = 0
	self.flickerDuration = 100

	setVisibility(self.id, self.isVisible)
	g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.oNWeatherChanged, self)

	return self
end

function NightlightFlicker:delete()
	g_messageCenter:unsubscribeAll(self)
end

function NightlightFlicker:update(dt)
	if self.isVisible then
		self.nextFlicker = self.nextFlicker - dt

		if self.nextFlicker <= 0 then
			self.isFlickerActive = true

			setVisibility(self.id, false)

			self.nextFlicker = math.floor(math.random() * 1500 + self.flickerDuration + 10)
		end

		if self.isFlickerActive then
			self.flickerDuration = self.flickerDuration - dt

			if self.flickerDuration <= 0 then
				self.isFlickerActive = false
				self.flickerDuration = math.floor(math.random() * 200)

				setVisibility(self.id, true)
			end
		end
	end
end

function NightlightFlicker:onWeatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		self.isVisible = not g_currentMission.environment.isSunOn or not not g_currentMission.environment.weather:getIsRaining()

		setVisibility(self.id, self.isVisible)
	end
end
