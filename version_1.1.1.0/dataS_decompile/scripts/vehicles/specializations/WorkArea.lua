WorkArea = {
	WORK_AREA_XML_KEY = "vehicle.workAreas.workArea(?)",
	WORK_AREA_XML_CONFIG_KEY = "vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(?).workArea(?)"
}

function WorkArea.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("default", false)
	g_workAreaTypeManager:addWorkAreaType("auxiliary", false)
	g_configurationManager:addConfigurationType("workArea", g_i18n:getText("configuration_workArea"), "workAreas", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("WorkArea")
	WorkArea.registerWorkAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_KEY)
	WorkArea.registerWorkAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_CONFIG_KEY)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(?)")
	schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#workAreaIndex", "Work area index")
	schema:setXMLSpecializationType()
end

function WorkArea.registerWorkAreaXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Work area type", "DEFAULT")
	schema:register(XMLValueType.BOOL, basePath .. "#requiresGroundContact", "Requires ground contact to work", true)
	schema:register(XMLValueType.BOOL, basePath .. "#disableBackwards", "Area is disabled while driving backwards", true)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresOwnedFarmland", "Requires owned farmland", true)
	schema:register(XMLValueType.STRING, basePath .. "#functionName", "Work area script function")
	schema:register(XMLValueType.STRING, basePath .. "#preprocessFunctionName", "Pre process work area script function")
	schema:register(XMLValueType.STRING, basePath .. "#postprocessFunctionName", "Post process work area script function")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Height node")
	schema:register(XMLValueType.INT, basePath .. ".groundReferenceNode#index", "Ground reference node index")
	schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Work area is only active when lowered", false)
end

function WorkArea.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(GroundReference, specializations)
end

function WorkArea.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartWorkAreaProcessing")
	SpecializationUtil.registerEvent(vehicleType, "onEndWorkAreaProcessing")
end

function WorkArea.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWorkAreaFromXML", WorkArea.loadWorkAreaFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getWorkAreaByIndex", WorkArea.getWorkAreaByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaActive", WorkArea.getIsWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaWidth", WorkArea.updateWorkAreaWidth)
	SpecializationUtil.registerFunction(vehicleType, "getWorkAreaWidth", WorkArea.getWorkAreaWidth)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaProcessing", WorkArea.getIsWorkAreaProcessing)
	SpecializationUtil.registerFunction(vehicleType, "getTypedNetworkAreas", WorkArea.getTypedNetworkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getTypedWorkAreas", WorkArea.getTypedWorkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getIsTypedWorkAreaActive", WorkArea.getIsTypedWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsFarmlandNotOwnedWarningShown", WorkArea.getIsFarmlandNotOwnedWarningShown)
	SpecializationUtil.registerFunction(vehicleType, "getLastTouchedFarmlandFarmId", WorkArea.getLastTouchedFarmlandFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getLastActiveMissionWork", WorkArea.getLastActiveMissionWork)
	SpecializationUtil.registerFunction(vehicleType, "getIsAccessibleAtWorldPosition", WorkArea.getIsAccessibleAtWorldPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateLastWorkedArea", WorkArea.updateLastWorkedArea)
end

function WorkArea.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", WorkArea.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", WorkArea.getIsSpeedRotatingPartActive)
end

function WorkArea.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkArea)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkArea)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", WorkArea)
end

