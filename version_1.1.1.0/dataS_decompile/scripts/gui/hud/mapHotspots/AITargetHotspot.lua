AITargetHotspot = {
	FILE_RESOLUTION = {
		1024,
		512
	}
}
AITargetHotspot.UVS = GuiUtils.getUVs({
	868,
	4,
	100,
	100
}, AITargetHotspot.FILE_RESOLUTION)
AITargetHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
local AITargetHotspot_mt = Class(AITargetHotspot, MapHotspot)

function AITargetHotspot.new(customMt)
	local self = MapHotspot.new(customMt or AITargetHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(80, 80)
	self.icon = Overlay.new(AITargetHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setUVs(AITargetHotspot.UVS)

	return self
end

function AITargetHotspot:getCategory()
	return MapHotspot.CATEGORY_AI
end

function AITargetHotspot:getIsPersistent()
	return true
end

function AITargetHotspot:getRenderLast()
	return true
end
