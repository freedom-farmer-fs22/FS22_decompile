BunkerSilo = {}
local BunkerSilo_mt = Class(BunkerSilo, Object)

InitStaticObjectClass(BunkerSilo, "BunkerSilo", ObjectIds.OBJECT_BUNKER_SILO)

BunkerSilo.STATE_FILL = 0
BunkerSilo.STATE_CLOSED = 1
BunkerSilo.STATE_FERMENTED = 2
BunkerSilo.STATE_DRAIN = 3
BunkerSilo.NUM_STATES = 4
BunkerSilo.COMPACTING_BASE_MASS = 5

function BunkerSilo:onCreate(id)
	Logging.error("BunkerSilo.onCreate is deprecated!")
end

function BunkerSilo.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or BunkerSilo_mt)
	self.interactionTriggerNode = nil
	self.bunkerSiloArea = {
		offsetFront = 0,
		offsetBack = 0
	}
	self.acceptedFillTypes = {}
	self.inputFillType = FillType.CHAFF
	self.outputFillType = FillType.SILAGE
	self.fermentingFillType = FillType.TARP
	self.isOpenedAtFront = false
	self.isOpenedAtBack = false
	self.distanceToCompactedFillLevel = 100
	self.fermentingTime = 0
	self.fermentingDuration = 86400000
	self.fermentingPercent = 0
	self.fillLevel = 0
	self.compactedFillLevel = 0
	self.compactedPercent = 0
	self.emptyThreshold = 100
	self.playerInRange = false
	self.vehiclesInRange = {}
	self.numVehiclesInRange = 0
	self.siloIsFullWarningTimer = 0
	self.siloIsFullWarningDuration = 2000
	self.updateTimer = 0
	self.activatable = BunkerSiloActivatable.new(self)
	self.state = BunkerSilo.STATE_FILL
	self.bunkerSiloDirtyFlag = self:getNextDirtyFlag()

	return self
end

