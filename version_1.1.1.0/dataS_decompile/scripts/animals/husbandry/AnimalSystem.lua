AnimalType = nil
AnimalSubType = nil
AnimalSystem = {}
local AnimalSystem_mt = Class(AnimalSystem)
AnimalSystem.SEND_NUM_BITS = 4

function AnimalSystem.new(isServer, mission, customMt)
	local self = setmetatable({}, customMt or AnimalSystem_mt)
	self.isServer = isServer
	self.mission = mission
	self.subTypeIndexToAnimalData = {}
	self.types = {}
	self.nameToType = {}
	self.nameToTypeIndex = {}
	self.typeIndexToName = {}
	self.subTypes = {}
	self.nameToSubType = {}
	self.nameToSubTypeIndex = {}
	self.fillTypeIndexToSubType = {}
	AnimalType = self.nameToTypeIndex
	AnimalSubType = self.nameToSubTypeIndex

	return self
end

function AnimalSystem:delete()
end

function AnimalSystem:loadMapData(xmlFile)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.animals#filename"), self.mission.baseDirectory)

	if filename == nil then
		Logging.xmlError(XMLFile.wrap(xmlFile), "Missing animals configuration file")

		return false
	end

	local xmlFileAnimals = XMLFile.load("animals", filename)

	if xmlFileAnimals == nil then
		return false
	end

	self:loadAnimals(xmlFileAnimals, self.mission.baseDirectory)
	xmlFileAnimals:delete()

	return #self.types > 0
end

function AnimalSystem:loadAnimals(xmlFile, baseDirectory)
	xmlFile:iterate("animals.animal", function (_, key)
		if #self.types >= 2^AnimalSystem.SEND_NUM_BITS - 1 then
			Logging.xmlWarning(xmlFile, "Maximum number of supported animal types reached. Ignoring remaining types")

			return false
		end

		local typeName = xmlFile:getString(key .. "#type")

		if typeName == nil then
			Logging.xmlError(xmlFile, "Missing animal type. '%s'", key)

			return false
		end

		typeName = typeName:upper()

		if self.nameToTypeIndex[typeName] ~= nil then
			Logging.xmlError(xmlFile, "Animal type '%s' already defined. '%s'", typeName, key)

			return false
		end

		local configFilename = xmlFile:getString(key .. ".configFilename")

		if configFilename == nil then
			Logging.xmlError(xmlFile, "Missing config file for animal type '%s'. '%s'", typeName, key)

			return false
		end

		local clusterClassName = xmlFile:getString(key .. "#clusterClass")

		if clusterClassName == nil then
			Logging.xmlError(xmlFile, "Missing animal clusterClass for '%s'!", key)

			return false
		end

		local statsBreedingName = xmlFile:getString(key .. "#statsBreeding")

		if not ClassUtil.getIsValidClassName(clusterClassName) then
			Logging.xmlError(xmlFile, "Invalid animal clusterClass name '%s' for '%s'!", tostring(clusterClassName), key)

			return false
		end

		if ClassUtil.getClassObject(clusterClassName) == nil then
			Logging.xmlError(xmlFile, "Unknown animal clusterClass '%s' for '%s'!", tostring(clusterClassName), key)

			return false
		end

		local animalType = {
			name = typeName,
			typeIndex = #self.types + 1,
			configFilename = configFilename,
			clusterClass = ClassUtil.getClassObject(clusterClassName),
			statsBreedingName = statsBreedingName,
			subTypes = {}
		}

		self:loadAnimalConfig(animalType, baseDirectory)

		if self:loadSubTypes(animalType, xmlFile, key, baseDirectory) then
			table.insert(self.types, animalType)

			self.nameToType[typeName] = animalType
			self.nameToTypeIndex[typeName] = animalType.typeIndex
			self.typeIndexToName[animalType.typeIndex] = typeName
		end
	end)
end

function AnimalSystem:loadAnimalConfig(animalType, baseDirectory)
	animalType.animals = {}
	local configFilename = Utils.getFilename(animalType.configFilename, baseDirectory)
	local xmlFile = XMLFile.load("animalsConfig", configFilename)

	if xmlFile == nil then
		return false
	end

	xmlFile:iterate("animalHusbandry.animals.animal", function (_, key)
		local animal = {
			filename = Utils.getFilename(xmlFile:getString(key .. ".assets#filename"), baseDirectory),
			filenamePosed = Utils.getFilename(xmlFile:getString(key .. ".assets#filenamePosed"), baseDirectory),
			variations = {}
		}

		xmlFile:iterate(key .. ".assets.texture", function (_, textureKey)
			local variation = {
				numTilesU = xmlFile:getInt(textureKey .. "#numTilesU", 1)
			}
			variation.tileUIndex = MathUtil.clamp(xmlFile:getInt(textureKey .. "#tileUIndex", 0), 0, variation.numTilesU - 1)
			variation.numTilesV = xmlFile:getInt(textureKey .. "#numTilesV", 1)
			variation.tileVIndex = MathUtil.clamp(xmlFile:getInt(textureKey .. "#tileVIndex", 0), 0, variation.numTilesV - 1)
			variation.mirrorV = xmlFile:getBool(textureKey .. "#mirrorV", false)
			variation.multi = xmlFile:getBool(textureKey .. "#multi", true)

			table.insert(animal.variations, variation)
		end)
		table.insert(animalType.animals, animal)
	end)
	xmlFile:delete()

	return true