function WorkArea:onLoad(savegame)
	local spec = self.spec_workArea

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#startIndex", "vehicle.workAreas.workArea(0).area#startIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#widthIndex", "vehicle.workAreas.workArea(0).area#widthIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#heightIndex", "vehicle.workAreas.workArea(0).area#heightIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMinLimit", "vehicle.workAreas.workArea(0).folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#foldMaxLimit", "vehicle.workAreas.workArea(0).folding#maxLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.workAreas.workArea(0)#refNodeIndex", "vehicle.workAreas.workArea(0).groundReferenceNode#index")

	local configurationId = Utils.getNoNil(self.configurations.workArea, 1)
	local configKey = string.format("vehicle.workAreas.workAreaConfigurations.workAreaConfiguration(%d)", configurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.workAreas.workAreaConfigurations.workAreaConfiguration", configurationId, self.components, self)

	if not self.xmlFile:hasProperty(configKey) then
		configKey = "vehicle.workAreas"
	end

	spec.workAreas = {}
	local i = 0

	while true do
		local key = string.format("%s.workArea(%d)", configKey, i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local workArea = {}

		if self:loadWorkAreaFromXML(workArea, self.xmlFile, key) then
			table.insert(spec.workAreas, workArea)

			workArea.index = #spec.workAreas

			self:updateWorkAreaWidth(workArea.index)
		end

		i = i + 1
	end

	spec.workAreaByType = {}

	for _, area in pairs(spec.workAreas) do
		if spec.workAreaByType[area.type] == nil then
			spec.workAreaByType[area.type] = {}
		end

		table.insert(spec.workAreaByType[area.type], area)
	end

	spec.lastAccessedFarmlandOwner = 0
	spec.lastActiveMissionWork = false
	spec.lastWorkedArea = -1
	spec.showFarmlandNotOwnedWarning = false
	spec.warningCantUseMissionVehiclesOnOtherLand = g_i18n:getText("warning_cantUseMissionVehiclesOnOtherLand")
	spec.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youDontHaveAccessToThisLand")
end

function WorkArea:getIsAccessibleAtWorldPosition(farmId, x, z, workAreaType)
	if self.propertyState == Vehicle.PROPERTY_STATE_MISSION then
		return g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType), farmId, true
	end

	local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)

	if farmlandId == nil then
		return false, nil, false
	end

	if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
		return false, FarmlandManager.NO_OWNER_FARM_ID, false
	end

	local landOwner = g_farmlandManager:getFarmlandOwner(farmlandId)
	local accessible = landOwner ~= 0 and g_currentMission.accessHandler:canFarmAccessOtherId(farmId, landOwner) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType)

	return accessible, landOwner, true
end

function WorkArea:updateLastWorkedArea(area)
	local spec = self.spec_workArea
	spec.lastWorkedArea = math.max(area, spec.lastWorkedArea)
end

function WorkArea:getLastTouchedFarmlandFarmId()
	local spec = self.spec_workArea

	if spec.lastAccessedFarmlandOwner ~= 0 then
		return spec.lastAccessedFarmlandOwner
	end

	return 0
end

function WorkArea:getLastActiveMissionWork()
	return self.spec_workArea.lastActiveMissionWork
end

