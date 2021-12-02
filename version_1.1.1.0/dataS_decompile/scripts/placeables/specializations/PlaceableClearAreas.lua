PlaceableClearAreas = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableClearAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadClearArea", PlaceableClearAreas.loadClearArea)
end

function PlaceableClearAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableClearAreas)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableClearAreas)
end

function PlaceableClearAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ClearAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearAreas.clearArea(?)#heightNode", "Height node")
	schema:setXMLSpecializationType()
end

function PlaceableClearAreas:onLoad(savegame)
	local spec = self.spec_clearAreas
	spec.areas = {}

	self.xmlFile:iterate("placeable.clearAreas.clearArea", function (_, key)
		local area = {}

		if self:loadClearArea(self.xmlFile, key, area) then
			table.insert(spec.areas, area)
		end
	end)

	if not self.xmlFile:hasProperty("placeable.clearAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing clear areas")
	end
end

function PlaceableClearAreas:loadClearArea(xmlFile, key, area)
	local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)

	if start == nil then
		Logging.xmlWarning(xmlFile, "Clear area start node not defined for '%s'", key)

		return false
	end

	local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)

	if width == nil then
		Logging.xmlWarning(xmlFile, "Clear area width node not defined for '%s'", key)

		return false
	end

	local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)

	if height == nil then
		Logging.xmlWarning(xmlFile, "Clear area height node not defined for '%s'", key)

		return false
	end

	area.start = start
	area.width = width
	area.height = height

	return true
end

function PlaceableClearAreas:onPostFinalizePlacement()
	if self.isServer and not self.isLoadedFromSavegame then
		local spec = self.spec_clearAreas

		for _, area in pairs(spec.areas) do
			local x, _, z = getWorldTranslation(area.start)
			local x1, _, z1 = getWorldTranslation(area.width)
			local x2, _, z2 = getWorldTranslation(area.height)

			FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
			FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
			FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
			FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
			DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
		end
	end
end