end

function AnimalSystem:loadSubTypes(animalType, xmlFile, key, baseDirectory)
	xmlFile:iterate(key .. ".subType", function (_, subTypeKey)
		local subTypeName = xmlFile:getString(subTypeKey .. "#subType")

		if subTypeName == nil then
			Logging.xmlError(xmlFile, "Missing animal subtype. '%s'", subTypeKey)

			return false
		end

		subTypeName = subTypeName:upper()

		if self.nameToSubTypeIndex[subTypeName] ~= nil then
			Logging.xmlError(xmlFile, "Animal subtype '%s' already defined. '%s'", subTypeName, subTypeKey)

			return false
		end

		local fillTypeName = xmlFile:getString(subTypeKey .. "#fillTypeName")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			Logging.xmlError(xmlFile, "FillType '%s' for animal subtype '%s' not defined!", fillTypeName, subTypeKey)

			return false
		end

		local subType = {
			name = subTypeName,
			subTypeIndex = #self.subTypes + 1,
			fillTypeIndex = fillTypeIndex,
			typeIndex = animalType.typeIndex
		}

		table.insert(animalType.subTypes, subType.subTypeIndex)

		if self:loadSubType(animalType, subType, xmlFile, subTypeKey, baseDirectory) then
			table.insert(self.subTypes, subType)

			self.nameToSubType[subTypeName] = subType
			self.nameToSubTypeIndex[subTypeName] = subType.subTypeIndex
			self.fillTypeIndexToSubType[fillTypeIndex] = subType
		end
	end)

	return true
end

