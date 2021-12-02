InGameMenuProductionFrame = {}
local InGameMenuProductionFrame_mt = Class(InGameMenuProductionFrame, TabbedMenuFrameElement)
InGameMenuProductionFrame.UPDATE_INTERVAL = 5000
InGameMenuProductionFrame.STATUS_BAR_LOW = 0.2
InGameMenuProductionFrame.STATUS_BAR_HIGH = 0.8
InGameMenuProductionFrame.CONTROLS = {
	"productionListBox",
	"productionList",
	"storageListBox",
	"storageList",
	"detailsBox",
	"detailProductionStatus",
	"detailCyclesPerHour",
	"detailCostsPerHour",
	"recipeFillIcon",
	"recipeText",
	"recipeArrow",
	"recipePlus",
	"detailRecipeInputLayout",
	"detailRecipeOutputLayout",
	"noPointsBox"
}

function InGameMenuProductionFrame.new(messageCenter, i18n)
	local self = InGameMenuProductionFrame:superClass().new(nil, InGameMenuProductionFrame_mt)
	self.i18n = i18n
	self.messageCenter = messageCenter

	self:registerControls(InGameMenuProductionFrame.CONTROLS)

	self.hasCustomMenuButtons = true
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.menuButtonInfo = {
		self.backButtonInfo
	}
	self.timeSinceLastStateUpdate = 0

	return self
end

function InGameMenuProductionFrame:delete()
	self.recipeFillIcon:delete()
	self.recipeText:delete()
	self.recipePlus:delete()
	InGameMenuProductionFrame:superClass().delete(self)
end

function InGameMenuProductionFrame:copyAttributes(src)
	InGameMenuProductionFrame:superClass().copyAttributes(self, src)

	self.i18n = src.i18n
	self.messageCenter = src.messageCenter
end

function InGameMenuProductionFrame:onGuiSetupFinished()
	InGameMenuProductionFrame:superClass().onGuiSetupFinished(self)
	self.productionList:setDataSource(self)
	self.storageList:setDataSource(self)
end

function InGameMenuProductionFrame:initialize()
	self.buttonChangeSettingInfo = {
		inputAction = InputAction.MENU_ACTIVATE
	}

	self.recipeFillIcon:unlinkElement()
	self.recipeText:unlinkElement()
	self.recipePlus:unlinkElement()

	self.hotspotButtonInfo = {
		profile = "buttonHotspot",
		inputAction = InputAction.MENU_CANCEL,
		text = self.i18n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function ()
			self:onButtonHotspot()
		end
	}
	self.activateButtonInfo = {
		profile = "buttonOk",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.i18n:getText("button_activate"),
		callback = function ()
			self:onButtonActivate()
		end
	}
	self.toggleStorageModeButtonInfo = {
		profile = "buttonOk",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.i18n:getText("ui_production_changeOutputMode"),
		callback = function ()
			self:onButtonToggleOutputMode()
		end
	}
end

function InGameMenuProductionFrame:onFrameOpen()
	InGameMenuProductionFrame:superClass().onFrameOpen(self)

	self.chainManager = g_currentMission.productionChainManager

	self:updateFrameState()
	self.productionList:reloadData()
	FocusManager:setFocus(self.productionList)
end

function InGameMenuProductionFrame:onFrameClose()
	InGameMenuProductionFrame:superClass().onFrameClose(self)

	self.selectedProductionPoint = nil
end

function InGameMenuProductionFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm

	if playerFarm ~= nil then
		self:updateFrameState()
	end
end

function InGameMenuProductionFrame:getProductionPoints()
	return self.chainManager:getProductionPointsForFarmId(self.playerFarm.farmId)
end

function InGameMenuProductionFrame:updateFrameState()
	local hasPoints = self.chainManager and #self:getProductionPoints() > 0

	self.productionListBox:setVisible(hasPoints)
	self.storageListBox:setVisible(hasPoints)
	self.detailsBox:setVisible(hasPoints)
	self.noPointsBox:setVisible(not hasPoints)
end

