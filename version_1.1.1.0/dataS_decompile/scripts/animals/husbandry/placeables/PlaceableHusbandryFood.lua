PlaceableHusbandryFood = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHusbandryFood.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateFillPlanes", PlaceableHusbandryFood.updateFillPlanes)
	SpecializationUtil.registerFunction(placeableType, "updateFoodPlaces", PlaceableHusbandryFood.updateFoodPlaces)
	SpecializationUtil.registerFunction(placeableType, "addFood", PlaceableHusbandryFood.addFood)
	SpecializationUtil.registerFunction(placeableType, "removeFood", PlaceableHusbandryFood.removeFood)
	SpecializationUtil.registerFunction(placeableType, "getTotalFood", PlaceableHusbandryFood.getTotalFood)
	SpecializationUtil.registerFunction(placeableType, "getFoodCapacity", PlaceableHusbandryFood.getFoodCapacity)
	SpecializationUtil.registerFunction(placeableType, "getFreeFoodCapacity", PlaceableHusbandryFood.getFreeFoodCapacity)
end

function PlaceableHusbandryFood.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryFood.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryFood.updateFeeding)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryFood.getFoodInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandryFood.collectPickObjects)
end

function PlaceableHusbandryFood.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryFood)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryFood)
end

function PlaceableHusbandryFood.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.food"

	schema:register(XMLValueType.INT, basePath .. "#capacity", "Trough capacity", 5000)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foodPlaces.foodPlace(?)#node", "Foodplace")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dynamicFoodPlane#node", "Node")
	schema:register(XMLValueType.STRING, basePath .. ".dynamicFoodPlane#defaultFillType", "Fillplane default filltype")
	FillPlaneUtil.registerFillPlaneXMLPaths(schema, basePath .. ".dynamicFoodPlane")
	FillPlane.registerXMLPaths(schema, basePath .. ".foodPlane", "Fillplane")
	schema:register(XMLValueType.STRING, basePath .. ".foodPlane#defaultFillType", "Fillplane default filltype")
	UnloadTrigger.registerXMLPaths(schema, basePath .. ".feedingTrough")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFood.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".fillLevel(?)#fillType", "Fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillLevel(?)#fillLevel", "Fill level")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFood.initSpecialization()
	g_storeManager:addSpecType("animalFoodFillTypes", "shopListAttributeIconFillTypes", PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes, PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes, "placeable")
end

