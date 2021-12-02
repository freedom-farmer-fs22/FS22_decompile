FoliageSystem = {}
local FoliageSystem_mt = Class(FoliageSystem)

function FoliageSystem.new(customMt)
	local self = setmetatable({}, customMt or FoliageSystem_mt)
	self.terrainRootNode = 0
	self.paintableFoliages = {}
	self.decoFoliages = {}
	self.decoFoliageMappings = {}

	return self
end

function FoliageSystem:delete()
	self.paintableFoliages = {}
	self.decoFoliages = {}
end

function FoliageSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	local xmlFile = XMLFile.wrap(mapXmlFile)

	xmlFile:iterate("map.paintableFoliages.paintableFoliage", function (index, key)
		local layerName = xmlFile:getString(key .. "#layerName")

		if layerName ~= nil then
			local startStateChannel = xmlFile:getInt(key .. "#startChannel", 0)
			local numStateChannels = xmlFile:getInt(key .. "#numChannels", 4)
			local state = xmlFile:getInt(key .. "#state", 0)
			local paintableFoliage = {
				layerName = layerName,
				startStateChannel = startStateChannel,
				numStateChannels = numStateChannels,
				state = state,
				id = #self.paintableFoliages + 1
			}

			table.insert(self.paintableFoliages, paintableFoliage)
		else
			Logging.xmlWarning(xmlFile, "Missing layerName for paintableFoliage '%s'", key)
		end
	end)

	local decoFoliageLayerNames = {}

	xmlFile:iterate("map.decoFoliages.decoFoliage", function (index, key)
		local decoFoliage = {
			layerName = xmlFile:getString(key .. "#layerName")
		}

		if decoFoliage.layerName ~= nil then
			decoFoliage.startStateChannel = xmlFile:getInt(key .. "#startChannel", 0)
			decoFoliage.numStateChannels = xmlFile:getInt(key .. "#numChannels", 4)
			decoFoliage.mowable = xmlFile:getBool(key .. "#mowable")
			decoFoliageLayerNames[decoFoliage.layerName:upper()] = decoFoliage

			table.insert(self.decoFoliages, decoFoliage)
		else
			Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage '%s'", key)
		end
	end)

	self.decoFoliageMappings = {}

	xmlFile:iterate("map.decoFoliages.mapping", function (index, key)
		local name = xmlFile:getString(key .. "#name")

		if name ~= nil then
			local nameUpper = name:upper()

			if self.decoFoliageMappings[nameUpper] == nil then
				local layerName = xmlFile:getString(key .. "#layerName")

				if layerName ~= nil then
					local layerNameUpper = layerName:upper()
					local decoFoliage = decoFoliageLayerNames[layerNameUpper]

					if decoFoliage ~= nil then
						local state = xmlFile:getInt(key .. "#state")
						self.decoFoliageMappings[nameUpper] = {
							decoFoliage = decoFoliage,
							state = state
						}
					else
						Logging.xmlWarning(xmlFile, "Mapping layerName '%s' not defined deco foliages for '%s'", layerName, key)
					end
				else
					Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage mapping '%s'", key)
				end
			else
				Logging.xmlWarning(xmlFile, "Name '%s' already defined for decoFoliage mapping '%s'", name, key)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing name for decoFoliage mapping '%s'", key)
		end
	end)
	xmlFile:delete()

	return true
end

function FoliageSystem:unloadMapData()
	self.paintableFoliages = {}
end

function FoliageSystem:initTerrain(mission, terrainRootNode, terrainDetailId)
	self.terrainRootNode = terrainRootNode

	for key, paintableFoliage in pairs(self.paintableFoliages) do
		local id = getTerrainDataPlaneByName(self.terrainRootNode, paintableFoliage.layerName)

		if id ~= nil and id ~= 0 then
			paintableFoliage.terrainDataPlaneId = id
			paintableFoliage.paintModifier = DensityMapModifier.new(id, paintableFoliage.startStateChannel, paintableFoliage.numStateChannels, terrainRootNode)
			paintableFoliage.paintFilter = DensityMapFilter.new(paintableFoliage.paintModifier)
		else
			paintableFoliage.disabled = true
		end
	end

	for key, decoFoliage in pairs(self.decoFoliages) do
		local id = getTerrainDataPlaneByName(self.terrainRootNode, decoFoliage.layerName)

		if id ~= nil and id ~= 0 then
			decoFoliage.terrainDataPlaneId = id
			decoFoliage.modifier = DensityMapModifier.new(id, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
		end
	end
end

function FoliageSystem:addDensityMapSyncer(densityMapSyncer)
	for key, decoFoliage in pairs(self.decoFoliages) do
		if decoFoliage.terrainDataPlaneId ~= nil then
			densityMapSyncer:addDensityMap(decoFoliage.terrainDataPlaneId)
		end
	end
end

function FoliageSystem:applyAreas(modifiedAreas, paintTerrainFoliageId)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.id == paintTerrainFoliageId and not paintableFoliage.disabled then
			for _, area in pairs(modifiedAreas) do
				local x, z, x1, z1, x2, z2 = unpack(area)

				self:apply(paintableFoliage, x, z, x1 - x, z1 - z, x2 - x, z2 - z)
			end

			return true
		end
	end

	return false
end

function FoliageSystem:getFoliagePaint(id)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.id == id and not paintableFoliage.disabled then
			return paintableFoliage
		end
	end

	return nil
end

function FoliageSystem:getFoliagePaintByName(name)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.layerName == name and not paintableFoliage.disabled then
			return paintableFoliage
		end
	end

	return nil
end

function FoliageSystem:apply(foliage, x, z, x1, z1, x2, z2, value)
	local modifier = foliage.paintModifier
	local filter = foliage.paintFilter

	if value == nil then
		value = foliage.value
	end

	modifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, value)

	local _, numPixels, _ = modifier:executeSet(value, filter)

	return numPixels / 4
end

function FoliageSystem:getDecoFoliages()
	return self.decoFoliages
end

function FoliageSystem:getIsDecoLayerDefined(decoName)
	local nameUpper = decoName:upper()
	local data = self.decoFoliageMappings[nameUpper]

	return data ~= nil
end

function FoliageSystem:applyDecoFoliage(decoName, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local nameUpper = decoName:upper()
	local data = self.decoFoliageMappings[nameUpper]

	if data ~= nil then
		local decoFoliage = data.decoFoliage
		local state = data.state
		local modifier = decoFoliage.modifier

		if modifier ~= nil then
			modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			modifier:executeSet(state)
		end
	end
end
