SellItemDialog = {
	CONTROLS = {
		ITEM_IMAGE = "dialogImageElement",
		HEADER_TEXT = "headerText",
		ITEM_NAME = "dialogItemNameElement",
		ITEM_PRICE = "dialogItemPriceElement"
	}
}
local SellItemDialog_mt = Class(SellItemDialog, YesNoDialog)

function SellItemDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or SellItemDialog_mt)
	self.selectedFillType = nil
	self.areButtonsDisabled = false

	self:registerControls(SellItemDialog.CONTROLS)

	return self
end

function SellItemDialog:setItem(item, price, storeItem)
	local imageFilename = "dataS/menu/blank.png"
	local name = "unknown"
	local sellPrice = g_i18n:formatMoney(Utils.getNoNil(price, 0), 0, true, true)

	if item ~= nil then
		storeItem = storeItem or g_storeManager:getItemByXMLFilename(item.configFileName)

		if storeItem ~= nil then
			imageFilename = storeItem.imageFilename
			name = storeItem.name
		end

		if item.getFullName ~= nil then
			name = item:getFullName()
		elseif item.getName ~= nil then
			name = item:getName()
		end

		if item.getImageFilename ~= nil then
			imageFilename = item:getImageFilename()
		end
	elseif storeItem ~= nil then
		imageFilename = storeItem.imageFilename
		name = storeItem.name
	end

	self.dialogImageElement:setImageFilename(imageFilename)
	self.dialogItemNameElement:setText(name)

	local title = g_i18n:getText("ui_sellItem")

	if item ~= nil and item.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		title = g_i18n:getText("button_return")
		sellPrice = "-"

		self.dialogItemPriceElement:setVisible(false)
	else
		self.dialogItemPriceElement:setVisible(true)
	end

	self.headerText:setText(title)
	self.dialogItemPriceElement:setText(sellPrice)
end
