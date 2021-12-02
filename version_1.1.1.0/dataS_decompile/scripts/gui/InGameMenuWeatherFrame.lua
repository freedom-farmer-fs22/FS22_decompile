InGameMenuWeatherFrame = {}
local InGameMenuWeatherFrame_mt = Class(InGameMenuWeatherFrame, TabbedMenuFrameElement)
InGameMenuWeatherFrame.CONTROLS = {
	"forecastHourlyList",
	"forecastDailyList",
	"forecastHourlySlider",
	"nowTemperature",
	"nowWindSpeed",
	"nowTemperatureUnit",
	"nowWeatherIcon",
	"nowWindDirection",
	"nowWeatherMonth",
	CONTAINER = "container"
}
InGameMenuWeatherFrame.TEXTURE_SIZE = {
	512,
	512
}

function InGameMenuWeatherFrame.new(i18n, messageCenter)
	local self = InGameMenuWeatherFrame:superClass().new(nil, InGameMenuWeatherFrame_mt)
	self.i18n = i18n
	self.messageCenter = messageCenter

	self:registerControls(InGameMenuWeatherFrame.CONTROLS)

	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0

	return self
end

function InGameMenuWeatherFrame:delete()
	InGameMenuWeatherFrame:superClass().delete(self)
end

function InGameMenuWeatherFrame:copyAttributes(src)
	InGameMenuWeatherFrame:superClass().copyAttributes(self, src)

	self.i18n = src.i18n
	self.messageCenter = src.messageCenter
end

function InGameMenuWeatherFrame:onGuiSetupFinished()
	InGameMenuWeatherFrame:superClass().onGuiSetupFinished(self)
	self.forecastHourlyList:setDataSource(self)
	self.forecastDailyList:setDataSource(self)
end

function InGameMenuWeatherFrame:initialize()
end

function InGameMenuWeatherFrame:onFrameOpen()
	InGameMenuWeatherFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	self.messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.onTemperatureUnitChanged, self)

	if g_currentMission ~= nil then
		self.forecast = g_currentMission.environment.weather.forecast
	end

	self:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.forecastHourlyList)
	self:setSoundSuppressed(false)
end

function InGameMenuWeatherFrame:onFrameClose()
	self.messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	self.messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
	self.messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self)
	InGameMenuWeatherFrame:superClass().onFrameClose(self)
end

function InGameMenuWeatherFrame:reloadData()
	self.forecastHourlyList:reloadData()
	self.forecastDailyList:reloadData()
	self:updateTodayView()
end

function InGameMenuWeatherFrame:updateTodayView()
	local now = self.forecast:getCurrentWeather()

	self.nowTemperature:setValue(g_i18n:getTemperature(now.temperature))
	self.nowWindSpeed:setValue(self:meterPerSecondToBeaufort(now.windSpeed))
	self.nowTemperatureUnit:setText(g_i18n:getTemperatureUnit(false))
	self.nowWeatherIcon:setImageUVs(nil, unpack(GuiUtils.getUVs(InGameMenuWeatherFrame.ICONS[now.forecastType], InGameMenuWeatherFrame.TEXTURE_SIZE)))

	local period = g_currentMission.environment.currentPeriod
	local dayInPeriod = g_currentMission.environment.currentDayInPeriod

	self.nowWeatherMonth:setText(g_i18n:formatDayInPeriod(dayInPeriod, period, false))

	local dir = self.nowWindDirection

	dir:setImageRotation(math.rad(now.windDirection) + math.pi)

	dir.overlay.customPivot = {
		dir.absSize[1] / 2,
		dir.absSize[2] * 0.343
	}
end

function InGameMenuWeatherFrame:getNumberOfItemsInSection(list, section)
	if self.forecast == nil then
		return 0
	end

	if list == self.forecastHourlyList then
		if g_currentMission.placeableSystem:getHasWeatherStation(g_currentMission:getFarmId()) then
			return 24
		else
			return 12
		end
	else
		return 7
	end
end

function InGameMenuWeatherFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.forecastHourlyList then
		local forecastInfo = self.forecast:getHourlyForecast(index - 1)

		if forecastInfo ~= nil then
			local timeHours = math.floor(forecastInfo.time / 3600000 + 0.0001)
			local uvs = GuiUtils.getUVs(InGameMenuWeatherFrame.ICONS[forecastInfo.forecastType], InGameMenuWeatherFrame.TEXTURE_SIZE)

			cell:getAttribute("icon"):setImageUVs(nil, unpack(uvs))
			cell:getAttribute("time"):setText(string.format("%02d:00", timeHours))
			cell:getAttribute("temperature"):setValue(forecastInfo.temperature)
			cell:getAttribute("windSpeed"):setValue(self:meterPerSecondToBeaufort(forecastInfo.windSpeed))
			cell:getAttribute("windDirection"):setImageRotation(math.rad(forecastInfo.windDirection) + math.pi)
		end
	else
		local forecastInfo = g_currentMission.environment.weather.forecast:getDailyForecast(index)
		local uvs = GuiUtils.getUVs(InGameMenuWeatherFrame.ICONS[forecastInfo.forecastType], InGameMenuWeatherFrame.TEXTURE_SIZE)

		cell:getAttribute("icon"):setImageUVs(nil, unpack(uvs))

		local period = g_currentMission.environment:getPeriodFromDay(forecastInfo.day)
		local dayInPeriod = g_currentMission.environment:getDayInPeriodFromDay(forecastInfo.day)

		cell:getAttribute("day"):setText(g_i18n:formatDayInPeriod(dayInPeriod, period, false))
		cell:getAttribute("highTemperature"):setValue(forecastInfo.highTemperature)
		cell:getAttribute("lowTemperature"):setValue(forecastInfo.lowTemperature)
		cell:getAttribute("windSpeed"):setValue(self:meterPerSecondToBeaufort(forecastInfo.windSpeed))
		cell:getAttribute("windDirection"):setImageRotation(math.rad(forecastInfo.windDirection) + math.pi)
	end

	local dir = cell:getAttribute("windDirection")
	dir.overlay.customPivot = {
		dir.size[1] * 0.5,
		dir.size[2] * 0.343
	}
end

function InGameMenuWeatherFrame:meterPerSecondToBeaufort(mps)
	return math.floor(math.pow(math.ceil(mps, 0) / 0.836, 0.6666666666666666))
end

function InGameMenuWeatherFrame:onDayChanged()
	self:reloadData()
end

function InGameMenuWeatherFrame:onHourChanged()
	self:reloadData()
end

function InGameMenuWeatherFrame:inputEvent(action, value, eventUsed)
	local pressedLeft = action == InputAction.MENU_AXIS_LEFT_RIGHT and value < -g_analogStickHTolerance
	local pressedRight = action == InputAction.MENU_AXIS_LEFT_RIGHT and g_analogStickHTolerance < value

	if pressedLeft or pressedRight then
		local dir = pressedLeft and -1 or 1

		if dir ~= self.scrollInputDelayDir or g_time - self.scrollInputDelay > 250 then
			self.scrollInputDelayDir = dir
			self.scrollInputDelay = g_time

			self.forecastHourlySlider:setValue(self.forecastHourlySlider:getValue() + dir)
		end
	end

	return true
end

function InGameMenuWeatherFrame:onTemperatureUnitChanged()
	self:updateTodayView()
end

InGameMenuWeatherFrame.ICONS = {
	[WeatherForecast.TYPE.CLEAR] = {
		0,
		0,
		128,
		128
	},
	[WeatherForecast.TYPE.CLOUDY] = {
		256,
		0,
		128,
		128
	},
	[WeatherForecast.TYPE.MIXED] = {
		128,
		0,
		128,
		128
	},
	[WeatherForecast.TYPE.RAIN] = {
		384,
		0,
		128,
		128
	},
	[WeatherForecast.TYPE.SNOW] = {
		0,
		128,
		128,
		128
	},
	[WeatherForecast.TYPE.HAIL] = {
		128,
		128,
		128,
		128
	},
	[WeatherForecast.TYPE.FOG] = {
		384,
		128,
		128,
		128
	},
	[WeatherForecast.TYPE.WINDY] = {
		256,
		128,
		128,
		128
	},
	[WeatherForecast.TYPE.THUNDER] = {
		0,
		192,
		128,
		128
	}
}
