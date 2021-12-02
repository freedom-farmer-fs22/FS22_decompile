AnimalFoodSystem = {}
local AnimalFoodSystem_mt = Class(AnimalFoodSystem)
AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL = 1
AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL = 2

g_xmlManager:addCreateSchemaFunction(function ()
	AnimalFoodSystem.xmlSchema = XMLSchema.new("animalFood")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = AnimalFoodSystem.xmlSchema

	schema:register(XMLValueType.STRING, "animalFood.animals.animal(?)#animalType", "Animal type name")
	schema:register(XMLValueType.STRING, "animalFood.animals.animal(?)#consumptionType", "Food consumption type", "SERIAL")
	schema:register(XMLValueType.STRING, "animalFood.animals.animal(?).foodGroup(?)#title", "Food group title")
	schema:register(XMLValueType.FLOAT, "animalFood.animals.animal(?).foodGroup(?)#productionWeight", "Food group production weight", 0)
	schema:register(XMLValueType.FLOAT, "animalFood.animals.animal(?).foodGroup(?)#eatWeight", "Food group eat weight", 1)
	schema:register(XMLValueType.STRING, "animalFood.animals.animal(?).foodGroup(?)#fillTypes", "Food group fill types")
	schema:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?)#fillType", "Mixture fill type")
	schema:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?)#animalType", "Mixture animal type")
	schema:register(XMLValueType.FLOAT, "animalFood.mixtures.mixture(?).ingredient(?)#weight", "Mixture ingredient weight", 0)
	schema:register(XMLValueType.STRING, "animalFood.mixtures.mixture(?).ingredient(?)#fillTypes", "Mixture ingredient fill types")
	schema:register(XMLValueType.STRING, "animalFood.recipes.recipe(?)#fillType", "Recipe fill type")
	schema:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#name", "Ingredient name")
	schema:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#title", "Ingredient title")
	schema:register(XMLValueType.INT, "animalFood.recipes.recipe(?).ingredient(?)#minPercentage", "Ingredient min percentage")
	schema:register(XMLValueType.INT, "animalFood.recipes.recipe(?).ingredient(?)#maxPercentage", "Ingredient max percentage")
	schema:register(XMLValueType.STRING, "animalFood.recipes.recipe(?).ingredient(?)#fillTypes", "Ingredient fill types")
end)

function AnimalFoodSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or AnimalFoodSystem_mt)
	self.mission = mission
	self.animalFood = {}
	self.indexToAnimalFood = {}
	self.animalTypeIndexToFood = {}
	self.mixtures = {}
	self.recipes = {}
	self.recipeFillTypeIndexToRecipe = {}
	self.animalMixtures = {}
	self.mixtureFillTypeIndexToMixture = {}

	return self
end

function AnimalFoodSystem:delete()
end

function AnimalFoodSystem:loadMapData(xmlFile, missionInfo)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.animals.food#filename"), self.mission.baseDirectory)

	if filename == nil then
		Logging.xmlError(xmlFile, "Missing animals food configuration file")

		return false
	end

	local xmlFileFood = XMLFile.load("animalFood", filename, AnimalFoodSystem.xmlSchema)

	if xmlFileFood == nil then
		return false
	end

	if not self:loadAnimalFood(xmlFileFood, self.mission.baseDirectory) then
		xmlFileFood:delete()

		return false
	end

	if not self:loadMixtures(xmlFileFood, self.mission.baseDirectory) then
		xmlFileFood:delete()

		return false
	end

	if not self:loadRecipes(xmlFileFood, self.mission.baseDirectory) then
		xmlFileFood:delete()

		return false
	end

	xmlFileFood:delete()

	return true
end

