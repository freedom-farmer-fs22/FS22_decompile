GuiTopDownCamera = {}
local GuiTopDownCamera_mt = Class(GuiTopDownCamera)
GuiTopDownCamera.TERRAIN_BORDER = 40
GuiTopDownCamera.INPUT_MOVE_FACTOR = 0.88
GuiTopDownCamera.MOVE_SPEED = 0.01
GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR = 1
GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR = 8
GuiTopDownCamera.ROTATION_SPEED = 0.0005
GuiTopDownCamera.ROTATION_MIN_X_NEAR = 10
GuiTopDownCamera.ROTATION_MAX_X_NEAR = 90
GuiTopDownCamera.ROTATION_MIN_X_FAR = 50
GuiTopDownCamera.ROTATION_MAX_X_FAR = 90
GuiTopDownCamera.DISTANCE_MIN_Z = -10
GuiTopDownCamera.DISTANCE_RANGE_Z = -60
GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = 2
GuiTopDownCamera.CAMERA_TERRAIN_OFFSET = 2

function GuiTopDownCamera.new(subclass_mt, messageCenter, inputManager)
	local self = setmetatable({}, subclass_mt or GuiTopDownCamera_mt)
	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.controlledPlayer = nil
	self.controlledVehicle = nil
	self.hud = nil
	self.terrainRootNode = nil
	self.waterLevelHeight = 0
	self.terrainSize = 0
	self.previousCamera = nil
	self.camera, self.cameraBaseNode = self:createCameraNodes()
	self.isActive = false
	self.cameraX = 0
	self.targetCameraX = 0
	self.cameraZ = 0
	self.targetCameraZ = 0
	self.cameraRotY = math.rad(45)
	self.targetRotation = self.cameraRotY
	self.cameraTransformInitialized = false
	self.isMouseEdgeScrollingActive = true
	self.isMouseMode = false
	self.mousePosX = 0.5
	self.mousePosY = 0.5
	self.tiltFactor = 0.5
	self.targetTiltFactor = 0.5
	self.zoomFactor = 0.3
	self.targetZoomFactor = 0.3
	self.isCatchingCursor = false
	self.lastPlayerPos = {
		0,
		0,
		0
	}
	self.lastPlayerTerrainHeight = 0
	self.lastActionFrame = 0
	self.inputZoom = 0
	self.inputMoveSide = 0
	self.inputMoveForward = 0
	self.inputRotate = 0
	self.inputTilt = 0
	self.eventMoveSide = nil
	self.eventMoveForward = nil
	self.eventRotateCamera = nil
	self.movementDisabledForGamepad = false

	return self
end

function GuiTopDownCamera:createCameraNodes()
	local camera = createCamera("TopDownCamera", math.rad(60), 1, 4000)
	local cameraBaseNode = createTransformGroup("topDownCameraBaseNode")

	link(cameraBaseNode, camera)
	setRotation(camera, 0, math.rad(180), 0)
	setTranslation(camera, 0, 0, -5)
	setRotation(cameraBaseNode, 0, 0, 0)
	setTranslation(cameraBaseNode, 0, 110, 0)
	setFastShadowUpdate(camera, true)

	return camera, cameraBaseNode
end

function GuiTopDownCamera:delete()
	if self.isActive then
		self:deactivate()
	end

	delete(self.cameraBaseNode)

	self.cameraBaseNode = nil
	self.camera = nil

	self:reset()
end

function GuiTopDownCamera:reset()
	self.cameraTransformInitialized = false
	self.controlledPlayer = nil
	self.controlledVehicle = nil
	self.terrainRootNode = nil
	self.waterLevelHeight = 0
	self.terrainSize = 0
	self.previousCamera = nil
	self.isCatchingCursor = false
end

function GuiTopDownCamera:setTerrainRootNode(terrainRootNode)
	self.terrainRootNode = terrainRootNode
	self.terrainSize = getTerrainSize(self.terrainRootNode)
end

function GuiTopDownCamera:setWaterLevelHeight(waterLevelHeight)
	self.waterLevelHeight = waterLevelHeight
end

function GuiTopDownCamera:setControlledPlayer(player)
	self.controlledPlayer = player
	self.controlledVehicle = nil
end

function GuiTopDownCamera:setControlledVehicle(vehicle)
	if vehicle ~= nil then
		self.controlledVehicle = vehicle
		self.controlledPlayer = nil
	end
