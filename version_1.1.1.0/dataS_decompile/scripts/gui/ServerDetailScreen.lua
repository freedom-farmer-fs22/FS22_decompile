ServerDetailScreen = {
	CONTROLS = {
		"mainBox",
		"mapIconElement",
		"warningElement",
		"warningTextElement",
		"serverNameElement",
		"mapElement",
		"languageElement",
		"passwordElement",
		"playerCircleElement",
		"numPlayersElement",
		"modList",
		"listItemTemplate",
		"noModsDLCsElement",
		"getModsButton",
		"startElement",
		"showProfileButton",
		"headerText",
		"notAllModsOnSystemLabel",
		"platformElement",
		"crossPlayElement",
		"blockOrShowButton"
	}
}
local ServerDetailScreen_mt = Class(ServerDetailScreen, ScreenElement)

function ServerDetailScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or ServerDetailScreen_mt)

	self:registerControls(ServerDetailScreen.CONTROLS)

	self.returnScreenName = "JoinGameScreen"

	return self
end

function ServerDetailScreen:onCreate(element)
	self.modList:removeElement(self.listItemTemplate)
end

function ServerDetailScreen:onCreateList(element)
	self.modList = element
end

function ServerDetailScreen:setServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, areAllModsAvailable, allowCrossPlay, platformId)
	self.serverId = id
	self.numPlayers = numPlayers
	self.capacity = capacity
	self.areAllModsAvailable = areAllModsAvailable
	self.hasPassword = hasPassword
	self.platformId = platformId
	self.serverName = name

	self.serverNameElement:setText(name)
	self.headerText:setText(name)
	self.mapElement:setText(mapName)
	self.languageElement:setText(getLanguageName(language))
	self.platformElement:setPlatformId(platformId)

	local map = g_mapManager:getMapById(mapId)

	if map ~= nil then
		self.mapIconElement:setImageFilename(map.iconFilename)
	else
		self.mapIconElement:setImageFilename("dataS/menu/modHubPreview_default.png")
	end

	self.passwordElement:setLocaKey(hasPassword and "ui_yes" or "ui_no")
	self.crossPlayElement:setLocaKey(allowCrossPlay and "ui_yes" or "ui_no")

	if numPlayers == 0 then
		self.numPlayersElement:applyProfile("serverDetailInfoValue")
	elseif numPlayers == capacity then
		self.numPlayersElement:applyProfile("serverDetailInfoValueDanger")
	else
		self.numPlayersElement:applyProfile("serverDetailInfoValue")
	end

	local numPlayersText = string.format("%02d/%02d", numPlayers, capacity)

	self.numPlayersElement:setText(numPlayersText)

	local canStart = areAllModsAvailable and numPlayers < capacity

	self.startElement:setDisabled(not canStart)

	self.modTitles = modTitles
	self.modHashes = modHashes

	self.noModsDLCsElement:setVisible(#modTitles == 0)
	self.notAllModsOnSystemLabel:setVisible(#modTitles > 0 and not areAllModsAvailable)
	self.modList:setDataSource(self)
	self.modList:reloadData()

	local _, _, numDownloadable = self:getDownloadableModsInfo()

	self.getModsButton:setDisabled(numDownloadable == 0)

	if Platform.hasNativeProfiles and getPlatformIdsAreCompatible(platformId, getPlatformId()) then
		self.blockOrShowButton:setText(g_i18n:getText("button_showProfile"))

		self.doShowUserProfile = true
	else
		self.blockOrShowButton:setText(g_i18n:getText("button_block"))

		self.doShowUserProfile = false
	end
end

function ServerDetailScreen:onOpen()
	ServerDetailScreen:superClass().onOpen(self)
	self.getModsButton:setVisible(not Platform.isStadia)
end

function ServerDetailScreen:onClickOk()
	if self.areAllModsAvailable and self.numPlayers < self.capacity then
		if not self.hasPassword then
			g_joinGameScreen:startGame("", self.serverId)
		else
			local password = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "password"), "")

			g_gui:showPasswordDialog({
				callback = self.onPasswordEntered,
				target = self,
				defaultPassword = password
			})
		end
	end
end

function ServerDetailScreen:getDownloadableModsInfo()
	local downloadable = {}
	local totalSize = 0
	local totalCount = 0

	for i = 1, #self.modTitles do
		local modHash = self.modHashes[i]

		if not g_modManager:getIsModAvailable(modHash) then
			local _, _, _, modName = ServerDetailScreen.unpackModInfo(self.modTitles[i])
			local modId = getModIdByFilename(modName)

			if modId ~= 0 and getModMetaAttributeString(modId, "hash") == modHash and not getModMetaAttributeBool(modId, "isDLC") then
				downloadable[#downloadable + 1] = modId
				totalCount = totalCount + 1
				totalSize = totalSize + getModMetaAttributeInt(modId, "filesize")
			end
		end
	end

	return downloadable, totalSize, totalCount
end

function ServerDetailScreen:onClickDownload()
	local downloadable, totalSize, totalCount = self:getDownloadableModsInfo()
	local freeSpaceKb = g_modHubController:getFreeModSpaceKb()
	totalSize = math.floor((totalSize + 1023) / 1024)

	if freeSpaceKb < totalSize then
		g_gui:showInfoDialog({
			text = string.format(g_l10n:getText("modHub_installNoFreeSpace"), totalSize, freeSpaceKb)
		})

		return
	end

	g_gui:showYesNoDialog({
		title = g_i18n:getText("ui_downloadingServerModsTitle"),
		text = string.format(g_i18n:getText("ui_downloadingServerMods"), totalCount, totalSize / 1024),
		callback = function (yes)
			if yes then
				self:installMods(downloadable)
			end
		end
	})
end

function ServerDetailScreen:onClickBlockOrShowInfo()
	if self.doShowUserProfile then
		local _, platformUserId, _ = masterServerGetServerUserInfo(self.serverId)

		showUserProfile(platformUserId)
	else
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_doYouWantToBlockThisServer_title"),
			text = g_i18n:getText("ui_doYouWantToBlockThisServer"),
			callback = function (yes)
				if yes then
					local uniqueUserId, platformUserId, platformId = masterServerGetServerUserInfo(self.serverId)

					setIsUserBlocked(uniqueUserId, platformUserId, platformId, true, self.serverName)
					self:onClickBack()
				end
			end
		})
	end
