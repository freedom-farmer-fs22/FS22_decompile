PlaceableHotspots = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHotspots.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getHotspot", PlaceableHotspots.getHotspot)
end

function PlaceableHotspots.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHotspots.setOwnerFarmId)
end

function PlaceableHotspots.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHotspots)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHotspots)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHotspots)
end

function PlaceableHotspots.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Hotspots")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#linkNode", "Node where hotspot is linked to")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".hotspots.hotspot(?)#teleportNode", "Node where player is teleported to. Teleporting is only available if this is set")
	schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#type", "Placeable hotspot type")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".hotspots.hotspot(?)#worldPosition", "Placeable world position")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".hotspots.hotspot(?)#teleportWorldPosition", "Placeable teleport world position")
	schema:register(XMLValueType.STRING, basePath .. ".hotspots.hotspot(?)#text", "Placeable hotspot text")
	schema:setXMLSpecializationType()
end

function PlaceableHotspots:onLoad(savegame)
	local spec = self.spec_hotspots
	spec.mapHotspots = {}

	self.xmlFile:iterate("placeable.hotspots.hotspot", function (_, key)
		local hotspot = PlaceableHotspot.new()

		hotspot:setPlaceable(self)

		local hotspotTypeName = self.xmlFile:getValue(key .. "#type", "UNLOADING")
		local hotspotType = PlaceableHotspot.getTypeByName(hotspotTypeName)

		if hotspotType == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown placeable hotspot type '%s'. Falling back to type 'UNLOADING'\nAvailable types: %s", hotspotTypeName, table.concatKeys(PlaceableHotspot.TYPE, " "))

			hotspotType = PlaceableHotspot.TYPE.UNLOADING
		end

		hotspot:setPlaceableType(hotspotType)

		local linkNode = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings) or self.rootNode

		if linkNode ~= nil then
			local x, _, z = getWorldTranslation(linkNode)

			hotspot:setWorldPosition(x, z)
		end

		local teleportNode = self.xmlFile:getValue(key .. "#teleportNode", nil, self.components, self.i3dMappings)

		if teleportNode ~= nil then
			local x, y, z = getWorldTranslation(teleportNode)

			hotspot:setTeleportWorldPosition(x, y, z)
		end

		local worldPositionX, worldPositionZ = self.xmlFile:getValue(key .. "#worldPosition", nil)

		if worldPositionX ~= nil then
			hotspot:setWorldPosition(worldPositionX, worldPositionZ)
		end

		local teleportX, teleportY, teleportZ = self.xmlFile:getValue(key .. "#teleportWorldPosition", nil)

		if teleportX ~= nil then
			if g_currentMission ~= nil then
				teleportY = math.max(teleportY, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, teleportX, 0, teleportZ))
			end

			hotspot:setTeleportWorldPosition(teleportX, teleportY, teleportZ)
		end

		local text = self.xmlFile:getValue(key .. "#text", nil)

		if text ~= nil then
			text = g_i18n:convertText(text, self.customEnvironment)

			hotspot:setName(text)
		end

		table.insert(spec.mapHotspots, hotspot)
	end)
end

function PlaceableHotspots:onDelete()
	local spec = self.spec_hotspots

	g_messageCenter:unsubscribeAll(self)

	if spec.mapHotspots ~= nil then
		for _, hotspot in ipairs(spec.mapHotspots) do
			g_currentMission:removeMapHotspot(hotspot)
			hotspot:delete()
		end
	end
end

function PlaceableHotspots:onPostFinalizePlacement()
	local spec = self.spec_hotspots

	for _, hotspot in ipairs(spec.mapHotspots) do
		g_currentMission:addMapHotspot(hotspot)
	end
end

function PlaceableHotspots:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	superFunc(self, ownerFarmId, noEventSend)

	local spec = self.spec_hotspots

	if spec.mapHotspots ~= nil then
		for _, hotspot in ipairs(spec.mapHotspots) do
			hotspot:setOwnerFarmId(ownerFarmId)
		end
	end
end

function PlaceableHotspots:getHotspot(index)
	local spec = self.spec_hotspots

	return spec.mapHotspots[index]
end
