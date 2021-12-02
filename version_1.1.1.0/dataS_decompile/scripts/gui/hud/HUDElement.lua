HUDElement = {}
local HUDElement_mt = Class(HUDElement)

function HUDElement.new(overlay, parentHudElement, customMt)
	local self = setmetatable({}, customMt or HUDElement_mt)
	self.overlay = overlay
	self.children = {}
	self.pivotX = 0
	self.pivotY = 0
	self.defaultPivotX = 0
	self.defaultPivotY = 0
	self.animation = TweenSequence.NO_SEQUENCE
	self.parent = nil

	if parentHudElement then
		parentHudElement:addChild(self)
	end

	return self
end

function HUDElement:delete()
	if self.overlay ~= nil then
		self.overlay:delete()

		self.overlay = nil
	end

	if self.parent ~= nil then
		self.parent:removeChild(self)
	end

	self.parent = nil

	for k, v in pairs(self.children) do
		v.parent = nil

		v:delete()

		self.children[k] = nil
	end
end

function HUDElement:addChild(childHudElement)
	if childHudElement.parent == self then
		return
	end

	if childHudElement.parent ~= nil then
		childHudElement.parent:removeChild(childHudElement)
	end

	table.insert(self.children, childHudElement)

	childHudElement.parent = self
end

function HUDElement:removeChild(childHudElement)
	if childHudElement.parent == self then
		for i, child in ipairs(self.children) do
			if child == childHudElement then
				child.parent = nil

				table.remove(self.children, i)

				return
			end
		end
	end
end

function HUDElement:setPosition(x, y)
	local prevX, prevY = self:getPosition()
	x = x or prevX
	y = y or prevY

	self.overlay:setPosition(x, y)

	if #self.children > 0 then
		local moveX = x - prevX
		local moveY = y - prevY

		for _, child in pairs(self.children) do
			local childX, childY = child:getPosition()

			assertWithCallstack(childY ~= nil)
			child:setPosition(childX + moveX, childY + moveY)
		end
	end
end

function HUDElement:setRotation(rotation, centerX, centerY)
	self.overlay:setRotation(rotation, centerX or self.pivotX, centerY or self.pivotY)
end

function HUDElement:setRotationPivot(pivotX, pivotY)
	self.pivotY = pivotY or self.defaultPivotY
	self.pivotX = pivotX or self.defaultPivotX
	self.defaultPivotY = pivotY or self.defaultPivotY
	self.defaultPivotX = pivotX or self.defaultPivotX
end

function HUDElement:getRotationPivot()
	return self.pivotX, self.pivotY
end

function HUDElement:getPosition()
	return self.overlay:getPosition()
end

function HUDElement:setScale(scaleWidth, scaleHeight)
	local prevSelfX, prevSelfY = self:getPosition()
	local prevScaleWidth, prevScaleHeight = self:getScale()

	self.overlay:setScale(scaleWidth, scaleHeight)

	local selfX, selfY = self:getPosition()

	if #self.children > 0 then
		local changeFactorX = scaleWidth / prevScaleWidth
		local changeFactorY = scaleHeight / prevScaleHeight

		for _, child in pairs(self.children) do
			local childScaleWidth, childScaleHeight = child:getScale()
			local childPrevX, childPrevY = child:getPosition()
			local offX = childPrevX - prevSelfX
			local offY = childPrevY - prevSelfY
			local posX = selfX + offX * changeFactorX
			local posY = selfY + offY * changeFactorY

			child:setPosition(posX, posY)
			child:setScale(childScaleWidth * changeFactorX, childScaleHeight * changeFactorY)
		end
	end

	self.pivotX = self.defaultPivotX * scaleWidth
	self.pivotY = self.defaultPivotY * scaleHeight
end

function HUDElement:getScale()
	return self.overlay:getScale()
end

function HUDElement:setAlignment(vertical, horizontal)
	self.overlay:setAlignment(vertical, horizontal)
end

function HUDElement:setVisible(isVisible)
	if self.overlay ~= nil then
		self.overlay.visible = isVisible
	end
end

function HUDElement:getVisible()
	return self.overlay.visible
end

function HUDElement:getColor()
	return self.overlay.r, self.overlay.g, self.overlay.b, self.overlay.a
end

function HUDElement:getAlpha()
	return self.overlay.a
end

function HUDElement:getWidth()
	return self.overlay.width
end

function HUDElement:getHeight()
	return self.overlay.height
end

function HUDElement:setDimension(width, height)
	self.overlay:setDimension(width, height)
end

function HUDElement:resetDimensions()
	self.overlay:resetDimensions()

	self.pivotX = self.defaultPivotX
	self.pivotY = self.defaultPivotY
end

function HUDElement:setColor(r, g, b, a)
	self.overlay:setColor(r, g, b, a)
end

function HUDElement:setAlpha(alpha)
	self.overlay:setColor(nil, , , alpha)
end

function HUDElement:setImage(imageFilename)
	self.overlay:setImage(imageFilename)
end

function HUDElement:setUVs(uvs)
	self.overlay:setUVs(uvs)
end

function HUDElement:update(dt)
	if not self.animation:getFinished() then
		self.animation:update(dt)
	end
end

function HUDElement:draw()
	if self.overlay.visible then
		self.overlay:render()

		for _, child in ipairs(self.children) do
			child:draw()
		end
	end
end

function HUDElement:scalePixelToScreenVector(vector2D)
	return vector2D[1] * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth, vector2D[2] * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end

function HUDElement:scalePixelToScreenHeight(height)
	return height * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end

function HUDElement:scalePixelToScreenWidth(width)
	return width * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth
end

function HUDElement:normalizeUVPivot(uvPivot, size, uvs)
	return self:scalePixelToScreenWidth(uvPivot[1] * size[1] / uvs[3]), self:scalePixelToScreenHeight(uvPivot[2] * size[2] / uvs[4])
end

HUDElement.UV = {
	FILL = {
		8,
		8,
		1,
		1
	}
}
HUDElement.TEXT_SIZE = {
	DEFAULT_TITLE = "20",
	DEFAULT_TEXT = "16"
}
