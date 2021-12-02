MissionHotspot = {
	FILE_RESOLUTION = {
		1024,
		512
	}
}
MissionHotspot.UVS = GuiUtils.getUVs({
	760,
	219,
	100,
	100
}, MissionHotspot.FILE_RESOLUTION)
MissionHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
local MissionHotspot_mt = Class(MissionHotspot, MapHotspot)

function MissionHotspot.new(customMt)
	local self = MapHotspot.new(customMt or MissionHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(60, 60)
	self.icon = Overlay.new(MissionHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setUVs(MissionHotspot.UVS)

	return self
end

function MissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function MissionHotspot:getIsPersistent()
	return true
end

function MissionHotspot:getRenderLast()
	return true
end

function MissionHotspot:render(x, y, rotation, small)
	local icon = self.icon

	if icon ~= nil then
		icon:setPosition(x, y)

		if self.isBlinking and self:getCanBlink() then
			icon:setColor(nil, , , IngameMap.alpha)
		end

		icon:render()
	end
end
