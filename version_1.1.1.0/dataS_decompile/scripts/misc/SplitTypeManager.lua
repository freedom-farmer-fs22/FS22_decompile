SplitTypeManager = {
	COLLISIONMASK_TRIGGER = 16777216
}
local SplitTypeManager_mt = Class(SplitTypeManager, AbstractManager)

function SplitTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or SplitTypeManager_mt)

	return self
end

function SplitTypeManager:initDataStructures()
	self.typesByIndex = {}
	self.typesByName = {}
end

function SplitTypeManager:loadMapData()
	SplitTypeManager:superClass().loadMapData(self)
	self:addSplitType("SPRUCE", "treeType_spruce", 1, 0.7, 3, true)
	self:addSplitType("PINE", "treeType_pine", 2, 0.7, 3, true)
	self:addSplitType("LARCH", "treeType_larch", 3, 0.7, 3, true)
	self:addSplitType("BIRCH", "treeType_birch", 4, 0.85, 3.2, false)
	self:addSplitType("BEECH", "treeType_beech", 5, 0.9, 3.4, false)
	self:addSplitType("MAPLE", "treeType_maple", 6, 0.9, 3.4, false)
	self:addSplitType("OAK", "treeType_oak", 7, 0.9, 3.4, false)
	self:addSplitType("ASH", "treeType_ash", 8, 0.9, 3.4, false)
	self:addSplitType("LOCUST", "treeType_locust", 9, 1, 3.8, false)
	self:addSplitType("MAHOGANY", "treeType_mahogany", 10, 1.1, 3, false)
	self:addSplitType("POPLAR", "treeType_poplar", 11, 0.7, 7.5, false)
	self:addSplitType("AMERICANELM", "treeType_americanElm", 12, 0.7, 3.5, false)
	self:addSplitType("CYPRESS", "treeType_cypress", 13, 0.7, 3.5, false)
	self:addSplitType("DOWNYSERVICEBERRY", "treeType_downyServiceberry", 14, 0.7, 3.5, false)
	self:addSplitType("PAGODADOGWOOD", "treeType_pagodaDogwood", 15, 0.7, 3.5, false)
	self:addSplitType("SHAGBARKHICKORY", "treeType_shagbarkHickory", 16, 0.7, 3.5, false)
	self:addSplitType("STONEPINE", "treeType_stonePine", 17, 0.7, 3.5, false)
	self:addSplitType("WILLOW", "treeType_willow", 18, 0.7, 3.5, false)
	self:addSplitType("OLIVETREE", "treeType_oliveTree", 19, 0.6, 3.5, false)

	return true
end

function SplitTypeManager:addSplitType(name, l10nKey, splitTypeIndex, pricePerLiter, woodChipsPerLiter, allowsWoodHarvester)
	if self.typesByIndex[splitTypeIndex] ~= nil then
		Logging.error("SplitTypeManager:addSplitType(): SplitTypeIndex '%d' is already in use for '%s'", splitTypeIndex, name)

		return
	end

	name = name:upper()

	if self.typesByName[name] ~= nil then
		Logging.error("SplitTypeManager:addSplitType(): SplitType name '%s' is already in use", name)

		return
	end

	local desc = {
		name = name,
		title = g_i18n:getText(l10nKey),
		splitTypeIndex = splitTypeIndex,
		pricePerLiter = pricePerLiter,
		woodChipsPerLiter = woodChipsPerLiter,
		allowsWoodHarvester = allowsWoodHarvester
	}
	self.typesByIndex[splitTypeIndex] = desc
	self.typesByName[name] = desc
end

function SplitTypeManager:getSplitTypeByIndex(index)
	return self.typesByIndex[index]
end

g_splitTypeManager = SplitTypeManager.new()