function PlaceableHusbandryFood:onLoad(savegame)
	local spec = self.spec_husbandryFood
	spec.animalTypeIndex = nil
	spec.litersPerHour = 0
	spec.fillLevels = {}
	spec.supportedFillTypes = {}
	spec.fillTypes = {}
	spec.lastPositionInfoSent = {
		0,
		0
	}
	spec.lastPositionInfo = {
		0,
		0
	}
	spec.foodPlaces = {}
	spec.info = {
		text = "",
		title = g_i18n:getText("ui_animalFood")
	}
	spec.dirtyFlagPosition = self:getNextDirtyFlag()
	spec.dirtyFlagFillLevel = self:getNextDirtyFlag()
	spec.capacity = self.xmlFile:getValue("placeable.husbandry.food#capacity", 5000)
	spec.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(spec.capacity)
	local feedingTrough = UnloadTrigger.new(self.isServer, self.isClient)
	local target = {
		getIsFillTypeAllowed = function (_, fillTypeIndex)
			return spec.supportedFillTypes[fillTypeIndex]
		end,
		getIsToolTypeAllowed = function (_, fillTypeIndex)
			return true
		end,
		addFillLevelFromTool = function (_, ...)
			return self:addFood(...)
		end,
		getFreeCapacity = function (_, fillTypeIndex)
			return self:getFreeFoodCapacity(fillTypeIndex)
		end
	}

	if not feedingTrough:load(self.components, self.xmlFile, "placeable.husbandry.food.feedingTrough", target, nil, self.i3dMappings) then
		feedingTrough:delete()
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	spec.feedingTrough = feedingTrough
	spec.baseNode = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#node", nil, self.components, self.i3dMappings)

	if spec.baseNode ~= nil then
		local fillPlane = FillPlaneUtil.createFromXML(self.xmlFile, "placeable.husbandry.food.dynamicFoodPlane", spec.baseNode, spec.capacity)
		local defaultFillTypeName = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#defaultFillType")
		local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeName) or FillType.FORAGE

		if fillPlane ~= nil then
			FillPlaneUtil.assignDefaultMaterials(fillPlane)
			FillPlaneUtil.setFillType(fillPlane, defaultFillTypeIndex)

			spec.dynamicFoodPlane = fillPlane
		end
	end

	spec.foodPlane = FillPlane.new()

	if spec.foodPlane:load(self.components, self.xmlFile, "placeable.husbandry.food.foodPlane", self.i3dMappings) then
		local defaultFillTypeName = self.xmlFile:getValue("placeable.husbandry.food.foodPlane#defaultFillType")
		local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeName) or FillType.DRYGRASS_WINDROW

		FillPlaneUtil.assignDefaultMaterials(spec.foodPlane.node)
		FillPlaneUtil.setFillType(spec.foodPlane.node, defaultFillTypeIndex)
		setShaderParameter(spec.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
		spec.foodPlane:setState(0)
	else
		spec.foodPlane:delete()

		spec.foodPlane = nil
	end

	self.xmlFile:iterate("placeable.husbandry.food.foodPlaces.foodPlace", function (_, key)
		local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

		table.insert(spec.foodPlaces, {
			node = node
		})
	end)
end

function PlaceableHusbandryFood:onPostLoad()
	local spec = self.spec_husbandryFood
	spec.animalTypeIndex = self:getAnimalTypeIndex()
	local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(spec.animalTypeIndex)
	local mixtures = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(spec.animalTypeIndex)

	if animalFood ~= nil then
		for _, foodGroup in pairs(animalFood.groups) do
			for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
				if spec.fillLevels[fillTypeIndex] == nil then
					spec.fillLevels[fillTypeIndex] = 0
					spec.supportedFillTypes[fillTypeIndex] = true

					table.insert(spec.fillTypes, fillTypeIndex)
				end
			end
		end
	end

	if mixtures ~= nil then
		for _, foodMixtureFillType in ipairs(mixtures) do
			spec.supportedFillTypes[foodMixtureFillType] = true

			table.insert(spec.fillTypes, foodMixtureFillType)
		end
	end
end

function PlaceableHusbandryFood:onDelete()
	local spec = self.spec_husbandryFood

	if spec.feedingTrough ~= nil then
		spec.feedingTrough:delete()

		spec.feedingTrough = nil
	end

	if spec.dynamicFoodPlane ~= nil then
		delete(spec.dynamicFoodPlane)

		spec.dynamicFoodPlane = nil
	end

	if spec.foodPlane ~= nil then
		spec.foodPlane:delete()

		spec.foodPlane = nil
	end
end

function PlaceableHusbandryFood:onFinalizePlacement()
	local spec = self.spec_husbandryFood

	if spec.feedingTrough ~= nil then
		spec.feedingTrough:register(true)
	end
end

function PlaceableHusbandryFood:onPostFinalizePlacement()
	self:updateFillPlanes()
end

function PlaceableHusbandryFood:onReadStream(streamId, connection)
	local spec = self.spec_husbandryFood

	for _, fillTypeIndex in ipairs(spec.fillTypes) do
		if spec.fillLevels[fillTypeIndex] ~= nil then
			spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, spec.FILLLEVEL_NUM_BITS)
		end
	end

	if spec.feedingTrough ~= nil then
		local feedingTroughId = NetworkUtil.readNodeObjectId(streamId)

		spec.feedingTrough:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.feedingTrough, feedingTroughId)
	end
end

function PlaceableHusbandryFood:onWriteStream(streamId, connection)
	local spec = self.spec_husbandryFood

	for _, fillTypeIndex in ipairs(spec.fillTypes) do
		if spec.fillLevels[fillTypeIndex] ~= nil then
			streamWriteUIntN(streamId, spec.fillLevels[fillTypeIndex], spec.FILLLEVEL_NUM_BITS)
		end
	end

	if spec.feedingTrough ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.feedingTrough))
		spec.feedingTrough:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.feedingTrough)
	end
end