function BunkerSilo:load(components, xmlFile, key, i3dMappings)
	self.bunkerSiloArea.start = xmlFile:getValue(key .. ".area#startNode", nil, components, i3dMappings)
	self.bunkerSiloArea.width = xmlFile:getValue(key .. ".area#widthNode", nil, components, i3dMappings)
	self.bunkerSiloArea.height = xmlFile:getValue(key .. ".area#heightNode", nil, components, i3dMappings)
	self.bunkerSiloArea.sx, self.bunkerSiloArea.sy, self.bunkerSiloArea.sz = getWorldTranslation(self.bunkerSiloArea.start)
	self.bunkerSiloArea.wx, self.bunkerSiloArea.wy, self.bunkerSiloArea.wz = getWorldTranslation(self.bunkerSiloArea.width)
	self.bunkerSiloArea.hx, self.bunkerSiloArea.hy, self.bunkerSiloArea.hz = getWorldTranslation(self.bunkerSiloArea.height)
	self.bunkerSiloArea.dhx = self.bunkerSiloArea.hx - self.bunkerSiloArea.sx
	self.bunkerSiloArea.dhy = self.bunkerSiloArea.hy - self.bunkerSiloArea.sy
	self.bunkerSiloArea.dhz = self.bunkerSiloArea.hz - self.bunkerSiloArea.sz
	self.bunkerSiloArea.dhx_norm, self.bunkerSiloArea.dhy_norm, self.bunkerSiloArea.dhz_norm = MathUtil.vector3Normalize(self.bunkerSiloArea.dhx, self.bunkerSiloArea.dhy, self.bunkerSiloArea.dhz)
	self.bunkerSiloArea.dwx = self.bunkerSiloArea.wx - self.bunkerSiloArea.sx
	self.bunkerSiloArea.dwy = self.bunkerSiloArea.wy - self.bunkerSiloArea.sy
	self.bunkerSiloArea.dwz = self.bunkerSiloArea.wz - self.bunkerSiloArea.sz
	self.bunkerSiloArea.dwx_norm, self.bunkerSiloArea.dwy_norm, self.bunkerSiloArea.dwz_norm = MathUtil.vector3Normalize(self.bunkerSiloArea.dwx, self.bunkerSiloArea.dwy, self.bunkerSiloArea.dwz)
	self.interactionTriggerNode = xmlFile:getValue(key .. ".interactionTrigger#node", nil, components, i3dMappings)

	if self.interactionTriggerNode ~= nil then
		addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
	end

	self.acceptedFillTypes = {}
	local data = xmlFile:getValue(key .. "#acceptedFillTypes", "chaff grass_windrow dryGrass_windrow"):split(" ")

	for i = 1, table.getn(data) do
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(data[i])

		if fillTypeIndex ~= nil then
			self.acceptedFillTypes[fillTypeIndex] = true
		else
			Logging.warning("'%s' is an invalid fillType for bunkerSilo '%s'!", tostring(data[i]), key .. "#acceptedFillTypes")
		end
	end

	local inputFillTypeName = xmlFile:getValue(key .. "#inputFillType", "chaff")
	local inputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(inputFillTypeName)

	if inputFillTypeIndex ~= nil then
		self.inputFillType = inputFillTypeIndex
	else
		Logging.warning("'%s' is an invalid input fillType for bunkerSilo '%s'!", tostring(inputFillTypeName), key .. "#inputFillType")
	end

	local outputFillTypeName = xmlFile:getValue(key .. "#outputFillType", "silage")
	local outputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeName)

	if outputFillTypeIndex ~= nil then
		self.outputFillType = outputFillTypeIndex
	else
		Logging.warning("'%s' is an invalid output fillType for bunkerSilo '%s'!", tostring(outputFillTypeName), key .. "#outputFillType")
	end

	g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)

	self.distanceToCompactedFillLevel = xmlFile:getValue(key .. "#distanceToCompactedFillLevel", self.distanceToCompactedFillLevel)
	self.openingLength = xmlFile:getValue(key .. "#openingLength", 5)
	local leftWallNode = xmlFile:getValue(key .. ".wallLeft#node", nil, components, i3dMappings)

	if leftWallNode ~= nil then
		self.wallLeft = {
			node = leftWallNode,
			visible = true,
			collision = xmlFile:getValue(key .. ".wallLeft#collision", nil, components, i3dMappings)
		}
	end

	local rightWallNode = xmlFile:getValue(key .. ".wallRight#node", nil, components, i3dMappings)

	if rightWallNode ~= nil then
		self.wallRight = {
			node = rightWallNode,
			visible = true,
			collision = xmlFile:getValue(key .. ".wallRight#collision", nil, components, i3dMappings)
		}
	end

	self.fillLevel = 0
	local difficultyMultiplier = g_currentMission.missionInfo.economicDifficulty
	self.fermentingDuration = self.fermentingDuration * difficultyMultiplier
	self.distanceToCompactedFillLevel = self.distanceToCompactedFillLevel / difficultyMultiplier

	self:setState(BunkerSilo.STATE_FILL)

	return true
end

function BunkerSilo:delete()
	g_currentMission:removeOnCreateLoadedObjectToSave(self)

	if self.interactionTriggerNode ~= nil then
		removeTrigger(self.interactionTriggerNode)
	end

	g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
	g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
	g_messageCenter:unsubscribeAll(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	BunkerSilo:superClass().delete(self)
end

function BunkerSilo:readStream(streamId, connection)
	BunkerSilo:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local state = streamReadUIntN(streamId, 3)

		self:setState(state)

		self.isOpenedAtFront = streamReadBool(streamId)
		self.isOpenedAtBack = streamReadBool(streamId)
		self.fillLevel = streamReadFloat32(streamId)
		self.compactedPercent = math.floor(streamReadUIntN(streamId, 8) / 2.55 + 0.5)
		self.fermentingPercent = math.floor(streamReadUIntN(streamId, 8) / 2.55 + 0.5)
	end
end

function BunkerSilo:writeStream(streamId, connection)
	BunkerSilo:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.state, 3)
		streamWriteBool(streamId, self.isOpenedAtFront)
		streamWriteBool(streamId, self.isOpenedAtBack)
		streamWriteFloat32(streamId, self.fillLevel)
		streamWriteUIntN(streamId, 2.55 * self.compactedPercent, 8)
		streamWriteUIntN(streamId, 2.55 * self.fermentingPercent, 8)
	end
end