function WorkArea:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workArea

	SpecializationUtil.raiseEvent(self, "onStartWorkAreaProcessing", dt, spec.workAreas)

	spec.showFarmlandNotOwnedWarning = false
	local hasProcessed = false
	local farmId = self:getActiveFarm()

	if farmId == nil then
		farmId = AccessHandler.EVERYONE
	end

	local isOwned = false
	local isBuyable = false
	local allowWarning = false

	for i = 1, #spec.workAreas do
		local workArea = spec.workAreas[i]

		if workArea.type ~= WorkAreaType.AUXILIARY then
			workArea.lastWorkedHectares = 0
			local isAreaActive = self:getIsWorkAreaActive(workArea)

			if isAreaActive and workArea.requiresOwnedFarmland then
				local xs, _, zs = getWorldTranslation(workArea.start)
				local isAccessible, farmlandOwner, buyable = self:getIsAccessibleAtWorldPosition(farmId, xs, zs, workArea.type)
				isBuyable = isBuyable or buyable

				if isAccessible then
					if farmlandOwner ~= nil then
						spec.lastAccessedFarmlandOwner = farmlandOwner
						spec.lastActiveMissionWork = g_missionManager:getIsMissionWorkAllowed(farmId, xs, zs, workArea.type)
					end

					isOwned = true
				else
					local xw, _, zw = getWorldTranslation(workArea.width)
					isAccessible, _, buyable = self:getIsAccessibleAtWorldPosition(farmId, xw, zw, workArea.type)
					isBuyable = isBuyable or buyable

					if isAccessible then
						isOwned = true
					else
						local xh, _, zh = getWorldTranslation(workArea.height)
						isAccessible, _, buyable = self:getIsAccessibleAtWorldPosition(farmId, xh, zh, workArea.type)
						isBuyable = isBuyable or buyable

						if isAccessible then
							isOwned = true
						else
							local x = xw + xh - xs
							local z = zw + zh - zs
							isAccessible, _, buyable = self:getIsAccessibleAtWorldPosition(farmId, x, z, workArea.type)
							isBuyable = isBuyable or buyable

							if isAccessible then
								isOwned = true
							end
						end
					end
				end

				if not isOwned then
					isAreaActive = false
				end

				allowWarning = isBuyable
			end

			if isAreaActive then
				if workArea.preprocessingFunction ~= nil then
					workArea.preprocessingFunction(self, workArea, dt)
				end

				if workArea.processingFunction ~= nil then
					local realArea, _ = workArea.processingFunction(self, workArea, dt)

					if realArea > 0 then
						workArea.lastWorkedHectares = MathUtil.areaToHa(realArea, g_currentMission:getFruitPixelsToSqm())
						workArea.lastProcessingTime = g_currentMission.time

						if g_currentMission.wildlifeSpawner ~= nil then
							local workAreaType = g_workAreaTypeManager:getWorkAreaTypeByIndex(workArea.type)

							if workAreaType.attractWildlife then
								local xw, _, zw = getWorldTranslation(workArea.width)
								local xh, _, zh = getWorldTranslation(workArea.height)
								local radius = 3
								local posX = 0.5 * xw + 0.5 * xh
								local posZ = 0.5 * zw + 0.5 * zh
								local lifeTime = 0

								g_currentMission.wildlifeSpawner:addAreaOfInterest(lifeTime, posX, posZ, radius)
							end
						end
					else
						workArea.lastWorkedHectares = 0
					end
				end

				if workArea.postprocessingFunction ~= nil then
					workArea.postprocessingFunction(self, workArea, dt)
				end

				hasProcessed = true
			end
		end
	end

	if allowWarning and not isOwned then
		spec.showFarmlandNotOwnedWarning = true
	end

	SpecializationUtil.raiseEvent(self, "onEndWorkAreaProcessing", dt, hasProcessed)

	if spec.lastWorkedArea >= 0 then
		local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())
		local ha = MathUtil.areaToHa(spec.lastWorkedArea, g_currentMission:getFruitPixelsToSqm())

		stats:updateStats("workedHectares", ha)
		stats:updateStats("workedTime", dt / 60000)

		spec.lastWorkedArea = -1
	end
end

function WorkArea:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workArea

	if spec.showFarmlandNotOwnedWarning then
		if self.propertyState == Vehicle.PROPERTY_STATE_MISSION then
			g_currentMission:showBlinkingWarning(spec.warningCantUseMissionVehiclesOnOtherLand)
		else
			g_currentMission:showBlinkingWarning(spec.warningYouDontHaveAccessToThisLand)
		end
	end
end

