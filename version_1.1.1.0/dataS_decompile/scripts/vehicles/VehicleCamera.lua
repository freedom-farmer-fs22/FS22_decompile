VehicleCamera = {}
local VehicleCamera_mt = Class(VehicleCamera)
VehicleCamera.doCameraSmoothing = false
VehicleCamera.raycastMask = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.WATER

function VehicleCamera.new(vehicle, customMt)
	local self = setmetatable({}, customMt or VehicleCamera_mt)
	self.vehicle = vehicle
	self.isActivated = false
	self.limitRotXDelta = 0
	self.raycastDistance = 0
	self.normalX = 0
	self.normalY = 0
	self.normalZ = 0
	self.raycastNodes = {}
	self.disableCollisionTime = -1
	self.lookAtPosition = {
		0,
		0,
		0
	}
	self.lookAtLastTargetPosition = {
		0,
		0,
		0
	}
	self.position = {
		0,
		0,
		0
	}
	self.lastTargetPosition = {
		0,
		0,
		0
	}
	self.upVector = {
		0,
		0,
		0
	}
	self.lastUpVector = {
		0,
		0,
		0
	}
	self.lastInputValues = {
		upDown = 0,
		leftRight = 0
	}
	self.isCollisionEnabled = true

	if g_modIsLoaded.FS22_disableVehicleCameraCollision then
		self.isCollisionEnabled = g_gameSettings:getValue("cameraCheckCollision")

		g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], self.onCameraCollisionDetectionSettingChanged, self)
	end

	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], self.onActiveCameraSuspensionSettingChanged, self)

	return self
end

