ModSelectionScreen = {
	CONTROLS = {
		"buttonToggleCrossplay",
		START_BUTTON = "buttonStart",
		SELECT_BUTTON = "buttonSelect",
		MOD_LIST = "modList",
		SELECT_ALL_BUTTON = "buttonSelectAll",
		NO_MODS_DLCS_ELEMENT = "noModsDLCsElement"
	}
}
local ModSelectionScreen_mt = Class(ModSelectionScreen, ScreenElement)

function ModSelectionScreen.new(target, customMt, startMissionInfo, l10n)
	local self = ScreenElement.new(target, customMt or ModSelectionScreen_mt)

	self:registerControls(ModSelectionScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.l10n = l10n
	self.availableMods = {}
	self.selectedMods = {}
	self.uniqueTypesInUse = {}
	self.numAddedModsBesidesMap = 0
	self.crossplayOnly = Platform.isConsole

	return self
end

function ModSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end

function ModSelectionScreen:onOpen()
	ModSelectionScreen:superClass().onOpen(self)

	self.mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)

	self:loadAvailableMods()
	self.modList:reloadData()
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
	self.buttonToggleCrossplay:setVisible(not Platform.isConsole and self.missionDynamicInfo.isMultiplayer)
	self.buttonToggleCrossplay.parent:invalidateLayout()

	if self.mapModName ~= nil then
		self:setItemState(g_modManager:getModByName(self.mapModName), true)
	end

	local defaultModSetting = true

	if GS_PLATFORM_PLAYSTATION and getModUseAvailability(false) ~= MultiplayerAvailability.AVAILABLE then
		defaultModSetting = false
	end

	if Platform.isMobile then
		defaultModSetting = false
	end

	if self.missionInfo.isValid then
		for _, modInfo in pairs(self.missionInfo.mods) do
			if modInfo.modName ~= self.mapModName then
				local modItem = g_modManager:getModByName(modInfo.modName)

				if modItem ~= nil and self:shouldShowModInList(modItem) then
					self:setItemState(modItem, modItem.isDLC or defaultModSetting)
				end
			end
		end
	else
		for _, mod in ipairs(self.availableMods) do
			self:setItemState(mod, mod.isDLC or defaultModSetting)
		end
	end

	if self.missionDynamicInfo.isMultiplayer then
		self.buttonStart:setText(self.l10n:getText("button_continue"))
	else
		self.buttonStart:setText(self.l10n:getText("button_start"))
	end

	if Platform.isMobile then
		self:onClickOk()
	end
end

function ModSelectionScreen:toggleAllAction()
	if #self.availableMods > 0 then
		if self.numAddedModsBesidesMap > 0 then
			for _, mod in pairs(self.selectedMods) do
				self:setItemState(mod, false)
			end
		else
			local numDlc = 0
			local numMod = 0

			for _, modItem in pairs(self.availableMods) do
				if modItem.isDLC then
					numDlc = numDlc + 1
				else
					numMod = numMod + 1
				end
			end

			if numMod > 0 and numDlc == 0 and not PlatformPrivilegeUtil.checkModUse(self.performSelectAll, self) then
				return
			end

			self:performSelectAll()
		end
	end
end

function ModSelectionScreen:performSelectAll()
	local modSetting = getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE

	for _, mod in ipairs(self.availableMods) do
		self:setItemState(mod, mod.isDLC or modSetting)
	end
end

function ModSelectionScreen:selectCurrentMod()
	local mod = self:getSelectedMod()

	if not mod.isDLC and not PlatformPrivilegeUtil.checkModUse(self.selectCurrentMod, self) then
		return
	end

	local newIsSelected = not self:getIsModSelected(mod)
	local updated = self:setItemState(mod, newIsSelected)

	if not updated then
		local activeUniqueMod = self.uniqueTypesInUse[mod.uniqueType]

		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_modConflictQuestion"), mod.title, activeUniqueMod.title),
			callback = function (yes)
				if yes then
					self:setItemState(activeUniqueMod, false)
					self:setItemState(mod, true)
				end
			end
		})
	end