function BunkerSilo:readUpdateStream(streamId, timestamp, connection)
	BunkerSilo:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		local state = streamReadUIntN(streamId, 3)

		if state ~= self.state then
			self:setState(state, true)
		end

		self.fillLevel = streamReadFloat32(streamId)
		self.isOpenedAtFront = streamReadBool(streamId)
		self.isOpenedAtBack = streamReadBool(streamId)

		if self.state == BunkerSilo.STATE_FILL then
			self.compactedPercent = math.floor(streamReadUIntN(streamId, 8) / 2.55 + 0.5)
		elseif self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
			self.fermentingPercent = math.floor(streamReadUIntN(streamId, 8) / 2.55 + 0.5)
		end
	end
end

function BunkerSilo:writeUpdateStream(streamId, connection, dirtyMask)
	BunkerSilo:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.bunkerSiloDirtyFlag) ~= 0) then
		streamWriteUIntN(streamId, self.state, 3)
		streamWriteFloat32(streamId, self.fillLevel)
		streamWriteBool(streamId, self.isOpenedAtFront)
		streamWriteBool(streamId, self.isOpenedAtBack)

		if self.state == BunkerSilo.STATE_FILL then
			streamWriteUIntN(streamId, 2.55 * self.compactedPercent, 8)
		elseif self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
			streamWriteUIntN(streamId, 2.55 * self.fermentingPercent, 8)
		end
	end
end

function BunkerSilo:loadFromXMLFile(xmlFile, key)
	local state = xmlFile:getValue(key .. "#state")

	if state ~= nil and state >= 0 and state < BunkerSilo.NUM_STATES then
		self:setState(state)
	end

	local fillLevel = xmlFile:getValue(key .. "#fillLevel")

	if fillLevel ~= nil then
		self.fillLevel = fillLevel
	end

	local compactedFillLevel = xmlFile:getValue(key .. "#compactedFillLevel")

	if compactedFillLevel ~= nil then
		self.compactedFillLevel = MathUtil.clamp(compactedFillLevel, 0, self.fillLevel)
	end

	self.compactedPercent = MathUtil.getFlooredPercent(math.min(self.compactedFillLevel, self.fillLevel), self.fillLevel)
	local fermentingTime = xmlFile:getValue(key .. "#fermentingTime")

	if fermentingTime ~= nil then
		self.fermentingTime = MathUtil.clamp(fermentingTime, 0, self.fermentingDuration)
		self.fermentingPercent = MathUtil.getFlooredPercent(self.fermentingTime, self.fermentingDuration)
	end

	self.isOpenedAtFront = xmlFile:getValue(key .. "#openedAtFront", false)
	self.isOpenedAtBack = xmlFile:getValue(key .. "#openedAtBack", false)

	if self.isOpenedAtFront then
		self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.outputFillType)
	else
		self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
	end

	if self.isOpenedAtBack then
		self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.outputFillType)
	else
		self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
	end

	if self.fillLevel > 0 and self.state == BunkerSilo.STATE_DRAIN then
		local area = self.bunkerSiloArea
		local offWx = area.wx - area.sx
		local offWz = area.wz - area.sz
		local offW = math.sqrt(offWx * offWx + offWz * offWz)
		local offHx = area.hx - area.sx
		local offHz = area.hz - area.sz
		local offH = math.sqrt(offHx * offHx + offHz * offHz)

		if offW > 0.001 and offH > 0.001 then
			local offWScale = math.min(0.45, 0.9 / offW)
			offWx = offWx * offWScale
			offWz = offWz * offWScale
			local offHScale = math.min(0.45, 0.9 / offH)
			offHx = offHx * offHScale
			offHz = offHz * offHScale
			local innerFillLevel1 = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx + offWx + offHx, area.sz + offWz + offHz, area.wx - offWx + offHx, area.wz - offWz + offHz, area.hx + offWx - offHx, area.hz + offWz - offHz)
			local innerFillLevel2 = DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx + offWx + offHx, area.sz + offWz + offHz, area.wx - offWx + offHx, area.wz - offWz + offHz, area.hx + offWx - offHx, area.hz + offWz - offHz)
			local innerFillLevel = innerFillLevel1 + innerFillLevel2

			if innerFillLevel < self.emptyThreshold * 0.5 then
				DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.fermentingFillType)
				DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.outputFillType)
				self:setState(BunkerSilo.STATE_FILL, false)
			end
		end
	elseif self.state == BunkerSilo.STATE_FILL then
		local area = self.bunkerSiloArea
		local fermentingFillLevel, fermentingPixels, totalFermentingPixels = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)

		if self.emptyThreshold < fermentingFillLevel and fermentingPixels > 0.5 * totalFermentingPixels then
			local inputFillLevel, inputPixels, totalInputPixels = DensityMapHeightUtil.getFillLevelAtArea(self.inputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)

			if inputPixels < 0.1 * totalInputPixels then
				self:setState(BunkerSilo.STATE_FERMENTED, false)
			end
		end
	end

	return true