end

function ServerDetailScreen:goToModHub()
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	g_modHubScreen:openDownloads()
end

function ServerDetailScreen:installMods(modIds)
	g_modHubController:startModification()

	local numToGo = #modIds

	function failure()
		numToGo = numToGo - 1

		g_gui:showInfoDialog({
			text = g_l10n:getText("modHub_installFailed")
		})

		if numToGo == 0 then
			self:goToModHub()
		end
	end

	function added()
		numToGo = numToGo - 1

		if numToGo == 0 then
			self:goToModHub()
		end
	end

	g_modHubController:setModInstallFailedCallback(failure, self)
	g_modHubController:setDependendModIstallFailedCallback(failure, self)
	g_modHubController:setAddedToDownloadCallback(added, self)

	for _, modId in ipairs(modIds) do
		g_modHubController:install(modId)
	end
end

function ServerDetailScreen:onPasswordEntered(password, clickOk)
	if clickOk then
		g_gameSettings:setTableValue("joinGame", "password", password)
		g_gameSettings:saveToXMLFile(g_savegameXML)
		g_joinGameScreen:startGame(password, self.serverId)
	end
end

function ServerDetailScreen.packModInfo(modTitle, version, author, modName)
	modTitle = string.gsub(modTitle, ";", " ")
	version = string.gsub(version, ";", " ")
	author = string.gsub(author, ";", " ")
	modName = string.gsub(modName, ";", " ")

	return modTitle .. ";" .. version .. ";" .. author .. ";" .. modName
end

function ServerDetailScreen.unpackModInfo(str)
	local parts = str:split(";")
	local modTitle = parts[1]
	local version = parts[2]
	local author = parts[3]
	local modName = parts[4]

	if modTitle == nil or modTitle == "" then
		modTitle = "Unknown Title"
	end

	if version == nil or version == "" then
		version = "0.0.0.1"
	end

	if author == nil then
		author = ""
	end

	if modName == nil then
		modName = ""
	end

	return modTitle, version, author, modName
end

function ServerDetailScreen:getNumberOfItemsInSection(list, section)
	return #self.modTitles
end

function ServerDetailScreen:populateCellForItemInSection(list, section, index, cell)
	local modTitle, modVersion, modAuthor, modName = ServerDetailScreen.unpackModInfo(self.modTitles[index])
	local modHash = self.modHashes[index]
	local title, version, hash, icon, iconIsWeb, availability, author = nil

	if g_modManager:getIsModAvailable(modHash) then
		local modItem = g_modManager:getModByFileHash(modHash)
		title = modItem.title
		version = modItem.version
		icon = modItem.iconFilename
		availability = "ui_modAvailable"
	else
		local modId = getModIdByFilename(modName)

		if modId ~= 0 and getModMetaAttributeString(modId, "hash") == modHash then
			local modInfo = g_modHubController:getModInfo(modId)
			title = modInfo:getName()
			version = modInfo:getVersionString()
			icon = modInfo:getIconFilename()
			iconIsWeb = true
			availability = "ui_modAvailableModHub"
		else
			title = modTitle
			author = modAuthor
			version = modVersion
			hash = modHash
			availability = "ui_modUnavailable"
		end
	end

	local iconElement = cell:getAttribute("icon")

	iconElement:setVisible(icon ~= nil)

	if icon ~= nil then
		iconElement:setIsWebOverlay(iconIsWeb == true)
		iconElement:setImageFilename(icon)
	end

	cell:getAttribute("title"):setText(title)
	cell:getAttribute("version"):setText(version)
	cell:getAttribute("availability"):setLocaKey(availability)
	cell:getAttribute("availability"):applyProfile(availability ~= "ui_modUnavailable" and "serverDetailModAvailability" or "serverDetailModAvailabilityUnavailable")
	cell:getAttribute("title"):applyProfile(hash ~= nil and "serverDetailModTitleUnavailable" or "serverDetailModTitle")
	cell:getAttribute("version").parent:applyProfile(hash ~= nil and "serverDetailModVersionBoxUnavailable" or "serverDetailModVersionBox")

	if hash ~= nil then
		local hash1 = hash:sub(1, hash:len() / 2)
		local hash2 = hash:sub(hash:len() / 2 + 1)

		cell:getAttribute("hash"):setText(hash1 .. "\n" .. hash2)
		cell:getAttribute("hash"):setVisible(true)
		cell:getAttribute("author"):setText(author)
		cell:getAttribute("author"):setVisible(true)
	else
		cell:getAttribute("hash"):setVisible(false)
		cell:getAttribute("author"):setVisible(false)
	end
end