function AnimalFoodSystem:loadAnimalFood(xmlFile)
	xmlFile:iterate("animalFood.animals.animal", function (_, key)
		local animalTypeName = xmlFile:getValue(key .. "#animalType")
		local animalTypeIndex = self.mission.animalSystem:getTypeIndexByName(animalTypeName)

		if animalTypeIndex ~= nil then
			local animalFood = {}

			if self:loadAnimalFoodData(animalFood, xmlFile, key) then
				animalFood.index = #self.animalFood + 1
				animalFood.animalTypeIndex = animalTypeIndex

				table.insert(self.animalFood, animalFood)

				self.indexToAnimalFood[animalFood.index] = animalFood
				self.animalTypeIndexToFood[animalTypeIndex] = animalFood
			end
		else
			Logging.xmlWarning(xmlFile, "Animal type '%s' not defined for foodgroup '%s'", animalTypeName, key)
		end
	end)

	for _, animalFood in pairs(self.animalFood) do
		if animalFood.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
			local sumWeigths = 0
			local eatWeights = 0

			for _, foodGroup in pairs(animalFood.groups) do
				sumWeigths = sumWeigths + foodGroup.productionWeight
				eatWeights = eatWeights + foodGroup.eatWeight
			end

			for _, foodGroup in pairs(animalFood.groups) do
				if sumWeigths > 0 then
					foodGroup.productionWeight = foodGroup.productionWeight / sumWeigths
				end

				if eatWeights > 0 then
					foodGroup.eatWeight = foodGroup.eatWeight / eatWeights
				end
			end
		end
	end

	return true
end

function AnimalFoodSystem:loadAnimalFoodData(animalFood, xmlFile, key)
	local consumptionType = AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL
	local consumptionTypeName = xmlFile:getValue(key .. "#consumptionType", "SERIAL")

	if consumptionTypeName:upper() == "PARALLEL" then
		consumptionType = AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL
	end

	local groups = {}
	local usedFillTypes = {}

	xmlFile:iterate(key .. ".foodGroup", function (_, foodGroupKey)
		local title = xmlFile:getValue(foodGroupKey .. "#title")

		if title == nil then
			Logging.xmlError(xmlFile, "Missing title for animal food group '%s'", foodGroupKey)

			return false
		end

		local foodGroup = {
			title = g_i18n:convertText(title),
			productionWeight = xmlFile:getValue(foodGroupKey .. "#productionWeight", 0),
			eatWeight = xmlFile:getValue(foodGroupKey .. "#eatWeight", 1),
			fillTypes = {}
		}

		if self:getFillTypesFromXML(foodGroup.fillTypes, usedFillTypes, xmlFile, foodGroupKey .. "#fillTypes") then
			table.insert(groups, foodGroup)
		end
	end)

	animalFood.groups = groups
	animalFood.consumptionType = consumptionType

	return true
end

function AnimalFoodSystem:loadMixtures(xmlFile)
	xmlFile:iterate("animalFood.mixtures.mixture", function (_, key)
		local mixtureFillTypeName = xmlFile:getValue(key .. "#fillType")

		if mixtureFillTypeName == nil then
			Logging.xmlError(xmlFile, "Missing fillType for food mixture '%s'", key)

			return false
		end

		local mixtureFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(mixtureFillTypeName)

		if mixtureFillTypeIndex == nil then
			Logging.xmlError(xmlFile, "FillType '%s' not defined for food mixture '%s'", mixtureFillTypeName, key)

			return false
		end

		if self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex] ~= nil then
			Logging.xmlError(xmlFile, "FillType '%s' already defined for mixture '%s'", mixtureFillTypeName, key)

			return false
		end

		local animalTypeName = xmlFile:getValue(key .. "#animalType")

		if animalTypeName == nil then
			Logging.xmlError(xmlFile, "Missing animal type for food mixture '%s'", key)

			return false
		end

		local animalTypeIndex = self.mission.animalSystem:getTypeIndexByName(animalTypeName)

		if animalTypeIndex == nil then
			Logging.xmlError(xmlFile, "Animal type '%s' not defined for food mixture '%s'", animalTypeName, key)

			return false
		end

		local mixture = {}

		if self:loadMixture(mixture, xmlFile, key) then
			mixture.index = #self.mixtures + 1

			table.insert(self.mixtures, mixture)

			self.animalMixtures[animalTypeIndex] = self.animalMixtures[animalTypeIndex] or {}

			table.insert(self.animalMixtures[animalTypeIndex], mixtureFillTypeIndex)

			self.mixtureFillTypeIndexToMixture[mixtureFillTypeIndex] = mixture
		end
	end)

	for _, mixture in pairs(self.mixtures) do
		local sumWeigths = 0

		for _, ingredient in pairs(mixture.ingredients) do
			sumWeigths = sumWeigths + ingredient.weight
		end

		if sumWeigths > 0 then
			for _, ingredient in pairs(mixture.ingredients) do
				ingredient.weight = ingredient.weight / sumWeigths
			end
		end
	end

	return true