end

function ModSelectionScreen:toggleModAction()
	self:selectCurrentMod()
end

function ModSelectionScreen:onClickOk()
	local valid, dependening, dependant, downloadModId = self:verifyDependencies()

	if valid then
		local mods = {}

		for _, modItem in pairs(self.selectedMods) do
			table.insert(mods, modItem)
		end

		self.missionDynamicInfo.mods = mods

		g_careerScreen:startGame(self.missionInfo, self.missionDynamicInfo)
	elseif g_dedicatedServer == nil then
		if downloadModId ~= 0 then
			g_gui:showYesNoDialog({
				dialogType = DialogElement.TYPE_ERROR,
				text = string.format(g_i18n:getText("ui_modDependencyMissing_download"), dependening.title, dependant.title),
				callback = function (yes)
					if yes then
						g_modHubScreen:openWithModId(downloadModId)
					end
				end
			})
		else
			g_gui:showInfoDialog({
				dialogType = DialogElement.TYPE_ERROR,
				text = string.format(g_i18n:getText("ui_modDependencyMissing"), dependening.title, dependant.title)
			})
		end
	else
		Logging.error("Could not start dedicated server with current mod setup because some dependencies are missing!")
	end
end

function ModSelectionScreen:onDoubleClick(index)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self:selectCurrentMod()
end

function ModSelectionScreen:toggleCrossplay()
	self.crossplayOnly = not self.crossplayOnly

	self:loadAvailableMods()
	self.modList:reloadData()
	self.buttonToggleCrossplay:setText(self.crossplayOnly and g_i18n:getText("button_modHubShowAll") or g_i18n:getText("button_modHubShowCrossplay"))
end

function ModSelectionScreen:update(dt)
	ModSelectionScreen:superClass().update(self, dt)

	if g_dedicatedServer ~= nil then
		for _, modItem in pairs(self.selectedMods) do
			self:setItemState(modItem, false)
		end

		for _, modName in pairs(g_dedicatedServer.mods) do
			local modItem = g_modManager:getModByName(modName)

			if modItem ~= nil then
				if self:shouldShowModInList(modItem) then
					self:setItemState(modItem, true)
				else
					Logging.error("Mod '%s' is not available for current dedicated server setup", modItem.title)
				end
			end
		end

		self:onClickOk()

		return
	end

	if self.startMissionInfo.isMultiplayer then
		Platform.verifyMultiplayerAvailabilityInMenu()
	end
end

function ModSelectionScreen:shouldShowModInList(mod)
	local showMod = not self.missionDynamicInfo.isMultiplayer or mod.isMultiplayerSupported and mod.fileHash ~= nil

	if showMod and not self.missionDynamicInfo.isMultiplayer and mod.multiplayerOnly then
		showMod = false
	end

	if not mod.isSelectable then
		showMod = false
	end

	if showMod and not mod.isDLC and mod.modName ~= self.mapModName then
		for mapId, _ in pairs(g_mapManager.idToMap) do
			local modName = g_mapManager:getModNameFromMapId(mapId)

			if modName ~= nil and modName == mod.modName then
				showMod = false

				break
			end
		end
	end

	if not mod.isDLC and self.crossplayOnly and self.missionDynamicInfo.isMultiplayer and showMod then
		if mod.hasScripts then
			showMod = false
		else
			local modId = getModIdByFilename(mod.modName)

			if modId == 0 or getModMetaAttributeString(modId, "hash") ~= mod.fileHash then
				showMod = false
			end
		end
	end

	return showMod
end

function ModSelectionScreen:isModActivated(name)
	for _, activeMod in pairs(self.selectedMods) do
		if activeMod.modName == name then
			return true
		end
	end

	return false
end

