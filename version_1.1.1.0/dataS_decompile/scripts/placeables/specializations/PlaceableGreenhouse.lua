PlaceableGreenhouse = {
	GROWTH_INTERVAL_SECONDS_MIN = 300,
	GROWTH_INTERVAL_SECONDS_MAX = 480,
	WATERING_INTERVAL_SECONDS_MIN = 240,
	WATERING_INTERVAL_SECONDS_MAX = 360,
	WATERING_DURATION_SECONDS = 10
}

function PlaceableGreenhouse.getRandomGrowthInterval()
	return math.random(PlaceableGreenhouse.GROWTH_INTERVAL_SECONDS_MIN, PlaceableGreenhouse.GROWTH_INTERVAL_SECONDS_MAX) * (1000 + math.random(50))
end

function PlaceableGreenhouse.getRandomWateringInterval()
	return math.random(PlaceableGreenhouse.WATERING_INTERVAL_SECONDS_MIN, PlaceableGreenhouse.WATERING_INTERVAL_SECONDS_MAX) * (1000 + math.random(50))
end

PlaceableGreenhouse.plantXmlSchema = nil

function PlaceableGreenhouse.prerequisitesPresent(specializations)
	return true
end

function PlaceableGreenhouse.initSpecialization()
	local plantXmlSchema = XMLSchema.new("greenhousePlant")

	plantXmlSchema:register(XMLValueType.STRING, "greenhousePlant.i3dFilename", "i3d file of plant")
	plantXmlSchema:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.growing(?)#node", "Growing mesh")
	plantXmlSchema:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.withered#node", "Withered mesh")

	PlaceableGreenhouse.plantXmlSchema = plantXmlSchema
end

function PlaceableGreenhouse.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadPlantFromXml", PlaceableGreenhouse.loadPlantFromXml)
	SpecializationUtil.registerFunction(placeableType, "addPlantPlace", PlaceableGreenhouse.addPlantPlace)
	SpecializationUtil.registerFunction(placeableType, "updatePlantDistribution", PlaceableGreenhouse.updatePlantDistribution)
	SpecializationUtil.registerFunction(placeableType, "setPlantAtPlace", PlaceableGreenhouse.setPlantAtPlace)
	SpecializationUtil.registerFunction(placeableType, "updatePlantsStage", PlaceableGreenhouse.updatePlantsStage)
	SpecializationUtil.registerFunction(placeableType, "setPlantPlaceStage", PlaceableGreenhouse.setPlantPlaceStage)
end

function PlaceableGreenhouse.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onOutputFillTypesChanged", PlaceableGreenhouse)
	SpecializationUtil.registerEventListener(placeableType, "onProductionStatusChanged", PlaceableGreenhouse)
end

function PlaceableGreenhouse.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Greenhouse")
	schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#fillType", "FillType of plant")
	schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#xmlFilename", "xml file of greenhouse plant")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.space(?)#node", "node where plant is placed")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.spacesParent(?)#node", "parent node of nodes where plants are placed")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".greenhouse.sounds", "watering")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".greenhouse.effectNodes")
	schema:setXMLSpecializationType()
end

