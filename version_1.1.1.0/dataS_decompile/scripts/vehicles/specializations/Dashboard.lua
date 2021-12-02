Dashboard = {
	DEFAULT_MAX_UPDATE_DISTANCE = 7.5,
	DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL = 20,
	GROUP_XML_KEY = "vehicle.dashboard.groups.group(?)",
	TYPES = {}
}
Dashboard.TYPES.EMITTER = 0
Dashboard.TYPES.NUMBER = 1
Dashboard.TYPES.ANIMATION = 2
Dashboard.TYPES.ROT = 3
Dashboard.TYPES.VISIBILITY = 4
Dashboard.TYPES.TEXT = 5
Dashboard.TYPES.SLIDER = 6
Dashboard.TYPES.MULTI_STATE = 7
Dashboard.COLORS = {
	GREY = {
		0.3,
		0.3,
		0.3,
		1
	},
	DARK_GREY = {
		0.15,
		0.15,
		0.15,
		1
	},
	BLACK = {
		0.05,
		0.05,
		0.05,
		1
	},
	LIGHT_GREEN = {
		0.05,
		0.15,
		0.05,
		1
	},
	RED = {
		1,
		0,
		0,
		1
	},
	GREEN = {
		0,
		1,
		0,
		1
	},
	BLUE = {
		0,
		0,
		1,
		1
	},
	YELLOW = {
		1,
		1,
		0,
		1
	},
	ORANGE = {
		1,
		0.5,
		0,
		1
	}
}

function Dashboard.prerequisitesPresent(specializations)
	return true
end

function Dashboard.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Dashboard")
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.dashboard.default")
	schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#name", "Dashboard group name")
	schema:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistanceCritical", "Max. distance to vehicle root to update critical connection hoses (All with type 'ROT')", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
	schema:setXMLSpecializationType()
end

function Dashboard.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboards", Dashboard.updateDashboards)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardGroupFromXML", Dashboard.loadDashboardGroupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDashboardGroupActive", Dashboard.getIsDashboardGroupActive)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardGroupByName", Dashboard.getDashboardGroupByName)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardsFromXML", Dashboard.loadDashboardsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardFromXML", Dashboard.loadDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadEmitterDashboardFromXML", Dashboard.loadEmitterDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadNumberDashboardFromXML", Dashboard.loadNumberDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadTextDashboardFromXML", Dashboard.loadTextDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimationDashboardFromXML", Dashboard.loadAnimationDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadRotationDashboardFromXML", Dashboard.loadRotationDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadVisibilityDashboardFromXML", Dashboard.loadVisibilityDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadSliderDashboardFromXML", Dashboard.loadSliderDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMultiStateDashboardFromXML", Dashboard.loadMultiStateDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setDashboardsDirty", Dashboard.setDashboardsDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardValue", Dashboard.getDashboardValue)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardColor", Dashboard.getDashboardColor)
end

function Dashboard.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Dashboard)
end

function Dashboard:onLoad(savegame)
	local spec = self.spec_dashboard
	spec.dashboards = {}
	spec.criticalDashboards = {}
	spec.groups = {}
	spec.sortedGroups = {}
	spec.groupUpdateIndex = 1
	spec.hasGroups = false
	local i = 0

	while true do
		local baseKey = string.format("%s.groups.group(%d)", "vehicle.dashboard", i)

		if not self.xmlFile:hasProperty(baseKey) then
			break
		end

		local group = {}

		if self:loadDashboardGroupFromXML(self.xmlFile, baseKey, group) then
			spec.groups[group.name] = group

			table.insert(spec.sortedGroups, group)

			spec.hasGroups = true
		end

		i = i + 1
	end

	spec.isDirty = false
	spec.isDirtyTick = false

	self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.default", {})

	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistance", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.maxUpdateDistanceCritical = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistanceCritical", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
end

function Dashboard:onPostLoad(savegame)
	local spec = self.spec_dashboard

	if not self.isClient or #spec.criticalDashboards == 0 and #spec.dashboards == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Dashboard)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Dashboard)
	end
end

