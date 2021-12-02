ModHubDetailsFrame = {}
local ModHubDetailsFrame_mt = Class(ModHubDetailsFrame, TabbedMenuFrameElement)
ModHubDetailsFrame.CONTROLS = {
	"breadcrumbs",
	"pageInformation",
	"modPreviewImage",
	"modAuthor",
	"modDescription",
	"modInfoVersion",
	"modInfoSize",
	"modInfoHash",
	"modInfoHashLabel",
	"modInfoSizeLabel",
	"descriptionLayout",
	"textSlider",
	"modInfoBox",
	"headerText",
	"spaceUsageLabel"
}

function ModHubDetailsFrame.new(subclass_mt, modHubController, l10n, isConsoleVersion, isSteamVersion)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ModHubDetailsFrame_mt)

	self:registerControls(ModHubDetailsFrame.CONTROLS)

	self.modHubController = modHubController
	self.l10n = l10n
	self.isConsoleVersion = isConsoleVersion
	self.isSteamVersion = isSteamVersion
	self.hasCustomMenuButtons = true
	self.currentModInfo = nil
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0

	return self
end

function ModHubDetailsFrame:copyAttributes(src)
	ModHubDetailsFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
	self.modHubController = src.modHubController
	self.isConsoleVersion = src.isConsoleVersion
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function ModHubDetailsFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.buyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_BUY),
		callback = function ()
			self:onButtonBuy()
		end
	}
	self.installButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_INSTALL),
		callback = function ()
			self:onButtonInstall()
		end
	}
	self.uninstallButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UNINSTALL),
		callback = function ()
			self:onButtonUninstall()
		end
	}
	self.updateButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_UPDATE),
		callback = function ()
			self:onButtonUpdate()
		end
	}
	self.downloadButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_DOWNLOAD),
		callback = function ()
			self:onButtonDownload()
		end
	}
	self.voteButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(ModHubDetailsFrame.L10N_SYMBOL.BUTTON_VOTE),
		callback = function ()
			self:onButtonVote()
		end
	}
end

function ModHubDetailsFrame:onFrameOpen()
	ModHubDetailsFrame:superClass().onFrameOpen(self)
	FocusManager:setFocus(self.itemsList)
	self.modHubController:setModInstallFailedCallback(self.onModInstallFailed, self)
	self.modHubController:setDependendModIstallFailedCallback(self.onDependendModInstallFailed, self)
	self.modHubController:setAddedToDownloadCallback(self.onAddedToDownload, self)
	self.modHubController:setUninstallFailedCallback(self.onUninstallFailed, self)
	self.modHubController:setUninstalledCallback(self.onUninstalled, self)
	self.modHubController:setVotedCallback(self.onVoted, self)
end

function ModHubDetailsFrame:getMenuButtonInfo()
	local buttons = {}
	local modInfo = self.modHubController:getModInfo(self.currentModInfo:getId())
	local isUpdate = modInfo:getIsUpdate()
	local isInstalled = modInfo:getIsInstalled()
	local isDownload = modInfo:getIsDownload()
	local isDLC = modInfo:getIsDLC()

	if not modInfo:getIsExternal() and (modInfo:getIsFailed() or not isDownload and (not isInstalled or isUpdate)) then
		if isUpdate then
			if not isDLC or not self.isConsoleVersion then
				table.insert(buttons, self.updateButtonInfo)
			end
		elseif isDLC then
			if modInfo:getPriceString():len() > 1 then
				table.insert(buttons, self.buyButtonInfo)
			end
		else
			table.insert(buttons, self.installButtonInfo)
		end
	end

	table.insert(buttons, self.backButtonInfo)

	if not modInfo:getIsExternal() and isInstalled and not isDLC then
		table.insert(buttons, self.voteButtonInfo)
	end

	if (isInstalled or isDownload) and not isDLC then
		table.insert(buttons, self.uninstallButtonInfo)
	end

	return buttons
end