function VehicleCamera:loadFromXML(xmlFile, key, savegame, cameraIndex)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, key .. "#index", "#node")

	self.cameraNode = xmlFile:getValue(key .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)

	if self.cameraNode == nil or not getHasClassId(self.cameraNode, ClassIds.CAMERA) then
		Logging.xmlWarning(xmlFile, "Invalid camera node for camera '%s'. Must be a camera type!", key)

		return false
	end

	self.fovY = calculateFovY(self.cameraNode)

	setFovY(self.cameraNode, self.fovY)

	self.isRotatable = xmlFile:getValue(key .. "#rotatable", false)
	self.limit = xmlFile:getValue(key .. "#limit", false)

	if self.limit then
		self.rotMinX = xmlFile:getValue(key .. "#rotMinX")
		self.rotMaxX = xmlFile:getValue(key .. "#rotMaxX")
		self.transMin = xmlFile:getValue(key .. "#transMin")
		self.transMax = xmlFile:getValue(key .. "#transMax")

		if self.transMax ~= nil then
			self.transMax = math.max(self.transMin, self.transMax * Platform.gameplay.maxCameraZoomFactor)
		end

		if self.rotMinX == nil or self.rotMaxX == nil or self.transMin == nil or self.transMax == nil then
			Logging.xmlWarning(xmlFile, "Missing 'rotMinX', 'rotMaxX', 'transMin' or 'transMax' for camera '%s'", key)

			return false
		end
	end

	self.isInside = xmlFile:getValue(key .. "#isInside", false)
	self.allowHeadTracking = xmlFile:getValue(key .. "#allowHeadTracking", self.isInside)
	self.shadowFocusBoxNode = xmlFile:getValue(key .. "#shadowFocusBox", nil, self.vehicle.components, self.vehicle.i3dMappings)

	if self.shadowFocusBoxNode ~= nil and not getHasClassId(self.shadowFocusBoxNode, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Invalid camera shadow focus box '%s'. Must be a shape and cpu mesh", getName(self.shadowFocusBoxNode))

		self.shadowFocusBoxNode = nil
	end

	if self.isInside and self.shadowFocusBoxNode == nil then
		Logging.xmlDevWarning(xmlFile, "Missing shadow focus box for indoor camera '%s'", key)
	end

	self.useOutdoorSounds = xmlFile:getValue(key .. "#useOutdoorSounds", not self.isInside)

	if self.isRotatable then
		self.rotateNode = xmlFile:getValue(key .. "#rotateNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
		self.hasExtraRotationNode = self.rotateNode ~= nil
	end

	local rotation = xmlFile:getValue(key .. "#rotation", nil, true)

	if rotation ~= nil then
		local rotationNode = self.cameraNode

		if self.rotateNode ~= nil then
			rotationNode = self.rotateNode
		end

		setRotation(rotationNode, unpack(rotation))
	end

	local translation = xmlFile:getValue(key .. "#translation", nil, true)

	if translation ~= nil then
		setTranslation(self.cameraNode, unpack(translation))
	end

	self.allowTranslation = self.rotateNode ~= nil and self.rotateNode ~= self.cameraNode
	self.useMirror = xmlFile:getValue(key .. "#useMirror", false)
	self.useWorldXZRotation = xmlFile:getValue(key .. "#useWorldXZRotation")
	self.resetCameraOnVehicleSwitch = xmlFile:getValue(key .. "#resetCameraOnVehicleSwitch")
	self.suspensionNodeIndex = xmlFile:getValue(key .. "#suspensionNodeIndex")

	if not Platform.gameplay.useWorldCameraInside and self.isInside or not Platform.gameplay.useWorldCameraOutside and not self.isInside then
		self.useWorldXZRotation = false
	end

	self.positionSmoothingParameter = 0
	self.lookAtSmoothingParameter = 0
	local useDefaultPositionSmoothing = xmlFile:getValue(key .. "#useDefaultPositionSmoothing", true)

	if useDefaultPositionSmoothing then
		if self.isInside then
			self.positionSmoothingParameter = 0.128
			self.lookAtSmoothingParameter = 0.176
		else
			self.positionSmoothingParameter = 0.016
			self.lookAtSmoothingParameter = 0.022
		end
	end

	self.positionSmoothingParameter = xmlFile:getValue(key .. "#positionSmoothingParameter", self.positionSmoothingParameter)
	self.lookAtSmoothingParameter = xmlFile:getValue(key .. "#lookAtSmoothingParameter", self.lookAtSmoothingParameter)
	local useHeadTracking = g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable() and self.allowHeadTracking

	if useHeadTracking then
		self.positionSmoothingParameter = 0
		self.lookAtSmoothingParameter = 0
	end

	self.cameraPositionNode = self.cameraNode

	if self.positionSmoothingParameter > 0 then
		self.cameraPositionNode = createTransformGroup("cameraPositionNode")
		local camIndex = getChildIndex(self.cameraNode)

		link(getParent(self.cameraNode), self.cameraPositionNode, camIndex)

		local x, y, z = getTranslation(self.cameraNode)
		local rx, ry, rz = getRotation(self.cameraNode)

		setTranslation(self.cameraPositionNode, x, y, z)
		setRotation(self.cameraPositionNode, rx, ry, rz)
		unlink(self.cameraNode)
	end

	self.rotYSteeringRotSpeed = xmlFile:getValue(key .. "#rotYSteeringRotSpeed", 0)

	if self.rotateNode == nil or self.rotateNode == self.cameraNode then
		self.rotateNode = self.cameraPositionNode
	end

	if useHeadTracking then
		local dx, _, dz = localDirectionToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 1)
		local tx, ty, tz = localToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 0)
		self.headTrackingNode = createTransformGroup("headTrackingNode")

		link(getParent(self.cameraPositionNode), self.headTrackingNode)
		setTranslation(self.headTrackingNode, tx, ty, tz)

		if math.abs(dx) + math.abs(dz) > 0.0001 then
			setDirection(self.headTrackingNode, dx, 0, dz, 0, 1, 0)
		else
			setRotation(self.headTrackingNode, 0, 0, 0)
		end
	end

	self.origRotX, self.origRotY, self.origRotZ = getRotation(self.rotateNode)
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	self.origTransX, self.origTransY, self.origTransZ = getTranslation(self.cameraPositionNode)
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local transLength = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ) + 1e-05
	self.zoom = transLength
	self.zoomTarget = transLength
	self.zoomDefault = transLength
	self.zoomLimitedTarget = -1
	local trans1OverLength = 1 / transLength
	self.transDirX = trans1OverLength * self.origTransX
	self.transDirY = trans1OverLength * self.origTransY
	self.transDirZ = trans1OverLength * self.origTransZ

	if self.allowTranslation and transLength <= 0.01 then
		Logging.xmlWarning(xmlFile, "Invalid camera translation for camera '%s'. Distance needs to be bigger than 0.01", key)
	end

	table.insert(self.raycastNodes, self.rotateNode)

	local i = 0

	while true do
		local raycastKey = key .. string.format(".raycastNode(%d)", i)

		if not xmlFile:hasProperty(raycastKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, raycastKey .. "#index", raycastKey .. "#node")

		local node = xmlFile:getValue(raycastKey .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)

		if node ~= nil then
			table.insert(self.raycastNodes, node)
		end

		i = i + 1
	end

	local sx, sy, sz = getScale(self.cameraNode)

	if sx ~= 1 or sy ~= 1 or sz ~= 1 then
		Logging.xmlWarning(xmlFile, "Vehicle camera with scale found for camera '%s'. Resetting to scale 1", key)
		setScale(self.cameraNode, 1, 1, 1)
	end

	self.headTrackingPositionOffset = {
		0,
		0,
		0
	}
	self.headTrackingRotationOffset = {
		0,
		0,
		0
	}
	self.changeObjects = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, self.changeObjects, self.vehicle.components, self.vehicle)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)

	if not g_gameSettings:getValue("resetCamera") and savegame ~= nil and not savegame.resetVehicles then
		local cameraKey = string.format(savegame.key .. ".enterable.camera(%d)", cameraIndex)

		if savegame.xmlFile:hasProperty(cameraKey) then
			self.rotX, self.rotY, self.rotZ = savegame.xmlFile:getValue(cameraKey .. "#rotation", {
				self.rotX,
				self.rotY,
				self.rotZ
			})
			self.transX, self.transY, self.transZ = savegame.xmlFile:getValue(cameraKey .. "#translation", {
				self.transX,
				self.transY,
				self.transZ
			})
			self.zoom = savegame.xmlFile:getValue(cameraKey .. "#zoom", self.zoom)
			self.zoomTarget = self.zoom

			setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
			setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)

			if g_currentMission.isReloadingVehicles then
				local fovY = savegame.xmlFile:getValue(cameraKey .. "#fovY")

				if fovY ~= nil then
					setFovY(self.cameraNode, fovY)
				end
			end
		end
	end

	return true
