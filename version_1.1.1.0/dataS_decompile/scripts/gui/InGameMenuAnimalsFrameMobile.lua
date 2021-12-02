InGameMenuAnimalsFrameMobile = {}
local InGameMenuAnimalsFrameMobile_mt = Class(InGameMenuAnimalsFrameMobile, InGameMenuAnimalsFrame)
InGameMenuAnimalsFrameMobile.MAX_NUM_ANIMALS = 6
InGameMenuAnimalsFrameMobile.CONTROLS = {
	"animalAttribute",
	"animalAttributeLabel",
	"animalAttributeText"
}
InGameMenuAnimalsFrameMobile.MODE = {
	DETAILS = 2,
	LIST = 1
}

function InGameMenuAnimalsFrameMobile.new(subclass_mt, messageCenter, l10n, fillTypeManager)
	local self = InGameMenuAnimalsFrameMobile:superClass().new(subclass_mt or InGameMenuAnimalsFrameMobile_mt, messageCenter, l10n, fillTypeManager)

	self:registerControls(InGameMenuAnimalsFrameMobile.CONTROLS)

	self.mode = InGameMenuAnimalsFrameMobile.MODE.LIST
	self.nextAnimalAttributeIndex = 1

	return self
end

function InGameMenuAnimalsFrameMobile:onFrameOpen()
	self:setMode(InGameMenuAnimalsFrameMobile.MODE.LIST)

	self.currentPage = 1

	InGameMenuAnimalsFrameMobile:superClass().onFrameOpen(self)
end

function InGameMenuAnimalsFrameMobile:initialize()
	InGameMenuAnimalsFrameMobile:superClass().onFrameOpen(self)

	self.selectButtonInfo = {
		profile = "buttonSelect",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText("button_select"),
		callback = function ()
			self:onButtonSelect()
		end
	}
	self.toListButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText("button_back"),
		callback = function ()
			self:onButtonBack()
		end
	}
	self.rideButtonInfo = {
		profile = "buttonRide",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText("button_ride"),
		callback = function ()
			self:onButtonRide()
		end
	}
	self.cleanButtonInfo = {
		profile = "buttonClean",
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText("button_clean"),
		callback = function ()
			self:onButtonClean()
		end
	}

	self.messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalDataChanged, self)
end

function InGameMenuAnimalsFrameMobile:setMode(mode)
	self.mode = mode

	self:updateMenuButtons()
	self:updateVisibilityOfBoxes()
end

function InGameMenuAnimalsFrameMobile:updateMenuButtons()
	self.menuButtonInfo = {}

	if self.mode == InGameMenuAnimalsFrameMobile.MODE.LIST then
		table.insert(self.menuButtonInfo, {
			inputAction = InputAction.MENU_BACK
		})

		if self.selectedHusbandry ~= nil then
			table.insert(self.menuButtonInfo, self.selectButtonInfo)
		end
	else
		table.insert(self.menuButtonInfo, self.toListButtonInfo)

		if self.selectedHorse ~= nil and not self.selectedHorse:getIsInUse() then
			table.insert(self.menuButtonInfo, self.rideButtonInfo)
		end
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuAnimalsFrameMobile:updateAnimalData()
	InGameMenuAnimalsFrameMobile:superClass().updateAnimalData(self)
	self:updateNumberOfPages()
end

function InGameMenuAnimalsFrameMobile:onAnimalDataSourceChanged()
	InGameMenuAnimalsFrameMobile:superClass().onAnimalDataSourceChanged(self)
	self:updateVisibilityOfBoxes()
end

function InGameMenuAnimalsFrameMobile:updateVisibilityOfBoxes()
	local hasAnimals = self.animalsDataSource:getCount() > 0

	self.animalsListBox:setVisible(hasAnimals and self.mode == InGameMenuAnimalsFrameMobile.MODE.LIST)
	self.detailsBox:setVisible(hasAnimals and self.mode == InGameMenuAnimalsFrameMobile.MODE.DETAILS)
	self.noHusbandriesBox:setVisible(not hasAnimals)
	self.pagingIndexState:setVisible(self.mode == InGameMenuAnimalsFrameMobile.MODE.LIST)
	self:updateNumberOfPages()
end

function InGameMenuAnimalsFrameMobile:updateNumberOfPages()
	self:setNumberOfPages(math.ceil(self.animalsDataSource:getCount() / InGameMenuAnimalsFrameMobile.MAX_NUM_ANIMALS))
	self:setPagingButtonsDisabled(self.mode ~= InGameMenuAnimalsFrameMobile.MODE.LIST)
end

function InGameMenuAnimalsFrameMobile:displayHorse(animal, horseHusbandry)
	self:resetAttributes()
	self.animalDetailTypeNameText:setText(animal:getName())

	local horseValue = animal:getValue()
	local horseValueText = self.l10n:formatMoney(horseValue, 0, true, true)

	self:addAttribute(self.l10n:getText("ui_sellValue"), horseValueText)

	local riding = MathUtil.clamp(animal:getTodaysRidingTime() / Horse.DAILY_TARGET_RIDING_TIME, 0, 1)

	self:addAttribute(self.l10n:getText("ui_horseDailyRiding"), string.format("%d %%", riding * 100))

	local storeInfo = animal:getSubType().storeInfo

	self.animalDetailTypeImage:setImageFilename(storeInfo.imageFilename)
	self:addAttribute(self.l10n:getText("ui_horseFitness"), string.format("%d %%", animal:getFitnessScale() * 100))
	self:addAttribute(self.l10n:getText("ui_horseHealth"), string.format("%d %%", animal:getHealthScale() * 100))

	local cleanliness = 1 - animal:getDirtScale()

	self:addAttribute(self.l10n:getText("statistic_cleanliness"), string.format("%d %%", cleanliness * 100))
	self:updateHusbandryConditionsDisplay(horseHusbandry)
	self:updateHusbandryFoodDisplay(horseHusbandry)