function Dashboard:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard

		if spec.hasGroups then
			local group = spec.sortedGroups[spec.groupUpdateIndex]

			if self:getIsDashboardGroupActive(group) ~= group.isActive then
				group.isActive = not group.isActive

				self:updateDashboards(spec.dashboards, dt, true)
				self:updateDashboards(spec.criticalDashboards, dt, true)
			end

			spec.groupUpdateIndex = spec.groupUpdateIndex + 1

			if spec.groupUpdateIndex > #spec.sortedGroups then
				spec.groupUpdateIndex = 1
			end
		end

		if self.currentUpdateDistance < spec.maxUpdateDistanceCritical or spec.isDirty then
			self:updateDashboards(spec.criticalDashboards, dt)

			spec.isDirty = false
		end

		if spec.isDirtyTick then
			self:raiseActive()
		end
	end
end

function Dashboard:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard

		if self.currentUpdateDistance < spec.maxUpdateDistance or spec.isDirtyTick then
			self:updateDashboards(spec.dashboards, dt)

			spec.isDirtyTick = false
		end
	end
end

function Dashboard:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard

		self:updateDashboards(spec.dashboards, dt, true)
		self:updateDashboards(spec.criticalDashboards, dt, true)
	end
end

function Dashboard:updateDashboards(dashboards, dt, force)
	for i = 1, #dashboards do
		local dashboard = dashboards[i]
		local isActive = true

		for j = 1, #dashboard.groups do
			if not dashboard.groups[j].isActive then
				isActive = false

				break
			end
		end

		if dashboard.valueObject ~= nil and dashboard.valueFunc ~= nil then
			local value = self:getDashboardValue(dashboard.valueObject, dashboard.valueFunc, dashboard)

			if dashboard.valueFactor ~= nil and type(value) == "number" then
				value = value * dashboard.valueFactor
			end

			if not isActive then
				value = dashboard.idleValue
			end

			if dashboard.doInterpolation and type(value) == "number" and value ~= dashboard.lastInterpolationValue then
				local dir = MathUtil.sign(value - dashboard.lastInterpolationValue)
				local limitFunc = math.min

				if dir < 0 then
					limitFunc = math.max
				end

				value = limitFunc(dashboard.lastInterpolationValue + dashboard.interpolationSpeed * dir * dt, value)
				dashboard.lastInterpolationValue = value
			end

			if value ~= dashboard.lastValue or force then
				dashboard.lastValue = value
				local min, max = nil

				if type(value) == "number" then
					min = self:getDashboardValue(dashboard.valueObject, dashboard.minFunc, dashboard)

					if min ~= nil then
						value = math.max(min, value)
					end

					max = self:getDashboardValue(dashboard.valueObject, dashboard.maxFunc, dashboard)

					if max ~= nil then
						value = math.min(max, value)
					end

					local center = self:getDashboardValue(dashboard.valueObject, dashboard.centerFunc, dashboard)

					if center ~= nil then
						local maxValue = math.max(math.abs(min), math.abs(max))

						if value < center then
							value = -value / min * maxValue
						elseif center < value then
							value = value / max * maxValue
						end

						max = maxValue
						min = -maxValue
					end
				end

				if dashboard.valueCompare ~= nil then
					if type(dashboard.valueCompare) == "table" then
						local oldValue = value
						value = false

						for _, compareValue in ipairs(dashboard.valueCompare) do
							if oldValue == compareValue then
								value = true
							end
						end
					else
						value = value == dashboard.valueCompare
					end
				end

				dashboard.stateFunc(self, dashboard, value, min, max, isActive)
			end
		elseif force then
			dashboard.stateFunc(self, dashboard, true, nil, , isActive)
		end
	end
end

function Dashboard:loadDashboardGroupFromXML(xmlFile, key, group)
	group.name = xmlFile:getValue(key .. "#name")

	if group.name == nil then
		Logging.xmlWarning(self.xmlFile, "Missing name for dashboard group '%s'", key)

		return false
	end

	if self:getDashboardGroupByName(group.name) ~= nil then
		Logging.xmlWarning(self.xmlFile, "Duplicated dashboard group name '%s' for group '%s'", group.name, key)

		return false
	end

	group.isActive = false

	return true
end

function Dashboard:getIsDashboardGroupActive(group)
	return true
end

function Dashboard:getDashboardGroupByName(name)
	return self.spec_dashboard.groups[name]
end

function Dashboard:loadDashboardsFromXML(xmlFile, key, dashboardData)
	if self.isClient then
		local spec = self.spec_dashboard
		local i = 0

		while true do
			local baseKey = string.format("%s.dashboard(%d)", key, i)

			if not xmlFile:hasProperty(baseKey) then
				break
			end

			local dashboard = {}

			if self:loadDashboardFromXML(xmlFile, baseKey, dashboard, dashboardData) then
				if dashboard.displayTypeIndex ~= Dashboard.TYPES.ROT then
					table.insert(spec.dashboards, dashboard)
				else
					table.insert(spec.criticalDashboards, dashboard)
				end
			end

			i = i + 1
		end
	end

	return true