function ModSelectionScreen:verifyDependencies()
	for _, modItem in pairs(self.selectedMods) do
		if modItem.dependencies ~= nil and #modItem.dependencies > 0 then
			for _, depName in ipairs(modItem.dependencies) do
				if not self:isModActivated(depName) then
					local depMod = g_modManager:getModByName(depName)
					local downloadModId = 0

					if depMod == nil then
						local modId = getModIdByFilename(depName)

						if modId ~= 0 then
							downloadModId = modId
							local modInfo = g_modHubController:getModInfo(modId)
							depMod = {
								title = modInfo:getName()
							}
						else
							depMod = {
								title = depName .. ".zip"
							}
						end
					end

					return false, modItem, depMod, downloadModId
				end
			end
		end
	end

	return true
end

function ModSelectionScreen:loadAvailableMods()
	self.availableMods = {}
	self.selectedMods = {}
	self.numAddedModsBesidesMap = 0
	local mods = g_modManager:getMods()

	table.sort(mods, function (a, b)
		return a.title < b.title
	end)

	for i = 1, #mods do
		local mod = mods[i]

		if self:shouldShowModInList(mod) then
			table.insert(self.availableMods, mod)
			self:setItemState(mod, false)
		end
	end

	self.buttonSelectAll:setDisabled(#self.availableMods == 0)
	self.noModsDLCsElement:setVisible(#self.availableMods == 0)
end

function ModSelectionScreen:setItemState(item, isSelected)
	if item ~= nil then
		if item.uniqueType ~= nil then
			if self.uniqueTypesInUse[item.uniqueType] ~= nil then
				if isSelected then
					return false
				else
					self.uniqueTypesInUse[item.uniqueType] = nil
				end
			elseif isSelected then
				self.uniqueTypesInUse[item.uniqueType] = item
			end
		end

		local isNotUsedMap = self.mapModName == nil or item.modName ~= self.mapModName

		if isSelected then
			if isNotUsedMap and self.selectedMods[item] == nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap + 1
			end

			self.selectedMods[item] = item
		elseif isNotUsedMap then
			if self.selectedMods[item] ~= nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap - 1
			end

			self.selectedMods[item] = nil
		end

		if not isNotUsedMap then
			isSelected = true
		end

		local index = self:getIndexForItem(item)

		if index ~= nil then
			local cell = self.modList:getElementAtSectionIndex(1, index)

			if cell ~= nil then
				cell:getAttribute("tick"):setVisible(isSelected)
			end
		end
	end

	self:updateSelectButton()

	return true
end

function ModSelectionScreen:getIndexForItem(item)
	for i = 1, #self.availableMods do
		if self.availableMods[i] == item then
			return i
		end
	end

	return nil
end

function ModSelectionScreen:getIsModSelected(item)
	return self.selectedMods[item] ~= nil
end

function ModSelectionScreen:onListSelectionChanged(list, section, index)
	self:updateSelectButton()
end

function ModSelectionScreen:getSelectedMod()
	return self.availableMods[self.modList.selectedIndex]
end

function ModSelectionScreen:updateSelectButton()
	if self.selectedMods[self:getSelectedMod()] == nil then
		self.buttonSelect:setText(self.l10n:getText("button_select"))
	else
		self.buttonSelect:setText(self.l10n:getText("button_deselect"))
	end

	if #self.availableMods > 0 then
		if self.numAddedModsBesidesMap > 0 then
			self.buttonSelectAll:setText(self.l10n:getText("button_deselectAll"))
		else
			self.buttonSelectAll:setText(self.l10n:getText("button_selectAll"))
		end
	end
end

function ModSelectionScreen:getNumberOfItemsInSection(list, section)
	return #self.availableMods
end

function ModSelectionScreen:populateCellForItemInSection(list, section, index, cell)
	local mod = self.availableMods[index]

	cell:getAttribute("title"):setText(mod.title)
	cell:getAttribute("version"):setText(mod.version)
	cell:getAttribute("icon"):setImageFilename(mod.iconFilename)
	cell:getAttribute("tick"):setVisible(self.selectedMods[mod] ~= nil)
end
