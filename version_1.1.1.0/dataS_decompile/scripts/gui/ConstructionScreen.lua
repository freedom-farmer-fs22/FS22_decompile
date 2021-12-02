ConstructionScreen = {
	CONTROLS = {
		"itemList",
		"listBox",
		"menuBox",
		"menuBackgroundLarge",
		"menuBackgroundSmall",
		"categoriesBox",
		"tabsBox",
		"categoryButtonTemplate",
		"tabButtonTemplate",
		"buttonDestruct",
		"detailsTitle",
		"detailsDescription",
		"detailsAttributesLayout",
		"attrIcon",
		"attrValue",
		"attrIconsLayout",
		"detailsInfoIcon",
		"detailsInfo",
		"fruitIconTemplate"
	},
	INPUT_CONTEXT = "CONSTRUCTION_MENU"
}
local ConstructionScreen_mt = Class(ConstructionScreen, ScreenElement)

function ConstructionScreen.new(target, customMt, l10n, messageCenter, inputManager)
	local self = ConstructionScreen:superClass().new(target, customMt or ConstructionScreen_mt)

	self:registerControls(ConstructionScreen.CONTROLS)

	self.inputManager = inputManager
	self.l10n = l10n
	self.messageCenter = messageCenter
	self.isMouseMode = true
	self.camera = GuiTopDownCamera.new(nil, messageCenter, inputManager)
	self.cursor = GuiTopDownCursor.new(nil, messageCenter, inputManager)
	self.brush = nil
	self.items = {}
	self.clonedElements = {}
	self.menuEvents = {}
	self.brushEvents = {}

	return self
end

function ConstructionScreen:delete()
	self.camera:delete()
	self.cursor:delete()

	if self.selectorBrush ~= nil then
		self.selectorBrush:delete()
	end

	if self.destructBrush ~= nil then
		self.destructBrush:delete()
	end

	self.categoryButtonTemplate:delete()
	self.tabButtonTemplate:delete()
	ConstructionScreen:superClass().delete(self)
end

function ConstructionScreen:onOpen()
	ConstructionScreen:superClass().onOpen(self)
	self.inputManager:setContext(ConstructionScreen.INPUT_CONTEXT)
	self.camera:setTerrainRootNode(g_currentMission.terrainRootNode)
	self.camera:setControlledPlayer(g_currentMission.player)
	self.camera:setControlledVehicle(g_currentMission.controlledVehicle)
	self.camera:activate()
	self.cursor:activate()
	g_currentMission.hud.ingameMap:setTopDownCamera(self.camera)

	if self.selectorBrush == nil then
		local class = g_constructionBrushTypeManager:getClassObjectByTypeName("select")
		self.selectorBrush = class.new(nil, self.cursor)
	end

	self:setBrush(self.selectorBrush, true)

	if self.destructBrush == nil then
		local class = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct")
		self.destructBrush = class.new(nil, self.cursor)
	end

	self.destructMode = false
	self.isMouseMode = self.inputManager.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD

	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
	g_depthOfFieldManager:pushArea(self.menuBox.absPosition[1], self.menuBox.absPosition[2], self.menuBox.absSize[1], self.menuBox.absSize[2])
	self:rebuildData()
	self:resetMenuState()
	self:updateMenuState()
end

function ConstructionScreen:onClose(element)
	self.messageCenter:unsubscribeAll(self)
	self:setBrush(nil)
	self.cursor:deactivate()
	self.camera:deactivate()
	g_currentMission.hud.ingameMap:setTopDownCamera(nil)
	g_depthOfFieldManager:popArea()
	self:removeMenuActionEvents()
	self.inputManager:revertContext()
	ConstructionScreen:superClass().onClose(self)
end

function ConstructionScreen:onGuiSetupFinished()
	ConstructionScreen:superClass().onGuiSetupFinished(self)
	self.categoryButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.categoryButtonTemplate)
	self.tabButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.tabButtonTemplate)
end

function ConstructionScreen:update(dt)
	ConstructionScreen:superClass().update(self, dt)
	self.camera:setCursorLocked(self.cursor.isCatchingCursor)
	self.camera:update(dt)

	if not self.isMouseMode or not self.isMouseInMenu then
		self.cursor:setCameraRay(self.camera:getPickRay())
	else
		self.cursor:setCameraRay(nil)
	end

	self.cursor:update(dt)
	self.brush:update(dt)

	if self.brush.inputTextDirty then
		self:updateBrushActionTexts()

		self.brush.inputTextDirty = false
	end

	g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