end

function BunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#state", self.state)
	xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
	xmlFile:setValue(key .. "#compactedFillLevel", self.compactedFillLevel)
	xmlFile:setValue(key .. "#fermentingTime", self.fermentingTime)
	xmlFile:setValue(key .. "#openedAtFront", self.isOpenedAtFront)
	xmlFile:setValue(key .. "#openedAtBack", self.isOpenedAtBack)
end

function BunkerSilo:update(dt)
	if self:getCanInteract(true) then
		local fillTypeIndex = self.inputFillType

		if self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED or self.state == BunkerSilo.STATE_DRAIN then
			fillTypeIndex = self.outputFillType
		end

		local fillTypeName = ""
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

		if fillType ~= nil then
			fillTypeName = fillType.title
		end

		if self.state == BunkerSilo.STATE_FILL then
			g_currentMission:addExtraPrintText(g_i18n:getText("info_fillLevel") .. string.format(" %s: %d", fillTypeName, self.fillLevel))
			g_currentMission:addExtraPrintText(g_i18n:getText("info_compacting") .. string.format(" %d%%", self.compactedPercent))
		elseif self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
			g_currentMission:addExtraPrintText(g_i18n:getText("info_fermenting") .. string.format(" %s: %d%%", fillTypeName, self.fermentingPercent))
		elseif self.state == BunkerSilo.STATE_DRAIN then
			g_currentMission:addExtraPrintText(g_i18n:getText("info_fillLevel") .. string.format(" %s: %d", fillTypeName, self.fillLevel))
		end
	end

	if self.state == BunkerSilo.STATE_CLOSED and self.isServer then
		self.fermentingTime = math.min(self.fermentingDuration, self.fermentingTime + dt * g_currentMission:getEffectiveTimeScale())
		local fermentingPercent = MathUtil.getFlooredPercent(self.fermentingTime, self.fermentingDuration)

		if fermentingPercent ~= self.fermentingPercent then
			self.fermentingPercent = fermentingPercent

			self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
		end

		if self.fermentingDuration <= self.fermentingTime then
			self:setState(BunkerSilo.STATE_FERMENTED, true)
		end
	end

	if self.isServer and self.state == BunkerSilo.STATE_FILL then
		for vehicle, state in pairs(self.vehiclesInRange) do
			if state and vehicle:getIsActive() then
				local distance = vehicle.lastMovedDistance

				if distance > 0 then
					local mass = vehicle:getTotalMass(false)
					local compactingFactor = mass / BunkerSilo.COMPACTING_BASE_MASS
					local compactingScale = 1

					if vehicle.getBunkerSiloCompacterScale ~= nil then
						compactingScale = vehicle:getBunkerSiloCompacterScale() or compactingScale
					end

					compactingFactor = compactingFactor * compactingScale
					local deltaCompact = distance * compactingFactor * self.distanceToCompactedFillLevel

					if vehicle.getWheels ~= nil then
						local wheels = vehicle:getWheels()
						local numWheels = #wheels

						if numWheels > 0 then
							local wheelsOnSilo = 0
							local wheelsInAir = 0

							for _, wheel in ipairs(wheels) do
								if wheel.contact == Wheels.WHEEL_GROUND_HEIGHT_CONTACT then
									wheelsOnSilo = wheelsOnSilo + 1
								elseif wheel.contact == Wheels.WHEEL_NO_CONTACT then
									wheelsInAir = wheelsInAir + 1
								end
							end

							if wheelsOnSilo > 0 then
								deltaCompact = deltaCompact * (wheelsOnSilo + wheelsInAir) / numWheels
							else
								deltaCompact = 0
							end
						end
					end

					if deltaCompact > 0 then
						local compactedFillLevel = math.min(self.compactedFillLevel + deltaCompact, self.fillLevel)

						if compactedFillLevel ~= self.compactedFillLevel then
							self.compactedFillLevel = compactedFillLevel
							self.compactedPercent = MathUtil.getFlooredPercent(math.min(self.compactedFillLevel, self.fillLevel), self.fillLevel)

							self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
						end
					end
				end
			end
		end
	end

	if g_currentMission ~= nil and g_currentMission.bunkerScore ~= nil and g_currentMission.bunkerScore < self.fillLevel then
		g_currentMission.bunkerScore = self.fillLevel
	end

	self:raiseActive()
