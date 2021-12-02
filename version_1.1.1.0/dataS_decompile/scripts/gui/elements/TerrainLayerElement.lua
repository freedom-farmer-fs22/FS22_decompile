TerrainLayerElement = {}
local TerrainLayerElement_mt = Class(TerrainLayerElement, GuiElement)

function TerrainLayerElement.new(target, custom_mt)
	local self = TerrainLayerElement:superClass().new(target, custom_mt or TerrainLayerElement_mt)
	self.terrainLayerTextureOverlay = nil

	return self
end

function TerrainLayerElement:delete()
	self:destroyOverlay(self.terrainRootNode)
	TerrainLayerElement:superClass().delete(self)
end

function TerrainLayerElement:copyAttributes(src)
	TerrainLayerElement:superClass().copyAttributes(self, src)
	self:setTerrainLayer(src.terrainRootNode, src.layer)
end

function TerrainLayerElement:setTerrainLayer(terrainRootNode, layer)
	if layer ~= nil then
		if self.terrainLayerTextureOverlay == nil then
			self:createOverlay(terrainRootNode)
		end

		local displayLayer = getTerrainLayerSubLayer(terrainRootNode, layer, 0)

		setOverlayLayer(self.terrainLayerTextureOverlay, displayLayer)

		self.layer = layer
	end
end

function TerrainLayerElement:createOverlay(terrainRootNode)
	self.terrainRootNode = terrainRootNode
	local terrainLayerTexture = createTerrainLayerTexture(g_currentMission.terrainRootNode)
	self.terrainLayerTextureOverlay = createImageOverlayWithTexture(terrainLayerTexture)

	delete(terrainLayerTexture)
end

function TerrainLayerElement:destroyOverlay(terrainRootNode)
	if self.terrainRootNode ~= nil and self.terrainRootNode == terrainRootNode then
		if self.terrainLayerTextureOverlay ~= nil then
			delete(self.terrainLayerTextureOverlay)

			self.terrainLayerTextureOverlay = nil
		end

		self.terrainRootNode = nil
	end
end

function TerrainLayerElement:draw(clipX1, clipY1, clipX2, clipY2)
	local posX = self.absPosition[1]
	local posY = self.absPosition[2]
	local sizeX = self.size[1]
	local sizeY = self.size[2]
	local u1 = 0
	local v1 = 0
	local u2 = 0
	local v2 = 1
	local u3 = 1
	local v3 = 0
	local u4 = 1
	local v4 = 1

	if clipX1 ~= nil then
		local oldX1 = posX
		local oldY1 = posY
		local oldX2 = sizeX + posX
		local oldY2 = sizeY + posY
		local posX2 = posX + sizeX
		local posY2 = posY + sizeY
		posX = math.max(posX, clipX1)
		posY = math.max(posY, clipY1)
		sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
		sizeY = math.max(math.min(posY2, clipY2) - posY, 0)
		local p1 = (posX - oldX1) / (oldX2 - oldX1)
		local p2 = (posY - oldY1) / (oldY2 - oldY1)
		local p3 = (posX + sizeX - oldX1) / (oldX2 - oldX1)
		local p4 = (posY + sizeY - oldY1) / (oldY2 - oldY1)
		u1 = p1
		v1 = p2
		u2 = p1
		v2 = p4
		u3 = p3
		v3 = p2
		u4 = p3
		v4 = p4
	end

	if u1 ~= u3 and v1 ~= v2 then
		setOverlayUVs(self.terrainLayerTextureOverlay, u1, v1, u2, v2, u3, v3, u4, v4)
		renderOverlay(self.terrainLayerTextureOverlay, posX, posY, sizeX, sizeY)
	end

	TerrainLayerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function TerrainLayerElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end

	for _, v in ipairs(self.elements) do
		if not v:canReceiveFocus() then
			return false
		end
	end

	return true
end

function TerrainLayerElement:getFocusTarget()
	if #self.elements > 0 then
		local _, firstElement = next(self.elements)

		if firstElement then
			return firstElement
		end
	end

	return self
end

function TerrainLayerElement:reset()
	self:destroyOverlay(self.terrainRootNode)
end
