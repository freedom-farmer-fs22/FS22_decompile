PlaceableHotspot = {
	TYPE = {}
}
PlaceableHotspot.TYPE.LOADING = 1
PlaceableHotspot.TYPE.UNLOADING = 2
PlaceableHotspot.TYPE.UNLOADING_TRAIN = 3
PlaceableHotspot.TYPE.PRODUCTION_POINT = 4
PlaceableHotspot.TYPE.SHOP = 5
PlaceableHotspot.TYPE.FARM = 6
PlaceableHotspot.TYPE.FUEL = 7
PlaceableHotspot.TYPE.ELECTRICITY = 8
PlaceableHotspot.TYPE.SHOP_ANIMAL = 9
PlaceableHotspot.TYPE.CHICKEN = 10
PlaceableHotspot.TYPE.PIG = 11
PlaceableHotspot.TYPE.SHEEP = 12
PlaceableHotspot.TYPE.COW = 13
PlaceableHotspot.TYPE.HORSE = 14
PlaceableHotspot.TYPE.TRAIN = 15
PlaceableHotspot.TYPE.BEE = 16
PlaceableHotspot.TYPE.EXCLAMATION_MARK = 17
PlaceableHotspot.CATEGORY_MAPPING = {
	[PlaceableHotspot.TYPE.UNLOADING] = MapHotspot.CATEGORY_UNLOADING,
	[PlaceableHotspot.TYPE.UNLOADING_TRAIN] = MapHotspot.CATEGORY_UNLOADING,
	[PlaceableHotspot.TYPE.LOADING] = MapHotspot.CATEGORY_LOADING,
	[PlaceableHotspot.TYPE.PRODUCTION_POINT] = MapHotspot.CATEGORY_PRODUCTION,
	[PlaceableHotspot.TYPE.SHOP] = MapHotspot.CATEGORY_SHOP,
	[PlaceableHotspot.TYPE.FARM] = MapHotspot.CATEGORY_OTHER,
	[PlaceableHotspot.TYPE.FUEL] = MapHotspot.CATEGORY_LOADING,
	[PlaceableHotspot.TYPE.ELECTRICITY] = MapHotspot.CATEGORY_LOADING,
	[PlaceableHotspot.TYPE.EXCLAMATION_MARK] = MapHotspot.CATEGORY_OTHER,
	[PlaceableHotspot.TYPE.SHOP_ANIMAL] = MapHotspot.CATEGORY_SHOP,
	[PlaceableHotspot.TYPE.CHICKEN] = MapHotspot.CATEGORY_ANIMAL,
	[PlaceableHotspot.TYPE.PIG] = MapHotspot.CATEGORY_ANIMAL,
	[PlaceableHotspot.TYPE.SHEEP] = MapHotspot.CATEGORY_ANIMAL,
	[PlaceableHotspot.TYPE.COW] = MapHotspot.CATEGORY_ANIMAL,
	[PlaceableHotspot.TYPE.HORSE] = MapHotspot.CATEGORY_ANIMAL,
	[PlaceableHotspot.TYPE.TRAIN] = MapHotspot.CATEGORY_OTHER,
	[PlaceableHotspot.TYPE.BEE] = MapHotspot.CATEGORY_ANIMAL
}
PlaceableHotspot.FILE_RESOLUTION = {
	1024,
	512
}
PlaceableHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
PlaceableHotspot.UV = {
	[PlaceableHotspot.TYPE.UNLOADING] = GuiUtils.getUVs({
		4,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.UNLOADING_TRAIN] = GuiUtils.getUVs({
		112,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.PRODUCTION_POINT] = GuiUtils.getUVs({
		220,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.SHOP] = GuiUtils.getUVs({
		328,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.FARM] = GuiUtils.getUVs({
		436,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.FUEL] = GuiUtils.getUVs({
		544,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.ELECTRICITY] = GuiUtils.getUVs({
		652,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.EXCLAMATION_MARK] = GuiUtils.getUVs({
		760,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.LOADING] = GuiUtils.getUVs({
		868,
		219,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.SHOP_ANIMAL] = GuiUtils.getUVs({
		4,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.CHICKEN] = GuiUtils.getUVs({
		112,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.PIG] = GuiUtils.getUVs({
		220,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.SHEEP] = GuiUtils.getUVs({
		328,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.COW] = GuiUtils.getUVs({
		436,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.HORSE] = GuiUtils.getUVs({
		544,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.TRAIN] = GuiUtils.getUVs({
		652,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION),
	[PlaceableHotspot.TYPE.BEE] = GuiUtils.getUVs({
		760,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION)
}
local PlaceableHotspot_mt = Class(PlaceableHotspot, MapHotspot)

function PlaceableHotspot.new(customMt)
	local self = MapHotspot.new(customMt or PlaceableHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(60, 60)
	self.placeableType = PlaceableHotspot.TYPE.UNLOADING
	self.iconSmall = Overlay.new(PlaceableHotspot.FILENAME, 0, 0, self.width, self.height)

	self.iconSmall:setUVs(GuiUtils.getUVs({
		868,
		327,
		100,
		100
	}, PlaceableHotspot.FILE_RESOLUTION))

	self.lastRenderedIcon = self.iconSmall
	self.clickArea = MapHotspot.getClickArea({
		13,
		13,
		74,
		74
	}, {
		100,
		100
	}, math.rad(45))
	self.teleportWorldX = nil
	self.teleportWorldY = nil
	self.teleportWorldZ = nil
	self.name = nil

	return self
end

function PlaceableHotspot:delete()
	PlaceableHotspot:superClass().delete(self)

	if self.iconSmall ~= nil then
		self.iconSmall:delete()

		self.iconSmall = nil
	end
end

function PlaceableHotspot:getCategory()
	return PlaceableHotspot.CATEGORY_MAPPING[self.placeableType]
end

function PlaceableHotspot:setPlaceable(placeable)
	self.placeable = placeable

	self:createIcon()
	self:setPlaceableType(self.placeableType)
end

function PlaceableHotspot:getPlaceable()
	return self.placeable
end

function PlaceableHotspot:setPlaceableType(placeableType)
	self.placeableType = placeableType

	if self.icon ~= nil then
		self.icon:setUVs(PlaceableHotspot.UV[placeableType])
	end
end

function PlaceableHotspot:createIcon()
	if self.icon ~= nil then
		self.icon:delete()
	end

	self.icon = Overlay.new(PlaceableHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setColor(unpack(self.color))
	self.icon:setScale(self.scale, self.scale)
	self.icon:setUVs(PlaceableHotspot.UV[self.placeableType])
end

function PlaceableHotspot:setTeleportWorldPosition(x, y, z)
	self.teleportWorldZ = z
	self.teleportWorldY = y
	self.teleportWorldX = x
end

function PlaceableHotspot:getTeleportWorldPosition()
	return self.teleportWorldX, self.teleportWorldY, self.teleportWorldZ
end

function PlaceableHotspot:getBeVisited()
	return self.teleportWorldX ~= nil
end

function PlaceableHotspot:setScale(scale)
	self.iconSmall:setScale(scale, scale)
	PlaceableHotspot:superClass().setScale(self, scale)
end

function PlaceableHotspot:getWidth()
	return self.lastRenderedIcon.width
end

function PlaceableHotspot:getHeight()
	return self.lastRenderedIcon.height
end

function PlaceableHotspot:render(x, y, rotation, small)
	local icon = self.icon

	if small then
		icon = self.iconSmall
	end

	self.lastRenderedIcon = icon

	if icon ~= nil then
		icon:setPosition(x, y)
		icon:setRotation(rotation or 0, icon.width * 0.5, icon.height * 0.5)
		icon:setColor(nil, , , self.isBlinking and self:getCanBlink() and IngameMap.alpha or 1)
		icon:render()
	end
end

function PlaceableHotspot:getName()
	if self.name ~= nil then
		return self.name
	end

	if self.placeable ~= nil then
		return self.placeable:getName()
	end

	return nil
end

function PlaceableHotspot:setName(name)
	self.name = name
end

function PlaceableHotspot.getTypeByName(name)
	if name == nil then
		return nil
	end

	name = name:upper()

	return PlaceableHotspot.TYPE[name]
end
