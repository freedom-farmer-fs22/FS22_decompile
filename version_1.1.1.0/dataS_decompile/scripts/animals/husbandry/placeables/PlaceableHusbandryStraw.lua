PlaceableHusbandryStraw = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHusbandryStraw.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateStrawPlane", PlaceableHusbandryStraw.updateStrawPlane)
end

function PlaceableHusbandryStraw.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryStraw.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryStraw.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryStraw.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryStraw.updateInfo)
end

function PlaceableHusbandryStraw.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryStraw)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryFillLevelChanged", PlaceableHusbandryStraw)
end

function PlaceableHusbandryStraw.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.straw"

	FillPlane.registerXMLPaths(schema, basePath .. ".strawPlane")
	schema:register(XMLValueType.FLOAT, basePath .. ".manure#factor", "Factor to transform straw to manure", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".manure#active", "Enable manure production", true)
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryStraw:onLoad(savegame)
	local spec = self.spec_husbandryStraw
	spec.manureFactor = self.xmlFile:getValue("placeable.husbandry.straw.manure#factor", 1)
	spec.isManureActive = self.xmlFile:getValue("placeable.husbandry.straw.manure#active", true)
	spec.strawPlane = FillPlane.new()

	if spec.strawPlane:load(self.components, self.xmlFile, "placeable.husbandry.straw.strawPlane", self.i3dMappings) then
		spec.strawPlane:setState(0)
	else
		spec.strawPlane:delete()

		spec.strawPlane = nil
	end

	spec.inputFillType = FillType.STRAW
	spec.outputFillType = FillType.MANURE
	spec.inputLitersPerHour = 0
	spec.outputLitersPerHour = 0
	spec.info = {
		text = "",
		title = g_i18n:getText("fillType_straw")
	}
end

function PlaceableHusbandryStraw:onPostFinalizePlacement()
	self:updateStrawPlane()
end

function PlaceableHusbandryStraw:onDelete()
	local spec = self.spec_husbandryStraw

	if spec.strawPlane ~= nil then
		spec.strawPlane:delete()

		spec.strawPlane = nil
	end
end

function PlaceableHusbandryStraw:onFinalizePlacement()
	local spec = self.spec_husbandryStraw

	if not self:getHusbandryIsFillTypeSupported(spec.inputFillType) then
		Logging.warning("Missing filltype 'straw' in husbandry storage!")
	end

	if self.isManureActive and not self:getHusbandryIsFillTypeSupported(spec.outputFillType) then
		Logging.warning("Missing filltype 'manure' in husbandry storage!")
	end
end

function PlaceableHusbandryStraw:onReadStream(streamId, connection)
	self:updateStrawPlane()
end

function PlaceableHusbandryStraw:updateStrawPlane()
	local spec = self.spec_husbandryStraw

	if spec.strawPlane ~= nil then
		local capacity = self:getHusbandryCapacity(spec.inputFillType, nil)
		local fillLevel = self:getHusbandryFillLevel(spec.inputFillType, nil)
		local factor = 0

		if capacity > 0 then
			factor = fillLevel / capacity
		end

		spec.strawPlane:setState(factor)
	end
end

function PlaceableHusbandryStraw:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local spec = self.spec_husbandryStraw

		if spec.inputLitersPerHour > 0 then
			self:removeHusbandryFillLevel(self:getOwnerFarmId(), spec.inputLitersPerHour * g_currentMission.environment.timeAdjustment, spec.inputFillType)
		end

		if spec.outputLitersPerHour > 0 then
			local liters = foodFactor * spec.outputLitersPerHour * g_currentMission.environment.timeAdjustment

			if liters > 0 then
				self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.outputFillType, nil, , )
			end
		end

		self:updateStrawPlane()
	end

	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

function PlaceableHusbandryStraw:updateProduction(superFunc, foodFactor)
	local factor = superFunc(self, foodFactor)

	if self.isServer then
		local spec = self.spec_husbandryStraw
		local fillLevel = self:getHusbandryFillLevel(spec.inputFillType)

		if fillLevel > 0 then
			local freeCapacity = self:getHusbandryFreeCapacity(spec.outputFillType)

			if freeCapacity <= 0 then
				factor = factor * 0.75
			end
		else
			factor = factor * 0.9
		end
	end

	return factor
end

function PlaceableHusbandryStraw:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryStraw
	spec.inputLitersPerHour = 0
	spec.outputLitersPerHour = 0

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local straw = subType.input.straw

			if straw ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = straw:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.inputLitersPerHour = spec.inputLitersPerHour + litersPerDay / 24
			end

			local manure = subType.output.manure

			if manure ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = manure:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.outputLitersPerHour = spec.outputLitersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryStraw:onHusbandryFillLevelChanged(fillTypeIndex, delta)
	local spec = self.spec_husbandryStraw

	if fillTypeIndex == spec.inputFillType then
		self:updateStrawPlane()
	end
end

function PlaceableHusbandryStraw:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local spec = self.spec_husbandryStraw
	local info = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(spec.inputFillType)
	info.title = fillType.title
	info.value = self:getHusbandryFillLevel(spec.inputFillType)
	local capacity = self:getHusbandryCapacity(spec.inputFillType)
	local ratio = 0

	if capacity > 0 then
		ratio = info.value / capacity
	end

	info.ratio = MathUtil.clamp(ratio, 0, 1)
	info.invertedBar = false

	table.insert(infos, info)

	return infos
end

function PlaceableHusbandryStraw:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_husbandryStraw
	local fillLevel = self:getHusbandryFillLevel(spec.inputFillType)
	spec.info.text = string.format("%d l", fillLevel)

	table.insert(infoTable, spec.info)
end