end

function Dashboard:loadDashboardFromXML(xmlFile, key, dashboard, dashboardData)
	local valueType = xmlFile:getValue(key .. "#valueType")

	if valueType ~= nil then
		if valueType ~= dashboardData.valueTypeToLoad then
			return false
		end
	elseif dashboardData.valueTypeToLoad ~= nil then
		Logging.xmlWarning(self.xmlFile, "Missing valueType for dashboard '%s'", key)

		return false
	end

	local displayType = xmlFile:getValue(key .. "#displayType")

	if displayType ~= nil then
		local displayTypeIndex = Dashboard.TYPES[displayType:upper()]

		if displayTypeIndex ~= nil then
			dashboard.displayTypeIndex = displayTypeIndex
		else
			Logging.xmlWarning(self.xmlFile, "Unknown displayType '%s' for dashboard '%s'", displayType, key)

			return false
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing displayType for dashboard '%s'", key)

		return false
	end

	dashboard.doInterpolation = xmlFile:getValue(key .. "#doInterpolation", false)
	dashboard.interpolationSpeed = xmlFile:getValue(key .. "#interpolationSpeed", 0.005)
	dashboard.idleValue = xmlFile:getValue(key .. "#idleValue", dashboardData.idleValue or 0)
	dashboard.lastInterpolationValue = dashboard.idleValue
	dashboard.groups = {}
	local groupsStr = xmlFile:getValue(key .. "#groups")
	local groups = string.split(groupsStr, " ")

	for _, name in ipairs(groups) do
		local group = self:getDashboardGroupByName(name)

		if group ~= nil then
			table.insert(dashboard.groups, group)
		else
			Logging.xmlWarning(self.xmlFile, "Unable to find dashboard group '%s' for dashboard '%s'", name, key)
		end
	end

	if dashboard.displayTypeIndex == Dashboard.TYPES.EMITTER then
		if not self:loadEmitterDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.NUMBER then
		if not self:loadNumberDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ANIMATION then
		if not self:loadAnimationDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ROT then
		if not self:loadRotationDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.VISIBILITY then
		if not self:loadVisibilityDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.TEXT then
		if not self:loadTextDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.SLIDER then
		if not self:loadSliderDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE and not self:loadMultiStateDashboardFromXML(xmlFile, key, dashboard) then
		return false
	end

	if dashboardData.additionalAttributesFunc ~= nil and not dashboardData.additionalAttributesFunc(self, xmlFile, key, dashboard) then
		return false
	end

	dashboard.valueObject = dashboardData.valueObject
	dashboard.valueFunc = dashboardData.valueFunc
	dashboard.valueCompare = dashboardData.valueCompare
	dashboard.valueFactor = dashboardData.valueFactor
	dashboard.minFunc = dashboardData.minFunc
	dashboard.maxFunc = dashboardData.maxFunc
	dashboard.centerFunc = dashboardData.centerFunc
	dashboard.stateFunc = dashboardData.stateFunc or Dashboard.defaultDashboardStateFunc
	dashboard.lastValue = dashboard.idleValue

	return true
end