end

function VehicleCamera:onPostLoad(savegame)
	self.suspensionNode = nil

	if self.suspensionNodeIndex ~= nil and self.vehicle.getSuspensionNodeFromIndex ~= nil then
		self.suspensionNode = self.vehicle:getSuspensionNodeFromIndex(self.suspensionNodeIndex)
	end

	if self.suspensionNode ~= nil then
		if self.suspensionNode.node ~= nil then
			self.cameraSuspensionParentNode = createTransformGroup("cameraSuspensionParentNode")

			link(self.suspensionNode.node, self.cameraSuspensionParentNode)
			setWorldTranslation(self.cameraSuspensionParentNode, getWorldTranslation(getParent(self.cameraPositionNode)))
			setWorldQuaternion(self.cameraSuspensionParentNode, getWorldQuaternion(getParent(self.cameraPositionNode)))

			self.cameraBaseParentNode = getParent(self.cameraPositionNode)
			self.lastActiveCameraSuspensionSetting = false
		else
			Logging.warning("Vehicle Camera '%s' with invalid suspensionIndex '%s' found. CharacterTorso suspensions are not allowed.", getName(self.cameraNode), self.suspensionNodeIndex)

			self.suspensionNode = nil
		end
	end
end

function VehicleCamera:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#rotation", self.rotX, self.rotY, self.rotZ)
	xmlFile:setValue(key .. "#translation", self.transX, self.transY, self.transZ)
	xmlFile:setValue(key .. "#zoom", self.zoom)
	xmlFile:setValue(key .. "#fovY", getFovY(self.cameraNode))
end

function VehicleCamera:delete()
	self:onDeactivate()

	if self.cameraNode ~= nil and self.positionSmoothingParameter > 0 then
		delete(self.cameraNode)

		self.cameraNode = nil
	end

	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], self)
end

function VehicleCamera:zoomSmoothly(offset)
	local zoomTarget = self.zoomTarget

	if self.transMin ~= nil and self.transMax ~= nil and self.transMin ~= self.transMax then
		zoomTarget = math.min(self.transMax, math.max(self.transMin, self.zoomTarget + offset))
	end

	self.zoomTarget = zoomTarget
end

function VehicleCamera:raycastCallback(transformId, x, y, z, distance, nx, ny, nz)
	self.raycastDistance = distance
	self.normalX = nx
	self.normalY = ny
	self.normalZ = nz
	self.raycastTransformId = transformId
end

