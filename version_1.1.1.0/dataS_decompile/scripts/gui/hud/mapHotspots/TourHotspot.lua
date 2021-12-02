TourHotspot = {
	FILE_RESOLUTION = {
		1024,
		512
	}
}
TourHotspot.UVS = GuiUtils.getUVs({
	760,
	219,
	100,
	100
}, TourHotspot.FILE_RESOLUTION)
TourHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
local TourHotspot_mt = Class(TourHotspot, MapHotspot)

function TourHotspot.new(customMt)
	local self = MapHotspot.new(customMt or TourHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(60, 60)
	self.icon = Overlay.new(TourHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setUVs(TourHotspot.UVS)

	self.isVisible = false

	return self
end

function TourHotspot:getCategory()
	return MapHotspot.CATEGORY_TOUR
end

function TourHotspot:getIsPersistent()
	return true
end

function TourHotspot:getRenderLast()
	return true
end
