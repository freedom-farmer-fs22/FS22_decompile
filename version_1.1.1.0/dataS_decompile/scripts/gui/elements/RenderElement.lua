RenderElement = {}
local RenderElement_mt = Class(RenderElement, GuiElement)

function RenderElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or RenderElement_mt)
	self.cameraPath = nil
	self.isRenderDirty = false
	self.overlay = 0
	self.shapesMask = 255
	self.lightMask = 67108864

	return self
end

function RenderElement:delete()
	self:destroyScene()
	RenderElement:superClass().delete(self)
end

function RenderElement:loadFromXML(xmlFile, key)
	RenderElement:superClass().loadFromXML(self, xmlFile, key)

	self.filename = getXMLString(xmlFile, key .. "#filename")
	self.cameraPath = getXMLString(xmlFile, key .. "#cameraNode")
	self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor")
	self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
	self.lightMask = getXMLInt(xmlFile, key .. "#lightMask") or self.lightMask

	self:addCallback(xmlFile, key .. "#onRenderLoad", "onRenderLoadCallback")
end

function RenderElement:loadProfile(profile, applyProfile)
	RenderElement:superClass().loadProfile(self, profile, applyProfile)

	self.filename = profile:getValue("filename")
	self.cameraPath = profile:getValue("cameraNode")
	self.superSamplingFactor = profile:getNumber("superSamplingFactor")

	if applyProfile then
		self:setScene(self.filename)
	end
end

function RenderElement:copyAttributes(src)
	RenderElement:superClass().copyAttributes(self, src)

	self.filename = src.filename
	self.cameraPath = src.cameraPath
	self.superSamplingFactor = src.superSamplingFactor
	self.onRenderLoadCallback = src.onRenderLoadCallback
end

function RenderElement:createScene()
	self:setScene(self.filename)
end

function RenderElement:destroyScene()
	if self.overlay ~= 0 then
		delete(self.overlay)

		self.overlay = 0
	end

	if self.scene then
		delete(self.scene)

		self.scene = nil
	end
end

function RenderElement:setScene(filename)
	if self.scene ~= nil then
		delete(self.scene)
	end

	self.isLoading = true
	self.filename = filename

	g_i3DManager:loadI3DFileAsync(filename, false, false, RenderElement.setSceneFinished, self, nil)
end

function RenderElement:setSceneFinished(node, failedReason, args)
	self.isLoading = false

	if failedReason == LoadI3DFailedReason.FILE_NOT_FOUND or failedReason == LoadI3DFailedReason.UNKNOWN then
		Logging.error("Failed to load character creation scene from '%s'", self.filename)
	end

	if node ~= 0 then
		self.scene = node

		link(getRootNode(), node)
		self:createOverlay()
	end
end

function RenderElement:createOverlay()
	if self.overlay ~= 0 then
		delete(self.overlay)

		self.overlay = 0
	end

	local resolutionX = math.ceil(g_screenWidth * self.absSize[1]) * self.superSamplingFactor
	local resolutionY = math.ceil(g_screenHeight * self.absSize[2]) * self.superSamplingFactor
	local aspectRatio = resolutionX / resolutionY
	local camera = I3DUtil.indexToObject(self.scene, self.cameraPath)

	if camera == nil then
		Logging.error("Could not find camera node '%s' in scene", self.cameraPath)
	else
		self.overlay = createRenderOverlay(camera, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightMask)
		self.isRenderDirty = true

		self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
	end
end

function RenderElement:update(dt)
	RenderElement:superClass().update(self, dt)

	if self.isRenderDirty and self.overlay ~= 0 then
		updateRenderOverlay(self.overlay)

		self.isRenderDirty = false
	end
end

function RenderElement:draw(clipX1, clipY1, clipX2, clipY2)
	if not self.isLoading and self.overlay ~= 0 then
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
			setOverlayUVs(self.overlay, u1, v1, u2, v2, u3, v3, u4, v4)
			renderOverlay(self.overlay, posX, posY, sizeX, sizeY)
		end
	end

	RenderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function RenderElement:canReceiveFocus()
	return false
end

function RenderElement:getSceneRoot()
	return self.scene
end

function RenderElement:setRenderDirty()
	self.isRenderDirty = true
end
