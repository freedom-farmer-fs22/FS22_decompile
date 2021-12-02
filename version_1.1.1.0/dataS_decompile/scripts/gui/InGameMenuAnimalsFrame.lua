InGameMenuAnimalsFrame = {}
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)
InGameMenuAnimalsFrame.CONTROLS = {
	REPRODUCTION_RATE_TEXT = "animalReproductionRateText",
	CLEANLINESS_ELEMENT = "cleanlinessElement",
	ANIMAL_TYPE_NAME_TEXT = "animalDetailTypeNameText",
	ANIMAL_VALUE_TEXT = "animalProductValue",
	AGE_TEXT = "animalAgeText",
	HEALTH_BAR_VALUE_TEXT = "healthValueText",
	CONDITION_VALUE_TEXTS = "conditionValue",
	FITNESS_ELEMENT = "fitnessElement",
	FOOD_VALUE_TEXTS = "foodValue",
	DETAIL_OUTPUT_BOX = "detailOutputBox",
	CONDITION_ROWS = "conditionRow",
	INFO_BARS = "infoStatusBar",
	REPRODUCTION_BAR = "reproductionStatusBar",
	NO_HUSBANDRIES_TEXT = "noHusbandriesBox",
	CLEANLINESS_BAR_VALUE_TEXT = "cleanlinessValueText",
	FITNESS_BAR_VALUE_TEXT = "fitnessValueText",
	REQUIREMENTS_LAYOUT = "requirementsLayout",
	FOOD_ROWS = "foodRow",
	INFO_ROWS = "infoRow",
	FOOD_BARS = "foodStatusBar",
	FITNESS_BAR = "fitnessStatusBar",
	DESCRIPTION_TEXT = "detailDescriptionText",
	LIVESTOCK_ATTRIBUTES_LAYOUT = "livestockAttributesLayout",
	ANIMAL_TYPE_VALUE_TEXT = "animalDetailTypeValueText",
	ANIMAL_TYPE_IMAGE = "animalDetailTypeImage",
	NO_ANIMALS_TEXT = "noAnimalsBox",
	ANIMAL_LIST = "list",
	FOOD_HEADER = "foodHeader",
	REPRODUCTION_ELEMENT = "reproductionElement",
	CONDITIONS_HEADER = "conditionsHeader",
	ANIMAL_BOX_TEMPLATE = "animalTemplate",
	TIME_UNTIL_REPRODUCTION_TEXT = "animalTimeTillNextAnimalText",
	TOTAL_FOOD_BAR = "foodRowTotalStatusBar",
	DETAILS_BOX = "detailsBox",
	TOTAL_FOOD_VALUE = "foodRowTotalValue",
	DETAIL_INPUT_BOX = "detailInputBox",
	CONDITION_BARS = "conditionStatusBar",
	CONDITION_LABEL_TEXTS = "conditionLabel",
	DETAIL_DESCRIPTION_BOX = "detailDescriptionBox",
	INFO_VALUE_TEXTS = "infoValue",
	HEALTH_BAR = "healthStatusBar",
	CLEANLINESS_BAR = "cleanlinessStatusBar",
	INFO_LABEL_TEXTS = "infoLabel",
	FOOD_LABEL_TEXTS = "foodLabel",
	REPRODUCTION_BAR_VALUE_TEXT = "reproductionValueText",
	ANIMAL_LIST_BOX = "animalsListBox",
	ANIMALS_CONTAINER = "animalsContainer"
}
InGameMenuAnimalsFrame.UPDATE_INTERVAL = 5000
InGameMenuAnimalsFrame.HORSE_TYPE = "HORSE"
InGameMenuAnimalsFrame.CHICKEN_TYPE = "CHICKEN"
InGameMenuAnimalsFrame.ANIMAL_PRODUCT_FILL_TYPES = {
	EGG = "EGG",
	MILK = "MILK",
	WOOL = "WOOL"
}
InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH = 16

function InGameMenuAnimalsFrame.new(subclass_mt, messageCenter, l10n, fillTypeManager)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or InGameMenuAnimalsFrame_mt)

	self:registerControls(InGameMenuAnimalsFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.fillTypeManager = fillTypeManager
	self.sortedHusbandries = {}
	self.selectedClusterIsHorse = false
	self.selectedCluster = nil
	self.selectedHusbandry = nil
	self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
	self.hasCustomMenuButtons = true
	self.renameButtonInfo = {}

	return self
end

function InGameMenuAnimalsFrame:copyAttributes(src)
	InGameMenuAnimalsFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.fillTypeManager = src.fillTypeManager
end

function InGameMenuAnimalsFrame:onGuiSetupFinished()
	InGameMenuAnimalsFrame:superClass().onGuiSetupFinished(self)
	self.list:setDataSource(self)
	self.list:setDelegate(self)
end

function InGameMenuAnimalsFrame:onFrameOpen()
	InGameMenuAnimalsFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalDataChanged, self)
	self.messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self.updateHusbandries, self)
	self.messageCenter:subscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self.updateHusbandries, self)
	self:updateHusbandries()
	self:updateMenuButtons()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.list)
	self:setSoundSuppressed(false)
