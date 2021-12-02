WardrobeColorsFrame = {}
local WardrobeColorsFrame_mt = Class(WardrobeColorsFrame, TabbedMenuFrameElement)
WardrobeColorsFrame.CONTROLS = {
	"primaryList"
}

function WardrobeColorsFrame.new(subclass_mt)
	local self = WardrobeColorsFrame:superClass().new(nil, subclass_mt or WardrobeColorsFrame_mt)

	self:registerControls(WardrobeColorsFrame.CONTROLS)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = g_i18n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = function ()
			self:onClickBack()
		end
	}
	self.equipButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function ()
			self:onClickSelect()
		end
	}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.equipButtonInfo
	}

	return self
end

function WardrobeColorsFrame:copyAttributes(src)
	WardrobeColorsFrame:superClass().copyAttributes(self, src)
end

function WardrobeColorsFrame:onGuiSetupFinished()
	WardrobeColorsFrame:superClass().onGuiSetupFinished(self)
	self.primaryList:setDataSource(self)
	self.primaryList:setDelegate(self)
end

function WardrobeColorsFrame:initialize(delegate)
	self.delegate = delegate
end

function WardrobeColorsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle
end

function WardrobeColorsFrame:setConfigAndItem(configName, item)
	self.configName = configName
	self.item = item

	self.primaryList:reloadData()
	FocusManager:setFocus(self.primaryList)
	self.primaryList:setSelectedIndex(self.playerStyle[self.configName].color)
end

function WardrobeColorsFrame:onFrameOpen()
	WardrobeColorsFrame:superClass().onFrameOpen(self)
end

function WardrobeColorsFrame:getNumberOfItemsInSection(list, section)
	if self.delegate == nil or self.item == nil then
		return 0
	end

	return #self.item.colors
end

function WardrobeColorsFrame:populateCellForItemInSection(list, section, index, cell)
	local color = self.item.colors[index].primary

	cell:getAttribute("icon"):setImageColor(nil, color[1], color[2], color[3], 1)
	cell:getAttribute("selected"):setVisible(self.savedPlayerStyle[self.configName].selection == self.item.itemIndex and self.savedPlayerStyle[self.configName].color == index)
end

function WardrobeColorsFrame:onListSelectionChanged(list, section, index)
	local config = self.playerStyle[self.configName]

	config.colorSetter(self.playerStyle, config, index)
	self.delegate:onColorSelectionChanged()
end

function WardrobeColorsFrame:onListHighlightChanged(list, section, index)
	if index == nil then
		self.delegate:onColorSelectionCancelled(true)
	else
		local config = self.playerStyle[self.configName]

		config.colorSetter(self.playerStyle, config, index)
		self.delegate:onColorSelectionChanged()
	end
end

function WardrobeColorsFrame:onClickSelect()
	self.delegate:onColorSelectionConfirmed(true)
	self.primaryList:reloadData()
end

function WardrobeColorsFrame:onDoubleClickSelect()
	self.delegate:onColorSelectionConfirmed()
end

function WardrobeColorsFrame:onClickBack()
	self.delegate:onColorSelectionCancelled()
end