end

function ConstructionScreen:setBrush(brush, skipMenuUpdate)
	if brush == self.brush then
		return
	end

	local previousBrush = self.brush

	if self.brush ~= nil then
		self.brush:deactivate()
	end

	self:removeMenuActionEvents()
	self:removeBrushActionEvents()
	self.camera:removeActionEvents()
	self.cursor:removeActionEvents()

	self.brush = brush

	self.camera:registerActionEvents()
	self.cursor:registerActionEvents()

	if self.brush == nil or self.brush == self.selectorBrush then
		self:registerMenuActionEvents(true)
	elseif self.brush ~= nil then
		self:registerMenuActionEvents(false)
	end

	if brush ~= nil then
		self.brush:activate()

		if previousBrush ~= nil and self.brush:class() == previousBrush:class() then
			self.brush:copyState(previousBrush)
		end

		self:registerBrushActionEvents()
	end

	if not skipMenuUpdate then
		self:updateMenuState(previousBrush)
	end

	self:updateBrushActionTexts()
	self:updateMenuActionTexts()
	self.camera:setMovementDisabledForGamepad(self.brush == nil)
end

function ConstructionScreen:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.menuBox.absPosition[1], self.menuBox.absPosition[2], self.menuBox.absSize[1], self.menuBox.absSize[2])

	if not self.isMouseInMenu then
		self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.categoriesBox.absPosition[1], self.categoriesBox.absPosition[2], self.categoriesBox.absSize[1], self.categoriesBox.absSize[2])
	end

	if not self.isMouseInMenu then
		self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.buttonDestruct.absPosition[1], self.buttonDestruct.absPosition[2], self.buttonDestruct.absSize[1], self.buttonDestruct.absSize[2])
	end

	self.camera.mouseDisabled = self.isMouseInMenu
	self.cursor.mouseDisabled = self.isMouseInMenu

	self.camera:mouseEvent(posX, posY, isDown, isUp, button)
	self.cursor:mouseEvent(posX, posY, isDown, isUp, button)
end

function ConstructionScreen:draw()
	ConstructionScreen:superClass().draw(self)
	g_currentMission.hud:drawBaseHUD()
	g_currentMission.hud:drawInputHelp()
	self.cursor:draw()
end

function ConstructionScreen:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD

	self:updateMenuState()
	self:updateMenuActionTexts()
end