end

function InGameMenuAnimalsFrame:onFrameClose()
	self.messageCenter:unsubscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)
	self.messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE, self)
	self.messageCenter:unsubscribe(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE, self)
	InGameMenuAnimalsFrame:superClass().onFrameClose(self)
end

function InGameMenuAnimalsFrame:initialize()
	self.renameButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME),
		callback = function ()
			self:onButtonRename()
		end
	}
	self.hotspotButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function ()
			self:onButtonHotspot()
		end
	}
end

function InGameMenuAnimalsFrame:onAnimalDataChanged()
	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm

	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:update(dt)
	InGameMenuAnimalsFrame:superClass().update(self, dt)

	if self.selectedHusbandry ~= nil then
		self.animalDataUpdateTime = self.animalDataUpdateTime - dt

		if self.animalDataUpdateTime < 0 then
			self:updateAnimalData()
			self:displayCluster(self.selectedCluster, self.selectedHusbandry)

			self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
		end
	end
end

local function sortHusbandries(a, b)
	local aX, aZ, bX, bZ = nil
	local aTypeIndex = a:getAnimalTypeIndex()
	local bTypeIndex = b:getAnimalTypeIndex()

	if aTypeIndex ~= bTypeIndex then
		if aTypeIndex == AnimalType.HORSE then
			return false
		elseif bTypeIndex == AnimalType.HORSE then
			return true
		end
	end

	local aHotspot, bHotspot = nil

	if a.getHotspot ~= nil then
		aHotspot = a:getHotspot(1)
	end

	if b.getHotspot ~= nil then
		bHotspot = b:getHotspot(1)
	end

	aX, aZ = aHotspot:getWorldPosition()
	bX, bZ = bHotspot:getWorldPosition()

	if aX == bX then
		return aZ < bZ
	end

	return aX < bX
end

function InGameMenuAnimalsFrame:updateHusbandries()
	self.sortedHusbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm(self.playerFarm.farmId)

	table.sort(self.sortedHusbandries, sortHusbandries)
	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:updateAnimalData()
	local hasHusbandries = #self.sortedHusbandries > 0
	local hasAnimals = false

	for _, husbandry in ipairs(self.sortedHusbandries) do
		if husbandry:getNumOfClusters() > 0 then
			hasAnimals = true

			break
		end
	end

	self.animalsListBox:setVisible(hasHusbandries)
	self.detailsBox:setVisible(hasAnimals)
	self.noHusbandriesBox:setVisible(not hasHusbandries)
	self.noAnimalsBox:setVisible(hasHusbandries and not hasAnimals)
	self.list:reloadData()
end

function InGameMenuAnimalsFrame:getMainElementSize()
	return self.animalsContainer.size
end

function InGameMenuAnimalsFrame:getMainElementPosition()
	return self.animalsContainer.absPosition
end

function InGameMenuAnimalsFrame:setStatusBarValue(statusBarElement, value, invertedBar, disabled)
	local profile = "ingameMenuAnimalsSmallStatusBarLow"
	local testValue = value

	if invertedBar then
		testValue = 1 - value
	end

	if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < testValue and testValue <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
		profile = "ingameMenuAnimalsSmallStatusBarMedium"
	elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < testValue then
		profile = "ingameMenuAnimalsSmallStatusBar"
	end

	statusBarElement:applyProfile(profile)

	local fullWidth = statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2
	local minSize = 0

	if statusBarElement.startSize ~= nil then
		minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
	end

	statusBarElement:setSize(math.max(minSize, fullWidth * math.min(1, value)), nil)

	disabled = Utils.getNoNil(disabled, false)

	statusBarElement:setDisabled(disabled)
end

function InGameMenuAnimalsFrame:updateConditionDisplay(husbandry)
	local infos = husbandry:getConditionInfos()

	for index, row in ipairs(self.conditionRow) do
		local info = infos[index]

		row:setVisible(info ~= nil)

		if info ~= nil then
			local valueText = info.valueText or self.l10n:formatVolume(info.value, 0, info.customUnitText)

			self.conditionLabel[index]:setText(info.title)
			self.conditionValue[index]:setText(valueText)
			self:setStatusBarValue(self.conditionStatusBar[index], info.ratio, info.invertedBar)
		end
	end
