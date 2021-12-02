GuiTopDownCursor = {}
local GuiTopDownCursor_mt = Class(GuiTopDownCursor)
GuiTopDownCursor.ROTATION_SPEED = 0.002
GuiTopDownCursor.SHAPES_FILENAME = "dataS/menu/construction/constructionCursorSimple.i3d"
GuiTopDownCursor.RAYCAST_DISTANCE = 150
GuiTopDownCursor.SHAPES = {
	SQUARE = 2,
	CIRCLE = 1,
	NONE = 0
}
GuiTopDownCursor.SHAPES_COLORS = {
	SUCCESS = 0,
	PAINTING = 4,
	SCULPTING = 2,
	SELECT = 3,
	ERROR = 1
}

function GuiTopDownCursor.new(subclass_mt, messageCenter, inputManager)
	local self = setmetatable({}, subclass_mt or GuiTopDownCursor_mt)
	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.isActive = false
	self.ray = {}
	self.cursorShapeHeights = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	self.isVisible = true
	self.rotationY = 0
	self.targetRotation = 0
	self.inputRotate = 0
	self.lastActionFrame = 0
	self.isCatchingCursor = false
	self.rotationEnabled = false
	self.lightEnabled = false
	self.selectionMode = false
	self.rayCollisionMask = CollisionMask.ALL - CollisionMask.TRIGGERS - CollisionFlag.FILLABLE - CollisionFlag.GROUND_TIP_BLOCKING

	self:setTerrainOnly(false)

	self.shapesLoaded = false

	return self
end

function GuiTopDownCursor:delete()
	if self.isActive then
		self:deactivate()
	end

	if self.cursorOverlay ~= nil then
		self.cursorOverlay:delete()

		self.cursorOverlay = nil
	end

	if self.rootNode ~= nil then
		delete(self.rootNode)
	end
end

function GuiTopDownCursor:loadShapes()
	self.rootNode = g_i3DManager:loadI3DFile(GuiTopDownCursor.SHAPES_FILENAME, false, false)

	link(getRootNode(), self.rootNode)

	self.shapeNode = getChildAt(self.rootNode, 0)

	setVisibility(self.rootNode, false)
	setWorldRotation(self.rootNode, 0, self.rotationY, 0)
	self:setShape(GuiTopDownCursor.SHAPES.NONE)
	self:setShapeSize(1)
	self:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT)
	self:setCursorTerrainOffset(false)

	self.shapesLoaded = true
	local uiScale = g_gameSettings:getValue("uiScale")
	local width, height = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
	self.cursorOverlay = Overlay.new(g_baseHUDFilename, 0.5, 0.5, width, height)

	self.cursorOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	self.cursorOverlay:setUVs(GuiUtils.getUVs({
		0,
		48,
		48,
		48
	}))
	self.cursorOverlay:setColor(1, 1, 1, 0.3)
end

function GuiTopDownCursor:activate()
	self.isActive = true

	self:onInputModeChanged({
		self.inputManager:getLastInputMode()
	})

	if not self.shapesLoaded then
		self:loadShapes()
	end

	setVisibility(self.rootNode, self.isVisible)
	self:registerActionEvents()
	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
end

function GuiTopDownCursor:deactivate()
	setVisibility(self.rootNode, false)
	self.messageCenter:unsubscribeAll(self)
	self:removeActionEvents()

	self.isActive = false
end

function GuiTopDownCursor:setCameraRay(x, y, z, dx, dy, dz)
	local ray = self.ray
	ray.dz = dz
	ray.dy = dy
	ray.dx = dx
	ray.z = z
	ray.y = y
	ray.x = x
end

function GuiTopDownCursor:setShape(shape)
	self.shape = shape

	setVisibility(self.shapeNode, shape ~= GuiTopDownCursor.SHAPES.NONE)

	local material = getMaterial(self.shapeNode, 0)

	if shape == GuiTopDownCursor.SHAPES.CIRCLE then
		setMaterialCustomShaderVariation(material, "circle", true)
	elseif shape == GuiTopDownCursor.SHAPES.SQUARE then
		setMaterialCustomShaderVariation(material, "square", true)
	end
end

function GuiTopDownCursor:setVisible(isVisible)
	self.isVisible = isVisible

	if self.rootNode ~= nil then
		setVisibility(self.rootNode, isVisible)
	end
end

function GuiTopDownCursor:setTerrainOnly(terrainOnly)
	self.hitTerrainOnly = terrainOnly
end

