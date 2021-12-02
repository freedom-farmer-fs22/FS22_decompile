WeatherObjectRain = {}
local WeatherObjectRain_mt = Class(WeatherObjectRain, WeatherObject)

function WeatherObjectRain.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, customMt)
	local self = WeatherObjectRain:superClass().new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, customMt or WeatherObjectRain_mt)
	self.sharedLoadRequestId = nil
	self.rainNode = nil
	self.geometries = {}
	self.isVisible = true
	self.alpha = 1
	self.duration = 1
	self.currentDropScale = 0
	self.lastDropScale = 0
	self.targetDropScale = 0

	self.windUpdater:addWindChangedListener(self)
	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)

	return self
end

function WeatherObjectRain:load(xmlFile, key, cloudPresets)
	if not WeatherObjectRain:superClass().load(self, xmlFile, key, cloudPresets) then
		return false
	end

	local filename = xmlFile:getString(key .. ".rain#filename")

	if filename ~= nil and filename ~= "" then
		filename = Utils.getFilename(filename, g_currentMission.baseDirectory)
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.rainI3DFileLoaded, self, nil)
	else
		Logging.xmlWarning(xmlFile, "Missing rain filename for '%s'", key)

		return false
	end

	return true
end

function WeatherObjectRain:rainI3DFileLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.rainNode = i3dNode

		link(getRootNode(), self.rainNode)
		setCullOverride(self.rainNode, true)
		setVisibility(self.rainNode, false)

		for i = 1, getNumOfChildren(self.rainNode) do
			local child = getChildAt(self.rainNode, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				local geometry = getGeometry(child)

				if geometry ~= 0 and getHasClassId(geometry, ClassIds.PRECIPITATION) then
					table.insert(self.geometries, geometry)
					setDropCountScale(geometry, 0)
				end
			end
		end
	else
		Logging.warning("Failed to load rain i3d file!'")
	end
end

function WeatherObjectRain:loadVariation(xmlFile, key, variation, cloudPresets)
	if not WeatherObjectRain:superClass().loadVariation(self, xmlFile, key, variation, cloudPresets) then
		return false
	end

	variation.rain = {
		dropScale = xmlFile:getFloat(key .. "#dropScale", 1)
	}

	return true
end

function WeatherObjectRain:delete()
	g_messageCenter:unsubscribeAll(self)
	self.windUpdater:removeWindChangedListener(self)

	if self.rainNode ~= nil then
		delete(self.rainNode)

		self.rainNode = nil

		for i = #self.geometries, 1, -1 do
			self.geometries[i] = nil
		end
	end

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end

	WeatherObjectRain:superClass().delete(self)
end

function WeatherObjectRain:update(dt)
	WeatherObjectRain:superClass().update(self, dt)

	if self.alpha ~= 1 then
		self.alpha = math.min(self.alpha + dt / self.duration, 1)
		self.currentDropScale = MathUtil.lerp(self.lastDropScale, self.targetDropScale, self.alpha)

		for _, geometry in ipairs(self.geometries) do
			setDropCountScale(geometry, self.currentDropScale)
		end
	end

	if self.rainNode ~= nil then
		setVisibility(self.rainNode, self.isVisible and self.currentDropScale ~= 0)
	end
end

function WeatherObjectRain:getRainFallScale()
	return self.currentDropScale
end

function WeatherObjectRain:activate(variationIndex, duration)
	WeatherObjectRain:superClass().activate(self, variationIndex, duration)

	local variation = self.variations[variationIndex]
	self.alpha = 0
	self.duration = duration
	self.lastDropScale = self.currentDropScale
	self.targetDropScale = variation.rain.dropScale
end

function WeatherObjectRain:deactivate(duration)
	WeatherObjectRain:superClass().deactivate(self, duration)

	self.alpha = 0
	self.targetDropScale = 0
	self.lastDropScale = self.currentDropScale
	self.duration = duration * 0.5
end

function WeatherObjectRain:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	local nDirX = windDirX * windVelocity / WindUpdater.MAX_SPEED
	local nDirZ = windDirZ * windVelocity / WindUpdater.MAX_SPEED

	for _, geometry in ipairs(self.geometries) do
		setWindVelocity(geometry, nDirX, 0, nDirZ)
	end
end

function WeatherObjectRain:onGameStateChanged(newGameState, oldGameState)
	self.isVisible = newGameState ~= GameState.MENU_SHOP_CONFIG
end
