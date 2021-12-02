GroundTypeManager = {}
local GroundTypeManager_mt = Class(GroundTypeManager, AbstractManager)

function GroundTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or GroundTypeManager_mt)

	return self
end

function GroundTypeManager:initDataStructures()
	self.groundTypes = {}
	self.groundTypeMappings = {}
	self.terrainLayerMapping = {}
end

function GroundTypeManager:loadGroundTypes()
	self.groundTypes = {}
	local xmlFile = loadXMLFile("fuitTypes", "data/maps/groundTypes.xml")
	local i = 0

	while true do
		local key = string.format("groundTypes.groundType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")

		if name ~= nil then
			local groundType = {
				fallbacks = string.split(getXMLString(xmlFile, key .. "#fallbacks"), " ")
			}
			self.groundTypes[name] = groundType
		else
			Logging.xmlWarning(xmlFile, "Missing groundType name for '%s'", key)
		end

		i = i + 1
	end

	delete(xmlFile)
end

function GroundTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GroundTypeManager:superClass().loadMapData(self)
	self:loadGroundTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "groundTypeMappings", baseDirectory, self, self.loadGroundTypeMappings, missionInfo)
end

function GroundTypeManager:loadGroundTypeMappings(xmlFile, missionInfo)
	local i = 0

	while true do
		local key = string.format("map.groundTypeMappings.groundTypeMapping(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local typeName = getXMLString(xmlFile, key .. "#type")

		if typeName ~= nil then
			local layerName = getXMLString(xmlFile, key .. "#layer")

			if layerName ~= nil then
				local title = getXMLString(xmlFile, key .. "#title")

				if title ~= nil then
					local groundType = {
						typeName = typeName,
						layerName = layerName,
						title = title
					}
					self.groundTypeMappings[groundType.typeName] = groundType
				else
					Logging.xmlWarning(xmlFile, "Missing groudTypeMapping title for '%s'", key)
				end
			else
				Logging.xmlWarning(xmlFile, "Missing groudTypeMapping layerName for '%s'", key)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing groudTypeMapping type for '%s'", key)
		end

		i = i + 1
	end

	return true
end

function GroundTypeManager:initTerrain(terrainRootNode)
	self.terrainLayerMapping = {}
	local numLayers = getTerrainNumOfLayers(terrainRootNode)

	for i = 0, numLayers - 1 do
		local layerName = getTerrainLayerName(terrainRootNode, i)
		self.terrainLayerMapping[layerName] = i
	end
end

function GroundTypeManager:getTerrainTitleByType(typeName)
	return self.groundTypeMappings[typeName].title
end

function GroundTypeManager:getTerrainLayerByType(typeName)
	local layerName = nil

	if typeName ~= nil and self.groundTypeMappings[typeName] ~= nil then
		layerName = self.groundTypeMappings[typeName].layerName
	end

	if layerName ~= nil then
		local layer = self.terrainLayerMapping[layerName]

		if layer ~= nil then
			return layer
		end
	end

	local groundType = self.groundTypes[typeName]

	if groundType ~= nil then
		for _, fallbackTypeName in pairs(groundType.fallbacks) do
			local callbackLayer = self.groundTypeMappings[fallbackTypeName]

			if callbackLayer ~= nil then
				local fallbackLayerName = self.groundTypeMappings[fallbackTypeName].layerName

				if fallbackLayerName ~= nil then
					local layer = self.terrainLayerMapping[fallbackLayerName]

					if layer ~= nil then
						return layer
					end
				end
			else
				Logging.warning("Unknown fallback layer '%s' for ground type '%s'", fallbackTypeName, typeName)
			end
		end
	end

	return 0
end

g_groundTypeManager = GroundTypeManager.new()