function PlaceableHusbandryFood:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_husbandryFood

		if streamReadBool(streamId) then
			local x = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			local z = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			spec.lastPositionInfo[1] = x
			spec.lastPositionInfo[2] = z
		end

		if streamReadBool(streamId) then
			for _, fillTypeIndex in ipairs(spec.fillTypes) do
				if spec.fillLevels[fillTypeIndex] ~= nil then
					local newFillLevel = streamReadUIntN(streamId, spec.FILLLEVEL_NUM_BITS)
					local delta = newFillLevel - spec.fillLevels[fillTypeIndex]

					if delta > 0 then
						self:addFood(self:getOwnerFarmId(), delta, fillTypeIndex, nil, , )
					else
						self:removeFood(math.abs(delta), fillTypeIndex)
					end
				end
			end
		end
	end
end

function PlaceableHusbandryFood:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_husbandryFood

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagPosition) ~= 0) then
			local x = (spec.lastPositionInfoSent[1] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, x, FillVolume.SEND_NUM_BITS)

			local z = (spec.lastPositionInfoSent[2] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, z, FillVolume.SEND_NUM_BITS)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagFillLevel) ~= 0) then
			for _, fillTypeIndex in ipairs(spec.fillTypes) do
				if spec.fillLevels[fillTypeIndex] ~= nil then
					streamWriteUIntN(streamId, spec.fillLevels[fillTypeIndex], spec.FILLLEVEL_NUM_BITS)
				end
			end
		end
	end
end

function PlaceableHusbandryFood:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_husbandryFood

	xmlFile:iterate(key .. ".fillLevel", function (_, fillLevelKey)
		local fillTypeName = xmlFile:getValue(fillLevelKey .. "#fillType")
		local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")

		if fillTypeName ~= nil and fillLevel ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

			if fillTypeIndex ~= nil and spec.supportedFillTypes[fillTypeIndex] ~= nil then
				self:addFood(self:getOwnerFarmId(), fillLevel, fillTypeIndex, nil, , )
			end
		end
	end)
end

function PlaceableHusbandryFood:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_husbandryFood
	local index = 0

	for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
		if fillLevel > 0 then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)

			if fillTypeName ~= nil then
				local fillLevelKey = string.format("%s.fillLevel(%d)", key, index)

				xmlFile:setValue(fillLevelKey .. "#fillType", fillTypeName)
				xmlFile:setValue(fillLevelKey .. "#fillLevel", fillLevel)

				index = index + 1
			end
		end
	end
end

function PlaceableHusbandryFood:updateFeeding(superFunc)
	local factor = superFunc(self)
	local spec = self.spec_husbandryFood

	if self.isServer and spec.animalTypeIndex ~= nil then
		local consumedFood = {}
		factor = factor * g_currentMission.animalFoodSystem:consumeFood(spec.animalTypeIndex, spec.litersPerHour * g_currentMission.environment.timeAdjustment, spec.fillLevels, consumedFood)

		for fillTypeIndex, delta in pairs(consumedFood) do
			self:removeFood(delta, fillTypeIndex)
		end
	end

	return factor
end

function PlaceableHusbandryFood:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_husbandryFood
	local fillLevel = self:getTotalFood()
	spec.info.text = string.format("%d l", fillLevel)

	table.insert(infoTable, spec.info)
end

function PlaceableHusbandryFood:getFoodInfos(superFunc)
	local foodInfos = superFunc(self)
	local spec = self.spec_husbandryFood
	local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(spec.animalTypeIndex)

	if animalFood ~= nil then
		for _, foodGroup in pairs(animalFood.groups) do
			local title = foodGroup.title
			local fillLevel = 0
			local capacity = spec.capacity

			for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
				if spec.fillLevels[fillTypeIndex] ~= nil then
					fillLevel = fillLevel + spec.fillLevels[fillTypeIndex]
				end
			end

			local info = {
				title = title,
				value = fillLevel,
				capacity = capacity,
				ratio = 0
			}

			if capacity > 0 then
				info.ratio = fillLevel / capacity
			end

			table.insert(foodInfos, info)
		end
	end

	return foodInfos
end