function AnimalSystem:loadSubType(animalType, subType, xmlFile, subTypeKey, baseDirectory)
	local rideableFilename = xmlFile:getString(subTypeKey .. ".rideable#filename")

	if rideableFilename ~= nil then
		subType.rideableFilename = Utils.getFilename(rideableFilename, baseDirectory)
	end

	local input = {
		straw = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.straw"),
		water = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.water"),
		food = self:loadAnimCurve(xmlFile, subTypeKey .. ".input.food")
	}
	subType.input = input
	local output = {
		milk = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.milk"),
		manure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.manure"),
		liquidManure = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.liquidManure"),
		pallets = self:loadAnimCurve(xmlFile, subTypeKey .. ".output.pallets")
	}
	subType.output = output
	subType.buyPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".buyPrice")
	subType.transportPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".transportPrice")
	subType.sellPrice = self:loadAnimCurve(xmlFile, subTypeKey .. ".sellPrice")
	subType.supportsReproduction = xmlFile:getBool(subTypeKey .. ".reproduction#supported", true)
	subType.reproductionMinAgeMonth = xmlFile:getInt(subTypeKey .. ".reproduction#minAgeMonth", 18)
	subType.reproductionDurationMonth = xmlFile:getInt(subTypeKey .. ".reproduction#durationMonth", 10)
	subType.reproductionMinHealth = MathUtil.clamp(xmlFile:getFloat(subTypeKey .. ".reproduction#minHealthFactor", 0.75), 0, 1)
	subType.healthIncreaseHour = MathUtil.clamp(xmlFile:getInt(subTypeKey .. ".health#increasePerHour", 10), 0, 100)
	subType.healthDecreaseHour = MathUtil.clamp(xmlFile:getInt(subTypeKey .. ".health#decreasePerHour", 25), 0, 100)
	subType.healthThresholdFactor = MathUtil.clamp(xmlFile:getFloat(subTypeKey .. ".health#thresholdFactor", 0.7), 0, 1)
	subType.ridingThresholdFactor = MathUtil.clamp(xmlFile:getFloat(subTypeKey .. ".health#ridingThreshold", 0.4), 0, 1)
	subType.visuals = {}

	xmlFile:iterate(subTypeKey .. ".visuals.visual", function (_, visualKey)
		local visual = self:loadVisualData(animalType, xmlFile, visualKey, baseDirectory)

		if visual ~= nil then
			local valid = true

			if #subType.visuals == 0 then
				if visual.minAge ~= 0 then
					valid = false

					Logging.xmlWarning(xmlFile, "First visual must have minAge = 0 for '%s'", visualKey)
				end
			elseif visual.minAge <= subType.visuals[#subType.visuals].minAge then
				valid = false

				Logging.xmlWarning(xmlFile, "Visual minAge has to be greater than predecessor minAge. '%s'", visualKey)
			end

			if valid then
				table.insert(subType.visuals, visual)
			end
		end
	end)

	if #subType.visuals == 0 then
		Logging.xmlWarning(xmlFile, "No visuals defined for '%s'", subTypeKey)

		return false
	end

	return true
end

function AnimalSystem:loadAnimCurve(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return nil
	end

	local curve = AnimCurve.new(linearInterpolator1)

	xmlFile:iterate(key .. ".key", function (_, valueKey)
		local ageMonth = xmlFile:getInt(valueKey .. "#ageMonth")
		local value = xmlFile:getInt(valueKey .. "#value")

		if ageMonth == nil then
			Logging.xmlWarning(xmlFile, "Missing ageMonth for '%s'", valueKey)

			return
		end

		if value == nil then
			Logging.xmlWarning(xmlFile, "Missing value for '%s'", valueKey)

			return
		end

		curve:addKeyframe({
			value,
			time = ageMonth
		})
	end)

	return curve
end

function AnimalSystem:loadVisualData(animalType, xmlFile, key, baseDirectory)
	if not xmlFile:hasProperty(key) then
		return nil
	end

	local visualAnimalIndex = xmlFile:getInt(key .. "#visualAnimalIndex")

	if visualAnimalIndex == nil then
		Logging.xmlError(xmlFile, "Missing animal index for '%s'", key)

		return nil
	end

	local animal = animalType.animals[visualAnimalIndex]

	if animal == nil then
		Logging.xmlError(xmlFile, "Animal index not defined for '%s'", key)

		return nil
	end

	local image = xmlFile:getString(key .. "#image")

	if image == nil then
		Logging.xmlError(xmlFile, "Missing store image for '%s'", key)

		return nil
	end

	local storeName = xmlFile:getString(key .. "#name")

	if storeName == nil then
		Logging.xmlError(xmlFile, "Missing store name for '%s'", key)

		return nil
	end

	local minAge = xmlFile:getInt(key .. "#minAge", 0)

	if minAge < 0 then
		Logging.xmlError(xmlFile, "Invalid minAge for '%s'", key)

		return nil
	end

	local descriptions = {}

	xmlFile:iterate(key .. ".description", function (_, descKey)
		local descItem = xmlFile:getString(descKey)

		if descItem ~= nil then
			table.insert(descriptions, g_i18n:convertText(descItem))
		end
	end)

	if #descriptions == 0 then
		Logging.xmlError(xmlFile, "Missing description for '%s'", key)

		return nil
	end

	local store = {
		name = g_i18n:convertText(storeName),
		imageFilename = Utils.getFilename(image, baseDirectory),
		canBeBought = xmlFile:getBool(key .. "#canBeBought", false),
		description = table.concat(descriptions, " ")
	}
	local visualData = {
		store = store,
		visualAnimalIndex = visualAnimalIndex,
		minAge = minAge,
		visualAnimal = animal
	}

	return visualData
end

function AnimalSystem:getAnimalBuyPrice(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]

	if subType == nil then
		return nil
	end

	return subType.buyPrice:get(age)
end

function AnimalSystem:getAnimalTransportFee(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]

	if subType == nil then
		return 0
	end

	return subType.transportPrice:get(age)
end

function AnimalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)
	local visual = self:getVisualByAge(subTypeIndex, age)

	if visual == nil then
		return nil
	end

	return visual.visualAnimalIndex
end

function AnimalSystem:getVisualByAge(subTypeIndex, age)
	local subType = self.subTypes[subTypeIndex]

	if subType == nil then
		return nil
	end

	local visual = nil

	for _, v in ipairs(subType.visuals) do
		if v.minAge <= age then
			visual = v
		end
	end

	return visual
end

function AnimalSystem:getSubTypeByIndex(index)
	return self.subTypes[index]
end

function AnimalSystem:getSubTypeByName(name)
	return self.nameToSubType[name:upper()]
end

function AnimalSystem:getSubTypeIndexByName(name)
	return self.nameToSubTypeIndex[name:upper()]
end

function AnimalSystem:getTypeByIndex(index)
	return self.types[index]
end

function AnimalSystem:getTypeByName(name)
	return self.nameToType[name:upper()]
end

function AnimalSystem:getTypeIndexByName(name)
	return self.nameToTypeIndex[name:upper()]
end

function AnimalSystem:getSubTypeByFillTypeIndex(fillTypeIndex)
	return self.fillTypeIndexToSubType[fillTypeIndex]
end

function AnimalSystem:getSubTypeIndexByFillTypeIndex(fillTypeIndex)
	if self.fillTypeIndexToSubType[fillTypeIndex] ~= nil then
		return self.fillTypeIndexToSubType[fillTypeIndex].subTypeIndex
	end

	return nil
end

function AnimalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
	local subType = self.subTypes[subTypeIndex]

	return subType.typeIndex
end

function AnimalSystem:getTypes()
	return self.types
end

function AnimalSystem:getClusterClassBySubTypeIndex(subTypeIndex)
	local subType = self:getSubTypeByIndex(subTypeIndex)
	local animalType = self:getTypeByIndex(subType.typeIndex)

	return animalType.clusterClass
end

function AnimalSystem:createClusterFromSubTypeIndex(subTypeIndex)
	local subType = self:getSubTypeByIndex(subTypeIndex)
	local animalType = self:getTypeByIndex(subType.typeIndex)
	local cluster = animalType.clusterClass.new()
	cluster.subTypeIndex = subTypeIndex

	return cluster
end
