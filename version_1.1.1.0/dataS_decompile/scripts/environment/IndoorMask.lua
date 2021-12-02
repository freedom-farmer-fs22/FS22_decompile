IndoorMask = {
	NUM_CHANNELS = 1,
	FIRST_CHANNEL = 0,
	INDOOR = 1,
	OUTDOOR = 0
}
local IndoorMask_mt = Class(IndoorMask)

function IndoorMask.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or IndoorMask_mt)
	self.mission = mission
	self.isServer = isServer
	self.visualizeMask = false
	self.handle = nil
	self.layerName = "indoorMask"

	if g_addCheatCommands then
		addConsoleCommand("gsIndoorMaskToggle", "Toggle indoor mask visualization", "consoleCommandToggleMask", self)
	end

	return self
end

function IndoorMask:delete()
	g_messageCenter:unsubscribeAll(self)

	if g_addCheatCommands then
		removeConsoleCommand("gsIndoorMaskToggle")
	end
end

function IndoorMask:loadMapData(xmlFile, missionInfo, baseDirectory)
end

function IndoorMask:onTerrainLoad(terrainRootNode)
	self.handle = getInfoLayerFromTerrain(terrainRootNode, self.layerName)

	if self.handle == nil or self.handle == 0 then
		self.handle = 0

		Logging.error("Layer '%s' is missing for current map!", self.layerName)
	end

	self.terrainSize = self.mission.terrainSize

	if self.handle ~= nil then
		self.maskSize = getBitVectorMapSize(self.handle)
		self.modifierValue = DensityMapModifier.new(self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
		self.filter = DensityMapFilter.new(self.modifierValue)
	end
end

function IndoorMask:draw()
	if self.visualizeMask then
		self:visualize()
	end
end

function IndoorMask:visualize()
	if self.handle ~= nil then
		local worldToDensityMap = self.maskSize / self.terrainSize
		local densityToWorldMap = self.terrainSize / self.maskSize
		local x, _, z = getWorldTranslation(getCamera(0))

		if self.mission.controlledVehicle ~= nil then
			local object = self.mission.controlledVehicle

			if self.mission.controlledVehicle.selectedImplement ~= nil then
				object = self.mission.controlledVehicle.selectedImplement.object
			end

			x, _, z = getWorldTranslation(object.components[1].node)
		end

		local terrainHalfSize = self.terrainSize * 0.5
		local xI = math.floor((x + terrainHalfSize) * worldToDensityMap)
		local zI = math.floor((z + terrainHalfSize) * worldToDensityMap)
		local minXi = math.max(xI - 20, 0)
		local minZi = math.max(zI - 20, 0)
		local maxXi = math.min(xI + 20, self.maskSize - 1)
		local maxZi = math.min(zI + 20, self.maskSize - 1)
		local areaSize = 0.5

		for zi = minZi, maxZi do
			for xi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.handle, xi, zi, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
				local r = 0
				local g = 1
				local b = 0

				if v == IndoorMask.INDOOR then
					b = 0.1
					g = 0
					r = 1
				end

				local xt = xi * densityToWorldMap - terrainHalfSize - areaSize * 0.25
				local zt = zi * densityToWorldMap - terrainHalfSize - areaSize * 0.25

				DebugUtil.drawDebugAreaRectangleFilled(xt, 0, zt, xt + areaSize, 0, zt, xt, 0, zt + areaSize, true, r, g, b, 0.2)
			end
		end
	end
end

function IndoorMask:hasMask()
	return self.handle ~= nil
end

function IndoorMask:getFilter(indoorOutdoor)
	if self.handle ~= nil then
		self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, indoorOutdoor)

		return self.filter
	end

	return nil
end

function IndoorMask:setPlaceableAreaInSnowMask(area, indoor)
	if self.handle == nil then
		return
	end

	local x, _, z = getWorldTranslation(area.start)
	local x1, _, z1 = getWorldTranslation(area.width)
	local x2, _, z2 = getWorldTranslation(area.height)

	self:setParallelogramUVCoords(self.modifierValue, x, z, x1, z1, x2, z2)
	self.modifierValue:executeSet(indoor)
end

function IndoorMask:setParallelogramUVCoords(modifier, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local terrainSize = self.terrainSize

	modifier:setParallelogramUVCoords(startWorldX / terrainSize + 0.5, startWorldZ / terrainSize + 0.5, widthWorldX / terrainSize + 0.5, widthWorldZ / terrainSize + 0.5, heightWorldX / terrainSize + 0.5, heightWorldZ / terrainSize + 0.5, DensityCoordType.POINT_POINT_POINT)
end

function IndoorMask:getDensityMapData()
	return self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS
end

function IndoorMask:consoleCommandToggleMask()
	self.visualizeMask = not self.visualizeMask

	return tostring(self.visualizeMask)
end
