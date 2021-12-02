PlaceableHusbandryWater = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHusbandryWater.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateWaterPlane", PlaceableHusbandryWater.updateWaterPlane)
end

function PlaceableHusbandryWater.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryWater.updateFeeding)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryWater.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryWater.updateInfo)
end

function PlaceableHusbandryWater.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryWater)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryWater)
end

function PlaceableHusbandryWater.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.water"

	schema:register(XMLValueType.BOOL, basePath .. "#automaticWaterSupply", "If husbandry has a automatic water supply", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".waterPlaces.waterPlace(?)#node", "Water place")
	FillPlane.registerXMLPaths(schema, basePath .. ".waterPlane")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryWater:onLoad(savegame)
	local spec = self.spec_husbandryWater
	spec.husbandry = nil
	spec.litersPerHour = 0
	spec.automaticWaterSupply = false
	spec.fillType = FillType.WATER
	spec.waterPlaces = {}
	spec.info = {
		text = "",
		title = g_i18n:getText("fillType_water")
	}
	spec.automaticWaterSupply = self.xmlFile:getValue("placeable.husbandry.water#automaticWaterSupply", spec.automaticWaterSupply)
	spec.waterPlane = FillPlane.new()

	if spec.waterPlane:load(self.components, self.xmlFile, "placeable.husbandry.water.waterPlane", self.i3dMappings) then
		spec.waterPlane:setState(spec.automaticWaterSupply and 1 or 0)
	else
		spec.waterPlane:delete()

		spec.waterPlane = nil
	end

	self.xmlFile:iterate("placeable.husbandry.water.waterPlaces.waterPlace", function (_, key)
		local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

		table.insert(spec.waterPlaces, {
			node = node
		})
	end)
end

function PlaceableHusbandryWater:onPostFinalizePlacement()
	self:updateWaterPlane()
end

function PlaceableHusbandryWater:onDelete()
	local spec = self.spec_husbandryWater

	if spec.waterPlane ~= nil then
		spec.waterPlane:delete()

		spec.waterPlane = nil
	end
end

function PlaceableHusbandryWater:onFinalizePlacement()
	local spec = self.spec_husbandryWater

	if not spec.automaticWaterSupply and not self:getHusbandryIsFillTypeSupported(spec.fillType) then
		Logging.warning("Missing filltype 'water' in husbandry storage! Changing to automatic water supply")

		spec.automaticWaterSupply = true
	end
end

function PlaceableHusbandryWater:updateWaterPlane()
	local spec = self.spec_husbandryWater
	local fillLevel = self:getHusbandryFillLevel(spec.fillType, nil)

	if spec.waterPlane ~= nil then
		local capacity = self:getHusbandryCapacity(spec.fillType, nil)
		local factor = 0

		if capacity > 0 then
			factor = fillLevel / capacity
		end

		spec.waterPlane:setState(factor)
	end

	if spec.husbandry ~= nil then
		for _, waterPlace in pairs(spec.waterPlaces) do
			if waterPlace.place ~= nil then
				updateFeedingPlace(spec.husbandry, waterPlace.place, fillLevel)
			end
		end
	end
end

function PlaceableHusbandryWater:updateFeeding(superFunc)
	local factor = superFunc(self)
	local spec = self.spec_husbandryWater

	if self.isServer and not spec.automaticWaterSupply and spec.litersPerHour > 0 then
		local delta = spec.litersPerHour * g_currentMission.environment.timeAdjustment
		local remainingLiters = self:removeHusbandryFillLevel(nil, delta, spec.fillType)
		local usedDelta = delta - remainingLiters
		factor = factor * MathUtil.clamp(usedDelta / delta, 0, 1)
	end

	return factor
end

function PlaceableHusbandryWater:onHusbandryAnimalsCreated(husbandry)
	if husbandry ~= nil then
		local spec = self.spec_husbandryWater
		spec.husbandry = husbandry

		for _, waterPlace in ipairs(spec.waterPlaces) do
			waterPlace.place = addFeedingPlace(husbandry, waterPlace.node, 0, AnimalHusbandryFeedingType.WATER)
		end
	end
end

function PlaceableHusbandryWater:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryWater
	spec.litersPerHour = 0

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local water = subType.input.water

			if water ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = water:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.litersPerHour = spec.litersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryWater:onHusbandryFillLevelChanged(fillTypeIndex, delta)
	local spec = self.spec_husbandryWater

	if fillTypeIndex == spec.fillType then
		self:updateWaterPlane()
	end
end

function PlaceableHusbandryWater:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local spec = self.spec_husbandryWater

	if not spec.automaticWaterSupply then
		local info = {}
		local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillType)
		info.title = fillType.title
		info.value = self:getHusbandryFillLevel(spec.fillType)
		local capacity = self:getHusbandryCapacity(spec.fillType)
		local ratio = 0

		if capacity > 0 then
			ratio = info.value / capacity
		end

		info.ratio = MathUtil.clamp(ratio, 0, 1)
		info.invertedBar = false

		table.insert(infos, info)
	end

	return infos
end

function PlaceableHusbandryWater:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_husbandryWater

	if not spec.automaticWaterSupply then
		local fillLevel = self:getHusbandryFillLevel(spec.fillType)
		spec.info.text = string.format("%d l", fillLevel)

		table.insert(infoTable, spec.info)
	end
end