function ConstructionScreen:registerMenuActionEvents(hasMenuButtons)
	self.menuEvents = {}
	local _, eventId = nil
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onButtonMenuAccept, false, true, false, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.acceptButtonEvent = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)

	self.backButtonEvent = eventId

	table.insert(self.menuEvents, eventId)

	_, eventId = self.inputManager:registerActionEvent(InputAction.PAUSE, g_currentMission, g_currentMission.onPause, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, g_currentMission, g_currentMission.onToggleHelpText, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	if hasMenuButtons then
		_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onMenuUpDown, false, true, true, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, true, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onReleaseUpDown, true, false, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onReleaseLeftRight, true, false, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(self.menuEvents, eventId)
	end

	self:updateMenuActionTexts()
end

function ConstructionScreen:onMenuUpDown(_, inputValue)
	g_gui:onMenuInput(InputAction.MENU_AXIS_UP_DOWN, inputValue)
end

function ConstructionScreen:onMenuLeftRight(_, inputValue)
	g_gui:onMenuInput(InputAction.MENU_AXIS_LEFT_RIGHT, inputValue)
end

function ConstructionScreen:onReleaseUpDown(action)
	g_gui:onReleaseMovement(InputAction.MENU_AXIS_UP_DOWN)
end

function ConstructionScreen:onReleaseLeftRight(action)
	g_gui:onReleaseMovement(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function ConstructionScreen:updateMenuActionTexts()
	self.inputManager:setActionEventTextVisibility(self.backButtonEvent, true)

	if self.brush == self.selectorBrush then
		self.inputManager:setActionEventText(self.backButtonEvent, self.l10n:getText("input_CONSTRUCTION_EXIT"))
	else
		self.inputManager:setActionEventText(self.backButtonEvent, self.l10n:getText("input_CONSTRUCTION_CANCEL"))
	end
end

function ConstructionScreen:removeMenuActionEvents()
	for _, event in ipairs(self.menuEvents) do
		self.inputManager:removeActionEvent(event)
	end
end

function ConstructionScreen:onButtonMenuAccept()
	if self.isMouseMode or self.brush == self.selectorBrush then
		g_gui:notifyControls("MENU_ACCEPT")
	else
		self:onButtonPrimary()
	end
end

function ConstructionScreen:onButtonMenuBack()
	if self.brush:canCancel() then
		self.brush:cancel()
	elseif self.brush == self.destructBrush then
		self.destructMode = false

		self:setBrush(self.previousBrush)
	elseif not self.brush.isSelector then
		self:setBrush(self.selectorBrush)
	else
		self:changeScreen(nil)
	end
end

function ConstructionScreen:registerBrushActionEvents()
	local _, eventId = nil
	local brush = self.brush

	if brush == nil then
		return
	end

	self.brushEvents = {}

	if brush.supportsPrimaryButton then
		if brush.supportsPrimaryDragging then
			_, eventId = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimaryDrag, true, true, true, true)

			table.insert(self.brushEvents, eventId)

			self.primaryBrushEvent = eventId
		else
			_, eventId = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)

			table.insert(self.brushEvents, eventId)

			self.primaryBrushEvent = eventId
		end

		self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
	end

	if brush.supportsSecondaryButton then
		if brush.supportsSecondaryDragging then
			_, eventId = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondaryDrag, true, true, true, true)

			table.insert(self.brushEvents, eventId)

			self.secondaryBrushEvent = eventId
		else
			_, eventId = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)

			table.insert(self.brushEvents, eventId)

			self.secondaryBrushEvent = eventId
		end

		self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
	end

	if brush.supportsTertiaryButton then
		_, self.tertiaryBrushEvent = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_TERTIARY, self, self.onButtonTertiary, false, true, false, true)

		self.inputManager:setActionEventTextPriority(self.tertiaryBrushEvent, GS_PRIO_HIGH)
		table.insert(self.brushEvents, self.tertiaryBrushEvent)
	end

	if brush.supportsFourthButton then
		_, self.fourthBrushEvent = self.inputManager:registerActionEvent(InputAction.CONSTRUCTION_ACTION_FOURTH, self, self.onButtonFourth, false, true, false, true)

		self.inputManager:setActionEventTextPriority(self.fourthBrushEvent, GS_PRIO_HIGH)
		table.insert(self.brushEvents, self.fourthBrushEvent)
	end

	if brush.supportsPrimaryAxis then
		_, self.primaryBrushAxisEvent = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY, self, self.onAxisPrimary, false, not brush.primaryAxisIsContinuous, brush.primaryAxisIsContinuous, true)

		self.inputManager:setActionEventTextPriority(self.primaryBrushAxisEvent, GS_PRIO_HIGH)
		table.insert(self.brushEvents, self.primaryBrushAxisEvent)
	end

	if brush.supportsSecondaryAxis then
		_, self.secondaryBrushAxisEvent = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY, self, self.onAxisSecondary, false, not brush.secondaryAxisIsContinuous, brush.secondaryAxisIsContinuous, true)

		self.inputManager:setActionEventTextPriority(self.secondaryBrushAxisEvent, GS_PRIO_HIGH)
		table.insert(self.brushEvents, self.secondaryBrushAxisEvent)
	end
end

function ConstructionScreen:updateBrushActionTexts()
	if self.primaryBrushEvent ~= nil then
		self.inputManager:setActionEventText(self.primaryBrushEvent, self.l10n:convertText(self.brush:getButtonPrimaryText()))
	end

	if self.secondaryBrushEvent ~= nil then
		local text = self.brush:getButtonSecondaryText()

		if text ~= nil then
			self.inputManager:setActionEventText(self.secondaryBrushEvent, self.l10n:convertText(text))
		end

		self.inputManager:setActionEventTextVisibility(self.secondaryBrushEvent, text ~= nil)
	end

	if self.tertiaryBrushEvent ~= nil then
		local text = self.brush:getButtonTertiaryText()

		if text ~= nil then
			self.inputManager:setActionEventText(self.tertiaryBrushEvent, self.l10n:convertText(text))
		end

		self.inputManager:setActionEventTextVisibility(self.tertiaryBrushEvent, text ~= nil)
	end

	if self.fourthBrushEvent ~= nil then
		local text = self.brush:getButtonFourthText()

		if text ~= nil then
			self.inputManager:setActionEventText(self.fourthBrushEvent, self.l10n:convertText(text))
		end

		self.inputManager:setActionEventTextVisibility(self.fourthBrushEvent, text ~= nil)
	end

	if self.primaryBrushAxisEvent ~= nil then
		local text = self.brush:getAxisPrimaryText()

		if text ~= nil then
			self.inputManager:setActionEventText(self.primaryBrushAxisEvent, self.l10n:convertText(text))
		end

		self.inputManager:setActionEventTextVisibility(self.primaryBrushAxisEvent, text ~= nil)
	end

	if self.secondaryBrushAxisEvent ~= nil then
		local text = self.brush:getAxisSecondaryText()

		if text ~= nil then
			self.inputManager:setActionEventText(self.secondaryBrushAxisEvent, self.l10n:convertText(text))
		end

		self.inputManager:setActionEventTextVisibility(self.secondaryBrushAxisEvent, text ~= nil)
	end
