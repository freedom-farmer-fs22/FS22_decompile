PlaceableWeatherStation = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEventListeners = function (placeableType)
		SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWeatherStation)
		SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWeatherStation)
	end,
	onDelete = function (self)
		g_currentMission.placeableSystem:removeWeatherStation(self)
	end,
	onFinalizePlacement = function (self)
		g_currentMission.placeableSystem:addWeatherStation(self)
	end
}
