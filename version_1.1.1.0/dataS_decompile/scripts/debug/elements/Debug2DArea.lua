Debug2DArea = {}
local Debug2DArea_mt = Class(Debug2DArea)

function Debug2DArea.new(filled, doubleSided, color, alignToTerrain, customMt)
	local self = setmetatable({}, customMt or Debug2DArea_mt)
	self.color = color or {
		1,
		1,
		1,
		1
	}
	self.filled = Utils.getNoNil(filled, false)
	self.alignToTerrain = Utils.getNoNil(alignToTerrain, true)
	self.doubleSided = Utils.getNoNil(doubleSided, false)
	self.positionNodes = {
		{
			-1,
			0,
			-1
		},
		{
			1,
			0,
			-1
		},
		{
			1,
			0,
			1
		},
		{
			-1,
			0,
			1
		},
		{
			-1,
			0,
			-1
		},
		{
			1,
			0,
			-1
		},
		{
			1,
			0,
			1
		},
		{
			-1,
			0,
			1
		}
	}

	return self
end

function Debug2DArea:delete()
end

function Debug2DArea:update(dt)
end

function Debug2DArea:draw()
	if g_currentMission.terrainRootNode == nil then
		return
	end

	local r, g, b, a = unpack(self.color)
	local pos = self.positionNodes
	local x1 = pos[1][1]
	local y1 = pos[1][2]
	local z1 = pos[1][3]
	local x2 = pos[2][1]
	local y2 = pos[2][2]
	local z2 = pos[2][3]
	local x3 = pos[3][1]
	local y3 = pos[3][2]
	local z3 = pos[3][3]
	local x4 = pos[4][1]
	local y4 = pos[4][2]
	local z4 = pos[4][3]

	if self.alignToTerrain then
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + 0.01
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + 0.01
		y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3) + 0.01
		y4 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x4, 0, z4) + 0.01
	end

	if self.filled then
		drawDebugTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a, false)
		drawDebugTriangle(x1, y1, z1, x3, y3, z3, x4, y4, z4, r, g, b, a, false)

		if self.doubleSided then
			drawDebugTriangle(x3, y3, z3, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
			drawDebugTriangle(x4, y4, z4, x3, y3, z3, x1, y1, z1, r, g, b, a, false)
		end
	else
		drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
		drawDebugLine(x2, y2, z2, r, g, b, x3, y3, z3, r, g, b)
		drawDebugLine(x3, y3, z3, r, g, b, x4, y4, z4, r, g, b)
		drawDebugLine(x4, y4, z4, r, g, b, x1, y1, z1, r, g, b)
	end
end

function Debug2DArea:setColor(r, g, b, a, isFilled)
	self.isFilled = Utils.getNoNil(isFilled, self.isFilled)
	self.color = {
		r,
		g,
		b,
		a
	}
end

function Debug2DArea:createWithNodes(startNode, widthNode, heightNode)
	local startX, startY, startZ = getWorldTranslation(startNode)
	local widthX, widthY, widthZ = getWorldTranslation(widthNode)
	local heightX, heightY, heightZ = getWorldTranslation(heightNode)

	self:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
end

function Debug2DArea:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
	if startY == nil then
		startY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, startX, 0, startZ)
	end

	if widthY == nil then
		widthY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, widthX, 0, widthZ)
	end

	if heightY == nil then
		heightY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, heightX, 0, heightZ)
	end

	local dirX = widthX - startX
	local dirY = widthY - startY
	local dirZ = widthZ - startZ
	local normX = heightX - startX
	local normY = heightY - startY
	local normZ = heightZ - startZ
	local offsetX = dirX + normX
	local offsetY = dirY + normY
	local offsetZ = dirZ + normZ
	local pos = self.positionNodes
	pos[1] = {
		startX,
		startY,
		startZ
	}
	pos[2] = {
		widthX,
		widthY,
		widthZ
	}
	pos[3] = {
		startX + offsetX,
		startY + offsetY,
		startZ + offsetZ
	}
	pos[4] = {
		heightX,
		heightY,
		heightZ
	}
end

function Debug2DArea:createWithStartEnd(startNode, endNode)
	local offsetX, offsetY, offsetZ = localToLocal(endNode, startNode, 0, 0, 0)
	local x, y, z = localToWorld(startNode, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
	local sizeX = math.abs(offsetX)
	local sizeZ = math.abs(offsetZ)
	local dirX, _, dirZ = localDirectionToWorld(startNode, 0, 0, 1)

	self:createFromPosAndDir(x, y, z, dirX, 0, dirZ, 0, 1, 0, sizeX, sizeZ)
end

function Debug2DArea:createSimple(x, y, z, size)
	self:createFromPosAndDir(x, y, z, 0, 0, 1, 0, 1, 0, size, size)
end

function Debug2DArea:createWithSizeAndOffset(node, width, length, widthOffset, lengthOffset)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
	local x, y, z = getWorldTranslation(node)
	x, y, z = MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, widthOffset, 0, lengthOffset)

	self:createFromPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, width, length)
end

function Debug2DArea:createFromPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, width, length)
	local halfWidth = width * 0.5
	local halfLength = length * 0.5
	local pos = self.positionNodes
	pos[1] = {
		MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -halfWidth, 0, -halfLength)
	}
	pos[2] = {
		MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -halfWidth, 0, halfLength)
	}
	pos[3] = {
		MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, halfWidth, 0, halfLength)
	}
	pos[4] = {
		MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, halfWidth, 0, -halfLength)
	}
end

function Debug2DArea:createWithNode(node, sizeX, sizeZ)
	local sizeXHalf = sizeX * 0.5
	local sizeZHalf = sizeZ * 0.5
	local pos = self.positionNodes
	pos[1] = {
		localToWorld(node, -sizeXHalf, 0, -sizeZHalf)
	}
	pos[2] = {
		localToWorld(node, -sizeXHalf, 0, sizeZHalf)
	}
	pos[3] = {
		localToWorld(node, sizeXHalf, 0, sizeZHalf)
	}
	pos[4] = {
		localToWorld(node, sizeXHalf, 0, -sizeZHalf)
	}
end
