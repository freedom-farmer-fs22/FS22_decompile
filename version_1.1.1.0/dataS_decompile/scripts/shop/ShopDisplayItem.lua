ShopDisplayItem = {}
local ShopDisplayItem_mt = Class(ShopDisplayItem)
ShopDisplayItem.NO_CONCRETE_ITEM = {}

function ShopDisplayItem.new(storeItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
	local self = setmetatable({}, ShopDisplayItem_mt)
	self.storeItem = storeItem
	self.concreteItem = concreteItem or ShopDisplayItem.NO_CONCRETE_ITEM
	self.attributeIconProfiles = attributeIconProfiles or {}
	self.attributeValues = attributeValues or {}
	self.fillTypeIconFilenames = iconFilenames.fillTypeIconFilenames or {}
	self.seedTypeIconFilenames = iconFilenames.seedTypeIconFilenames or {}
	self.foodFillTypeIconFilenames = iconFilenames.foodFillTypeIconFilenames or {}
	self.prodPointInputFillTypeIconFilenames = iconFilenames.prodPointInputFillTypeIconFilenames or {}
	self.prodPointOutputFillTypeIconFilenames = iconFilenames.prodPointOutputFillTypeIconFilenames or {}
	self.sellingStationFillTypesIconFilenames = iconFilenames.sellingStationFillTypesIconFilenames or {}
	self.functionText = functionText
	self.orderValue = orderValue
	self.numOwned = numOwned
	self.numLeased = numLeased
	self.saleItem = saleItem

	return self
end

function ShopDisplayItem:getSellPrice()
	if self.saleItem ~= nil then
		return self.saleItem.price
	elseif self.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
		return self.concreteItem:getSellPrice()
	else
		return self.storeItem.price
	end
end

function ShopDisplayItem:getSortId()
	if self.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
		return self.concreteItem.id
	else
		return self.storeItem.xmlFilename
	end
end

function ShopDisplayItem:hasCombinationInfo()
	if self.saleItem ~= nil then
		return false
	elseif self.storeItem.specs.combinations ~= nil then
		return #self.storeItem.specs.combinations > 0
	else
		return false
	end
end