end

function AnimalFoodSystem:loadMixture(mixture, xmlFile, key)
	local ingredients = {}
	local usedFillTypes = {}

	xmlFile:iterate(key .. ".ingredient", function (_, ingredientKey)
		local ingredient = {
			fillTypes = {},
			weight = xmlFile:getValue(ingredientKey .. "#weight", 0)
		}

		if self:getFillTypesFromXML(ingredient.fillTypes, usedFillTypes, xmlFile, ingredientKey .. "#fillTypes") then
			table.insert(ingredients, ingredient)
		end
	end)

	mixture.ingredients = ingredients

	return true
end

function AnimalFoodSystem:loadRecipes(xmlFile)
	xmlFile:iterate("animalFood.recipes.recipe", function (_, key)
		local recipeFillTypeName = xmlFile:getValue(key .. "#fillType")

		if recipeFillTypeName == nil then
			Logging.xmlError(xmlFile, "Missing fillType for recipe '%s'", key)

			return false
		end

		local recipeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(recipeFillTypeName)

		if recipeFillTypeIndex == nil then
			Logging.xmlError(xmlFile, "Recipe filltype '%s' not defined for '%s'", recipeFillTypeName, key)

			return false
		end

		if self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex] ~= nil then
			Logging.xmlError(xmlFile, "Recipe '%s' already defined in '%s'", recipeFillTypeName, key)

			return false
		end

		local recipe = {}

		if self:loadRecipe(recipe, xmlFile, key) then
			recipe.index = #self.recipes + 1
			recipe.fillType = recipeFillTypeIndex

			table.insert(self.recipes, recipe)

			self.recipeFillTypeIndexToRecipe[recipeFillTypeIndex] = recipe
		end
	end)

	return true
end

function AnimalFoodSystem:loadRecipe(recipe, xmlFile, key)
	local ingredients = {}
	local sumRatios = 0
	local usedFillTypes = {}

	xmlFile:iterate(key .. ".ingredient", function (_, ingredientKey)
		local ingredient = {
			name = xmlFile:getValue(ingredientKey .. "#name"),
			title = g_i18n:convertText(xmlFile:getValue(ingredientKey .. "#title")),
			minPercentage = xmlFile:getValue(ingredientKey .. "#minPercentage", 0) / 100,
			maxPercentage = xmlFile:getValue(ingredientKey .. "#maxPercentage", 75) / 100
		}
		ingredient.ratio = ingredient.maxPercentage - ingredient.minPercentage
		ingredient.fillTypes = {}
		sumRatios = sumRatios + ingredient.ratio

		if self:getFillTypesFromXML(ingredient.fillTypes, usedFillTypes, xmlFile, ingredientKey .. "#fillTypes") then
			table.insert(ingredients, ingredient)
		end
	end)

	for _, ingredient in ipairs(ingredients) do
		ingredient.ratio = ingredient.ratio / sumRatios
	end

	if #ingredients == 0 then
		Logging.xmlWarning(xmlFile, "No ingredients defined for recipe '%s'", key)

		return false
	end

	recipe.ingredients = ingredients

	return true
end