function PlaceableGreenhouse:onLoad(savegame)
	local spec = self.spec_greenhouse
	local xmlFile = self.xmlFile
	local key = "placeable.greenhouse"
	spec.filltypeIdToPlant = {}
	spec.plantPlaces = {}
	spec.activeFilltypes = {}
	spec.hasWater = true

	xmlFile:iterate(key .. ".plants.plant", function (index, plantKey)
		local fillTypeName = xmlFile:getValue(plantKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillType ~= nil then
			local plantXmlFilename = xmlFile:getValue(plantKey .. "#xmlFilename")

			if plantXmlFilename ~= nil then
				plantXmlFilename = Utils.getFilename(plantXmlFilename, self.baseDirectory)
				local plant = self:loadPlantFromXml(plantXmlFilename)

				if plant ~= nil then
					spec.filltypeIdToPlant[fillType] = plant
				end
			end
		else
			Logging.xmlWarning(xmlFile, "Unknown fillType '%s' for plant '%s'", fillTypeName, plantKey)
		end
	end)
	xmlFile:iterate(key .. ".plantSpaces.space", function (index, plantSpaceKey)
		local plantPlaceNode = self.xmlFile:getValue(plantSpaceKey .. "#node", nil, self.components, self.i3dMappings)

		if plantPlaceNode ~= nil then
			self:addPlantPlace(plantPlaceNode)
		end
	end)
	xmlFile:iterate(key .. ".plantSpaces.spacesParent", function (index, plantParentKey)
		local parentNode = self.xmlFile:getValue(plantParentKey .. "#node", nil, self.components, self.i3dMappings)
		local numChildren = getNumOfChildren(parentNode)

		if numChildren > 0 then
			for i = 0, numChildren - 1 do
				self:addPlantPlace(getChildAt(parentNode, i))
			end
		else
			Logging.xmlWarning(xmlFile, "No i3d child nodes for '%s'", plantParentKey)
		end
	end)

	if self.isClient then
		spec.samples = {
			watering = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "watering", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
		}
		spec.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", self.components, self, self.i3dMappings)
	end

	spec.growthTimer = Timer.new(PlaceableGreenhouse.getRandomGrowthInterval())

	spec.growthTimer:setFinishCallback(function (timerInstance)
		timerInstance:setDuration(PlaceableGreenhouse.getRandomGrowthInterval())
		self:updatePlantsStage()
	end)

	spec.wateringTimer = Timer.new(PlaceableGreenhouse.getRandomWateringInterval())

	spec.wateringTimer:setFinishCallback(function (timerInstance)
		if spec.hasWater then
			g_effectManager:startEffects(spec.effects)
			g_soundManager:playSample(spec.samples.watering)
			Timer.createOneshot(PlaceableGreenhouse.WATERING_DURATION_SECONDS * 1000, function ()
				g_effectManager:stopEffects(spec.effects)
				g_soundManager:stopSample(spec.samples.watering)
			end)
			timerInstance:start()
		end
	end)
end

function PlaceableGreenhouse:addPlantPlace(node)
	local spec = self.spec_greenhouse

	setRotation(node, 0, math.random() * math.pi * 2, 0)
	table.insert(spec.plantPlaces, {
		node = node
	})
end

function PlaceableGreenhouse:loadPlantFromXml(xmlFilename)
	local plant = {
		i3dFilename = "",
		stages = {
			growing = {}
		}
	}
	local plantXml = XMLFile.load("plantXml", xmlFilename, PlaceableGreenhouse.plantXmlSchema)

	if plantXml ~= nil then
		local i3dFilename = plantXml:getValue("greenhousePlant.i3dFilename")

		if i3dFilename ~= nil then
			plant.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
			plant.i3dNode, plant.sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(plant.i3dFilename, false, false)

			if plant.i3dNode ~= nil then
				plantXml:iterate("greenhousePlant.stages.growing", function (index, key)
					local growingNode = plantXml:getValue(key .. "#node", nil, plant.i3dNode)

					if growingNode ~= nil then
						local childIndex = getChildIndex(growingNode)

						table.insert(plant.stages.growing, childIndex)
					end
				end)

				plant.stages.first = plant.stages.growing[1]
				plant.stages.last = plant.stages.growing[#plant.stages.growing]
				local witheredNode = plantXml:getValue("greenhousePlant.stages.withered#node", nil, plant.i3dNode)

				if witheredNode ~= nil then
					plant.stages.withered = getChildIndex(witheredNode)
				end
			end
		end

		plantXml:delete()
	end

	return plant
end

function PlaceableGreenhouse:onDelete()
	local spec = self.spec_greenhouse

	if spec.growthTimer ~= nil then
		spec.growthTimer:delete()
	end

	if spec.wateringTimer ~= nil then
		spec.wateringTimer:delete()
	end

	if spec.filltypeIdToPlant ~= nil then
		for _, plant in pairs(spec.filltypeIdToPlant) do
			if plant.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(plant.sharedLoadRequestId)
			end

			if plant.i3dNode ~= nil then
				delete(plant.i3dNode)

				plant.i3dNode = nil
			end
		end
	end

	g_effectManager:deleteEffects(spec.effects)
	g_soundManager:deleteSamples(spec.samples)
end

function PlaceableGreenhouse:onFinalizePlacement()
	self:updatePlantDistribution()
	self.spec_greenhouse.wateringTimer:start()
end

function PlaceableGreenhouse:onOutputFillTypesChanged(outputs, state)
	local spec = self.spec_greenhouse

	for _, output in pairs(outputs) do
		local fillType = output.type

		if state then
			if spec.filltypeIdToPlant[fillType] ~= nil then
				spec.activeFilltypes[fillType] = true
			end
		else
			spec.activeFilltypes[fillType] = nil
		end
	end

	if self:getIsSynchronized() then
		self:updatePlantDistribution()
	end
end

function PlaceableGreenhouse:onProductionStatusChanged(production, status)
	local spec = self.spec_greenhouse
	local hasWater = status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS

	if spec.hasWater ~= hasWater then
		spec.hasWater = hasWater

		self:updatePlantsStage()
	end

	if hasWater and next(spec.activeFilltypes) ~= nil then
		spec.wateringTimer:startIfNotRunning()
	else
		spec.wateringTimer:stop()
	end
end

function PlaceableGreenhouse:updatePlantDistribution()
	local spec = self.spec_greenhouse
	local numActiveFilltypes = table.size(spec.activeFilltypes)
	local numPlaces = #spec.plantPlaces
	local fillTypesList = table.toList(spec.activeFilltypes)

	for i = 1, numPlaces do
		local fillType = fillTypesList[i % numActiveFilltypes + 1]
		local plantPlace = spec.plantPlaces[i]

		self:setPlantAtPlace(fillType, plantPlace)
	end

	self:updatePlantsStage()
end

function PlaceableGreenhouse:setPlantAtPlace(fillType, plantPlace)
	local spec = self.spec_greenhouse

	if plantPlace.fillType ~= fillType then
		if plantPlace.fillType ~= nil then
			for i = getNumOfChildren(plantPlace.node) - 1, 0, -1 do
				local plantStage = getChildAt(plantPlace.node, i)

				delete(plantStage)
			end

			plantPlace.fillType = nil
		end

		local plant = spec.filltypeIdToPlant[fillType]

		if plant ~= nil then
			local plantClone = clone(getChildAt(plant.i3dNode, 0), false, false, false)

			for n = getNumOfChildren(plantClone) - 1, 0, -1 do
				local plantStage = getChildAt(plantClone, n)

				link(plantPlace.node, plantStage, 0)
			end

			plantPlace.fillType = fillType
			plantPlace.stage = nil

			delete(plantClone)
		end
	end
end

function PlaceableGreenhouse:updatePlantsStage()
	local spec = self.spec_greenhouse

	if table.size(spec.activeFilltypes) == 0 then
		return
	end

	if not spec.hasWater then
		spec.growthTimer:stop()
	else
		spec.growthTimer:start()
	end

	for i = 1, #spec.plantPlaces do
		local plantPlace = spec.plantPlaces[i]
		local plant = spec.filltypeIdToPlant[plantPlace.fillType]
		local newStage = nil

		if not spec.hasWater then
			newStage = plant.stages.withered
		else
			newStage = plantPlace.stage and plantPlace.stage + 1 or plant.stages.first

			if plant.stages.last < newStage then
				newStage = plant.stages.first
			end
		end

		self:setPlantPlaceStage(plantPlace, newStage)
	end
end

function PlaceableGreenhouse:setPlantPlaceStage(plantPlace, stage)
	for n = 0, getNumOfChildren(plantPlace.node) - 1 do
		local plantStage = getChildAt(plantPlace.node, n)

		setVisibility(plantStage, n == stage)
	end

	plantPlace.stage = stage
end
