DebugBitVectorMap = {}
local DebugBitVectorMap_mt = Class(DebugBitVectorMap)

function DebugBitVectorMap.new(radius, resolution, opacity, yOffset, customMt)
	local self = setmetatable({}, customMt or DebugBitVectorMap_mt)
	self.radius = radius or 15
	self.resolution = resolution or 0.5
	self.colorPos = {
		0,
		1,
		0,
		opacity
	}
	self.colorNeg = {
		1,
		0,
		0,
		opacity
	}
	self.yOffset = yOffset or 0.1

	return self
end

function DebugBitVectorMap:delete()
end

function DebugBitVectorMap:update(dt)
end

function DebugBitVectorMap:draw()
	if self.aiVehicle ~= nil then
		if not self.aiVehicle.isDeleted and not self.aiVehicle.isDeleting then
			local cx, _, cz = getWorldTranslation(self.aiVehicle.rootNode)

			self:drawAroundCenter(cx, cz, DebugBitVectorMap.aiAreaCheck)
		end
	elseif self.customFunc ~= nil then
		local cx, _, cz = getWorldTranslation(getCamera())

		self:drawAroundCenter(cx, cz, self.customFunc)
	end
end

function DebugBitVectorMap:createWithAIVehicle(vehicle)
	self.aiVehicle = vehicle
end

function DebugBitVectorMap:createWithCustomFunc(customFunc)
	self.customFunc = customFunc
end

function DebugBitVectorMap:setAdditionalDrawInfoFunc(drawInfoFunc)
	self.drawInfoFunc = drawInfoFunc
end

function DebugBitVectorMap:drawAroundCenter(x, z, func)
	local resolution = self.resolution
	local colorPos = self.colorPos
	local colorNeg = self.colorNeg
	local steps = math.ceil(self.radius / resolution) * 2
	z = math.floor(z)
	x = math.floor(x)

	for xStep = 0, steps do
		for zStep = 0, steps do
			local startWorldX = x + (xStep - steps * 0.5) * resolution
			local startWorldZ = z + (zStep - steps * 0.5) * resolution
			local widthWorldX = x + (xStep + 1 - steps * 0.5) * resolution
			local widthWorldZ = z + (zStep - steps * 0.5) * resolution
			local heightWorldX = x + (xStep - steps * 0.5) * resolution
			local heightWorldZ = z + (zStep + 1 - steps * 0.5) * resolution
			local area, areaTotal = func(self, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			local color = area > 0 and colorPos or colorNeg
			startWorldZ = startWorldZ + resolution * 0.1
			startWorldX = startWorldX + resolution * 0.1
			widthWorldZ = widthWorldZ + resolution * 0.1
			widthWorldX = widthWorldX - resolution * 0.1
			heightWorldZ = heightWorldZ - resolution * 0.1
			heightWorldX = heightWorldX + resolution * 0.1

			self:drawDebugAreaRectangleFilled(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, color[1], color[2], color[3], color[4])

			if self.drawInfoFunc ~= nil then
				self:drawInfoFunc((startWorldX + widthWorldX) * 0.5, (startWorldZ + heightWorldZ) * 0.5, area, areaTotal)
			end
		end
	end
end

function DebugBitVectorMap:drawDebugAreaRectangleFilled(x, z, x1, z1, x2, z2, r, g, b, a)
	local x3 = x1
	local z3 = z2
	local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + self.yOffset
	local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + self.yOffset
	local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + self.yOffset
	local y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3) + self.yOffset

	drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
	drawDebugTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a, false)
end

function DebugBitVectorMap:aiAreaCheck(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return AIVehicleUtil.getAIAreaOfVehicle(self.aiVehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false)
end