end

function InGameMenuAnimalsFrameMobile:displayLivestock(animals, livestockHusbandry)
	self:resetAttributes()

	local animal = animals[1]
	local subType = animal:getSubType()
	local storeInfo = animal:getSubType().storeInfo

	self.animalDetailTypeNameText:setText(storeInfo.shopItemName)
	self.animalDetailTypeImage:setImageFilename(storeInfo.imageFilename)

	local productivity = livestockHusbandry:getGlobalProductionFactor()
	local valueText = self.l10n:formatNumber(productivity * 100, 0) .. " %"

	self:addAttribute(self.l10n:getText("statistic_productivity"), valueText)

	local rate = livestockHusbandry:getReproductionTimePerDay(subType.fillType)

	self:addAttribute(self.l10n:getText("statistic_reproductionRate"), self.l10n:formatMinutes(rate))

	local minutesUntilNextAnimal = livestockHusbandry:getMinutesUntilNextAnimal(animal:getFillTypeIndex())

	self:addAttribute(self.l10n:getText("statistic_timeTillNextAnimal"), self.l10n:formatMinutes(minutesUntilNextAnimal))
	self:addAttribute(self.l10n:getText("statistic_numOwned"), #animals)

	self.productionDisplayAttributeIndex = self.nextAnimalAttributeIndex

	self:updateLivestockHusbandryProductionDisplay(livestockHusbandry)
	self:updateHusbandryConditionsDisplay(livestockHusbandry)
	self:updateHusbandryFoodDisplay(livestockHusbandry)
end

function InGameMenuAnimalsFrameMobile:addAttribute(title, text)
	local index = self.nextAnimalAttributeIndex

	self.animalAttributeLabel[index]:setText(title)
	self.animalAttributeText[index]:setText(text)

	self.nextAnimalAttributeIndex = index + 1
end

function InGameMenuAnimalsFrameMobile:resetAttributes(toNum)
	if toNum == nil then
		toNum = 1
	end

	for i = self.nextAnimalAttributeIndex - 1, toNum, -1 do
		self.animalAttributeLabel[i]:setText("")
		self.animalAttributeText[i]:setText("")
	end

	self.nextAnimalAttributeIndex = toNum
end

function InGameMenuAnimalsFrameMobile:updateLivestockHusbandryProductionDisplay(livestockHusbandry)
	local productionInfos = livestockHusbandry:getProductionFilltypeInfo()

	self:resetAttributes(self.productionDisplayAttributeIndex)

	for _, infoGroup in ipairs(productionInfos) do
		local level, _, label = self:sumFillLevelInfos(infoGroup)
		local valueText = self.l10n:formatVolume(level, 0)

		self:addAttribute(label, valueText)
	end
end

function InGameMenuAnimalsFrameMobile:update(dt)
	if self.mode == InGameMenuAnimalsFrameMobile.MODE.DETAILS then
		InGameMenuAnimalsFrameMobile:superClass().update(self, dt)
	end
end

function InGameMenuAnimalsFrameMobile:onListSelectionChanged(selectedIndex)
	self.selectedHorse = nil
	self.selectedAnimals = nil

	if self.animalsDataSource:getCount() > 0 then
		local selectedData = self.animalsDataSource:getItem(selectedIndex)

		if selectedData ~= nil then
			if selectedData.isHorse then
				self.selectedHorse = selectedData.horse
			else
				self.selectedAnimals = selectedData.animals
			end

			self.selectedHusbandry = selectedData.husbandry
		end
	end
end

function InGameMenuAnimalsFrameMobile:onButtonSelect()
	self:setMode(InGameMenuAnimalsFrameMobile.MODE.DETAILS)

	local selectedIndex = self.animalList:getSelectedDataIndex()

	InGameMenuAnimalsFrameMobile:superClass().onListSelectionChanged(self, selectedIndex)
end

function InGameMenuAnimalsFrameMobile:onButtonBack()
	self:setMode(InGameMenuAnimalsFrameMobile.MODE.LIST)
end

function InGameMenuAnimalsFrame:onButtonRide()
	g_currentMission:fadeScreen(1, 1)
	self.selectedHorse:activateRiding(g_currentMission.player)
	g_gui:changeScreen(nil)
end

function InGameMenuAnimalsFrame:onButtonClean()
	self.selectedHorse:setDirtScale(0)
	g_currentMission:addMoney(-300, g_currentMission:getFarmId(), MoneyType.ANIMAL_UPKEEP, true)
	self:updateMenuButtons()
end

function InGameMenuAnimalsFrameMobile:onListDoubleClick()
	self:onButtonSelect()
end

function InGameMenuAnimalsFrameMobile:onPageChanged(page, fromPage)
	InGameMenuAnimalsFrameMobile:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * InGameMenuAnimalsFrameMobile.MAX_NUM_ANIMALS + 1

	self.animalList:scrollTo(firstIndex)
end

function InGameMenuAnimalsFrameMobile:onNextPage()
	if self.mode == InGameMenuAnimalsFrameMobile.MODE.LIST then
		InGameMenuAnimalsFrameMobile:superClass().onNextPage(self)
	end
end

function InGameMenuAnimalsFrameMobile:onPreviousPage()
	if self.mode == InGameMenuAnimalsFrameMobile.MODE.LIST then
		InGameMenuAnimalsFrameMobile:superClass().onPreviousPage(self)
	end
end