function VehicleCamera:update(dt)
	local target = self.zoomTarget

	if self.zoomLimitedTarget >= 0 then
		target = math.min(self.zoomLimitedTarget, self.zoomTarget)
	end

	self.zoom = target + math.pow(0.99579, dt) * (self.zoom - target)

	if self.lastInputValues.upDown ~= 0 then
		local value = self.lastInputValues.upDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.upDown = 0

		if g_gameSettings:getValue("invertYLook") then
			value = -value or value
		end

		if self.isRotatable and self.isActivated and not g_gui:getIsGuiVisible() then
			if self.limitRotXDelta > 0.001 then
				self.rotX = math.min(self.rotX - value, self.rotX)
			elseif self.limitRotXDelta < -0.001 then
				self.rotX = math.max(self.rotX - value, self.rotX)
			else
				self.rotX = self.rotX - value
			end

			if self.limit then
				self.rotX = math.min(self.rotMaxX, math.max(self.rotMinX, self.rotX))
			end
		end
	end

	if self.lastInputValues.leftRight ~= 0 then
		local value = self.lastInputValues.leftRight * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.leftRight = 0

		if self.isRotatable and self.isActivated and not g_gui:getIsGuiVisible() then
			self.rotY = self.rotY - value
		end
	end

	if g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable() and self.allowHeadTracking and self.headTrackingNode ~= nil then
		local tx, ty, tz = getHeadTrackingTranslation()
		local pitch, yaw, roll = getHeadTrackingRotation()

		if pitch ~= nil then
			local camParent = getParent(self.cameraNode)
			local ctx, cty, ctz, crx, cry, crz = nil

			if camParent ~= 0 then
				ctx, cty, ctz = localToLocal(self.headTrackingNode, camParent, tx, ty, tz)
				crx, cry, crz = localRotationToLocal(self.headTrackingNode, camParent, pitch, yaw, roll)
			else
				ctx, cty, ctz = localToWorld(self.headTrackingNode, tx, ty, tz)
				crx, cry, crz = localRotationToWorld(self.headTrackingNode, pitch, yaw, roll)
			end

			setRotation(self.cameraNode, crx, cry, crz)
			setTranslation(self.cameraNode, ctx, cty, ctz)
		end
	else
		self:updateRotateNodeRotation()

		if self.limit then
			if self.isRotatable and (self.useWorldXZRotation == nil and g_gameSettings:getValue("useWorldCamera") or self.useWorldXZRotation) then
				local numIterations = 4

				for _ = 1, numIterations do
					local transX = self.transDirX * self.zoom
					local transY = self.transDirY * self.zoom
					local transZ = self.transDirZ * self.zoom
					local x, y, z = localToWorld(getParent(self.cameraPositionNode), transX, transY, transZ)
					local terrainHeight = DensityMapHeightUtil.getHeightAtWorldPos(x, 0, z)
					local minHeight = terrainHeight + 0.9

					if y < minHeight then
						local h = math.sin(self.rotX) * self.zoom
						local h2 = h - (minHeight - y)
						self.rotX = math.asin(MathUtil.clamp(h2 / self.zoom, -1, 1))

						self:updateRotateNodeRotation()
					else
						break
					end
				end
			end

			if self.allowTranslation then
				self.limitRotXDelta = 0
				local hasCollision, collisionDistance, nx, ny, nz, normalDotDir = self:getCollisionDistance()

				if hasCollision then
					local distOffset = 0.1

					if normalDotDir ~= nil then
						local absNormalDotDir = math.abs(normalDotDir)
						distOffset = MathUtil.lerp(1.2, 0.1, absNormalDotDir * absNormalDotDir * (3 - 2 * absNormalDotDir))
					end

					collisionDistance = math.max(collisionDistance - distOffset, 0.01)
					self.disableCollisionTime = g_currentMission.time + 400
					self.zoomLimitedTarget = collisionDistance

					if collisionDistance < self.zoom then
						self.zoom = collisionDistance
					end

					if self.isRotatable and nx ~= nil and collisionDistance < self.transMin then
						local _, lny, _ = worldDirectionToLocal(self.rotateNode, nx, ny, nz)

						if lny > 0.5 then
							self.limitRotXDelta = 1
						elseif lny < -0.5 then
							self.limitRotXDelta = -1
						end
					end
				elseif self.disableCollisionTime <= g_currentMission.time then
					self.zoomLimitedTarget = -1
				end
			end
		end

		self.transZ = self.transDirZ * self.zoom
		self.transY = self.transDirY * self.zoom
		self.transX = self.transDirX * self.zoom

		setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)

		if self.positionSmoothingParameter > 0 then
			local interpDt = g_physicsDt

			if self.vehicle.spec_rideable ~= nil then
				interpDt = self.vehicle.spec_rideable.interpolationDt
			end

			if g_server == nil then
				interpDt = dt
			end

			if interpDt > 0 then
				local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
				local lookAtPos = self.lookAtPosition
				local lookAtLastPos = self.lookAtLastTargetPosition
				lookAtPos[1], lookAtPos[2], lookAtPos[3] = self:getSmoothed(self.lookAtSmoothingParameter, lookAtPos[1], lookAtPos[2], lookAtPos[3], xlook, ylook, zlook, lookAtLastPos[1], lookAtLastPos[2], lookAtLastPos[3], interpDt)
				lookAtLastPos[3] = zlook
				lookAtLastPos[2] = ylook
				lookAtLastPos[1] = xlook
				local x, y, z = getWorldTranslation(self.cameraPositionNode)
				local pos = self.position
				local lastPos = self.lastTargetPosition
				pos[1], pos[2], pos[3] = self:getSmoothed(self.positionSmoothingParameter, pos[1], pos[2], pos[3], x, y, z, lastPos[1], lastPos[2], lastPos[3], interpDt)
				lastPos[3] = z
				lastPos[2] = y
				lastPos[1] = x
				local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
				local up = self.upVector
				local lastUp = self.lastUpVector
				up[1], up[2], up[3] = self:getSmoothed(self.positionSmoothingParameter, up[1], up[2], up[3], upx, upy, upz, lastUp[1], lastUp[2], lastUp[3], interpDt)
				lastUp[3] = upz
				lastUp[2] = upy
				lastUp[1] = upx

				self:setSeparateCameraPose()
			end
		end
	end