end

function InGameMenuAnimalsFrame:updateFoodDisplay(husbandry)
	local infos = husbandry:getFoodInfos()
	local totalCapacity = 0
	local totalValue = 0

	for index, row in ipairs(self.foodRow) do
		local info = infos[index]

		row:setVisible(info ~= nil)

		if info ~= nil then
			local valueText = self.l10n:formatVolume(info.value, 0)
			totalCapacity = info.capacity
			totalValue = totalValue + info.value

			self.foodLabel[index]:setText(info.title)
			self.foodValue[index]:setText(valueText)
			self:setStatusBarValue(self.foodStatusBar[index], info.ratio, info.invertedBar)
		end
	end

	local totalValueText = self.l10n:formatVolume(totalValue, 0)
	local totalRatio = 0

	if totalCapacity > 0 then
		totalRatio = totalValue / totalCapacity
	end

	self.foodRowTotalValue:setText(totalValueText)
	self:setStatusBarValue(self.foodRowTotalStatusBar, totalRatio, false)
end

function InGameMenuAnimalsFrame:displayCluster(cluster, husbandry)
	local subTypeIndex = cluster:getSubTypeIndex()
	local age = cluster:getAge()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
	local visual = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)

	if visual ~= nil then
		local name = visual.store.name

		if cluster.getName ~= nil then
			name = cluster:getName()
		end

		self.animalDetailTypeNameText:setText(name)
		self.animalDetailTypeImage:setImageFilename(visual.store.imageFilename)

		local value = cluster:getSellPrice()
		local priceText = self.l10n:formatMoney(value, 0, true, true)

		self.animalDetailTypeValueText:setText(priceText)

		local ageText = self.l10n:formatNumMonth(age)

		self.animalAgeText:setText(ageText)

		local infos = husbandry:getAnimalInfos(cluster)

		for index, row in ipairs(self.infoRow) do
			local info = infos[index]

			row:setVisible(info ~= nil)

			if info ~= nil then
				local valueText = info.valueText or self.l10n:formatVolume(info.value, 0, info.customUnitText)

				self.infoLabel[index]:setText(info.title)
				self.infoValue[index]:setText(valueText)
				self:setStatusBarValue(self.infoStatusBar[index], info.ratio, info.invertedBar, info.disabled)
			end
		end

		local infoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_LIVESTOCK)

		if subType.typeIndex == AnimalType.CHICKEN then
			infoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_CHICKEN)
		elseif subType.typeIndex == AnimalType.HORSE then
			infoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_HORSE)
		end

		local foodText = self:getFoodDescription(subType.typeIndex)

		self.detailDescriptionText:setText(infoText .. " " .. foodText)
	end

	self:updateConditionDisplay(husbandry)
	self:updateFoodDisplay(husbandry)
end

function InGameMenuAnimalsFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	if self.selectedClusterIsHorse then
		table.insert(self.menuButtonInfo, self.renameButtonInfo)
	end

	if self.selectedHusbandry ~= nil then
		local hotspot = nil

		if self.selectedHusbandry.getHotspot ~= nil then
			hotspot = self.selectedHusbandry:getHotspot(1)
		end

		if hotspot ~= nil then
			if hotspot == g_currentMission.currentMapTargetHotspot then
				self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.REMOVE_MARKER)
			else
				self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.SET_MARKER)
			end

			table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
		end
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuAnimalsFrame:renameCurrentHorse(newName, hasConfirmed)
	if hasConfirmed and self.selectedClusterIsHorse then
		self.selectedHusbandry:renameAnimal(self.selectedCluster.id, newName)
	end
end

function InGameMenuAnimalsFrame:getFoodDescription(animalTypeIndex)
	local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
	local consumptionType = animalFood.consumptionType
	local foodGroups = animalFood.groups
	local foodDescription = nil

	if consumptionType == AnimalFoodSystem.FOOD_CONSUME_TYPE_PARALLEL then
		foodDescription = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_PARALLEL)
	else
		foodDescription = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_SERIAL)
	end

	foodDescription = foodDescription .. "\n"
	local weightLabel = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_MIX_EFFECTIVENESS)
	local line = nil

	for i, group in ipairs(foodGroups) do
		local fillTypeNames = ""

		for j, fillTypeIndex in ipairs(group.fillTypes) do
			local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			fillTypeNames = fillTypeNames .. fillType.title

			if j < #group.fillTypes then
				fillTypeNames = fillTypeNames .. InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR
			end
		end

		line = "- " .. fillTypeNames
		line = line .. string.format(" (%s: %.0f%%)", weightLabel, group.productionWeight * 100)
		foodDescription = foodDescription .. line

		if i < #foodGroups then
			foodDescription = foodDescription .. "\n"
		end
	end

	return foodDescription