function WorkArea:loadWorkAreaFromXML(workArea, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#startIndex", key .. ".area#startNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#widthIndex", key .. ".area#widthNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".area#heightIndex", key .. ".area#heightNode")

	local start = xmlFile:getValue(key .. ".area#startNode", workArea.start, self.components, self.i3dMappings)
	local width = xmlFile:getValue(key .. ".area#widthNode", workArea.width, self.components, self.i3dMappings)
	local height = xmlFile:getValue(key .. ".area#heightNode", workArea.height, self.components, self.i3dMappings)

	if start ~= nil and width ~= nil and height ~= nil then
		if calcDistanceFrom(start, width) < 0.001 then
			Logging.xmlError(xmlFile, "'start' and 'width' have the same position for '%s'!", key)

			return false
		end

		if calcDistanceFrom(width, height) < 0.001 then
			Logging.xmlError(xmlFile, "'width' and 'height' have the same position for '%s'!", key)

			return false
		end

		local areaTypeStr = xmlFile:getValue(key .. "#type")
		workArea.type = g_workAreaTypeManager:getWorkAreaTypeIndexByName(areaTypeStr) or WorkAreaType.DEFAULT

		if workArea.type == nil then
			Logging.xmlWarning(xmlFile, "Invalid workArea type '%s' for workArea '%s'!", areaTypeStr, key)

			return false
		end

		workArea.requiresGroundContact = xmlFile:getValue(key .. "#requiresGroundContact", true)

		if workArea.type ~= WorkAreaType.AUXILIARY then
			if workArea.requiresGroundContact then
				XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#refNodeIndex", key .. ".groundReferenceNode#index")

				local groundReferenceNodeIndex = xmlFile:getValue(key .. ".groundReferenceNode#index")

				if groundReferenceNodeIndex == nil then
					Logging.xmlWarning(xmlFile, "Missing groundReference 'groundReferenceNode#index' for workArea '%s'. Add requiresGroundContact=\"false\" if groundContact is not required!", key)

					return false
				end

				local groundReferenceNode = self:getGroundReferenceNodeFromIndex(groundReferenceNodeIndex)

				if groundReferenceNode ~= nil then
					workArea.groundReferenceNode = groundReferenceNode
				else
					Logging.xmlWarning(xmlFile, "Invalid groundReferenceNode-index for workArea '%s'!", key)

					return false
				end
			end

			workArea.disableBackwards = xmlFile:getValue(key .. "#disableBackwards", true)
			workArea.onlyActiveWhenLowered = xmlFile:getValue(key .. ".onlyActiveWhenLowered#value", false)
			workArea.functionName = xmlFile:getValue(key .. "#functionName")

			if workArea.functionName == nil then
				Logging.xmlWarning(xmlFile, "Missing 'functionName' for workArea '%s'!", key)

				return false
			else
				if self[workArea.functionName] == nil then
					Logging.xmlWarning(xmlFile, "Given functionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.functionName))

					return false
				end

				workArea.processingFunction = self[workArea.functionName]
			end

			if g_isDevelopmentVersion and not SpecializationUtil.hasSpecialization(Cutter, self.specializations) and not SpecializationUtil.hasSpecialization(Pickup, self.specializations) and not SpecializationUtil.hasSpecialization(Drivable, self.specializations) and xmlFile:getString(key .. ".onlyActiveWhenLowered#value") == nil then
				Logging.xmlDevWarning(xmlFile, "Work area has no 'onlyActiveWhenLowered' attribute set! '%s'", key)
			end

			workArea.preprocessFunctionName = xmlFile:getValue(key .. "#preprocessFunctionName")

			if workArea.preprocessFunctionName ~= nil then
				if self[workArea.preprocessFunctionName] == nil then
					Logging.xmlWarning(xmlFile, "Given preprocessFunctionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.preprocessFunctionName))

					return false
				end

				workArea.preprocessingFunction = self[workArea.preprocessFunctionName]
			end

			workArea.postprocessFunctionName = xmlFile:getValue(key .. "#postprocessFunctionName")

			if workArea.postprocessFunctionName ~= nil then
				if self[workArea.postprocessFunctionName] == nil then
					Logging.xmlWarning(xmlFile, "Given postprocessFunctionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.postprocessFunctionName))

					return false
				end

				workArea.postprocessingFunction = self[workArea.postprocessFunctionName]
			end

			workArea.requiresOwnedFarmland = xmlFile:getValue(key .. "#requiresOwnedFarmland", true)
		end

		workArea.lastProcessingTime = 0
		workArea.start = start
		workArea.width = width
		workArea.height = height
		workArea.workWidth = -1

		return true
	end

	return false
end

function WorkArea:getWorkAreaByIndex(workAreaIndex)
	local spec = self.spec_workArea

	return spec.workAreas[workAreaIndex]
end

function WorkArea:getIsWorkAreaActive(workArea)
	if workArea.requiresGroundContact == true and workArea.groundReferenceNode ~= nil and not self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode) then
		return false
	end

	if workArea.disableBackwards and self.movingDirection <= 0 then
		return false
	end

	if workArea.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
		return false
	end

	return true
end

function WorkArea:updateWorkAreaWidth(workAreaIndex)
	local spec = self.spec_workArea
	local workArea = spec.workAreas[workAreaIndex]
	local x1, _, _ = localToLocal(self.components[1].node, workArea.start, 0, 0, 0)
	local x2, _, _ = localToLocal(self.components[1].node, workArea.width, 0, 0, 0)
	local x3, _, _ = localToLocal(self.components[1].node, workArea.height, 0, 0, 0)
	workArea.workWidth = math.max(x1, x2, x3) - math.min(x1, x2, x3)
end

function WorkArea:getWorkAreaWidth(workAreaIndex)
	local spec = self.spec_workArea

	return spec.workAreas[workAreaIndex].workWidth
end

function WorkArea:getIsWorkAreaProcessing(workArea)
	return g_currentMission.time <= workArea.lastProcessingTime + 200
end

function WorkArea:getTypedNetworkAreas(areaType, needsFieldProperty)
	local workAreasSend = {}
	local area = 0
	local typedWorkAreas = self:getTypedWorkAreas(areaType)
	local showFarmlandNotOwnedWarning = false

	for _, workArea in pairs(typedWorkAreas) do
		if self:getIsWorkAreaActive(workArea) then
			local x, _, z = getWorldTranslation(workArea.start)
			local isAccessible = not needsFieldProperty

			if needsFieldProperty then
				local farmId = g_currentMission:getFarmId()
				isAccessible = g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, areaType)
			end

			if isAccessible then
				local x1, _, z1 = getWorldTranslation(workArea.width)
				local x2, _, z2 = getWorldTranslation(workArea.height)
				area = area + math.abs((z1 - z) * (x2 - x) - (x1 - x) * (z2 - z))

				table.insert(workAreasSend, {
					x,
					z,
					x1,
					z1,
					x2,
					z2
				})
			else
				showFarmlandNotOwnedWarning = true
			end
		end
	end

	return workAreasSend, showFarmlandNotOwnedWarning, area
end

function WorkArea:getTypedWorkAreas(areaType)
	local spec = self.spec_workArea
	local workAreas = spec.workAreaByType[areaType]

	if workAreas == nil then
		workAreas = {}
	end

	return workAreas
end

function WorkArea:getIsTypedWorkAreaActive(areaType)
	local isActive = false
	local typedWorkAreas = self:getTypedWorkAreas(areaType)

	for _, workArea in pairs(typedWorkAreas) do
		if self:getIsWorkAreaActive(workArea) then
			isActive = true

			break
		end
	end

	return isActive, typedWorkAreas
end

function WorkArea:getIsFarmlandNotOwnedWarningShown()
	return self.spec_workArea.showFarmlandNotOwnedWarning
end

function WorkArea:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")

	return true
end

function WorkArea:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.workAreaIndex ~= nil then
		local spec = self.spec_workArea
		local workArea = spec.workAreas[speedRotatingPart.workAreaIndex]

		if workArea == nil then
			speedRotatingPart.workAreaIndex = nil

			Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex '%s'. Indexing starts with 1!", tostring(speedRotatingPart.workAreaIndex))

			return true
		end

		if not self:getIsWorkAreaProcessing(spec.workAreas[speedRotatingPart.workAreaIndex]) then
			return false
		end
	end

	return superFunc(self, speedRotatingPart)
end