end

function VehicleCamera:getSmoothed(alpha, curX, curY, curZ, targetX, targetY, targetZ, lastTargetX, lastTargetY, lastTargetZ, dt)
	local dtLooped = math.max(math.floor(dt - 6), 0)
	local dtDirect = dt - dtLooped
	local invDt = 1 / dt
	local velX = (targetX - lastTargetX) * invDt
	local velY = (targetY - lastTargetY) * invDt
	local velZ = (targetZ - lastTargetZ) * invDt
	local velScale = math.pow(1 - alpha, 1 + dtDirect) + (1 + dtDirect) * alpha - 1
	local posScale = math.pow(1 - alpha, dtDirect)
	local newX = (velScale * velX + alpha * (posScale * (curX - lastTargetX) + lastTargetX)) / alpha
	local newY = (velScale * velY + alpha * (posScale * (curY - lastTargetY) + lastTargetY)) / alpha
	local newZ = (velScale * velZ + alpha * (posScale * (curZ - lastTargetZ) + lastTargetZ)) / alpha

	for i = 1, dtLooped do
		newX = newX + (lastTargetX + velX * (i + dtDirect) - newX) * alpha
		newY = newY + (lastTargetY + velY * (i + dtDirect) - newY) * alpha
		newZ = newZ + (lastTargetZ + velZ * (i + dtDirect) - newZ) * alpha
	end

	return newX, newY, newZ
end

function VehicleCamera:onActivate()
	if self.cameraNode == nil then
		return
	end

	self:onActiveCameraSuspensionSettingChanged(g_gameSettings:getValue("activeSuspensionCamera"))

	self.isActivated = true

	if self.resetCameraOnVehicleSwitch == nil and g_gameSettings:getValue("resetCamera") or self.resetCameraOnVehicleSwitch then
		self:resetCamera()
	end

	setCamera(self.cameraNode)

	if self.shadowFocusBoxNode then
		setShadowFocusBox(self.shadowFocusBoxNode)
	end

	if self.positionSmoothingParameter > 0 then
		local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
		self.lookAtPosition[1] = xlook
		self.lookAtPosition[2] = ylook
		self.lookAtPosition[3] = zlook
		self.lookAtLastTargetPosition[1] = xlook
		self.lookAtLastTargetPosition[2] = ylook
		self.lookAtLastTargetPosition[3] = zlook
		local x, y, z = getWorldTranslation(self.cameraPositionNode)
		self.position[1] = x
		self.position[2] = y
		self.position[3] = z
		self.lastTargetPosition[1] = x
		self.lastTargetPosition[2] = y
		self.lastTargetPosition[3] = z
		local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
		self.upVector[1] = upx
		self.upVector[2] = upy
		self.upVector[3] = upz
		self.lastUpVector[1] = upx
		self.lastUpVector[2] = upy
		self.lastUpVector[3] = upz
		local rx, ry, rz = getWorldRotation(self.rotateNode)

		setRotation(self.cameraNode, rx, ry, rz)
		setTranslation(self.cameraNode, x, y, z)
	end

	self.lastInputValues = {
		upDown = 0,
		leftRight = 0
	}
	local _, actionEventId1 = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, VehicleCamera.actionEventLookUpDown, false, false, true, true, nil)
	local _, actionEventId2 = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, VehicleCamera.actionEventLookLeftRight, false, false, true, true, nil)

	g_inputBinding:setActionEventTextVisibility(actionEventId1, false)
	g_inputBinding:setActionEventTextVisibility(actionEventId2, false)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, true, self.vehicle, self.vehicle.setMovingToolDirty)

	if g_touchHandler ~= nil then
		self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, VehicleCamera.touchEventZoomInOut, self)
		self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, VehicleCamera.touchEventLookUpDown, self)
		self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, VehicleCamera.touchEventLookLeftRight, self)
	end
