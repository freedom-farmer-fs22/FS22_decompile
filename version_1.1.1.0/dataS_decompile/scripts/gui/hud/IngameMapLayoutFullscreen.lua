IngameMapLayoutFullscreen = {}
local IngameMapLayoutFullscreen_mt = Class(IngameMapLayoutFullscreen, IngameMapLayout)

function IngameMapLayoutFullscreen.new()
	local self = IngameMapLayoutFullscreen:superClass().new(IngameMapLayoutFullscreen_mt)
	self.mapCenterY = 0.5
	self.mapCenterX = 0.5
	self.zoomFactor = 1

	return self
end

function IngameMapLayoutFullscreen:delete()
end

function IngameMapLayoutFullscreen:createComponents(element, hudAtlasPath)
end

function IngameMapLayoutFullscreen:storeScaledValues(element, uiScale)
end

function IngameMapLayoutFullscreen:drawBefore()
end

function IngameMapLayoutFullscreen:drawAfter()
end

function IngameMapLayoutFullscreen:getMapSize()
	local height = 2 * self.zoomFactor

	return height / g_screenAspectRatio, height
end

function IngameMapLayoutFullscreen:getMapPosition()
	local width, height = self:getMapSize()

	return self.mapCenterX - width * 0.5, self.mapCenterY - height * 0.5
end

function IngameMapLayoutFullscreen:setMapCenter(x, y)
	self.mapCenterY = y
	self.mapCenterX = x
end

function IngameMapLayoutFullscreen:setMapZoom(zoomFactor)
	self.zoomFactor = zoomFactor
end

function IngameMapLayoutFullscreen:getIconZoom()
	return 0.25 + self.zoomFactor * 0.25
end

function IngameMapLayoutFullscreen:getBlinkPlayerArrow()
	return true
end

function IngameMapLayoutFullscreen:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local mapWidth, mapHeight = self:getMapSize()
	local mapX, mapY = self:getMapPosition()
	local objectX = objectU * mapWidth + mapX - width * 0.5
	local objectY = (1 - objectV) * mapHeight + mapY - height * 0.5

	return objectX, objectY, rot, true
end