function ModHubDetailsFrame:setModInfo(modInfo)
	self.currentModInfo = modInfo

	self.modDescription:setText(modInfo:getDescription())

	local totalHeight, numLines = self.modDescription:getTextHeight()

	self.modDescription:setSize(nil, totalHeight)
	self.modDescription.parent:invalidateLayout()
	self.modAuthor:setText(modInfo:getAuthor())

	local isDLC = modInfo:getIsDLC()

	self.modInfoSize:setVisible(not isDLC)
	self.modInfoSizeLabel:setVisible(not isDLC)

	local hash = modInfo:getHash()
	local showHash = not isDLC and hash ~= "" and not GS_IS_CONSOLE_VERSION

	self.modInfoHash:setVisible(showHash)
	self.modInfoHashLabel:setVisible(showHash)

	local hash1 = hash:sub(1, hash:len() / 2)
	local hash2 = hash:sub(hash:len() / 2 + 1)

	self.modInfoHash:setText(hash1 .. "\n" .. hash2)

	if not isDLC then
		local size = modInfo:getFilesize() / 1024 / 1024

		self.modInfoSize:setText(string.format("%.02f MB", size))
	end

	self.modInfoVersion:setText(modInfo:getVersionString())

	self.title = modInfo:getName()

	self.headerText:setText(self.title)
	self:setImage(self.modPreviewImage[1], modInfo:getScreenshot1Filename())
	self:setImage(self.modPreviewImage[2], modInfo:getScreenshot2Filename())
	self:setImage(self.modPreviewImage[3], modInfo:getScreenshot3Filename())
end

function ModHubDetailsFrame:setImage(element, image)
	if image ~= nil and image ~= "" then
		element:setImageFilename(image)
		element:setVisible(true)
	else
		element:setVisible(false)
	end
end

function ModHubDetailsFrame:setBreadcrumbs(list)
	self.breadcrumbs:setBreadcrumbs(list)
end

function ModHubDetailsFrame:getMainElementSize()
	return self.pageInformation.size
end

function ModHubDetailsFrame:getMainElementPosition()
	return self.pageInformation.absPosition
end

function ModHubDetailsFrame:onButtonBuy()
	local modInfo = self.currentModInfo
	local url = modInfo:getDLCLink()

	if self.isSteamVersion then
		url = modInfo:getDLCSteamLink()
	end

	if storeHasNativeGUI() then
		if not storeShow(url) then
			g_gui:showInfoDialog({
				text = self.l10n:getText("ui_dlcStoreNotConnected"),
				callback = self.onStoreFailedOk,
				target = self
			})
		end
	else
		openWebFile(url, "")
	end
end

function ModHubDetailsFrame:onButtonInstall()
	local dependendMods = self.modHubController:getDependendMods(self.currentModInfo:getId())

	if #dependendMods > 0 then
		local dependendModNames = ""

		for _, modInfo in ipairs(dependendMods) do
			if not modInfo:getIsInstalled() then
				if dependendModNames ~= "" then
					dependendModNames = dependendModNames .. ", "
				end

				dependendModNames = dependendModNames .. modInfo:getName()
			end
		end

		g_gui:showInfoDialog({
			text = string.format(self.l10n:getText("modHub_dependenciesText"), dependendModNames),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.installCurrentMod,
			target = self
		})
	else
		self:installCurrentMod()
	end
end

function ModHubDetailsFrame:onButtonUninstall()
	local modInfo = self.currentModInfo

	if (modInfo:getIsInstalled() or modInfo:getIsDownload()) and not modInfo:getIsDLC() then
		local title = self.l10n:getText("modHub_uninstallModTitle")
		local text = string.format(self.l10n:getText("modHub_uninstallModText"), modInfo:getName())

		g_gui:showYesNoDialog({
			title = title,
			text = text,
			callback = ModHubDetailsFrame.uninstallYesNo,
			target = self
		})
	end
end

function ModHubDetailsFrame:uninstallYesNo(yes)
	if yes then
		local modInfo = self.currentModInfo

		self.modHubController:uninstall(modInfo:getId())
	end