end

function VehicleCamera:consoleCommandLODDebug()
	if not self.lodDebugMode then
		self.transMaxOrig = self.transMax
		self.transMax = 350
		self.lodDebugMode = true
		self.loadDebugZoom = self.zoom
	else
		self.lodDebugMode = false
		self.transMax = self.transMaxOrig
		self.zoomTarget = self.zoomDefault
		self.zoom = self.zoomDefault

		setFovY(self.cameraNode, self.fovY)
	end
end

function VehicleCamera:onDeactivate()
	self.isActivated = false

	setShadowFocusBox(0)
	g_inputBinding:removeActionEventsByTarget(self)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)

	if g_touchHandler ~= nil then
		g_touchHandler:removeGestureListener(self.touchListenerPinch)
		g_touchHandler:removeGestureListener(self.touchListenerY)
		g_touchHandler:removeGestureListener(self.touchListenerX)
	end
end

function VehicleCamera:actionEventLookUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end

	self.lastInputValues.upDown = self.lastInputValues.upDown + inputValue
end

function VehicleCamera:touchEventLookUpDown(value)
	if self.isActivated then
		local factor = g_screenHeight / g_screenWidth * -150

		VehicleCamera.actionEventLookUpDown(self, nil, value * factor, nil, , false)
	end
end

function VehicleCamera:touchEventZoomInOut(value)
	if self.isActivated then
		self:zoomSmoothly(value * 15)
	end
end

function VehicleCamera:touchEventLookLeftRight(value)
	if self.isActivated then
		local factor = g_screenWidth / g_screenHeight * 150

		VehicleCamera.actionEventLookLeftRight(self, nil, value * factor, nil, , false)
	end
end

function VehicleCamera:actionEventLookLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
	if isMouse then
		inputValue = inputValue * 0.001 * 16.666
	else
		inputValue = inputValue * 0.001 * g_currentDt
	end

	self.lastInputValues.leftRight = self.lastInputValues.leftRight + inputValue
end

function VehicleCamera:resetCamera()
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local transLength = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ)
	self.zoom = transLength
	self.zoomTarget = transLength
	self.zoomLimitedTarget = -1

	self:updateRotateNodeRotation()
	setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)

	if self.positionSmoothingParameter > 0 then
		local xlook, ylook, zlook = getWorldTranslation(self.rotateNode)
		self.lookAtPosition[1] = xlook
		self.lookAtPosition[2] = ylook
		self.lookAtPosition[3] = zlook
		local x, y, z = getWorldTranslation(self.cameraPositionNode)
		self.position[1] = x
		self.position[2] = y
		self.position[3] = z

		self:setSeparateCameraPose()
	end
end

function VehicleCamera:updateRotateNodeRotation()
	local rotY = self.rotY

	if self.rotYSteeringRotSpeed ~= nil and self.rotYSteeringRotSpeed ~= 0 and self.vehicle.spec_articulatedAxis ~= nil and self.vehicle.spec_articulatedAxis.interpolatedRotatedTime ~= nil then
		rotY = rotY + self.vehicle.spec_articulatedAxis.interpolatedRotatedTime * self.rotYSteeringRotSpeed
	end

	if self.useWorldXZRotation == nil and g_gameSettings:getValue("useWorldCamera") or self.useWorldXZRotation then
		local upx = 0
		local upy = 1
		local upz = 0
		local dx, _, dz = localDirectionToWorld(getParent(self.rotateNode), 0, 0, 1)
		local invLen = 1 / math.sqrt(dx * dx + dz * dz)
		dx = dx * invLen
		dz = dz * invLen
		local newDx = math.cos(self.rotX) * (math.cos(rotY) * dx + math.sin(rotY) * dz)
		local newDy = -math.sin(self.rotX)
		local newDz = math.cos(self.rotX) * (-math.sin(rotY) * dx + math.cos(rotY) * dz)
		newDx, newDy, newDz = worldDirectionToLocal(getParent(self.rotateNode), newDx, newDy, newDz)
		upx, upy, upz = worldDirectionToLocal(getParent(self.rotateNode), upx, upy, upz)

		if math.abs(MathUtil.dotProduct(newDx, newDy, newDz, upx, upy, upz)) > 0.99 * MathUtil.vector3Length(newDx, newDy, newDz) * MathUtil.vector3Length(upx, upy, upz) then
			setRotation(self.rotateNode, self.rotX, rotY, self.rotZ)
		else
			setDirection(self.rotateNode, newDx, newDy, newDz, upx, upy, upz)
		end
	else
		setRotation(self.rotateNode, self.rotX, rotY, self.rotZ)
	end