function Dashboard:loadEmitterDashboardFromXML(xmlFile, key, dashboard)
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node ~= nil then
		if getHasClassId(node, ClassIds.SHAPE) then
			dashboard.node = node
			dashboard.baseColor = self:getDashboardColor(xmlFile, xmlFile:getValue(key .. "#baseColor"))

			if dashboard.baseColor ~= nil then
				setShaderParameter(dashboard.node, "baseColor", dashboard.baseColor[1], dashboard.baseColor[2], dashboard.baseColor[3], 1, false)
			end

			dashboard.emitColor = self:getDashboardColor(xmlFile, xmlFile:getValue(key .. "#emitColor"))

			if dashboard.emitColor ~= nil then
				setShaderParameter(dashboard.node, "emitColor", dashboard.emitColor[1], dashboard.emitColor[2], dashboard.emitColor[3], 1, false)
			end

			dashboard.intensity = xmlFile:getValue(key .. "#intensity", 1)

			setShaderParameter(dashboard.node, "lightControl", dashboard.idleValue, 0, 0, 0, false)
		else
			Logging.xmlWarning(self.xmlFile, "Emitter Dashboard node is not a shape! '%s' in '%s'", getName(node), key)

			return false
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing node for emitter dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadNumberDashboardFromXML(xmlFile, key, dashboard)
	dashboard.numbers = xmlFile:getValue(key .. "#numbers", nil, self.components, self.i3dMappings)
	dashboard.numberColor = self:getDashboardColor(xmlFile, xmlFile:getValue(key .. "#numberColor"))

	if dashboard.numberColor == nil then
		dashboard.numberColor = {
			0.9,
			0.9,
			0.9,
			1
		}
	end

	if dashboard.numbers ~= nil then
		dashboard.precision = xmlFile:getValue(key .. "#precision", 1)
		dashboard.numChilds = getNumOfChildren(dashboard.numbers)
		dashboard.fontMaterialName = xmlFile:getValue(key .. "#font", "DIGIT")
		dashboard.hasNormalMap = xmlFile:getValue(key .. "#hasNormalMap", false)
		dashboard.emissiveScale = xmlFile:getValue(key .. "#emissiveScale", 0.2)

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#hiddenAlpha")

		dashboard.fontMaterial = g_materialManager:getFontMaterial(dashboard.fontMaterialName, self.customEnvironment)

		if dashboard.fontMaterial ~= nil then
			dashboard.numberNodes = {}

			if dashboard.numChilds - dashboard.precision <= 0 then
				Logging.xmlWarning(self.xmlFile, "Not enough number meshes for vehicle hud '%s'", key)

				return false
			else
				for i = 1, dashboard.numChilds do
					local numberNode = getChildAt(dashboard.numbers, i - 1)

					if numberNode ~= nil then
						dashboard.fontMaterial:assignFontMaterialToNode(numberNode, dashboard.hasNormalMap)

						if dashboard.numberColor ~= nil then
							dashboard.fontMaterial:setFontCharacterColor(numberNode, dashboard.numberColor[1], dashboard.numberColor[2], dashboard.numberColor[3], 1, dashboard.emissiveScale)
						end

						setVisibility(numberNode, false)
						table.insert(dashboard.numberNodes, numberNode)
					end
				end
			end
		else
			Logging.xmlWarning(self.xmlFile, "Unknown font '%s' in '%s'", dashboard.fontMaterialName, key)

			return false
		end

		dashboard.maxValue = 10^dashboard.numChilds - 1 / 10^dashboard.precision
	else
		Logging.xmlWarning(self.xmlFile, "Missing numbers node for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadTextDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	dashboard.textColor = self:getDashboardColor(xmlFile, xmlFile:getValue(key .. "#textColor"))

	if dashboard.textColor == nil then
		dashboard.textColor = {
			0.9,
			0.9,
			0.9,
			1
		}
	end

	dashboard.hiddenColor = self:getDashboardColor(xmlFile, xmlFile:getValue(key .. "#hiddenColor"))

	if dashboard.node ~= nil then
		local textAlignmentStr = xmlFile:getValue(key .. "#textAlignment", "RIGHT")
		dashboard.textAlignment = RenderText["ALIGN_" .. textAlignmentStr:upper()] or RenderText.ALIGN_RIGHT
		dashboard.textSize = xmlFile:getValue(key .. "#textSize", 0.03)
		dashboard.textScaleX = xmlFile:getValue(key .. "#textScaleX", 1)
		dashboard.textScaleY = xmlFile:getValue(key .. "#textScaleY", 1)
		dashboard.textMask = xmlFile:getValue(key .. "#textMask", "00.0")
		dashboard.textFormatStr, dashboard.textFormatPrecision = string.maskToFormat(dashboard.textMask)
		dashboard.fontName = xmlFile:getValue(key .. "#font", "DIGIT"):upper()
		dashboard.fontThickness = xmlFile:getValue(key .. "#fontThickness", 1)
		dashboard.emissiveScale = xmlFile:getValue(key .. "#emissiveScale", 0.2)
		dashboard.fontMaterial = g_materialManager:getFontMaterial(dashboard.fontName, self.customEnvironment)

		if dashboard.fontMaterial ~= nil then
			dashboard.characterLine = dashboard.fontMaterial:createCharacterLine(dashboard.node, dashboard.textMask:len(), dashboard.textSize, dashboard.textColor, dashboard.hiddenColor, dashboard.emissiveScale, dashboard.textScaleX, dashboard.textScaleY, dashboard.textAlignment, nil, dashboard.fontThickness)

			dashboard.fontMaterial:updateCharacterLine(dashboard.characterLine, dashboard.textMask)
		else
			Logging.xmlWarning(self.xmlFile, "Unknown font '%s' in '%s'", dashboard.fontName, key)

			return false
		end

		setVisibility(dashboard.node, false)
	else
		Logging.xmlWarning(self.xmlFile, "Missing node for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadAnimationDashboardFromXML(xmlFile, key, dashboard)
	dashboard.animName = xmlFile:getValue(key .. "#animName")

	if dashboard.animName ~= nil then
		dashboard.minValueAnim = xmlFile:getValue(key .. "#minValueAnim")
		dashboard.maxValueAnim = xmlFile:getValue(key .. "#maxValueAnim")
	else
		Logging.xmlWarning(self.xmlFile, "Missing animation for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadRotationDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if dashboard.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	dashboard.rotAxis = xmlFile:getValue(key .. "#rotAxis")
	local minRotStr = xmlFile:getValue(key .. "#minRot")

	if minRotStr ~= nil then
		if dashboard.rotAxis ~= nil then
			dashboard.minRot = math.rad(tonumber(minRotStr))
		else
			dashboard.minRot = minRotStr:getRadians(3)
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing 'minRot' attribute for dashboard '%s'", key)

		return false
	end

	local maxRotStr = xmlFile:getValue(key .. "#maxRot")

	if maxRotStr ~= nil then
		if dashboard.rotAxis ~= nil then
			dashboard.maxRot = math.rad(tonumber(maxRotStr))
		else
			dashboard.maxRot = maxRotStr:getRadians(3)
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing 'maxRot' attribute for dashboard '%s'", key)

		return false
	end

	dashboard.minValueRot = xmlFile:getValue(key .. "#minValueRot")
	dashboard.maxValueRot = xmlFile:getValue(key .. "#maxValueRot")

	return true
end

function Dashboard:loadVisibilityDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if dashboard.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	setVisibility(dashboard.node, false)

	return true
end

function Dashboard:loadSliderDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if dashboard.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	if not getHasClassId(dashboard.node, ClassIds.SHAPE) then
		Logging.xmlWarning(self.xmlFile, "Slider Dashboard node is not a shape! '%s' in '%s'", getName(dashboard.node), key)

		return false
	end

	if getHasShaderParameter(dashboard.node, "sliderPos") then
		setShaderParameter(dashboard.node, "sliderPos", 0, 0, 0, 0, false)

		dashboard.minValueSlider = xmlFile:getValue(key .. "#minValueSlider")
		dashboard.maxValueSlider = xmlFile:getValue(key .. "#maxValueSlider")
	else
		Logging.xmlWarning(self.xmlFile, "Node '%s' does not have a 'sliderPos' shader parameter for dashboard '%s'", getName(dashboard.node), key)

		return false
	end

	return true
end

function Dashboard:loadMultiStateDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if dashboard.node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	dashboard.states = {}

	self.xmlFile:iterate(key .. ".state", function (index, stateKey)
		local state = {
			values = xmlFile:getValue(stateKey .. "#value", nil, true)
		}

		if state.values ~= nil and #state.values > 0 then
			state.rotation = xmlFile:getValue(stateKey .. "#rotation", nil, true)
			state.translation = xmlFile:getValue(stateKey .. "#translation", nil, true)
			state.scale = xmlFile:getValue(stateKey .. "#scale", nil, true)
			state.visibility = xmlFile:getValue(stateKey .. "#visibility")

			table.insert(dashboard.states, state)
		end
	end)

	if #dashboard.states == 0 then
		Logging.xmlWarning(self.xmlFile, "No states defined for dashboard '%s'", key)

		return false
	end

	dashboard.multiStateInterpolationTime = 1 / dashboard.interpolationSpeed
	dashboard.interpolationSpeed = 99999
	dashboard.lastState = nil

	function dashboard.get()
		local x, y, z = getTranslation(dashboard.node)
		local rx, ry, rz = getRotation(dashboard.node)
		local sx, sy, sz = getScale(dashboard.node)
		local vis = getVisibility(dashboard.node) and 1 or 0

		return x, y, z, rx, ry, rz, sx, sy, sz, vis
	end

	function dashboard.set(x, y, z, rx, ry, rz, sx, sy, sz, vis)
		setTranslation(dashboard.node, x, y, z)
		setRotation(dashboard.node, rx, ry, rz)
		setScale(dashboard.node, sx, sy, sz)
		setVisibility(dashboard.node, vis >= 0.5)

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(dashboard.node)
		end
	end

	dashboard.defaultRotation = {
		getRotation(dashboard.node)
	}
	dashboard.defaultTranslation = {
		getTranslation(dashboard.node)
	}
	dashboard.defaultScale = {
		getScale(dashboard.node)
	}
	dashboard.defaultVisibility = getVisibility(dashboard.node)

	return true
end

function Dashboard:defaultDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.displayTypeIndex == Dashboard.TYPES.EMITTER then
		Dashboard.defaultEmitterDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.NUMBER then
		Dashboard.defaultNumberDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ANIMATION then
		Dashboard.defaultAnimationDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ROT then
		Dashboard.defaultRotationDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.VISIBILITY then
		Dashboard.defaultVisibilityDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.TEXT then
		Dashboard.defaultTextDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.SLIDER then
		Dashboard.defaultSliderDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
		Dashboard.defaultMultiStateDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	end
end

function Dashboard:defaultEmitterDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	newValue = newValue == nil and isActive or newValue and isActive

	setShaderParameter(dashboard.node, "lightControl", newValue and dashboard.intensity or dashboard.idleValue, 0, 0, 0, false)
end

function Dashboard:defaultNumberDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		local value = tonumber(string.format("%." .. dashboard.precision .. "f", newValue))
		value = math.floor(value * 10^dashboard.precision)

		for i = 1, #dashboard.numberNodes do
			local numberNode = dashboard.numberNodes[i]

			if value > 0 then
				local curNumber = value - math.floor(value / 10) * 10
				value = (value - curNumber) / 10

				dashboard.fontMaterial:setFontCharacter(numberNode, ("%d"):format(curNumber))
				setVisibility(numberNode, true)
			else
				dashboard.fontMaterial:setFontCharacter(numberNode, "0")

				if not isActive or i - 1 > dashboard.precision then
					setVisibility(numberNode, false)
				end
			end
		end
	elseif type(newValue) == "string" then
		local length = newValue:len()

		for i = 1, #dashboard.numberNodes do
			local numberNode = dashboard.numberNodes[i]

			if i <= length then
				local index = length - (i - 1)

				dashboard.fontMaterial:setFontCharacter(numberNode, newValue:sub(index, index))
			end

			setVisibility(numberNode, isActive)
		end
	end
end

function Dashboard:defaultTextDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		local int, floatPart = math.modf(newValue)
		local value = string.format(dashboard.textFormatStr, int, math.abs(math.floor((floatPart + 1e-06) * 10^dashboard.textFormatPrecision)))

		dashboard.fontMaterial:updateCharacterLine(dashboard.characterLine, value)
	elseif type(newValue) == "string" then
		dashboard.fontMaterial:updateCharacterLine(dashboard.characterLine, newValue)
	end

	setVisibility(dashboard.node, isActive)
end

function Dashboard:defaultAnimationDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.animName ~= nil then
		if self:getAnimationExists(dashboard.animName) then
			local normValue = nil

			if dashboard.minValueAnim ~= nil and dashboard.maxValueAnim ~= nil then
				newValue = MathUtil.clamp(newValue, dashboard.minValueAnim, dashboard.maxValueAnim)
				normValue = MathUtil.round((newValue - dashboard.minValueAnim) / (dashboard.maxValueAnim - dashboard.minValueAnim), 3)
			else
				minValue = minValue or 0
				maxValue = maxValue or 1
				normValue = MathUtil.round((newValue - minValue) / (maxValue - minValue), 3)
			end

			self:setAnimationTime(dashboard.animName, normValue, true)
		else
			Logging.xmlWarning(self.xmlFile, "Unknown animation name '%s' for dashboard!", dashboard.animName)

			dashboard.animName = nil
		end
	end
end

function Dashboard:defaultRotationDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	local alpha = nil

	if type(newValue) == "boolean" then
		if newValue then
			alpha = 1
		else
			alpha = 0
		end
	elseif dashboard.minValueRot ~= nil and dashboard.maxValueRot ~= nil then
		newValue = MathUtil.clamp(newValue, dashboard.minValueRot, dashboard.maxValueRot)
		alpha = MathUtil.round((newValue - dashboard.minValueRot) / (dashboard.maxValueRot - dashboard.minValueRot), 3)
	else
		minValue = minValue or 0
		maxValue = maxValue or 1
		alpha = (newValue - minValue) / (maxValue - minValue)
	end

	if dashboard.rotAxis ~= nil then
		local x, y, z = getRotation(dashboard.node)
		local rot = MathUtil.lerp(dashboard.minRot, dashboard.maxRot, alpha)

		if dashboard.rotAxis == 1 then
			x = rot
		elseif dashboard.rotAxis == 2 then
			y = rot
		else
			z = rot
		end

		setRotation(dashboard.node, x, y, z)

		if self.setCharacterTargetNodeStateDirty ~= nil then
			self:setCharacterTargetNodeStateDirty(dashboard.node)
		end

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(dashboard.node)
		end
	else
		local x1, y1, z1 = unpack(dashboard.minRot)
		local x2, y2, z2 = unpack(dashboard.maxRot)
		local x, y, z = MathUtil.lerp3(x1, y1, z1, x2, y2, z2, alpha)

		setRotation(dashboard.node, x, y, z)

		if self.setCharacterTargetNodeStateDirty ~= nil then
			self:setCharacterTargetNodeStateDirty(dashboard.node)
		end

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(dashboard.node)
		end
	end
end

function Dashboard:defaultVisibilityDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	newValue = newValue == nil and isActive or newValue and isActive

	setVisibility(dashboard.node, newValue)
end

function Dashboard:defaultSliderDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.node ~= nil then
		local normValue = nil

		if dashboard.minValueSlider ~= nil and dashboard.maxValueSlider ~= nil then
			newValue = MathUtil.clamp(newValue, dashboard.minValueSlider, dashboard.maxValueSlider)
			normValue = MathUtil.round((newValue - dashboard.minValueSlider) / (dashboard.maxValueSlider - dashboard.minValueSlider), 3)
		else
			minValue = minValue or 0
			maxValue = maxValue or 1
			normValue = MathUtil.round((newValue - minValue) / (maxValue - minValue), 3)
		end

		setShaderParameter(dashboard.node, "sliderPos", normValue, 0, 0, 0, false)
	end
end

function Dashboard:defaultMultiStateDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.node ~= nil then
		local activeState = nil

		if isActive then
			for i = 1, #dashboard.states do
				local state = dashboard.states[i]

				if type(newValue) == "table" then
					for j = 1, #state.values do
						if newValue[state.values[j]] == true then
							activeState = state
						end
					end
				elseif type(newValue) == "number" then
					for j = 1, #state.values do
						if state.values[j] == MathUtil.round(newValue) then
							activeState = state
						end
					end
				end
			end
		end

		local rotation = dashboard.defaultRotation
		local translation = dashboard.defaultTranslation
		local scale = dashboard.defaultScale
		local visibility = dashboard.defaultVisibility

		if activeState ~= dashboard.lastState then
			if activeState ~= nil then
				rotation = activeState.rotation or rotation
				translation = activeState.translation or translation
				scale = activeState.scale or scale

				if activeState.visibility ~= nil then
					visibility = activeState.visibility
				end
			end

			if dashboard.doInterpolation then
				if dashboard.interpolator ~= nil then
					dashboard.interpolator:update(9999999)
				end

				local interpolator = ValueInterpolator.new(dashboard.node .. "_dashboard", dashboard.get, dashboard.set, {
					translation[1],
					translation[2],
					translation[3],
					rotation[1],
					rotation[2],
					rotation[3],
					scale[1],
					scale[2],
					scale[3],
					visibility and 1 or 0
				}, dashboard.multiStateInterpolationTime)

				if interpolator ~= nil then
					dashboard.interpolator = interpolator

					dashboard.interpolator:setDeleteListenerObject(self)
					dashboard.interpolator:setFinishedFunc(function (dash)
						dash.interpolator = nil
					end, dashboard)
				end
			else
				setRotation(dashboard.node, rotation[1], rotation[2], rotation[3])
				setTranslation(dashboard.node, translation[1], translation[2], translation[3])
				setScale(dashboard.node, scale[1], scale[2], scale[3])
				setVisibility(dashboard.node, visibility)

				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(dashboard.node)
				end
			end

			dashboard.lastState = activeState
		end
	end
end

function Dashboard:warningAttributes(xmlFile, key, dashboard, isActive)
	dashboard.warningThresholdMin = xmlFile:getValue(key .. "#warningThresholdMin", -math.huge)
	dashboard.warningThresholdMax = xmlFile:getValue(key .. "#warningThresholdMax", math.huge)

	return true
end

function Dashboard:warningState(dashboard, newValue, minValue, maxValue, isActive)
	Dashboard.defaultDashboardStateFunc(self, dashboard, dashboard.warningThresholdMin < newValue and newValue < dashboard.warningThresholdMax, minValue, maxValue, isActive)
end

function Dashboard:setDashboardsDirty()
	self.spec_dashboard.isDirty = true
	self.spec_dashboard.isDirtyTick = true

	self:raiseActive()
end

function Dashboard:getDashboardValue(valueObject, valueFunc, dashboard)
	if type(valueFunc) == "number" or type(valueFunc) == "boolean" then
		return valueFunc
	elseif type(valueFunc) == "function" then
		return valueFunc(valueObject, dashboard)
	end

	local object = valueObject[valueFunc]

	if type(object) == "function" then
		return valueObject[valueFunc](valueObject, dashboard)
	elseif type(object) == "number" or type(object) == "boolean" then
		return object
	end

	return nil
end

function Dashboard:getDashboardColor(xmlFile, colorStr)
	if colorStr == nil then
		return nil
	end

	if Dashboard.COLORS[colorStr:upper()] ~= nil then
		return Dashboard.COLORS[colorStr:upper()]
	end

	local brandColor = g_brandColorManager:getBrandColorByName(colorStr)

	if brandColor ~= nil then
		return brandColor
	end

	local vector = string.getVectorN(colorStr)

	if vector ~= nil and #vector >= 3 then
		if #vector == 3 then
			vector[4] = 1
		end

		return vector
	end

	Logging.xmlWarning(xmlFile, "Unable to resolve color '%s'", colorStr)

	return nil
end

function Dashboard.registerDashboardXMLPaths(schema, basePath, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#valueType", string.format("Value type name (Available: %s)", availableValueTypes or "no valueTypes available here"))
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#displayType", "Display type name")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#doInterpolation", "Do interpolation", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#interpolationSpeed", "Interpolation speed", 0.005)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#idleValue", "Idle value", 0)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#groups", "List of groups")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dashboard(?)#node", "(EMITTER | ROT | VISIBILITY) Node")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#baseColor", "(EMITTER) Base color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#emitColor", "(EMITTER) Emit color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "(EMITTER) Intensity", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dashboard(?)#numbers", "(NUMBER) Numbers node")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#numberColor", "(NUMBER) Numbers color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.INT, basePath .. ".dashboard(?)#precision", "(NUMBER) Precision", 1)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#font", "(NUMBER) Name of font to apply to mesh", "DIGIT")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#hasNormalMap", "(NUMBER) Normal map will be applied to number decals", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#emissiveScale", "(NUMBER) Scale of emissive map", 0.2)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textColor", "(TEXT) Font color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#hiddenColor", "(TEXT) Color of hidden character (if defined a '0' in this color is display instead of nothing)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textAlignment", "(TEXT) Alignment of text (LEFT | RIGHT | CENTER)", "RIGHT")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textSize", "(TEXT) Size of font in meter", 0.03)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#fontThickness", "(TEXT) Thickness factor for font characters", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textScaleX", "(TEXT) Global X scale of text", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textScaleY", "(TEXT) Global Y scale of text", 1)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textMask", "(TEXT) Font Mask", "00.0")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#animName", "(ANIMATION) Animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueAnim", "(ANIMATION) Min. reference value for animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueAnim", "(ANIMATION) Max. reference value for animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#rotAxis", "(ROT) Rotation axis")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#minRot", "(ROT) Min. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#maxRot", "(ROT) Min. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueRot", "(ROT) Min. reference value for rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueRot", "(ROT) Max. reference value for rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueSlider", "(SLIDER) Min. reference value for slider")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueSlider", "(SLIDER) Max. reference value for slider")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".dashboard(?).state(?)#value", "(MULTI_STATE) One or multiple values separated by space to activate the state")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".dashboard(?).state(?)#rotation", "(MULTI_STATE) Rotation while state is active")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".dashboard(?).state(?)#translation", "(MULTI_STATE) Translation while state is active")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".dashboard(?).state(?)#scale", "(MULTI_STATE) Scale while state is active")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?).state(?)#visibility", "(MULTI_STATE) Visibility while state is active")
end

function Dashboard.registerDashboardWarningXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMin", "(WARNING) Threshold min.")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMax", "(WARNING) Threshold max.")
end