end

function GuiTopDownCamera:activate()
	self.inputManager:setShowMouseCursor(true)
	self:onInputModeChanged({
		self.inputManager:getLastInputMode()
	})
	self:updatePosition()

	self.previousCamera = getCamera()

	setCamera(self.camera)

	if self.controlledPlayer ~= nil then
		local x, y, z = getTranslation(self.controlledPlayer.rootNode)
		self.lastPlayerPos[3] = z
		self.lastPlayerPos[2] = y
		self.lastPlayerPos[1] = x
		self.lastPlayerTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, x, 0, z)

		self.controlledPlayer:setVisibility(true)
	end

	self:resetToPlayer()
	self:registerActionEvents()
	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

	self.isActive = true
end

function GuiTopDownCamera:deactivate()
	self.isActive = false

	self.messageCenter:unsubscribeAll(self)
	self:removeActionEvents()
	self.inputManager:setShowMouseCursor(false)

	if self.controlledPlayer ~= nil then
		local x, y, z = unpack(self.lastPlayerPos)
		local currentPlayerTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, x, 0, z)
		local deltaTerrainHeight = currentPlayerTerrainHeight - self.lastPlayerTerrainHeight

		if deltaTerrainHeight > 0 then
			y = y + deltaTerrainHeight
		end

		self.controlledPlayer:moveRootNodeToAbsolute(x, y, z)
		self.controlledPlayer:setVisibility(false)
	end

	if self.previousCamera ~= nil then
		setCamera(self.previousCamera)

		self.previousCamera = nil
	end
end

function GuiTopDownCamera:getIsActive()
	return self.isActive
end

function GuiTopDownCamera:setMapPosition(mapX, mapZ)
	self.cameraZ = mapZ
	self.cameraX = mapX
	self.targetCameraZ = mapZ
	self.targetCameraX = mapX

	self:updatePosition()
end

function GuiTopDownCamera:resetToPlayer()
	local playerX = 0
	local playerZ = 0

	if self.controlledPlayer ~= nil then
		playerZ = self.lastPlayerPos[3]
		playerX = self.lastPlayerPos[1]
	elseif self.controlledVehicle ~= nil then
		local _ = nil
		playerX, _, playerZ = getTranslation(self.controlledVehicle.rootNode)
	end

	self:setMapPosition(playerX, playerZ)
end

function GuiTopDownCamera:determineMapPosition()
	return self.cameraX, 0, self.cameraZ, self.cameraRotY - math.rad(180), 0
end

function GuiTopDownCamera:getPickRay()
	if self.isCatchingCursor then
		return nil
	end

	return RaycastUtil.getCameraPickingRay(self.mousePosX, self.mousePosY, self.camera)
end

function GuiTopDownCamera:updatePosition()
	local samplingGridStep = 2
	local cameraTargetHeight = self.waterLevelHeight

	for x = -samplingGridStep, samplingGridStep, samplingGridStep do
		for z = -samplingGridStep, samplingGridStep, samplingGridStep do
			local sampleTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, self.cameraX + x, 0, self.cameraZ + z)
			cameraTargetHeight = math.max(cameraTargetHeight, sampleTerrainHeight)
		end
	end

	cameraTargetHeight = cameraTargetHeight + GuiTopDownCamera.CAMERA_TERRAIN_OFFSET
	local rotMin = math.rad(GuiTopDownCamera.ROTATION_MIN_X_NEAR + (GuiTopDownCamera.ROTATION_MIN_X_FAR - GuiTopDownCamera.ROTATION_MIN_X_NEAR) * self.zoomFactor)
	local rotMax = math.rad(GuiTopDownCamera.ROTATION_MAX_X_NEAR + (GuiTopDownCamera.ROTATION_MAX_X_FAR - GuiTopDownCamera.ROTATION_MAX_X_NEAR) * self.zoomFactor)
	local rotationX = rotMin + (rotMax - rotMin) * self.tiltFactor
	local cameraZ = GuiTopDownCamera.DISTANCE_MIN_Z + self.zoomFactor * GuiTopDownCamera.DISTANCE_RANGE_Z

	setTranslation(self.camera, 0, 0, cameraZ)
	setRotation(self.cameraBaseNode, rotationX, self.cameraRotY, 0)
	setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight, self.cameraZ)

	local cameraX, cameraY = nil
	cameraX, cameraY, cameraZ = getWorldTranslation(self.camera)
	local terrainHeight = self.waterLevelHeight

	for x = -samplingGridStep, samplingGridStep, samplingGridStep do
		for z = -samplingGridStep, samplingGridStep, samplingGridStep do
			local y = getTerrainHeightAtWorldPos(self.terrainRootNode, cameraX + x, 0, cameraZ + z)
			local hit, _, hitY, _ = RaycastUtil.raycastClosest(cameraX + x, y + 100, cameraZ + z, 0, -1, 0, 100, CollisionMask.ALL - CollisionMask.TRIGGERS)

			if hit then
				y = hitY
			end

			terrainHeight = math.max(terrainHeight, y)
		end
	end

	if cameraY < terrainHeight + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y then
		cameraTargetHeight = cameraTargetHeight + terrainHeight - cameraY + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y

		setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight, self.cameraZ)
	end