end

function VehicleCamera:setSeparateCameraPose()
	if self.rotateNode ~= self.cameraPositionNode then
		local dx = self.position[1] - self.lookAtPosition[1]
		local dy = self.position[2] - self.lookAtPosition[2]
		local dz = self.position[3] - self.lookAtPosition[3]
		local upx, upy, upz = unpack(self.upVector)

		if upx == 0 and upy == 0 and upz == 0 then
			upy = 1
		end

		if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
			upx = 0.1
		end

		setDirection(self.cameraNode, dx, dy, dz, upx, upy, upz)
	else
		local dx, dy, dz = localDirectionToWorld(self.rotateNode, 0, 0, 1)
		local upx, upy, upz = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)

		setDirection(self.cameraNode, dx, dy, dz, upx, upy, upz)
	end

	setTranslation(self.cameraNode, self.position[1], self.position[2], self.position[3])
end

function VehicleCamera:getTiltDirectionOffset()
	if not self.isInside and g_gameSettings:getValue(GameSettings.SETTING.CAMERA_TILTING) and getHasTouchpad() then
		local dx, dy, dz = getGravityDirection()
		local tiltOffset = MathUtil.getHorizontalRotationFromDeviceGravity(dx, dy, dz)

		return tiltOffset
	end

	return 0
end

function VehicleCamera:getCollisionDistance()
	if not self.isCollisionEnabled then
		return false, nil, , , , 
	end

	local raycastMask = VehicleCamera.raycastMask
	local targetCamX, targetCamY, targetCamZ = localToWorld(self.rotateNode, self.transDirX * self.zoomTarget, self.transDirY * self.zoomTarget, self.transDirZ * self.zoomTarget)
	local hasCollision = false
	local collisionDistance = -1
	local normalX, normalY, normalZ, normalDotDir = nil

	for _, raycastNode in ipairs(self.raycastNodes) do
		hasCollision = false
		local nodeX, nodeY, nodeZ = getWorldTranslation(raycastNode)
		local dirX = targetCamX - nodeX
		local dirY = targetCamY - nodeY
		local dirZ = targetCamZ - nodeZ
		local dirLength = MathUtil.vector3Length(dirX, dirY, dirZ)
		dirX = dirX / dirLength
		dirY = dirY / dirLength
		dirZ = dirZ / dirLength
		local startX = nodeX
		local startY = nodeY
		local startZ = nodeZ
		local currentDistance = 0
		local minDistance = self.transMin

		while true do
			if dirLength - currentDistance <= 0 then
				break
			end

			self.raycastDistance = 0

			raycastClosest(startX, startY, startZ, dirX, dirY, dirZ, "raycastCallback", dirLength - currentDistance, self, raycastMask, true)

			if self.raycastDistance ~= 0 then
				currentDistance = currentDistance + self.raycastDistance + 0.001
				local ndotd = MathUtil.dotProduct(self.normalX, self.normalY, self.normalZ, dirX, dirY, dirZ)
				local isAttachedVehicle = false
				local ignoreObject = false
				local object = g_currentMission:getNodeObject(self.raycastTransformId)

				if object ~= nil then
					local vehicles = self.vehicle:getChildVehicles()

					for i = 1, #vehicles do
						local vehicle = vehicles[i]

						if object ~= vehicle then
							local attached1 = object.getIsAttachedTo ~= nil and object:getIsAttachedTo(vehicle)
							local attached2 = vehicle.getIsAttachedTo ~= nil and vehicle:getIsAttachedTo(object)
							isAttachedVehicle = attached1 or attached2
							local mountObject = object.dynamicMountObject or object.tensionMountObject or object.mountObject

							if mountObject ~= nil and (mountObject == vehicle or mountObject.rootVehicle == vehicle) then
								isAttachedVehicle = true
							end
						end

						if isAttachedVehicle then
							break
						end
					end
				end

				if getHasClassId(self.raycastTransformId, ClassIds.SHAPE) and getSplitType(self.raycastTransformId) ~= 0 then
					ignoreObject = true
				end

				if getHasTrigger(self.raycastTransformId) then
					ignoreObject = true
				end

				if isAttachedVehicle or object == self.vehicle or ignoreObject then
					if ndotd > 0 then
						minDistance = math.max(minDistance, currentDistance)
					end
				else
					hasCollision = true

					if raycastNode == self.rotateNode then
						normalZ = self.normalZ
						normalY = self.normalY
						normalX = self.normalX

						if getRigidBodyType(self.raycastTransformId) == RigidBodyType.STATIC then
							collisionDistance = currentDistance
						else
							collisionDistance = math.max(self.transMin, currentDistance)
						end

						normalDotDir = ndotd
					end

					break
				end

				startX = nodeX + dirX * currentDistance
				startY = nodeY + dirY * currentDistance
				startZ = nodeZ + dirZ * currentDistance
			else
				break
			end
		end

		if not hasCollision then
			break
		end
	end

	return hasCollision, collisionDistance, normalX, normalY, normalZ, normalDotDir