function GuiTopDownCursor:setSelectionMode(isSelection)
	self.selectionMode = isSelection

	if isSelection then
		self.rayCollisionMask = CollisionMask.ALL - CollisionMask.TRIGGERS - CollisionFlag.FILLABLE
	else
		self.rayCollisionMask = CollisionMask.ALL - CollisionMask.TRIGGERS - CollisionFlag.FILLABLE - CollisionFlag.GROUND_TIP_BLOCKING
	end
end

function GuiTopDownCursor:setRotationEnabled(isEnabled)
	if self.rotationEnabled ~= isEnabled then
		self.rotationEnabled = isEnabled

		if self.rotateEventId ~= nil then
			self.inputManager:setActionEventActive(self.rotateEventId, self.rotationEnabled)
		end
	end
end

function GuiTopDownCursor:setRotation(rotY)
	self.targetRotation = rotY
	self.rotationY = rotY
end

function GuiTopDownCursor:setLightEnabled(isEnabled)
	self.lightEnabled = isEnabled
end

function GuiTopDownCursor:setShapeSize(size)
	setScale(self.shapeNode, size, size, size)

	self.shapeScale = size
end

function GuiTopDownCursor:getMessagePosition()
	if self.isCatchingCursor then
		return nil
	end

	return self.mousePosX, self.mousePosY
end

function GuiTopDownCursor:setErrorMessage(message)
	local x, y = self:getMessagePosition()

	if x == nil then
		return
	end

	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)

	local textSize = getCorrectTextSize(0.016)
	x = x + 0.01

	setTextColor(0, 0, 0, 0.75)
	renderText(x, y - 0.0015, textSize, message)
	setTextColor(1, 0.5, 0.5, 1)
	renderText(x, y, textSize, message)
	setTextColor(1, 1, 1, 1)
end

function GuiTopDownCursor:setMessage(message)
	local x, y = self:getMessagePosition()

	if x == nil then
		return
	end

	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)

	local textSize = getCorrectTextSize(0.016)
	y = y + 0.01

	setTextColor(0, 0, 0, 0.75)
	renderText(x, y - 0.0015, textSize, message)
	setTextColor(1, 1, 1, 1)
	renderText(x, y, textSize, message)
	setTextColor(1, 1, 1, 1)
end

function GuiTopDownCursor:setColor(r, g, b, a)
	setShaderParameter(self.shapeNode, "colorInside", r, g, b, a, true)
	setShaderParameter(self.shapeNode, "colorOutside", r, g, b, 1, true)
end

function GuiTopDownCursor:setGradientColor(ri, gi, bi, ro, go, bo, a)
	setShaderParameter(self.shapeNode, "colorInside", ri, gi, bi, a, true)
	setShaderParameter(self.shapeNode, "colorOutside", ro, go, bo, 1, true)
end

function GuiTopDownCursor:setColorMode(mode)
	local alpha = 0.3

	if mode == GuiTopDownCursor.SHAPES_COLORS.SUCCESS then
		self:setColor(0, 1, 0, alpha)
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.ERROR then
		self:setColor(1, 0, 0, alpha)
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.SCULPTING then
		self:setGradientColor(1, 0, 0, 0, 1, 0, alpha)
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.SELECT then
		self:setColor(1, 1, 1, alpha)
	elseif mode == GuiTopDownCursor.SHAPES_COLORS.PAINTING then
		self:setColor(1, 1, 1, 0.25)
	end
end

function GuiTopDownCursor:setCursorTerrainOffset(isLarge)
	if isLarge then
		self.terrainBrushOffset = 0.5
	else
		self.terrainBrushOffset = 0.05
	end
end

function GuiTopDownCursor:getHitNode()
	if self.currentHitId ~= g_currentMission.terrainRootNode then
		return self.currentHitId
	end
end

function GuiTopDownCursor:getHitPlaceable()
	if self.currentHitId == nil or self.currentHitId == g_currentMission.terrainRootNode then
		return nil
	end

	local object = g_currentMission:getNodeObject(self.currentHitId)

	if object ~= nil and object:isa(Placeable) then
		return object
	end
end

function GuiTopDownCursor:getHitTerrainPosition()
	if self.currentHitId == g_currentMission.terrainRootNode then
		return self.currentHitX, self.currentHitY, self.currentHitZ
	end
end

function GuiTopDownCursor:getRotation()
	return self.rotationY % (2 * math.pi)
end

function GuiTopDownCursor:getPosition()
	return self.currentHitX, self.currentHitY, self.currentHitZ
end

function GuiTopDownCursor:update(dt)
	if self.isActive then
		self:updateRaycast()
		self:updateRotation(dt)
	end