end

function BunkerSilo:updateTick(dt)
	if self.isServer then
		self.updateTimer = self.updateTimer - dt

		if self.updateTimer <= 0 then
			self.updateTimer = 200 + math.random() * 100
			local oldFillLevel = self.fillLevel

			self:updateFillLevel()

			if oldFillLevel ~= self.fillLevel then
				self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
			end
		end
	end

	if not self.adjustedOpeningLength then
		self.adjustedOpeningLength = true
		self.openingLength = math.max(self.openingLength, DensityMapHeightUtil.getDefaultMaxRadius(self.outputFillType) + 1)
	end
end

function BunkerSilo:updateFillLevel()
	local area = self.bunkerSiloArea
	local fillLevel = self.fillLevel
	local fillType = self.inputFillType

	if fillType ~= FillType.UNKNOWN then
		if self.state == BunkerSilo.STATE_FILL then
			fillLevel = DensityMapHeightUtil.getFillLevelAtArea(fillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
		elseif self.state == BunkerSilo.STATE_CLOSED then
			fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
		elseif self.state == BunkerSilo.STATE_FERMENTED then
			local fillLevel1 = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
			local fillLevel2 = DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
			fillLevel = fillLevel1 + fillLevel2
		elseif self.state == BunkerSilo.STATE_DRAIN then
			local fillLevel1 = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
			local fillLevel2 = DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
			fillLevel = fillLevel1 + fillLevel2

			if fillLevel < self.emptyThreshold then
				DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.fermentingFillType)
				DensityMapHeightUtil.removeFromGroundByArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz, self.outputFillType)
				self:setState(BunkerSilo.STATE_FILL, true)
			end
		end
	end

	self.fillLevel = fillLevel
end

function BunkerSilo:setState(state, showNotification)
	if state ~= self.state then
		if state == BunkerSilo.STATE_FILL then
			self.fermentingTime = 0
			self.fermentingPercent = 0
			self.compactedFillLevel = 0
			self.compactedPercent = 0
			self.isOpenedAtFront = false
			self.isOpenedAtBack = false
			self.bunkerSiloArea.offsetFront = 0
			self.bunkerSiloArea.offsetBack = 0

			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloIsEmpty"))
			end

			if self.isServer then
				g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
				g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)
			end
		elseif state == BunkerSilo.STATE_CLOSED then
			if self.isServer then
				local area = self.bunkerSiloArea
				local offsetFront = self:getBunkerAreaOffset(true, 0, self.inputFillType)
				local offsetBack = self:getBunkerAreaOffset(false, 0, self.inputFillType)
				local x0 = area.sx + offsetFront * area.dhx_norm
				local z0 = area.sz + offsetFront * area.dhz_norm
				local x1 = x0 + area.dwx
				local z1 = z0 + area.dwz
				local x2 = area.sx + area.dhx - offsetBack * area.dhx_norm
				local z2 = area.sz + area.dhz - offsetBack * area.dhz_norm
				local changed = DensityMapHeightUtil.changeFillTypeAtArea(x0, z0, x1, z1, x2, z2, self.inputFillType, self.fermentingFillType)

				g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
				g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
			end

			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloCovered"))
			end
		elseif state == BunkerSilo.STATE_FERMENTED then
			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloDoneFermenting"))
			end
		elseif state == BunkerSilo.STATE_DRAIN then
			self.bunkerSiloArea.offsetFront = 0
			self.bunkerSiloArea.offsetBack = 0

			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloOpened"))
			end

			if self.isServer then
				g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)

				local fillTypes = {
					[self.outputFillType] = true
				}

				g_densityMapHeightManager:setFixedFillTypesArea(self.bunkerSiloArea, fillTypes)
			end
		end

		self.state = state

		if self.isServer then
			self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
		end
	end