end

function ModHubDetailsFrame:onButtonUpdate()
	if self.currentModInfo:getIsDLC() then
		self:onButtonBuy()
	else
		self.modHubController:update(self.currentModInfo:getId())
	end
end

function ModHubDetailsFrame:installCurrentMod()
	local modInfo = self.currentModInfo
	local totalFilesizeKb = self.modHubController:getTotalFilesizeKb(modInfo:getId())
	local freeSpaceKb = self.modHubController:getFreeModSpaceKb()

	if freeSpaceKb < totalFilesizeKb then
		g_gui:showInfoDialog({
			text = string.format(self.l10n:getText("modHub_installNoFreeSpace"), totalFilesizeKb, freeSpaceKb)
		})

		return
	end

	self.modHubController:install(modInfo:getId())
end

function ModHubDetailsFrame:onModInstallFailed()
	g_gui:showInfoDialog({
		text = self.l10n:getText("modHub_installFailed")
	})
end

function ModHubDetailsFrame:onDependendModInstallFailed(dependendMods)
	local failedNames = ""

	for _, dependendModInfo in ipairs(dependendMods) do
		if failedNames ~= "" then
			failedNames = failedNames .. ", "
		end

		failedNames = failedNames .. dependendModInfo:getName()
	end

	g_gui:showInfoDialog({
		text = string.format(self.l10n:getText("modHub_installDependenciesFailed"), failedNames)
	})
end

function ModHubDetailsFrame:onAddedToDownload()
	g_gui:showInfoDialog({
		text = string.format(self.l10n:getText("modHub_addedToDownloads"), self.currentModInfo:getName()),
		dialogType = DialogElement.TYPE_INFO
	})
	self:setMenuButtonInfoDirty()
end

function ModHubDetailsFrame:onStoreFailedOk()
	self:changeScreen(ModHubScreen)
end

function ModHubDetailsFrame:onUninstallFailed()
	g_gui:showInfoDialog({
		text = self.l10n:getText("modHub_uninstallModFailed")
	})
end

function ModHubDetailsFrame:onUninstalled()
	g_gui:showInfoDialog({
		text = self.l10n:getText("modHub_uninstallModSuccess"),
		dialogType = DialogElement.TYPE_INFO
	})
	self:setMenuButtonInfoDirty()
end

function ModHubDetailsFrame:onButtonVote()
	local knownVote = self.modHubController:getVote(self.currentModInfo:getId())
	local value = knownVote ~= 0 and knownVote or 0

	g_gui:showVoteDialog({
		callback = self.onVote,
		target = self,
		value = value
	})
end

function ModHubDetailsFrame:onButtonDownload()
end

function ModHubDetailsFrame:onVote(value)
	if value ~= nil then
		self.modHubController:vote(self.currentModInfo:getId(), value)
	end
end

function ModHubDetailsFrame:onVoted()
	g_gui:showInfoDialog({
		text = self.l10n:getText("modHub_rateSuccess")
	})
end

function ModHubDetailsFrame:inputEvent(action, value, eventUsed)
	local pressedUp = action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value
	local pressedDown = action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance

	if pressedUp or pressedDown then
		local dir = pressedUp and -1 or 1

		if dir ~= self.scrollInputDelayDir or g_time - self.scrollInputDelay > 250 then
			self.scrollInputDelayDir = dir
			self.scrollInputDelay = g_time

			self.textSlider:setValue(self.textSlider:getValue() + dir)
		end
	end

	return true
end

ModHubDetailsFrame.L10N_SYMBOL = {
	BUTTON_BUY = "button_modHubBuy",
	BUTTON_UPDATE = "button_modHubUpdate",
	BUTTON_UNINSTALL = "button_modHubUninstall",
	BUTTON_INSTALL = "button_modHubInstall",
	BUTTON_DOWNLOAD = "button_modHubDownload",
	BUTTON_VOTE = "button_rate"
}