end

function VehicleCamera:onActiveCameraSuspensionSettingChanged(newState)
	if self.suspensionNode ~= nil and self.lastActiveCameraSuspensionSetting ~= newState then
		if newState then
			link(self.cameraSuspensionParentNode, self.cameraPositionNode)
		else
			link(self.cameraBaseParentNode, self.cameraPositionNode)
		end

		self.lastActiveCameraSuspensionSetting = newState
	end
end

function VehicleCamera:onCameraCollisionDetectionSettingChanged(newState)
	self.isCollisionEnabled = newState
end

function VehicleCamera.registerCameraXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Camera node")
	schema:register(XMLValueType.BOOL, basePath .. "#rotatable", "Camera is rotatable", false)
	schema:register(XMLValueType.BOOL, basePath .. "#limit", "Has limits", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#rotMinX", "Min. X rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#rotMaxX", "Max. X rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#transMin", "Min. Z translation")
	schema:register(XMLValueType.FLOAT, basePath .. "#transMax", "Max. Z translation")
	schema:register(XMLValueType.BOOL, basePath .. "#isInside", "Is camera inside. Used for camera smoothing and fallback/default value for 'useOutdoorSounds'", false)
	schema:register(XMLValueType.BOOL, basePath .. "#allowHeadTracking", "Allow head tracking", "isInside value")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#shadowFocusBox", "Shadow focus box")
	schema:register(XMLValueType.BOOL, basePath .. "#useOutdoorSounds", "Use outdoor sounds", "false for 'isInside' cameras, otherwise true")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rotateNode", "Rotate node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Camera rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Camera translation")
	schema:register(XMLValueType.BOOL, basePath .. "#useMirror", "Use mirrors", false)
	schema:register(XMLValueType.BOOL, basePath .. "#useWorldXZRotation", "Use world XZ rotation")
	schema:register(XMLValueType.BOOL, basePath .. "#resetCameraOnVehicleSwitch", "Reset camera on vehicle switch")
	schema:register(XMLValueType.INT, basePath .. "#suspensionNodeIndex", "Index of seat suspension node")
	schema:register(XMLValueType.BOOL, basePath .. "#useDefaultPositionSmoothing", "Use default position smoothing parameters", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#positionSmoothingParameter", "Position smoothing parameter", "0.128 for indoor / 0.016 for outside")
	schema:register(XMLValueType.FLOAT, basePath .. "#lookAtSmoothingParameter", "Look at smoothing parameter", "0.176 for indoor / 0.022 for outside")
	schema:register(XMLValueType.ANGLE, basePath .. "#rotYSteeringRotSpeed", "Rot Y steering rotation speed", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".raycastNode(?)#node", "Raycast node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function VehicleCamera.registerCameraSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Camera rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Camera translation")
	schema:register(XMLValueType.FLOAT, basePath .. "#zoom", "Camera zoom")
	schema:register(XMLValueType.FLOAT, basePath .. "#fovY", "Custom Field of View Y")
	schema:register(XMLValueType.BOOL, basePath .. "#lodDebugActive", "LOD Debug Mode Active")
	schema:register(XMLValueType.FLOAT, basePath .. "#lodDebugZoom", "LOD Debug Mode Zoom Ref")
end