end

function BunkerSilo:showBunkerMessage(msg)
	if g_currentMission.player.farmId == self:getOwnerFarmId() then
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
	end
end

function BunkerSilo:openSilo(px, py, pz)
	self:setState(BunkerSilo.STATE_DRAIN, true)

	self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
	self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
	local openAtFront = self:getIsCloserToFront(px, py, pz)

	if openAtFront and not self.isOpenedAtFront then
		self:switchFillTypeAtOffset(true, self.bunkerSiloArea.offsetFront, self.openingLength)

		self.isOpenedAtFront = true

		self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
	elseif not self.isOpenedAtBack then
		self:switchFillTypeAtOffset(false, self.bunkerSiloArea.offsetBack, self.openingLength)

		self.isOpenedAtBack = true

		self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
	end
end

function BunkerSilo:getBunkerAreaOffset(updateAtFront, offset, fillType)
	local area = self.bunkerSiloArea
	local hx = area.dhx_norm
	local hz = area.dhz_norm
	local hl = MathUtil.vector3Length(area.dhx, area.dhy, area.dhz)

	while offset <= hl - 1 do
		local pos = offset

		if not updateAtFront then
			pos = hl - offset - 1
		end

		local d1x = pos * hx
		local d1z = pos * hz
		local d2x = (pos + 1) * hx
		local d2z = (pos + 1) * hz
		local a0x = area.sx + d1x
		local a0z = area.sz + d1z
		local a1x = area.wx + d1x
		local a1z = area.wz + d1z
		local a2x = area.sx + d2x
		local a2z = area.sz + d2z
		local fillLevel = DensityMapHeightUtil.getFillLevelAtArea(fillType, a0x, a0z, a1x, a1z, a2x, a2z)

		if fillLevel > 0 then
			return offset
		end

		offset = offset + 1
	end

	return math.max(hl - 1, 0)
end

function BunkerSilo:switchFillTypeAtOffset(switchAtFront, offset, length)
	local fillType = self.fermentingFillType
	local newFillType = self.outputFillType
	local a0x, a0z, a1x, a1z, a2x, a2z = nil
	local area = self.bunkerSiloArea

	if switchAtFront then
		a0z = area.sz + offset * area.dhz_norm
		a0x = area.sx + offset * area.dhx_norm
		a1z = a0z + area.dwz
		a1x = a0x + area.dwx
		a2z = area.sz + (offset + length) * area.dhz_norm
		a2x = area.sx + (offset + length) * area.dhx_norm
	else
		a0z = area.hz - offset * area.dhz_norm
		a0x = area.hx - offset * area.dhx_norm
		a1z = a0z + area.dwz
		a1x = a0x + area.dwx
		a2z = area.hz - (offset + length) * area.dhz_norm
		a2x = area.hx - (offset + length) * area.dhx_norm
	end

	DensityMapHeightUtil.changeFillTypeAtArea(a0x, a0z, a1x, a1z, a2x, a2z, fillType, newFillType)
end

function BunkerSilo:getIsCloserToFront(ix, iy, iz)
	local area = self.bunkerSiloArea
	local x = area.sx + 0.5 * area.dwx + area.offsetFront * area.dhx_norm
	local y = area.sy + 0.5 * area.dwy + area.offsetFront * area.dhy_norm
	local z = area.sz + 0.5 * area.dwz + area.offsetFront * area.dhz_norm
	local distFront = MathUtil.vector3Length(x - ix, y - iy, z - iz)
	x = area.sx + 0.5 * area.dwx + area.dhx - area.offsetBack * area.dhx_norm
	y = area.sy + 0.5 * area.dwy + area.dhy - area.offsetBack * area.dhy_norm
	z = area.sz + 0.5 * area.dwz + area.dhz - area.offsetBack * area.dhz_norm
	local distBack = MathUtil.vector3Length(x - ix, y - iy, z - iz)

	return distFront < distBack
end

function BunkerSilo:getCanInteract(showInformationOnly)
	if showInformationOnly then
		if g_currentMission.controlPlayer and self.playerInRange then
			return true
		end

		if not g_currentMission.controlPlayer then
			for vehicle in pairs(self.vehiclesInRange) do
				if vehicle:getIsActiveForInput(true) then
					return true
				end
			end
		end
	elseif g_currentMission.controlPlayer and self.playerInRange then
		return true
	end

	return false
