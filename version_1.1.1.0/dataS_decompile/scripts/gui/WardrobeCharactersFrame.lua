WardrobeCharactersFrame = {}
local WardrobeCharactersFrame_mt = Class(WardrobeCharactersFrame, TabbedMenuFrameElement)
WardrobeCharactersFrame.CONTROLS = {
	"itemList",
	"title",
	"nicknameElement"
}

function WardrobeCharactersFrame.new(subclass_mt)
	local self = WardrobeCharactersFrame:superClass().new(nil, subclass_mt or WardrobeCharactersFrame_mt)

	self:registerControls(WardrobeCharactersFrame.CONTROLS)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = g_i18n:getText("button_confirm")
	}
	self.selectButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function ()
			self:onClickSelect()
		end
	}
	self.nicknameButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_changeName"),
		callback = function ()
			self:onClickChangeName()
		end
	}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.selectButtonInfo
	}

	if Platform.canChangeGamerTag then
		table.insert(self.menuButtonInfo, self.nicknameButtonInfo)
	end

	self.mapping = {}

	return self
end

function WardrobeCharactersFrame:onGuiSetupFinished()
	WardrobeCharactersFrame:superClass().onGuiSetupFinished(self)
	self.itemList:setDataSource(self)
	self.itemList:setDelegate(self)
end

function WardrobeCharactersFrame:initialize(configName, delegate, titleKey)
	self.configName = configName
	self.delegate = delegate

	self.title:setLocaKey(titleKey)
	self:loadPlayers()
end

function WardrobeCharactersFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle

	self:resetList()
end

function WardrobeCharactersFrame:onFrameOpen()
	WardrobeCharactersFrame:superClass().onFrameOpen(self)
	self.delegate:onItemSelectionStart()
	self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
	g_messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onNicknameChanged, self)
	self:resetList()
end

function WardrobeCharactersFrame:resetList()
	self.mapping = {}

	if self.playerStyle ~= nil then
		local selectedIndex = 1

		for playerIndex, player in ipairs(self.players) do
			for i, item in ipairs(player.style.faceConfig.items) do
				table.insert(self.mapping, {
					xmlFilename = player.xmlFilename,
					uvSlot = item.uvSlot,
					index = i,
					style = player.style
				})

				if self.playerStyle.faceConfig.selection == i and self.playerStyle.xmlFilename == player.xmlFilename then
					selectedIndex = #self.mapping
				end
			end
		end

		self.itemList:reloadData()
		self.itemList:setSelectedItem(1, selectedIndex)
	end

	FocusManager:setFocus(self.itemList)
end

function WardrobeCharactersFrame:onFrameClose()
	for _, cell in ipairs(self.itemList.elements) do
		cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
	end

	g_messageCenter:unsubscribe(MessageType.PLAYER_NICKNAME_CHANGED, self)
	WardrobeCharactersFrame:superClass().onFrameClose(self)
end

function WardrobeCharactersFrame:loadPlayers()
	self.players = {}

	for _, playerModel in ipairs(g_characterModelManager.playerModels) do
		local playerStyle = PlayerStyle.new()

		playerStyle:loadConfigurationXML(playerModel.xmlFilename)

		local info = {
			xmlFilename = playerModel.xmlFilename,
			style = playerStyle
		}

		table.insert(self.players, info)
	end
end

function WardrobeCharactersFrame:getNumberOfItemsInSection(list, section)
	return #self.mapping
end

function WardrobeCharactersFrame:populateCellForItemInSection(list, section, index, cell)
	local item = self.mapping[index]
	local icon = cell:getAttribute("icon")

	icon:setImageFilename(item.style.atlasFilename)
	icon:setImageUVs(nil, item.style:getSlotUVs(item.uvSlot))
	cell:getAttribute("selected"):setVisible(self.savedPlayerStyle.faceConfig.selection == item.index and self.savedPlayerStyle.xmlFilename == item.xmlFilename)
end

function WardrobeCharactersFrame:onListSelectionChanged(list, section, index)
	local item = self.mapping[index]

	if self.playerStyle.xmlFilename ~= item.xmlFilename then
		self.playerStyle:loadConfigurationXML(item.xmlFilename)
	end

	self.playerStyle.faceConfig.setter(self.playerStyle, item.index)
	self.delegate:onItemSelectionChanged()
end

function WardrobeCharactersFrame:onClickSelect(element)
	self.delegate:onItemSelectionConfirmed()
	self.itemList:reloadData()
end

function WardrobeCharactersFrame:onClickChangeName()
	g_gui:showTextInputDialog({
		text = g_i18n:getText("ui_enterName"),
		callback = function (newName, ok)
			if ok and newName ~= g_currentMission.playerNickname then
				g_currentMission:setPlayerNickname(g_currentMission.player, newName)
				self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
			end
		end,
		defaultText = g_currentMission.playerNickname,
		imePrompt = g_i18n:getText("ui_enterName"),
		confirmText = g_i18n:getText("button_change")
	})
end

function WardrobeCharactersFrame:onNicknameChanged()
	self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
end