end

function InGameMenuAnimalsFrame:getNumberOfSections()
	return #self.sortedHusbandries
end

function InGameMenuAnimalsFrame:getTitleForSectionHeader(list, section)
	local husbandry = self.sortedHusbandries[section]

	return husbandry:getName()
end

function InGameMenuAnimalsFrame:getNumberOfItemsInSection(list, section)
	local husbandry = self.sortedHusbandries[section]

	return husbandry:getNumOfClusters()
end

function InGameMenuAnimalsFrame:populateCellForItemInSection(list, section, index, cell)
	local husbandry = self.sortedHusbandries[section]
	local cluster = husbandry:getCluster(index)
	local subTypeIndex = cluster:getSubTypeIndex()
	local age = cluster:getAge()
	local visual = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)

	if visual ~= nil then
		local name = visual.store.name

		if cluster.getName ~= nil then
			name = cluster:getName()
		end

		local price = cluster:getSellPrice()
		local priceText = self.l10n:formatMoney(price, 0, true, true)

		cell:getAttribute("priceValue"):setText(priceText)
		cell:getAttribute("count"):setValue(cluster.numAnimals)
		cell:getAttribute("count"):setVisible(subType.typeIndex ~= AnimalType.HORSE)
		cell:getAttribute("name"):setText(name)
		cell:getAttribute("typeIcon"):setImageFilename(visual.store.imageFilename)
	end
end

function InGameMenuAnimalsFrame:onButtonRename()
	local promptText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.PROMPT_RENAME)
	local imePromptText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.IME_PROMPT_RENAME)
	local confirmText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_CONFIRM)
	local activateInputText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME)

	g_gui:showTextInputDialog({
		target = self,
		callback = self.renameCurrentHorse,
		defaultText = self.selectedCluster:getName(),
		dialogPrompt = promptText,
		imePrompt = imePromptText,
		confirmText = confirmText,
		maxCharacters = InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH,
		activateInputText = activateInputText
	})
end

function InGameMenuAnimalsFrame:onButtonHotspot()
	local husbandry = self.selectedHusbandry
	local hotspot = nil

	if self.selectedHusbandry.getHotspot ~= nil then
		hotspot = self.selectedHusbandry:getHotspot(1)
	end

	if husbandry and hotspot ~= nil then
		if hotspot == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
		else
			g_currentMission:setMapTargetHotspot(hotspot)
		end

		self:updateMenuButtons()
	end
end

function InGameMenuAnimalsFrame:onListSelectionChanged(list, section, index)
	local husbandry = self.sortedHusbandries[section]
	local cluster = husbandry:getCluster(index)
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
	self.selectedHusbandry = husbandry
	local isHorse = subType.typeIndex == AnimalType.HORSE
	self.selectedClusterIsHorse = isHorse
	self.selectedCluster = cluster

	self:displayCluster(self.selectedCluster, husbandry)
	self.livestockAttributesLayout:invalidateLayout()
	self:updateMenuButtons()
end

InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR = " / "
InGameMenuAnimalsFrame.L10N_SYMBOL = {
	FOOD_MIX_EFFECTIVENESS = "animals_foodMixEffectiveness",
	BUTTON_CONFIRM = "button_confirm",
	REMOVE_MARKER = "action_untag",
	HORSE_FITNESS = "ui_horseFitness",
	FOOD_DESCRIPTION_PARALLEL = "animals_foodMixDescriptionParallel",
	IME_PROMPT_RENAME = "ui_horseName",
	BUTTON_HOTSPOT = "button_showOnMap",
	FOOD_MIX_QUANITITY = "animals_foodMixQuantity",
	FOOD_DESCRIPTION_SERIAL = "animals_foodMixDescriptionSerial",
	PROMPT_RENAME = "ui_enterHorseName",
	DESC_HORSE = "animals_descriptionHorse",
	BUTTON_RENAME = "button_rename",
	SET_MARKER = "action_tag",
	DESC_CHICKEN = "animals_descriptionChicken",
	WATER = "statistic_water",
	DESC_LIVESTOCK = "animals_descriptionGeneric",
	CLEANLINESS = "statistic_cleanliness",
	STRAW = "statistic_strawStorage"
}
InGameMenuAnimalsFrame.STATUS_BAR_HIGH = 0.66
InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM = 0.33