function PlaceableHusbandryFood:updateFillPlanes(fillTypeIndex)
	local spec = self.spec_husbandryFood

	if spec.foodPlane ~= nil then
		local fillLevel = self:getTotalFood()
		local capacity = self:getFoodCapacity()
		local state = 0

		if capacity > 0 then
			state = fillLevel / capacity
		end

		spec.foodPlane:setState(state)

		if state > 0 and fillTypeIndex ~= nil then
			FillPlaneUtil.assignDefaultMaterials(spec.foodPlane.node)
			FillPlaneUtil.setFillType(spec.foodPlane.node, fillTypeIndex)
			setShaderParameter(spec.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
		end
	end
end

function PlaceableHusbandryFood:collectPickObjects(superFunc, node)
	local spec = self.spec_husbandryFood

	if spec.feedingTrough ~= nil and node == spec.feedingTrough.exactFillRootNode then
		return
	end

	superFunc(self, node)
end

function PlaceableHusbandryFood:onHusbandryAnimalsCreated(husbandry)
	if husbandry ~= nil then
		local spec = self.spec_husbandryFood
		spec.husbandry = husbandry

		for _, foodPlace in ipairs(spec.foodPlaces) do
			foodPlace.place = addFeedingPlace(husbandry, foodPlace.node, 0, AnimalHusbandryFeedingType.FOOD)
		end
	end
end

function PlaceableHusbandryFood:updateFoodPlaces()
	local spec = self.spec_husbandryFood

	if spec.husbandry ~= nil then
		local fillLevel = self:getTotalFood()

		for _, foodPlace in pairs(spec.foodPlaces) do
			if foodPlace.place ~= nil then
				updateFeedingPlace(spec.husbandry, foodPlace.place, fillLevel)
			end
		end
	end
end

function PlaceableHusbandryFood:getTotalFood()
	local spec = self.spec_husbandryFood
	local fillLevel = 0

	for _, level in pairs(spec.fillLevels) do
		fillLevel = fillLevel + level
	end

	return fillLevel
end

function PlaceableHusbandryFood:getFoodCapacity()
	return self.spec_husbandryFood.capacity
end

function PlaceableHusbandryFood:getFreeFoodCapacity(fillTypeIndex)
	local spec = self.spec_husbandryFood

	if spec.supportedFillTypes[fillTypeIndex] == nil then
		return 0
	end

	return spec.capacity - self:getTotalFood()
end

function PlaceableHusbandryFood:addFood(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local spec = self.spec_husbandryFood

	if spec.supportedFillTypes[fillTypeIndex] == nil then
		return 0
	end

	local mixture = g_currentMission.animalFoodSystem:getMixtureByFillType(fillTypeIndex)

	if mixture ~= nil then
		local filled = 0
		local maxDelta = math.min(deltaFillLevel, self:getFreeFoodCapacity(fillTypeIndex))

		for _, ingredient in ipairs(mixture.ingredients) do
			local delta = maxDelta * ingredient.weight
			local ingredientFillType = ingredient.fillTypes[1]
			local filledDelta = self:addFood(farmId, delta, ingredientFillType, fillPositionData, toolType, extraAttributes)
			filled = filled + filledDelta
		end

		if filled > 0 then
			self:updateFillPlanes(fillTypeIndex)
		end

		return filled
	end

	local freeCapacity = self:getFreeFoodCapacity(fillTypeIndex)

	if freeCapacity == 0 then
		return 0
	end

	deltaFillLevel = math.min(freeCapacity, deltaFillLevel)

	if spec.dynamicFoodPlane ~= nil then
		if fillPositionData ~= nil then
			local data = fillPositionData
			local x0, y0, z0 = getWorldTranslation(data.node)
			local d1x, d1y, d1z = localDirectionToWorld(data.node, data.width, 0, 0)
			local d2x, d2y, d2z = localDirectionToWorld(data.node, 0, 0, data.length)

			if VehicleDebug.state == VehicleDebug.DEBUG then
				drawDebugLine(x0, y0, z0, 1, 0, 0, x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0)
				drawDebugLine(x0, y0, z0, 0, 0, 1, x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1)
				drawDebugPoint(x0, y0, z0, 1, 1, 1, 1)
				drawDebugPoint(x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0, 1)
				drawDebugPoint(x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1, 1)
			end

			x0 = x0 - (d1x + d2x) / 2
			y0 = y0 - (d1y + d2y) / 2
			z0 = z0 - (d1z + d2z) / 2

			fillPlaneAdd(spec.dynamicFoodPlane, deltaFillLevel, x0, y0, z0, d1x, d1y, d1z, d2x, d2y, d2z)

			if self.isServer and FillVolume.SEND_PRECISION < math.abs(x0 - spec.lastPositionInfoSent[1]) or FillVolume.SEND_PRECISION < math.abs(z0 - spec.lastPositionInfoSent[2]) then
				spec.lastPositionInfoSent[1] = x0
				spec.lastPositionInfoSent[2] = z0

				self:raiseDirtyFlags(spec.dirtyFlagPosition)
			end
		else
			local x, y, z = localToWorld(spec.dynamicFoodPlane, 0, 0, 0)
			local d1x, d1y, d1z = localDirectionToWorld(spec.dynamicFoodPlane, 0.1, 0, 0)
			local d2x, d2y, d2z = localDirectionToWorld(spec.dynamicFoodPlane, 0, 0, 0.1)

			if not self.isServer and spec.lastPositionInfo[1] ~= 0 and spec.lastPositionInfo[2] ~= 0 then
				x, y, z = localToWorld(spec.dynamicFoodPlane, spec.lastPositionInfo[1], 0, spec.lastPositionInfo[2])
			end

			local steps = MathUtil.clamp(math.floor(deltaFillLevel / 400), 1, 25)

			for _ = 1, steps do
				fillPlaneAdd(spec.dynamicFoodPlane, deltaFillLevel / steps, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
			end
		end
	end

	if self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlagFillLevel)
	end

	spec.fillLevels[fillTypeIndex] = spec.fillLevels[fillTypeIndex] + deltaFillLevel

	self:updateFillPlanes(fillTypeIndex)
	self:updateFoodPlaces()

	return deltaFillLevel
end

function PlaceableHusbandryFood:removeFood(absDeltaFillLevel, fillTypeIndex)
	local spec = self.spec_husbandryFood

	if spec.supportedFillTypes[fillTypeIndex] == nil then
		return 0
	end

	if absDeltaFillLevel <= 0 then
		return 0
	end

	absDeltaFillLevel = math.min(math.abs(absDeltaFillLevel), spec.fillLevels[fillTypeIndex])

	if spec.dynamicFoodPlane ~= nil then
		local x, y, z = localToWorld(spec.dynamicFoodPlane, 0, 0, 0)
		local d1x, d1y, d1z = localDirectionToWorld(spec.dynamicFoodPlane, 0.1, 0, 0)
		local d2x, d2y, d2z = localDirectionToWorld(spec.dynamicFoodPlane, 0, 0, 0.1)
		local steps = MathUtil.clamp(math.floor(absDeltaFillLevel / 400), 1, 25)
		local delta = absDeltaFillLevel / steps

		for _ = 1, steps do
			fillPlaneAdd(spec.dynamicFoodPlane, -delta, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
		end
	end

	spec.fillLevels[fillTypeIndex] = spec.fillLevels[fillTypeIndex] - absDeltaFillLevel

	if self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlagFillLevel)
	end

	self:updateFillPlanes()
	self:updateFoodPlaces()

	return absDeltaFillLevel
end

function PlaceableHusbandryFood:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryFood
	spec.litersPerHour = 0

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local food = subType.input.food

			if food ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = food:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.litersPerHour = spec.litersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes(xmlFile, customEnvironment)
	local data = nil

	if xmlFile:hasProperty("placeable.husbandry.animals") then
		data = data or {}
		data.animalTypeName = xmlFile:getString("placeable.husbandry.animals#type")
	end

	if xmlFile:hasProperty("placeable.husbandry.water") then
		data = data or {}
		data.needsWater = not xmlFile:getValue("placeable.husbandry.water#automaticWaterSupply", false)
	end

	return data
end

function PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes(storeItem, realItem)
	local data = storeItem.specs.animalFoodFillTypes

	if data == nil then
		return nil
	end

	local fillTypes = {}
	local animalType = g_currentMission.animalSystem:getTypeByName(data.animalTypeName)

	if animalType == nil then
		return nil
	end

	local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalType.typeIndex)
	local mixtures = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(animalType.typeIndex)

	if animalFood ~= nil then
		for _, foodGroup in pairs(animalFood.groups) do
			for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
				table.addElement(fillTypes, fillTypeIndex)
			end
		end
	end

	if mixtures ~= nil then
		for _, foodMixtureFillType in ipairs(mixtures) do
			table.addElement(fillTypes, foodMixtureFillType)
		end
	end

	if data.needsWater then
		table.addElement(fillTypes, FillType.WATER)
	end

	return fillTypes
end