end

function GuiTopDownCursor:draw()
	if not self.isMouseMode and self.selectionMode then
		self.cursorOverlay:render()
	end
end

function GuiTopDownCursor:updateRaycast()
	local ray = self.ray
	local cursorShouldBeVisible = false

	if ray.x == nil then
		self.currentHitId = nil
	else
		local id, x, y, z = RaycastUtil.raycastClosest(ray.x, ray.y, ray.z, ray.dx, ray.dy, ray.dz, GuiTopDownCursor.RAYCAST_DISTANCE, self.rayCollisionMask)
		self.currentHitZ = z
		self.currentHitY = y
		self.currentHitX = x
		self.currentHitId = id

		if id ~= nil then
			setWorldTranslation(self.rootNode, x, y, z)

			cursorShouldBeVisible = not self.hitTerrainOnly or g_currentMission.terrainRootNode == id

			if cursorShouldBeVisible and getVisibility(self.shapeNode) then
				self:updateCursorHeights(x, y, z, self.shapeScale)
			end
		end
	end

	self:setVisible(cursorShouldBeVisible)
end

function GuiTopDownCursor:updateRotation(dt)
	self.targetRotation = self.targetRotation - dt * self.inputRotate * GuiTopDownCursor.ROTATION_SPEED
	local rotateChange = (self.targetRotation - self.rotationY) / dt * 5

	if rotateChange < 0.0001 and rotateChange > -0.0001 then
		self.rotationY = self.targetRotation
	else
		self.rotationY = self.rotationY + rotateChange
	end

	self.inputRotate = 0
end

function GuiTopDownCursor:updateCursorHeights(x, y, z, scale)
	local offsetY = self.terrainBrushOffset - y
	local terrain = g_currentMission.terrainRootNode
	local h = self.cursorShapeHeights

	for i = 1, 8 do
		local offsetZ = 0.14285714285714285 * (i - 1) - 0.5
		local zs = z + offsetZ * scale

		for j = 1, 8 do
			local offsetX = (0.14285714285714285 * (j - 1) - 0.5) * scale
			h[j] = getTerrainHeightAtWorldPos(terrain, x + offsetX, 0, zs) + offsetY
		end

		local row = math.ceil(i / 2)
		local col = (i - 1) % 2 + 1

		setShaderParameter(self.shapeNode, "heights" .. row .. col * 2 - 1, h[1], h[2], h[3], h[4], true)
		setShaderParameter(self.shapeNode, "heights" .. row .. col * 2, h[5], h[6], h[7], h[8], true)
	end
end

function GuiTopDownCursor:registerActionEvents()
	local _, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CURSOR_ROTATE, self, self.onRotate, false, false, true, false)
	self.rotateEventId = eventId

	self.inputManager:setActionEventActive(self.rotateEventId, self.rotationEnabled)
	self.inputManager:setActionEventTextPriority(self.rotateEventId, GS_PRIO_NORMAL)
end

function GuiTopDownCursor:removeActionEvents()
	self.rotateEventId = nil

	self.inputManager:removeActionEventsByTarget(self)
end

function GuiTopDownCursor:mouseEvent(posX, posY, isDown, isUp, button)
	if self.mouseDisabled then
		return
	end

	if g_time <= self.lastActionFrame then
		return
	end

	if self.isCatchingCursor then
		self.isCatchingCursor = false

		self.inputManager:setShowMouseCursor(true, true)
		wrapMousePosition(self.lockedMousePosX, self.lockedMousePosY)

		self.inputManager.mousePosYLast = self.lockedMousePosY
		self.inputManager.mousePosXLast = self.lockedMousePosX
		self.mousePosX = self.lockedMousePosX
		self.mousePosY = self.lockedMousePosY
	elseif self.isMouseMode then
		self.mousePosX = posX
		self.mousePosY = posY
	end
end

function GuiTopDownCursor:onRotate(_, inputValue, _, isAnalog, isMouse)
	if isMouse and self.mouseDisabled then
		return
	end

	if isMouse then
		self.lastActionFrame = g_time

		if not self.isCatchingCursor then
			self.lockedMousePosY = self.inputManager.mousePosYLast or 0.5
			self.lockedMousePosX = self.inputManager.mousePosXLast or 0.5

			self.inputManager:setShowMouseCursor(false, true)

			self.isCatchingCursor = true
		end
	end

	if isMouse and isAnalog then
		inputValue = inputValue * 3
	end

	self.inputRotate = inputValue
end

function GuiTopDownCursor:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD

	if not self.isMouseMode then
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	end
end
