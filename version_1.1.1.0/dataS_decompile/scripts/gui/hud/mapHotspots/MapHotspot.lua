MapHotspot = {
	CATEGORY_FIELD = 1,
	CATEGORY_ANIMAL = 2,
	CATEGORY_MISSION = 3,
	CATEGORY_TOUR = 4,
	CATEGORY_STEERABLE = 5,
	CATEGORY_COMBINE = 6,
	CATEGORY_TRAILER = 7,
	CATEGORY_TOOL = 8,
	CATEGORY_UNLOADING = 9,
	CATEGORY_LOADING = 10,
	CATEGORY_PRODUCTION = 11,
	CATEGORY_SHOP = 12,
	CATEGORY_OTHER = 13,
	CATEGORY_AI = 14,
	CATEGORY_PLAYER = 15
}
MapHotspot.CATEGORY_DEFAULT = MapHotspot.CATEGORY_OTHER
MapHotspot.AREA = {
	RECTANGLE = 1,
	CIRCLE = 2
}
local MapHotspot_mt = Class(MapHotspot)

function MapHotspot.new(customMt)
	local self = setmetatable({}, customMt or MapHotspot_mt)
	self.isVisible = true
	self.isBlinking = false
	self.isPersistent = false
	self.worldZ = 0
	self.worldX = 0
	self.worldRotation = 0
	self.scale = 1
	self.color = {
		1,
		1,
		1,
		1
	}
	self.lastScreenPositionX = 0
	self.lastScreenPositionY = 0
	self.lastScreenRotation = 0
	self.lastScreenLayout = nil
	self.icon = nil
	self.clickArea = nil
	self.ownerFarmId = AccessHandler.EVERYONE

	return self
end

function MapHotspot:delete()
	if self.icon ~= nil then
		self.icon:delete()

		self.icon = nil
	end
end

function MapHotspot:getCategory()
	return MapHotspot.CATEGORY_DEFAULT
end

function MapHotspot:getIsPersistent()
	return self.isPersistent
end

function MapHotspot:setPersistent(isPersistent)
	self.isPersistent = isPersistent
end

function MapHotspot:getRenderLast()
	return false
end

function MapHotspot:setVisible(isVisible)
	self.isVisible = isVisible
end

function MapHotspot:getIsVisible()
	return self.isVisible
end

function MapHotspot:setBlinking(isBlinking)
	self.isBlinking = isBlinking
end

function MapHotspot:setWorldPosition(x, z)
	self.worldZ = z
	self.worldX = x
end

function MapHotspot:getWorldPosition()
	return self.worldX, self.worldZ
end

function MapHotspot:setLastRenderInfo(x, y, rotation, layout)
	self.lastScreenPositionX = x
	self.lastScreenPositionY = y
	self.lastScreenRotation = rotation
	self.lastScreenLayout = layout
end

function MapHotspot:getLastScreenPosition()
	return self.lastScreenPositionX, self.lastScreenPositionY, self.lastScreenRotation
end

function MapHotspot:getLastScreenPositionCenter()
	return self.lastScreenPositionX + self:getWidth() * 0.5, self.lastScreenPositionY + self:getHeight() * 0.5
end

function MapHotspot:setWorldRotation(rotation)
	self.worldRotation = rotation
end

function MapHotspot:getWorldRotation()
	return self.worldRotation
end

function MapHotspot:getWidth()
	if self.icon ~= nil then
		return self.icon.width
	end

	return 0
end

function MapHotspot:getHeight()
	if self.icon ~= nil then
		return self.icon.height
	end

	return 0
end

function MapHotspot:setScale(scale)
	self.scale = scale

	if self.icon ~= nil then
		self.icon:setScale(scale, scale)
	end
end

function MapHotspot:setSelected(isSelected)
	self.isSelected = isSelected
end

function MapHotspot:setOwnerFarmId(farmId)
	if farmId == nil then
		farmId = AccessHandler.EVERYONE
	end

	self.ownerFarmId = farmId
end

function MapHotspot:getCanBeAccessed()
	return self.ownerFarmId == AccessHandler.EVERYONE or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId)
end

function MapHotspot:getCanBlink()
	return true
end

function MapHotspot:setColor(r, g, b)
	self.color[1] = r
	self.color[2] = g
	self.color[3] = b
end

function MapHotspot:getColor()
	return self.color
end

function MapHotspot:render(x, y, rotation, small)
	local icon = self.icon

	if icon ~= nil then
		icon:setPosition(x, y)
		icon:setRotation(rotation or 0, icon.width * 0.5, icon.height * 0.5)

		local r, g, b = unpack(self:getColor())

		icon:setColor(r, g, b, self.isBlinking and self:getCanBlink() and IngameMap.alpha or 1)
		icon:render()
	end
end

function MapHotspot:hasMouseOverlap(x, y)
	local areaType = nil

	if self.clickArea ~= nil then
		areaType = self.clickArea.areaType
	end

	if areaType == MapHotspot.AREA.RECTANGLE then
		return self:checkOverlapRectangle(x, y, self.clickArea)
	elseif areaType == MapHotspot.AREA.CIRCLE then
		return self:checkOverlapCircle(x, y, self.clickArea)
	end

	return false
end

function MapHotspot:checkOverlapRectangle(x, y, clickArea)
	local width = self:getWidth()
	local height = self:getHeight()
	local lastX = self.lastScreenPositionX
	local lastY = self.lastScreenPositionY
	local area = clickArea.area
	local startX = lastX + area[1] * width
	local endX = startX + area[3] * width
	local startY = lastY + area[2] * height
	local endY = startY + area[4] * height
	local centerX = lastX + width * 0.5
	local centerY = lastY + height * 0.5
	local rotation = self.lastScreenRotation + clickArea.rotation
	local cosRot = math.cos(-rotation)
	local sinRot = math.sin(-rotation)
	local offsetX = (x - centerX) * g_screenAspectRatio
	local offsetY = y - centerY
	x = centerX + (cosRot * offsetX - sinRot * offsetY) / g_screenAspectRatio
	y = centerY + sinRot * offsetX + cosRot * offsetY
	local isInRange = startX <= x and x <= endX and startY <= y and y <= endY

	return isInRange
end

function MapHotspot:checkOverlapCircle(x, y, clickArea)
	local width = self:getWidth()
	local height = self:getHeight()
	local lastX = self.lastScreenPositionX
	local lastY = self.lastScreenPositionY
	local centerX = lastX + width * 0.5
	local centerY = lastY + height * 0.5
	local distanceX = (x - centerX) * g_screenAspectRatio
	local distanceY = y - centerY
	local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY) / g_screenAspectRatio
	local radius = width * clickArea.radiusFactor

	return distance <= radius
end

function MapHotspot.getClickArea(area, refSize, rotation)
	local startX = area[1] / refSize[1]
	local startY = area[2] / refSize[2]
	local width = area[3] / refSize[1]
	local height = area[4] / refSize[2]

	return {
		areaType = MapHotspot.AREA.RECTANGLE,
		area = {
			startX,
			startY,
			width,
			height
		},
		rotation = rotation
	}
end

function MapHotspot.getClickCircle(radiusFactor)
	return {
		areaType = MapHotspot.AREA.CIRCLE,
		radiusFactor = radiusFactor
	}
end