function InGameMenuProductionFrame:updateDetails()
	local production = self:getSelectedProduction()
	local status = production.status
	local statusKey = ProductionPoint.PROD_STATUS_TO_L10N[production.status] or "unknown"
	local statusProfile = "ingameMenuProductionDetailValue"

	if status == ProductionPoint.PROD_STATUS.MISSING_INPUTS then
		statusProfile = "ingameMenuProductionDetailValueError"
	elseif status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
		statusProfile = "ingameMenuProductionDetailValueError"
	end

	self.detailProductionStatus:applyProfile(statusProfile)
	self.detailProductionStatus:setLocaKey(statusKey)
	self.detailCyclesPerHour:setText(MathUtil.round(production.cyclesPerHour, 2))
	self.detailCostsPerHour:setValue(production.costsPerActiveHour)

	local function addIcons(list, layout)
		for i = 1, #layout.elements do
			layout.elements[1]:delete()
		end

		for index, item in ipairs(list) do
			if index > 1 then
				self.recipePlus:clone(layout)
			end

			if item.amount ~= 1 then
				local count = self.recipeText:clone(layout)

				count:setText(g_i18n:formatNumber(item.amount, 2))
			end

			local fillType = g_fillTypeManager:getFillTypeByIndex(item.type)
			local icon = self.recipeFillIcon:clone(layout)

			icon:setImageFilename(fillType.hudOverlayFilename)
		end

		layout:invalidateLayout()
	end

	addIcons(production.inputs, self.detailRecipeInputLayout)
	addIcons(production.outputs, self.detailRecipeOutputLayout)
	self.storageList:reloadData()
end

function InGameMenuProductionFrame:setSelectedProductionPoint(productionPoint)
	for index, listProdPoint in ipairs(self:getProductionPoints()) do
		if listProdPoint == productionPoint then
			self.productionList:setSelectedItem(index, 1)

			break
		end
	end
end

function InGameMenuProductionFrame:updateMenuButtons()
	self.menuButtonInfo = {
		self.backButtonInfo
	}
	local isProductionListActive = self.productionList == FocusManager:getFocusedElement()

	if isProductionListActive then
		local production, productionPoint = self:getSelectedProduction()
		local state = productionPoint:getIsProductionEnabled(production.id)
		self.activateButtonInfo.text = state and self.i18n:getText("button_deactivate") or self.i18n:getText("button_activate")

		table.insert(self.menuButtonInfo, self.activateButtonInfo)

		local hotspot = productionPoint.owningPlaceable:getHotspot()

		if hotspot ~= nil then
			if hotspot == g_currentMission.currentMapTargetHotspot then
				self.hotspotButtonInfo.text = self.i18n:getText("action_untag")
			else
				self.hotspotButtonInfo.text = self.i18n:getText("action_tag")
			end

			table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
		end
	else
		local fillType, isInput = self:getSelectedStorageFillType()

		if not isInput and fillType ~= FillType.UNKNOWN then
			table.insert(self.menuButtonInfo, self.toggleStorageModeButtonInfo)
		end
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuProductionFrame:getSelectedProduction()
	local productionPoint = self:getProductionPoints()[self.productionList:getSelectedSection()]
	local production = productionPoint.productions[self.productionList:getSelectedIndexInSection()]

	return production, productionPoint
end

function InGameMenuProductionFrame:getSelectedStorageFillType()
	if self.productionList == FocusManager:getFocusedElement() then
		return nil
	end

	local index = self.storageList:getSelectedIndexInSection()

	if index == 0 then
		return nil
	end

	if self.storageList:getSelectedSection() == 1 then
		return self.selectedProductionPoint.inputFillTypeIdsArray[index], true
	else
		return self.selectedProductionPoint.outputFillTypeIdsArray[index], false
	end
end

function InGameMenuProductionFrame:update(dt)
	InGameMenuProductionFrame:superClass().update(self, dt)

	self.timeSinceLastStateUpdate = self.timeSinceLastStateUpdate + dt

	if InGameMenuProductionFrame.UPDATE_INTERVAL <= self.timeSinceLastStateUpdate then
		self.timeSinceLastStateUpdate = 0

		self.productionList:reloadData()
	end
end

function InGameMenuProductionFrame:getNumberOfSections(list, section)
	if list == self.productionList then
		return #self:getProductionPoints()
	else
		return 2
	end
end

function InGameMenuProductionFrame:getTitleForSectionHeader(list, section)
	if list == self.productionList then
		local productionPoint = self:getProductionPoints()[section]

		return productionPoint:getName()
	elseif section == 1 then
		return g_i18n:getText("ui_productions_incomingMaterials")
	else
		return g_i18n:getText("ui_productions_outgoingProducts")
	end
end

function InGameMenuProductionFrame:getNumberOfItemsInSection(list, section)
	if list == self.productionList then
		local productionPoint = self:getProductionPoints()[section]

		return #productionPoint.productions
	elseif self.selectedProductionPoint ~= nil then
		if section == 1 then
			return #self.selectedProductionPoint.inputFillTypeIdsArray
		else
			return #self.selectedProductionPoint.outputFillTypeIdsArray
		end
	end

	return 0
end

function InGameMenuProductionFrame:getCellTypeForItemInSection(list, section, index)
	if list == self.storageList then
		if section == 1 then
			return "inputCell"
		else
			return "outputCell"
		end
	end
end

function InGameMenuProductionFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.productionList then
		local productionPoint = self:getProductionPoints()[section]
		local production = productionPoint.productions[index]
		local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)

		if fillTypeDesc ~= nil then
			cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
		end

		cell:getAttribute("icon"):setVisible(fillTypeDesc ~= nil)
		cell:getAttribute("name"):setText(production.name or fillTypeDesc.title)

		local status = production.status
		local activityElement = cell:getAttribute("activity")

		if status == ProductionPoint.PROD_STATUS.RUNNING then
			activityElement:applyProfile("ingameMenuProductionProductionActivityActive")
		elseif status == ProductionPoint.PROD_STATUS.MISSING_INPUTS or status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
			activityElement:applyProfile("ingameMenuProductionProductionActivityIssue")
		else
			activityElement:applyProfile("ingameMenuProductionProductionActivity")
		end
	else
		local _, productionPoint = self:getSelectedProduction()
		local fillType, isInput = nil

		if section == 1 then
			fillType = self.selectedProductionPoint.inputFillTypeIdsArray[index]
			isInput = true
		else
			fillType = self.selectedProductionPoint.outputFillTypeIdsArray[index]
			isInput = false
		end

		if fillType ~= FillType.UNKNOWN then
			local fillLevel = self.selectedProductionPoint.storage:getFillLevel(fillType)
			local capacity = self.selectedProductionPoint.storage:getCapacity(fillType)
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)

			cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
			cell:getAttribute("fillType"):setText(fillTypeDesc.title)
			cell:getAttribute("fillLevel"):setText(self.i18n:formatVolume(fillLevel, 0))

			if not isInput then
				local outputMode = productionPoint:getOutputDistributionMode(fillType)
				local outputModeText = self.i18n:getText("ui_production_output_storing")

				if outputMode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
					outputModeText = self.i18n:getText("ui_production_output_selling")
				elseif outputMode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
					outputModeText = self.i18n:getText("ui_production_output_distributing")
				end

				cell:getAttribute("outputMode"):setText(outputModeText)
			end

			self:setStatusBarValue(cell:getAttribute("bar"), fillLevel / capacity, isInput)
		end
	end
end

function InGameMenuProductionFrame:setStatusBarValue(statusBarElement, value, lowIsDanger)
	local profile = "ingameMenuProductionStorageBar"

	if lowIsDanger and value < InGameMenuProductionFrame.STATUS_BAR_LOW or not lowIsDanger and InGameMenuProductionFrame.STATUS_BAR_HIGH < value then
		profile = "ingameMenuProductionStorageBarDanger"
	end

	statusBarElement:applyProfile(profile)

	local fullWidth = statusBarElement.parent.absSize[1] - statusBarElement.margin[1] * 2
	local minSize = 0

	if statusBarElement.startSize ~= nil then
		minSize = statusBarElement.startSize[1] + statusBarElement.endSize[1]
	end

	statusBarElement:setSize(math.max(minSize, fullWidth * math.min(1, value)), nil)
end

function InGameMenuProductionFrame:onListSelectionChanged(list, section, index)
	if list == self.productionList then
		self.selectedProductionPoint = self:getProductionPoints()[section]

		if self.selectedProductionPoint == nil then
			return
		end

		self.selectedProduction = self.selectedProductionPoint.productions[index]
		self.selectedStorage = nil

		self:updateDetails()
	else
		self.selectedStorage = self.selectedProductionPoint.storage.sortedFillTypes[index]
	end

	self:updateMenuButtons()
end

function InGameMenuProductionFrame:onButtonActivate()
	local production, productionPoint = self:getSelectedProduction()

	if production ~= nil then
		local state = productionPoint:getIsProductionEnabled(production.id)

		productionPoint:setProductionState(production.id, not state)
		self.productionList:reloadData()
	end
end

function InGameMenuProductionFrame:onButtonToggleOutputMode()
	local _, productionPoint = self:getSelectedProduction()
	local fillType = self:getSelectedStorageFillType()

	if fillType ~= FillType.UNKNOWN then
		productionPoint:toggleOutputDistributionMode(fillType)
		self.storageList:reloadData()
	end
end

function InGameMenuProductionFrame:onButtonHotspot()
	local _, productionPoint = self:getSelectedProduction()

	if productionPoint ~= nil then
		local hotspot = productionPoint.owningPlaceable:getHotspot()

		if hotspot ~= nil then
			if g_currentMission.currentMapTargetHotspot == hotspot then
				g_currentMission:setMapTargetHotspot(nil)
			else
				g_currentMission:setMapTargetHotspot(hotspot)
			end

			self:updateMenuButtons()
		else
			g_currentMission:setMapTargetHotspot(nil)
		end
	end
end
