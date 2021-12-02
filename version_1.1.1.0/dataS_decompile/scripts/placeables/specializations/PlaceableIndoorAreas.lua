PlaceableIndoorAreas = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableIndoorAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadIndoorArea", PlaceableIndoorAreas.loadIndoorArea)
end

function PlaceableIndoorAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableIndoorAreas)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableIndoorAreas)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableIndoorAreas)
end

function PlaceableIndoorAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("IndoorAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#startNode", "Start node of indoor mask area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#widthNode", "Width node of indoor mask area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".indoorAreas.indoorArea(?)#heightNode", "Height node of indoor mask area")
	schema:setXMLSpecializationType()
end

function PlaceableIndoorAreas:onLoad(savegame)
	local spec = self.spec_indoorAreas
	spec.resetIndoorMaskOnDelete = false
	spec.areas = {}

	self.xmlFile:iterate("placeable.indoorAreas.indoorArea", function (_, key)
		local area = {}

		if self:loadIndoorArea(self.xmlFile, key, area) then
			table.insert(spec.areas, area)
		end
	end)

	if not self.xmlFile:hasProperty("placeable.indoorAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing indoor areas")
	end
end

function PlaceableIndoorAreas:onDelete()
	local spec = self.spec_indoorAreas

	if spec.areas ~= nil and spec.resetIndoorMaskOnDelete and not self.isReloading then
		for _, area in ipairs(spec.areas) do
			g_currentMission.indoorMask:setPlaceableAreaInSnowMask(area, IndoorMask.OUTDOOR)
		end
	end
end

function PlaceableIndoorAreas:loadIndoorArea(xmlFile, key, area)
	local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)

	if start == nil then
		Logging.xmlWarning(xmlFile, "Indoor area start node not defined for '%s'", key)

		return false
	end

	local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)

	if width == nil then
		Logging.xmlWarning(xmlFile, "Indoor area width node not defined for '%s'", key)

		return false
	end

	local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)

	if height == nil then
		Logging.xmlWarning(xmlFile, "Indoor area height node not defined for '%s'", key)

		return false
	end

	area.start = start
	area.width = width
	area.height = height

	return true
end

function PlaceableIndoorAreas:onFinalizePlacement()
	local spec = self.spec_indoorAreas

	for _, area in pairs(spec.areas) do
		g_currentMission.indoorMask:setPlaceableAreaInSnowMask(area, IndoorMask.INDOOR)
	end

	spec.resetIndoorMaskOnDelete = true
end
