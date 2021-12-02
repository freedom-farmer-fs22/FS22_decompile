PlaceableFoliageAreas = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableFoliageAreas.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadFoliageArea", PlaceableFoliageAreas.loadFoliageArea)
end

function PlaceableFoliageAreas.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFoliageAreas)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableFoliageAreas)
end

function PlaceableFoliageAreas.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("FoliageAreas")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foliageAreas.foliageArea(?)#heightNode", "Height node")
	schema:register(XMLValueType.STRING, basePath .. ".foliageAreas.foliageArea(?)#fruitType", "Fruit type name")
	schema:register(XMLValueType.STRING, basePath .. ".foliageAreas.foliageArea(?)#decoFoliage", "Deco foliage name")
	schema:register(XMLValueType.INT, basePath .. ".foliageAreas.foliageArea(?)#state", "Fruit type state")
	schema:setXMLSpecializationType()
end

function PlaceableFoliageAreas:onLoad(savegame)
	local spec = self.spec_foliageAreas
	spec.areas = {}

	self.xmlFile:iterate("placeable.foliageAreas.foliageArea", function (_, key)
		local area = {}

		if self:loadFoliageArea(self.xmlFile, key, area) then
			table.insert(spec.areas, area)
		end
	end)
end

function PlaceableFoliageAreas:loadFoliageArea(xmlFile, key, area)
	local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
	local decoFoliage = xmlFile:getValue(key .. "#decoFoliage")

	if fruitTypeName ~= nil and decoFoliage ~= nil then
		Logging.xmlInfo(xmlFile, "Foliage area fruit type and decoFoliage defined defined for '%s'. Ignoring decoFoliage", fruitTypeName, key)

		decoFoliage = nil
	end

	local fruitType, fruitState = nil

	if fruitTypeName ~= nil then
		fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)

		if fruitType == nil then
			Logging.xmlWarning(xmlFile, "Foliage area fruit type '%s' not defined for '%s'", fruitTypeName, key)

			return false
		end

		fruitState = xmlFile:getValue(key .. "#state", fruitType.maxHarvestingGrowthState - 1)
	end

	if decoFoliage ~= nil and not g_currentMission.foliageSystem:getIsDecoLayerDefined(decoFoliage) then
		Logging.xmlInfo(xmlFile, "Foliage area decoFoliage '%s' not defined on current map for '%s'", decoFoliage, key)

		return false
	end

	local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)

	if start == nil then
		Logging.xmlWarning(xmlFile, "Foliage area start node not defined for '%s'", key)

		return false
	end

	local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)

	if width == nil then
		Logging.xmlWarning(xmlFile, "Foliage area width node not defined for '%s'", key)

		return false
	end

	local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)

	if height == nil then
		Logging.xmlWarning(xmlFile, "Foliage area height node not defined for '%s'", key)

		return false
	end

	area.start = start
	area.width = width
	area.height = height
	area.fruitState = fruitState
	area.fruitType = fruitType
	area.decoFoliage = decoFoliage

	return true
end

function PlaceableFoliageAreas:onPostFinalizePlacement()
	if self.isServer then
		local spec = self.spec_foliageAreas

		for _, area in pairs(spec.areas) do
			local x, _, z = getWorldTranslation(area.start)
			local xWidth, _, zWidth = getWorldTranslation(area.width)
			local xHeight, _, zHeight = getWorldTranslation(area.height)

			if area.fruitType ~= nil then
				FieldUtil.setFruit(x, z, xWidth, zWidth, xHeight, zHeight, area.fruitType.index, area.fruitState)
			else
				g_currentMission.foliageSystem:applyDecoFoliage(area.decoFoliage, x, z, xWidth, zWidth, xHeight, zHeight)
			end
		end
	end
end