function AnimalFoodSystem:getFillTypesFromXML(fillTypes, usedFillTypes, xmlFile, key)
	local fillTypeNameStr = xmlFile:getValue(key)

	if fillTypeNameStr == nil then
		Logging.xmlError(xmlFile, "Missing fillTypes for ingredient '%s'", key)

		return false
	end

	local fillTypeNames = string.split(fillTypeNameStr, " ")

	for _, fillTypeName in pairs(fillTypeNames) do
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex ~= nil then
			if usedFillTypes[fillTypeIndex] == nil then
				table.addElement(fillTypes, fillTypeIndex)
			else
				Logging.xmlWarning(xmlFile, "FillType '%s' already used in other ingredient", fillTypeName)
			end
		else
			Logging.xmlWarning(xmlFile, "FillType '%s' not defined. Ignoring it", fillTypeName)
		end
	end

	if #fillTypes == 0 then
		Logging.xmlError(xmlFile, "No fillTypes defined - '%s'", key)

		return false
	end

	return true
end

function AnimalFoodSystem:getAnimalFood(animalTypeIndex)
	return self.animalTypeIndexToFood[animalTypeIndex]
end

function AnimalFoodSystem:getRecipeByFillTypeIndex(fillTypeIndex)
	return self.recipeFillTypeIndexToRecipe[fillTypeIndex]
end

function AnimalFoodSystem:getMixtureByFillType(fillTypeIndex)
	return self.mixtureFillTypeIndexToMixture[fillTypeIndex]
end

function AnimalFoodSystem:getMixturesByAnimalTypeIndex(animalTypeIndex)
	return self.animalMixtures[animalTypeIndex]
end

function AnimalFoodSystem:consumeFood(animalTypeIndex, amountToConsume, fillLevels, consumedFood)
	local animalFood = self.animalTypeIndexToFood[animalTypeIndex]

	if animalFood ~= nil then
		if animalFood.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_SERIAL then
			return self:consumeFoodSerially(amountToConsume, animalFood.groups, fillLevels, consumedFood)
		elseif animalFood.consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
			return self:consumeFoodParallelly(amountToConsume, animalFood.groups, fillLevels, consumedFood)
		end
	end

	return 0
end

function AnimalFoodSystem:consumeFoodSerially(amount, foodGroups, fillLevels, consumedFood)
	local productionWeight = 0
	local totalAmountToConsume = amount

	if totalAmountToConsume > 0 then
		for _, foodGroup in ipairs(foodGroups) do
			local oldAmount = amount
			amount = self:consumeFoodGroup(foodGroup, amount, fillLevels, consumedFood)
			local deltaProdWeight = (oldAmount - amount) / totalAmountToConsume * foodGroup.productionWeight
			productionWeight = productionWeight + deltaProdWeight
		end
	end

	return productionWeight
end

function AnimalFoodSystem:consumeFoodParallelly(amount, foodGroups, fillLevels, consumedFood)
	local productionWeight = 0

	if amount > 0 then
		for _, foodGroup in pairs(foodGroups) do
			local totalFillLevelInGroup = self:getTotalFillLevelInGroup(foodGroup, fillLevels)
			local foodGroupConsume = amount * foodGroup.eatWeight
			local consumeFood = math.min(totalFillLevelInGroup, foodGroupConsume)
			local ret = self:consumeFoodGroup(foodGroup, consumeFood, fillLevels, consumedFood)
			local foodFactor = (consumeFood - ret) / foodGroupConsume
			productionWeight = productionWeight + foodFactor * foodGroup.productionWeight
		end
	end

	return productionWeight
end

function AnimalFoodSystem:consumeFoodGroup(foodGroup, amount, fillLevels, consumedFood)
	for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
		if fillLevels[fillTypeIndex] ~= nil then
			local currentFillLevel = fillLevels[fillTypeIndex]
			local amountToConsume = math.min(amount, currentFillLevel)
			local deltaConsumed = math.min(fillLevels[fillTypeIndex], amountToConsume)
			amount = math.max(amount - deltaConsumed, 0)
			consumedFood[fillTypeIndex] = deltaConsumed

			if amount == 0 then
				return amount
			end
		end
	end

	return amount
end

function AnimalFoodSystem:getTotalFillLevelInGroup(foodGroup, fillLevels)
	local totalFillLevel = 0

	for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
		if fillLevels[fillTypeIndex] ~= nil then
			totalFillLevel = totalFillLevel + fillLevels[fillTypeIndex]
		end
	end

	return totalFillLevel
end