end

function ConstructionScreen:removeBrushActionEvents()
	for _, event in ipairs(self.brushEvents) do
		self.inputManager:removeActionEvent(event)
	end

	self.primaryBrushEvent = nil
	self.secondaryBrushEvent = nil
	self.tertiaryBrushEvent = nil
	self.fourthBrushEvent = nil
	self.primaryBrushAxisEvent = nil
	self.secondaryBrushAxisEvent = nil
end

function ConstructionScreen:onButtonPrimary(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		self.brush:onButtonPrimary()
	end
end

function ConstructionScreen:onButtonPrimaryDrag(a, inputValue, b, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local isDown = inputValue == 1 and self.previousPrimaryDragValue ~= 1
		local isDrag = inputValue == 1 and self.previousPrimaryDragValue == 1
		local isUp = inputValue == 0
		self.previousPrimaryDragValue = inputValue

		self.brush:onButtonPrimary(isDown, isDrag, isUp)
	end
end

function ConstructionScreen:onButtonSecondary(_, inputValue, _, isAnalog, isMouse)
	if not self.isMouseInMenu then
		self.brush:onButtonSecondary()
	end
end

function ConstructionScreen:onButtonSecondaryDrag(a, inputValue, b, isAnalog, isMouse)
	if not self.isMouseInMenu then
		local isDown = inputValue == 1 and self.previousSecondaryDragValue ~= 1
		local isDrag = inputValue == 1 and self.previousSecondaryDragValue == 1
		local isUp = inputValue == 0
		self.previousSecondaryDragValue = inputValue

		self.brush:onButtonSecondary(isDown, isDrag, isUp)
	end
end

function ConstructionScreen:onButtonTertiary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onButtonTertiary()
end

function ConstructionScreen:onButtonFourth(_, inputValue, _, isAnalog, isMouse)
	self.brush:onButtonFourth()
end

function ConstructionScreen:onAxisPrimary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onAxisPrimary(inputValue)
end

function ConstructionScreen:onAxisSecondary(_, inputValue, _, isAnalog, isMouse)
	self.brush:onAxisSecondary(inputValue)
end

function ConstructionScreen:onClickDestruct()
	if self.destructMode then
		self.destructMode = false

		self:setBrush(self.previousBrush)
	else
		self.destructMode = true
		self.previousBrush = self.brush

		self:setBrush(self.destructBrush)
	end
end

function ConstructionScreen:getNumberOfItemsInSection(list, section)
	if self.currentCategory == nil or self.currentTab == nil then
		return 0
	end

	return #self.items[self.currentCategory][self.currentTab]
end

function ConstructionScreen:populateCellForItemInSection(list, section, index, cell)
	local item = self.items[self.currentCategory][self.currentTab][index]

	cell:getAttribute("price"):setValue(item.price)

	if item.brandFilename ~= nil then
		cell:getAttribute("brand"):setImageFilename(item.brandFilename)
		cell:getAttribute("brand"):setVisible(true)
	else
		cell:getAttribute("brand"):setVisible(false)
	end

	cell:getAttribute("icon"):setVisible(false)
	cell:getAttribute("terrainLayer"):setVisible(false)

	if item.imageFilename ~= nil then
		cell:getAttribute("icon"):applyProfile(item.brandFilename == nil and "constructionListItemIconNoBrand" or "constructionListItemIcon")
		cell:getAttribute("icon"):setImageFilename(item.imageFilename)
		cell:getAttribute("icon"):setVisible(true)
	elseif item.terrainOverlayLayer ~= nil then
		cell:getAttribute("terrainLayer"):setTerrainLayer(g_currentMission.terrainRootNode, item.terrainOverlayLayer)
		cell:getAttribute("terrainLayer"):setVisible(true)
	end

	cell:getAttribute("bg"):applyProfile(self.brush ~= nil and item.uniqueIndex == self.brush.uniqueIndex and "constructionListItemBgActive" or "constructionListItemBg")
end

function ConstructionScreen:onListSelectionChanged(list, section, index)
	local selectedBrush = self.items[self.currentCategory][self.currentTab][index]

	self.detailsTitle:setText(selectedBrush.name)

	if selectedBrush.storeItem ~= nil then
		local descriptionText = ""

		for _, func in pairs(selectedBrush.storeItem.functions) do
			descriptionText = descriptionText .. func .. " "
		end

		self.detailsDescription:setText(descriptionText)
		self.detailsDescription:setVisible(true)
		self.detailsInfoIcon:setVisible(true)
	else
		self.detailsDescription:setVisible(false)
		self.detailsInfoIcon:setVisible(false)
	end

	self:setDetailAttributes(selectedBrush.storeItem, selectedBrush.displayItem)
end

function ConstructionScreen:onClickItem()
	local item = self.items[self.currentCategory][self.currentTab][self.itemList.selectedIndex]
	local brush = item.brushClass.new(nil, self.cursor)

	if item.brushParameters ~= nil then
		brush:setStoreItem(item.storeItem)
		brush:setParameters(unpack(item.brushParameters))

		brush.uniqueIndex = item.uniqueIndex
	end

	self.destructMode = false

	self:setBrush(brush)
	self.itemList:reloadData()
end

function ConstructionScreen:assignItemFillTypesData(baseIconProfile, iconFilenames, attributeIndex)
	local parentBox = self.attrIconsLayout[attributeIndex]

	if attributeIndex > #self.attrValue or #iconFilenames == 0 then
		parentBox:setVisible(false)

		return attributeIndex
	end

	local totalWidth = 0.02
	local maxWidth = self.detailsAttributesLayout.absSize[1]

	self.attrIcon[attributeIndex]:applyProfile(baseIconProfile)
	self.attrIcon[attributeIndex]:setVisible(true)
	parentBox:setVisible(true)
	self.attrValue[attributeIndex]:setVisible(false)

	for i = 1, #iconFilenames do
		local icon = self.fruitIconTemplate:clone(parentBox)

		icon:setVisible(true)
		table.insert(self.clonedElements, icon)

		totalWidth = totalWidth + icon.absSize[1] + icon.margin[1] + icon.margin[3]

		if maxWidth <= totalWidth then
			icon:applyProfile("constructionListAttributeIconPlus")
			icon:setImageFilename(g_baseUIFilename)

			break
		else
			icon:applyProfile("constructionListAttributeFruitIcon")
			icon:setImageFilename(iconFilenames[i])
		end
	end

	parentBox:setSize(totalWidth, nil)
	parentBox:invalidateLayout()

	return attributeIndex + 1
end

function ConstructionScreen:assignItemTextData(storeItem, displayItem)
	local numAttributesUsed = 0

	for i = 1, #self.attrValue do
		local attributeVisible = false

		if displayItem ~= nil and i <= #displayItem.attributeValues then
			local value = displayItem.attributeValues[i]
			local profile = displayItem.attributeIconProfiles[i]

			if profile ~= nil and profile ~= "" then
				self.attrValue[i]:setText(value)
				self.attrValue[i]:updateAbsolutePosition()

				if profile:startsWith("shopListAttributeIcon") then
					profile = "constructionListAttributeIcon" .. profile:sub(22)
				end

				self.attrIcon[i]:applyProfile(profile)

				attributeVisible = value ~= nil and value ~= ""
			end
		end

		self.attrValue[i]:setVisible(attributeVisible)
		self.attrIcon[i]:setVisible(attributeVisible)
		self.attrIconsLayout[i]:setVisible(false)

		if attributeVisible then
			numAttributesUsed = numAttributesUsed + 1
		end
	end

	return numAttributesUsed
end

function ConstructionScreen:setDetailAttributes(storeItem, displayItem)
	for k, clone in pairs(self.clonedElements) do
		clone:delete()

		self.clonedElements[k] = nil
	end

	local numAttributesUsed = self:assignItemTextData(storeItem, displayItem)

	if displayItem ~= nil then
		local nextAttributeIndex = self:assignItemFillTypesData("constructionListAttributeIconFillTypes", displayItem.fillTypeIconFilenames, numAttributesUsed + 1)
		nextAttributeIndex = self:assignItemFillTypesData("constructionListAttributeIconFillTypes", displayItem.foodFillTypeIconFilenames, nextAttributeIndex)
		nextAttributeIndex = self:assignItemFillTypesData("constructionListAttributeIconInput", displayItem.prodPointInputFillTypeIconFilenames, nextAttributeIndex)
		nextAttributeIndex = self:assignItemFillTypesData("constructionListAttributeIconOutput", displayItem.prodPointOutputFillTypeIconFilenames, nextAttributeIndex)

		self:assignItemFillTypesData("constructionListAttributeIconInput", displayItem.sellingStationFillTypesIconFilenames, nextAttributeIndex)
	end

	self.detailsAttributesLayout:invalidateLayout()
end

function ConstructionScreen:rebuildData()
	self.categories = g_storeManager:getConstructionCategories()
	self.items = {}
	local numItems = 0
	local maxTabs = 0

	for c, category in ipairs(self.categories) do
		self.items[c] = {}

		for t = 1, #category.tabs do
			self.items[c][t] = {}
		end

		maxTabs = math.max(maxTabs, #category.tabs)
	end

	for _, storeItem in ipairs(g_storeManager:getItems()) do
		if storeItem.brush ~= nil then
			local brushClass = g_constructionBrushTypeManager:getClassObjectByTypeName(storeItem.brush.type)
			local parameters = storeItem.brush.parameters

			if parameters == nil or #parameters == 0 then
				parameters = {
					storeItem.xmlFilename
				}
			end

			if brushClass ~= nil then
				local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
				local brandImage = nil

				if brand ~= nil and brand.name ~= "NONE" then
					brandImage = brand.image
				end

				table.insert(self.items[storeItem.brush.category.index][storeItem.brush.tab.index], {
					name = storeItem.name,
					brushClass = brushClass,
					brushParameters = parameters,
					price = storeItem.price,
					imageFilename = storeItem.imageFilename,
					brandFilename = brandImage,
					storeItem = storeItem,
					displayItem = g_currentMission.shopMenu.shopController:makeDisplayItem(storeItem),
					uniqueIndex = numItems + 1
				})

				numItems = numItems + 1
			end
		end
	end

	numItems = self:buildTerrainPaintBrushes(numItems)
	numItems = self:buildTerrainSculptBrushes(numItems)

	for i = #self.categoriesBox.elements, 1, -1 do
		self.categoriesBox.elements[i]:delete()
	end

	for c, category in ipairs(self.categories) do
		local button = self.categoryButtonTemplate:clone(self.categoriesBox)

		FocusManager:loadElementFromCustomValues(button)
		button:setText(category.title)

		function button.onClickCallback()
			self:setSelectedCategory(c)
		end
	end

	self.categoriesBox:invalidateLayout()
	FocusManager:linkElements(self.categoriesBox.elements[1], FocusManager.LEFT, nil)

	for i = #self.tabsBox.elements, 1, -1 do
		self.tabsBox.elements[i]:delete()
	end

	for t = 1, maxTabs do
		local button = self.tabButtonTemplate:clone(self.tabsBox)

		FocusManager:loadElementFromCustomValues(button)

		function button.onClickCallback()
			self:setSelectedTab(t)
		end
	end

	self.tabsBox:invalidateLayout()
	FocusManager:setFocus(self.categoriesBox.elements[1])
end

function ConstructionScreen:buildTerrainPaintBrushes(numItems)
	local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
	local paintingIndex = g_storeManager:getConstructionTabByName("painting", "landscaping").index
	local paintsTab = self.items[landscapingIndex][paintingIndex]
	local groundTypes = {}

	for typeName, layerName in pairs(g_groundTypeManager.groundTypeMappings) do
		table.insert(groundTypes, typeName)
	end

	table.sort(groundTypes)

	local knownLayers = {}

	for _, typeName in ipairs(groundTypes) do
		local layer = g_groundTypeManager:getTerrainLayerByType(typeName)
		local title = g_groundTypeManager:getTerrainTitleByType(typeName)

		if not knownLayers[layer] then
			table.insert(paintsTab, {
				price = 2,
				name = g_i18n:convertText(title),
				brushClass = ConstructionBrushPaint,
				brushParameters = {
					typeName
				},
				terrainOverlayLayer = layer,
				uniqueIndex = numItems + 1
			})

			numItems = numItems + 1
			knownLayers[layer] = true
		end
	end

	return numItems
end

function ConstructionScreen:buildTerrainSculptBrushes(numItems)
	local landscapingIndex = g_storeManager:getConstructionCategoryByName("landscaping").index
	local sculptingIndex = g_storeManager:getConstructionTabByName("sculpting", "landscaping").index
	local sculptTab = self.items[landscapingIndex][sculptingIndex]

	table.insert(sculptTab, {
		price = 10,
		imageFilename = "dataS/menu/construction/icon_shift.png",
		name = g_i18n:getText("construction_item_shift"),
		brushClass = ConstructionBrushSculpt,
		brushParameters = {
			ConstructionBrushSculpt.MODE.SHIFT
		},
		uniqueIndex = numItems + 1
	})
	table.insert(sculptTab, {
		price = 10,
		imageFilename = "dataS/menu/construction/icon_level.png",
		name = g_i18n:getText("construction_item_level"),
		brushClass = ConstructionBrushSculpt,
		brushParameters = {
			ConstructionBrushSculpt.MODE.LEVEL
		},
		uniqueIndex = numItems + 2
	})
	table.insert(sculptTab, {
		price = 10,
		imageFilename = "dataS/menu/construction/icon_soften.png",
		name = g_i18n:getText("construction_item_soften"),
		brushClass = ConstructionBrushSculpt,
		brushParameters = {
			ConstructionBrushSculpt.MODE.SOFTEN
		},
		uniqueIndex = numItems + 3
	})
	table.insert(sculptTab, {
		price = 10,
		imageFilename = "dataS/menu/construction/icon_slope.png",
		name = g_i18n:getText("construction_item_slope"),
		brushClass = ConstructionBrushSculpt,
		brushParameters = {
			ConstructionBrushSculpt.MODE.SLOPE
		},
		uniqueIndex = numItems + 4
	})

	return numItems + 4
end

function ConstructionScreen:setSelectedCategory(index)
	if self.currentCategory == index then
		return
	end

	self.currentCategory = index
	self.currentTab = 1

	self:setBrush(self.selectorBrush, true)
	self:updateMenuState()
end

function ConstructionScreen:setSelectedTab(index)
	if index == nil then
		index = 1
	end

	self.currentTab = index

	self:setBrush(self.selectorBrush, true)
	self:updateMenuState()
end

function ConstructionScreen:resetMenuState()
	self.currentCategory = 1
	self.currentTab = 1

	self:updateMenuState()
end

function ConstructionScreen:updateMenuState(brushChangedFrom)
	if self.currentCategory == nil then
		if self.listBox.visible then
			if self.previousCategory ~= nil then
				FocusManager:setFocus(self.categoriesBox.elements[self.previousCategory])
			else
				FocusManager:setFocus(self.categoriesBox)
			end
		end
	elseif not self.listBox.visible then
		FocusManager:setFocus(self.itemList)
	end

	self.itemList:reloadData()

	for c, button in ipairs(self.categoriesBox.elements) do
		if c == self.currentCategory then
			button:applyProfile("constructionCategoryButtonSelected")
		else
			button:applyProfile("constructionCategoryButton")
		end

		local category = self.categories[c]

		button:setImageFilename(nil, category.iconFilename)
		button:setImageUVs(nil, category.iconUVs)
	end

	self.buttonDestruct:applyProfile(self.destructMode and "constructionCategoryButtonDestructSelected" or "constructionCategoryButtonDestruct")

	local numTabsForCategory = 0

	if self.currentCategory ~= nil then
		numTabsForCategory = #self.items[self.currentCategory]
	end

	for t, button in ipairs(self.tabsBox.elements) do
		button:setVisible(t <= numTabsForCategory)

		if t <= numTabsForCategory then
			if t == self.currentTab then
				button:applyProfile("constructionTabButtonSelected")
			else
				button:applyProfile("constructionTabButton")
			end

			local tab = self.categories[self.currentCategory].tabs[t]

			button:setText(tab.title)
			button:setImageFilename(nil, tab.iconFilename)
			button:setImageUVs(nil, tab.iconUVs)
		end
	end

	self:updateMenuActionTexts()
end
