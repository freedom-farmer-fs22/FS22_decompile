ShopOthersFrame = {}
local ShopOthersFrame_mt = Class(ShopOthersFrame, TabbedMenuFrameElement)
ShopOthersFrame.CONTROLS = {
	"categoryHeaderIcon",
	"categoryHeaderText",
	"otherShopsList"
}

function ShopOthersFrame.new(subclass_mt, shopController)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ShopOthersFrame_mt)

	self:registerControls(ShopOthersFrame.CONTROLS)

	self.headerLabelText = ""
	self.headerIconUVs = {}
	self.otherShops = {
		{
			iconFilename = "dataS/menu/storePacks/store_animalDealer.png",
			title = g_i18n:getText("ui_animalDealerScreen"),
			callback = function ()
				self:onOpenAnimalDealer()
			end
		},
		{
			iconFilename = "dataS/menu/storePacks/store_characterCustomization.png",
			title = g_i18n:getText("ui_wardrobeScreen"),
			callback = function ()
				self:onOpenWardrobeScreen()
			end
		},
		{
			iconFilename = "dataS/menu/storePacks/store_construction.png",
			title = g_i18n:getText("ui_constructionScreen"),
			callback = function ()
				self:onOpenConstructionScreen()
			end
		},
		{
			iconFilename = "dataS/menu/storePacks/store_farmlands.png",
			title = g_i18n:getText("ui_farmlandScreen"),
			callback = function ()
				self:onOpenFarmlandScreen()
			end
		}
	}

	return self
end

function ShopOthersFrame:onGuiSetupFinished()
	ShopOthersFrame:superClass().onGuiSetupFinished(self)
	self.otherShopsList:setDataSource(self)
	self.otherShopsList:setDelegate(self)
end

function ShopOthersFrame:initialize(categorySelectedCallback, headerIconUVs, headerText)
	self.headerLabelText = headerText
	self.headerIconUVs = headerIconUVs
	self.notifySelectedCategoryCallback = categorySelectedCallback or NO_CALLBACK

	if self.categoryHeaderText ~= nil then
		self.categoryHeaderIcon:setImageUVs(nil, unpack(headerIconUVs))
		self.categoryHeaderText:setText(headerText)
		self.categoryHeaderText:updateAbsolutePosition()
	end

	self:setTitle(headerText)
end

function ShopOthersFrame:onFrameOpen()
	ShopOthersFrame:superClass().onFrameOpen(self)
	self.notifySelectedCategoryCallback(nil)
	self.otherShopsList:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.otherShopsList)
	self:setSoundSuppressed(false)
end

function ShopOthersFrame:onFrameClose()
	ShopOthersFrame:superClass().onFrameClose(self)
	self:setSoundSuppressed(true)
end

function ShopOthersFrame:onOpenCategory()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

	local otherShop = self.otherShops[self.otherShopsList.selectedIndex]

	if otherShop ~= nil then
		otherShop.callback()
	end
end

function ShopOthersFrame:onOpenAnimalDealer()
	local husbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm()

	if #husbandries == 0 then
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageNoHusbandries")
		})

		return
	end

	if #husbandries > 1 then
		g_gui:showAnimalDialog({
			title = g_i18n:getText("category_animalpens"),
			husbandries = husbandries,
			callback = self.onSelectedHusbandry,
			target = self
		})

		return
	end

	self:onSelectedHusbandry(husbandries[1])
end

function ShopOthersFrame:onSelectedHusbandry(husbandry)
	if husbandry ~= nil then
		local controller = AnimalScreenDealerFarm.new(husbandry)

		controller:init()
		g_animalScreen:setController(controller)
		g_gui:showGui("AnimalScreen")
	end
end

function ShopOthersFrame:onOpenWardrobeScreen()
	g_gui:changeScreen(nil, WardrobeScreen)
end

function ShopOthersFrame:onOpenConstructionScreen()
	g_gui:changeScreen(nil, ConstructionScreen)
end

function ShopOthersFrame:onOpenFarmlandScreen()
	g_gui:changeScreen(nil, InGameMenu)

	local ingameMenu = g_currentMission.inGameMenu

	ingameMenu:goToPage(ingameMenu.pageMapOverview)
	ingameMenu.pageMapOverview:setMode(InGameMenuMapFrame.MODE_FARMLANDS)
end

function ShopOthersFrame:onListSelectionChanged(list, section, index)
	self.notifySelectedCategoryCallback(index)
end

function ShopOthersFrame:getNumberOfItemsInSection(list, section)
	return #self.otherShops
end

function ShopOthersFrame:populateCellForItemInSection(list, section, index, cell)
	local otherShop = self.otherShops[index]

	cell:getAttribute("icon"):setImageFilename(otherShop.iconFilename)
	cell:getAttribute("title"):setText(otherShop.title)
end

function ShopOthersFrame:getTitleForSectionHeader(list, section)
	return ""
end