end

function GuiTopDownCamera:applyMovement(dt)
	local xChange = (self.targetCameraX - self.cameraX) / dt * 5

	if xChange < 0.0001 and xChange > -0.0001 then
		self.cameraX = self.targetCameraX
	else
		self.cameraX = self.cameraX + xChange
	end

	local zChange = (self.targetCameraZ - self.cameraZ) / dt * 5

	if zChange < 0.0001 and zChange > -0.0001 then
		self.cameraZ = self.targetCameraZ
	else
		self.cameraZ = self.cameraZ + zChange
	end

	local zoomChange = (self.targetZoomFactor - self.zoomFactor) / dt * 2

	if zoomChange < 0.0001 and zoomChange > -0.0001 then
		self.zoomFactor = self.targetZoomFactor
	else
		self.zoomFactor = MathUtil.clamp(self.zoomFactor + zoomChange, 0, 1)
	end

	local tiltChange = (self.targetTiltFactor - self.tiltFactor) / dt * 5

	if tiltChange < 0.0001 and tiltChange > -0.0001 then
		self.tiltFactor = self.targetTiltFactor
	else
		self.tiltFactor = MathUtil.clamp(self.tiltFactor + tiltChange, 0, 1)
	end

	local rotateChange = (self.targetRotation - self.cameraRotY) / dt * 5

	if rotateChange < 0.0001 and rotateChange > -0.0001 then
		self.cameraRotY = self.targetRotation
	else
		self.cameraRotY = self.cameraRotY + rotateChange
	end
end

function GuiTopDownCamera:setMouseEdgeScrollingActive(isActive)
	self.isMouseEdgeScrollingActive = isActive
end

function GuiTopDownCamera:getMouseEdgeScrollingMovement()
	local moveMarginStartX = 0.02
	local moveMarginEndX = 0.015
	local moveMarginStartY = 0.02
	local moveMarginEndY = 0.015
	local moveX = 0
	local moveZ = 0

	if self.mousePosX >= 1 - moveMarginStartX then
		moveX = math.min((moveMarginStartX - (1 - self.mousePosX)) / (moveMarginStartX - moveMarginEndX), 1)
	elseif self.mousePosX <= moveMarginStartX then
		moveX = -math.min((moveMarginStartX - self.mousePosX) / (moveMarginStartX - moveMarginEndX), 1)
	end

	if self.mousePosY >= 1 - moveMarginStartY then
		moveZ = math.min((moveMarginStartY - (1 - self.mousePosY)) / (moveMarginStartY - moveMarginEndY), 1)
	elseif self.mousePosY <= moveMarginStartY then
		moveZ = -math.min((moveMarginStartY - self.mousePosY) / (moveMarginStartY - moveMarginEndY), 1)
	end

	return moveX, moveZ
end

function GuiTopDownCamera:setMovementDisabledForGamepad(disabled)
	self.movementDisabledForGamepad = disabled
end

function GuiTopDownCamera:update(dt)
	if self.isActive and (self.isMouseMode or not self.movementDisabledForGamepad) then
		self:updateMovement(dt)
		self:resetInputState()
	end
end