end

function BunkerSilo:getCanCloseSilo()
	return self.state == BunkerSilo.STATE_FILL and self.fillLevel > 0 and self.compactedPercent >= 100
end

function BunkerSilo:getCanOpenSilo()
	if self.state ~= BunkerSilo.STATE_FERMENTED and self.state ~= BunkerSilo.STATE_DRAIN then
		return false
	end

	local ix, iy, iz = self:getInteractionPosition()

	if ix ~= nil then
		local closerToFront = self:getIsCloserToFront(ix, iy, iz)

		if closerToFront and not self.isOpenedAtFront then
			return true
		end

		if not closerToFront and not self.isOpenedAtBack then
			return true
		end
	end

	return false
end

function BunkerSilo:clearSiloArea()
	local xs, _, zs = getWorldTranslation(self.bunkerSiloArea.start)
	local xw, _, zw = getWorldTranslation(self.bunkerSiloArea.width)
	local xh, _, zh = getWorldTranslation(self.bunkerSiloArea.height)

	DensityMapHeightUtil.clearArea(xs, zs, xw, zw, xh, zh)
end

function BunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
	if self.wallLeft ~= nil then
		isLeftVisible = Utils.getNoNil(isLeftVisible, self.wallLeft.visible)

		if self.wallLeft.visible ~= isLeftVisible then
			self.wallLeft.visible = isLeftVisible

			setVisibility(self.wallLeft.node, isLeftVisible)

			if self.wallLeft.collision ~= nil then
				setRigidBodyType(self.wallLeft.collision, isLeftVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end

	if self.wallRight ~= nil then
		isRightVisible = Utils.getNoNil(isRightVisible, self.wallRight.visible)

		if self.wallRight.visible ~= isRightVisible then
			self.wallRight.visible = isRightVisible

			setVisibility(self.wallRight.node, isRightVisible)

			if self.wallRight.collision ~= nil then
				setRigidBodyType(self.wallRight.collision, isRightVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
end

function BunkerSilo:getInteractionPosition()
	if g_currentMission.controlPlayer and self.playerInRange then
		return getWorldTranslation(g_currentMission.player.rootNode)
	elseif self.vehiclesInRange[g_currentMission.currentVehicle] ~= nil then
		return getWorldTranslation(self.vehiclesInRange[g_currentMission.currentVehicle].components[1].node)
	end

	return nil
end

function BunkerSilo:interactionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.playerInRange = true

				g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			else
				self.playerInRange = false

				if self.numVehiclesInRange == 0 then
					g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
				end
			end
		else
			local vehicle = g_currentMission.nodeToObject[otherShapeId]

			if vehicle ~= nil then
				if onEnter then
					if self.vehiclesInRange[vehicle] == nil then
						self.vehiclesInRange[vehicle] = true
						self.numVehiclesInRange = self.numVehiclesInRange + 1

						g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)

						if vehicle.setBunkerSiloInteractorCallback ~= nil then
							vehicle:setBunkerSiloInteractorCallback(BunkerSilo.onChangedFillLevelCallback, self)
						end
					end
				elseif self.vehiclesInRange[vehicle] then
					self.vehiclesInRange[vehicle] = nil
					self.numVehiclesInRange = self.numVehiclesInRange - 1

					if self.numVehiclesInRange == 0 and not self.playerInRange then
						g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
					end

					if vehicle.setBunkerSiloInteractorCallback ~= nil then
						vehicle:setBunkerSiloInteractorCallback(nil)
					end
				end
			end
		end
	end
end

function BunkerSilo:onChangedFillLevelCallback(vehicle, fillDelta, fillType, x, y, z)
	if fillDelta >= 0 then
		return
	end

	local area = self.bunkerSiloArea

	if x == nil or y == nil or z == nil then
		x, y, z = getWorldTranslation(vehicle.components[1].node)
	end

	local closerToFront = self:getIsCloserToFront(x, y, z)
	local length = self.openingLength

	if closerToFront then
		if self.isOpenedAtFront then
			local p1 = MathUtil.getProjectOnLineParameter(x, z, area.sx, area.sz, area.dhx_norm, area.dhz_norm)

			if p1 > area.offsetFront - length then
				local offset = self:getBunkerAreaOffset(true, area.offsetFront, self.fermentingFillType)
				local targetOffset = math.max(p1, offset) + length

				self:switchFillTypeAtOffset(true, area.offsetFront, targetOffset - area.offsetFront)

				area.offsetFront = targetOffset
			end
		end
	elseif self.isOpenedAtBack then
		local p1 = MathUtil.getProjectOnLineParameter(x, z, area.hx, area.hz, -area.dhx_norm, -area.dhz_norm)

		if p1 > area.offsetBack - length then
			local offset = self:getBunkerAreaOffset(true, area.offsetBack, self.fermentingFillType)
			local targetOffset = math.max(p1, offset) + length

			self:switchFillTypeAtOffset(false, area.offsetBack, targetOffset - area.offsetBack)

			area.offsetBack = targetOffset
		end
	end
end

function BunkerSilo.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Area height node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#node", "Left wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#collision", "Left wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#node", "Right wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#collision", "Right wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".interactionTrigger#node", "Interaction trigger node")
	schema:register(XMLValueType.STRING, basePath .. "#acceptedFillTypes", "Accepted fill types", "chaff grass_windrow dryGrass_windrow")
	schema:register(XMLValueType.STRING, basePath .. "#inputFillType", "Input fill type", "chaff")
	schema:register(XMLValueType.STRING, basePath .. "#outputFillType", "Output fill type", "silage")
	schema:register(XMLValueType.FLOAT, basePath .. "#distanceToCompactedFillLevel", "Distance to drive on bunker silo for full compaction", 100)
	schema:register(XMLValueType.FLOAT, basePath .. "#openingLength", "Opening length", 5)
end

function BunkerSilo.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#state", "Current silo state (FILL = 0, CLOSED = 1, FERMENTED = 2, DRAIN = 3)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current fill level")
	schema:register(XMLValueType.FLOAT, basePath .. "#compactedFillLevel", "Compacted fill level")
	schema:register(XMLValueType.FLOAT, basePath .. "#fermentingTime", "Fermenting time")
	schema:register(XMLValueType.BOOL, basePath .. "#openedAtFront", "Is opened at front", false)
	schema:register(XMLValueType.BOOL, basePath .. "#openedAtBack", "Is opened at back", false)
end

BunkerSiloActivatable = {}
local BunkerSiloActivatable_mt = Class(BunkerSiloActivatable)

function BunkerSiloActivatable.new(bunkerSilo)
	local self = {}

	setmetatable(self, BunkerSiloActivatable_mt)

	self.bunkerSilo = bunkerSilo
	self.activateText = "unknown"

	return self
end

function BunkerSiloActivatable:getIsActivatable()
	if self.bunkerSilo:getCanInteract() and (self.bunkerSilo:getCanCloseSilo() or self.bunkerSilo:getCanOpenSilo()) then
		self:updateActivateText()

		return true
	end

	return false
end

function BunkerSiloActivatable:run()
	if self.bunkerSilo:getCanCloseSilo() then
		if g_server ~= nil then
			self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED, true)
		else
			g_client:getServerConnection():sendEvent(BunkerSiloCloseEvent.new(self.bunkerSilo))
		end
	elseif self.bunkerSilo:getCanOpenSilo() then
		local ix, iy, iz = self.bunkerSilo:getInteractionPosition()

		if ix ~= nil then
			if g_server ~= nil then
				self.bunkerSilo:openSilo(ix, iy, iz)
			else
				g_client:getServerConnection():sendEvent(BunkerSiloOpenEvent.new(self.bunkerSilo, ix, iy, iz))
			end
		end
	end

	self:updateActivateText()
end

function BunkerSiloActivatable:updateActivateText()
	self.activateText = "unknown"

	if self.bunkerSilo.state == BunkerSilo.STATE_FILL then
		self.activateText = g_i18n:getText("action_blanketSilo")
	elseif self.bunkerSilo.state == BunkerSilo.STATE_FERMENTED then
		self.activateText = g_i18n:getText("action_openSilo")
	elseif self.bunkerSilo.state == BunkerSilo.STATE_DRAIN and (not self.bunkerSilo.isOpenedAtFront or not self.bunkerSilo.isOpenedAtBack) then
		self.activateText = g_i18n:getText("action_openSilo")
	end
end