function GuiTopDownCamera:updateMovement(dt)
	self.targetZoomFactor = MathUtil.clamp(self.targetZoomFactor - self.inputZoom * 0.2, 0, 1)
	self.targetRotation = self.targetRotation + dt * self.inputRotate * GuiTopDownCamera.ROTATION_SPEED
	self.targetTiltFactor = MathUtil.clamp(self.targetTiltFactor + self.inputTilt * dt * GuiTopDownCamera.ROTATION_SPEED, 0, 1)
	local moveX = self.inputMoveSide * dt
	local moveZ = -self.inputMoveForward * dt

	if moveX == 0 and moveZ == 0 and self.isMouseEdgeScrollingActive then
		moveX, moveZ = self:getMouseEdgeScrollingMovement()
	end

	local zoomMovementSpeedFactor = GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR + self.zoomFactor * (GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR - GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR)
	moveX = moveX * zoomMovementSpeedFactor
	moveZ = moveZ * zoomMovementSpeedFactor
	local dirX = math.sin(self.cameraRotY) * moveZ + math.cos(self.cameraRotY) * -moveX
	local dirZ = math.cos(self.cameraRotY) * moveZ - math.sin(self.cameraRotY) * -moveX
	local limit = self.terrainSize * 0.5 - GuiTopDownCamera.TERRAIN_BORDER
	local moveFactor = dt * GuiTopDownCamera.MOVE_SPEED
	self.targetCameraX = MathUtil.clamp(self.targetCameraX + dirX * moveFactor, -limit, limit)
	self.targetCameraZ = MathUtil.clamp(self.targetCameraZ + dirZ * moveFactor, -limit, limit)

	self:applyMovement(dt)
	self:updatePosition()
end

function GuiTopDownCamera:setCursorLocked(locked)
	self.cursorLocked = locked
end

function GuiTopDownCamera:mouseEvent(posX, posY, isDown, isUp, button)
	if g_time <= self.lastActionFrame or self.cursorLocked then
		return
	end

	if self.isCatchingCursor then
		self.isCatchingCursor = false

		self.inputManager:setShowMouseCursor(true)
		wrapMousePosition(0.5, 0.5)

		self.mousePosX = 0.5
		self.mousePosY = 0.5
	elseif self.isMouseMode then
		self.mousePosX = posX
		self.mousePosY = posY
	end
end

function GuiTopDownCamera:resetInputState()
	self.inputZoom = 0
	self.inputMoveSide = 0
	self.inputMoveForward = 0
	self.inputTilt = 0
	self.inputRotate = 0
end

function GuiTopDownCamera:registerActionEvents()
	local _, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onMoveSide, false, false, true, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.eventMoveSide = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onMoveForward, false, false, true, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.eventMoveForward = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM, self, self.onZoom, false, false, true, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_LOW)

	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE, self, self.onRotate, false, false, true, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_LOW)

	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_TILT, self, self.onTilt, false, false, true, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_LOW)
end

function GuiTopDownCamera:removeActionEvents()
	self.inputManager:removeActionEventsByTarget(self)
end

function GuiTopDownCamera:onZoom(_, inputValue, _, isAnalog, isMouse)
	if isMouse and self.mouseDisabled then
		return
	end

	local change = 0.2 * inputValue

	if isAnalog then
		change = change * 0.5
	elseif isMouse then
		change = change * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
	end

	self.inputZoom = change
end

function GuiTopDownCamera:onMoveSide(_, inputValue)
	self.inputMoveSide = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end

function GuiTopDownCamera:onMoveForward(_, inputValue)
	self.inputMoveForward = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end

function GuiTopDownCamera:onRotate(_, inputValue, _, isAnalog, isMouse)
	if isMouse and self.mouseDisabled then
		return
	end

	if isMouse and inputValue ~= 0 then
		self.lastActionFrame = g_time

		if not self.isCatchingCursor then
			self.inputManager:setShowMouseCursor(false)

			self.isCatchingCursor = true
		end
	end

	if isMouse and isAnalog then
		inputValue = inputValue * 3
	end

	self.inputRotate = -inputValue * 3 / g_currentDt * 16
end

function GuiTopDownCamera:onTilt(_, inputValue, _, isAnalog, isMouse)
	if isMouse and self.mouseDisabled then
		return
	end

	if isMouse and inputValue ~= 0 then
		self.lastActionFrame = g_time

		if not self.isCatchingCursor then
			self.inputManager:setShowMouseCursor(false)

			self.isCatchingCursor = true
		end
	end

	if isMouse and isAnalog then
		inputValue = inputValue * 3
	end

	self.inputTilt = inputValue * 3
end

function GuiTopDownCamera:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD

	if not self.isMouseMode then
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	end
end
