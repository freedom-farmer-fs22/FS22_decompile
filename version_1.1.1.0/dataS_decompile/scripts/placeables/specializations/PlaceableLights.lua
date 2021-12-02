PlaceableLights = {}

source("dataS/scripts/placeables/specializations/events/PlaceableLightsStateEvent.lua")

PlaceableLights.MAX_NUM_BITS = 5
PlaceableLights.MAX_NUM_GROUPS = 2^PlaceableLights.MAX_NUM_BITS

function PlaceableLights.prerequisitesPresent(specializations)
	return true
end

function PlaceableLights.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "lightSetupChanged", PlaceableLights.lightSetupChanged)
	SpecializationUtil.registerFunction(placeableType, "getUseHighProfile", PlaceableLights.getUseHighProfile)
	SpecializationUtil.registerFunction(placeableType, "setGroupIsActive", PlaceableLights.setGroupIsActive)
	SpecializationUtil.registerFunction(placeableType, "lightsTriggerCallback", PlaceableLights.lightsTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "sharedLightLoaded", PlaceableLights.sharedLightLoaded)
	SpecializationUtil.registerFunction(placeableType, "updateLightState", PlaceableLights.updateLightState)
end

function PlaceableLights.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableLights)
end

function PlaceableLights.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Lights")
	schema:register(XMLValueType.STRING, basePath .. ".lights.sharedLight(?)#filename", "Path to shared light xml file")
	schema:register(XMLValueType.INT, basePath .. ".lights.sharedLight(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.sharedLight(?)#linkNode", "Link node")
	schema:register(XMLValueType.COLOR, basePath .. ".lights.sharedLight(?)#color", "Light color")
	schema:register(XMLValueType.STRING, basePath .. ".lights.sharedLight(?).rotationNode(?)#name", "Rotation node name")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".lights.sharedLight(?).rotationNode(?)#rotation", "Rotation to set")
	schema:register(XMLValueType.INT, basePath .. ".lights.lightShape(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.lightShape(?)#node", "Light shape / self-illum-mesh node. Always visible, only shader is set")
	schema:register(XMLValueType.FLOAT, basePath .. ".lights.lightShape(?)#intensity", "Intensity for the shader if active", 25)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.realLights.low.light(?)#node", "Real light node used on low performance profile. Visibility is toggled based on settings")
	schema:register(XMLValueType.INT, basePath .. ".lights.realLights.low.light(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.realLights.high.light(?)#node", "Real light node used on high performance profile. Visibility is toggled based on settings")
	schema:register(XMLValueType.INT, basePath .. ".lights.realLights.high.light(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.group(?)#triggerNode", "Activation Trigger for manual control")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#inputAction", "Input Action name", "INTERACT")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#name", "Group name for display", "action_placeableLightShed")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#activateText", "Activate text to display in help menu", "action_placeableLightPos")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#deactivateText", "Deactivate text to display in help menu", "action_placeableLightNeg")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#activateTime", "If defined, light will be turned on at this time of day. Format hh:mm")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#deactivateTime", "If defined, light will be turned off at this time of day. Format hh:mm")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#weatherRequiredFlags", "Space separeted list of environment flag names to be used as required mask")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#weatherPreventFlags", "Space separeted list of environment flag names to be used as prevent mask")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".lights.group(?).sounds", "toggle")
	schema:setXMLSpecializationType()
end

function PlaceableLights:onLoad(savegame)
	local spec = self.spec_lights
	local xmlFile = self.xmlFile
	local environmentMaskSystem = g_currentMission.environment.environmentMaskSystem
	spec.sharedLights = {}
	spec.groups = {}
	spec.triggerToGroup = {}
	spec.activatable = PlaceableLightsActivatable.new(self)

	g_messageCenter:subscribe(MessageType.SETTING_CHANGED.lightsProfile, self.lightSetupChanged, self)
	xmlFile:iterate("placeable.lights.group", function (lightIndex, lightGroupKey)
		local group = {
			triggerNode = xmlFile:getValue(lightGroupKey .. "#triggerNode", nil, self.components, self.i3dMappings)
		}

		if group.triggerNode ~= nil then
			addTrigger(group.triggerNode, "lightsTriggerCallback", self)

			spec.triggerToGroup[group.triggerNode] = group
		end

		local inputActionName = xmlFile:getValue(lightGroupKey .. "#inputAction", "INTERACT")
		group.inputAction = InputAction[inputActionName] or InputAction.INTERACT
		group.name = xmlFile:getValue(lightGroupKey .. "#name", "action_placeableLightShed", self.customEnvironment)
		group.activateText = xmlFile:getValue(lightGroupKey .. "#activateText", "action_placeableLightPos", self.customEnvironment)
		group.deactivateText = xmlFile:getValue(lightGroupKey .. "#deactivateText", "action_placeableLightNeg", self.customEnvironment)
		local activateTimeStr = xmlFile:getValue(lightGroupKey .. "#activateTime", nil)

		if activateTimeStr ~= nil then
			group.activateMinute = Utils.getMinuteOfDayFromTime(activateTimeStr)

			if group.activateMinute == nil then
				Logging.xmlWarning(xmlFile, "Invalid activateTime string '%s' given for group '%s'. Use 'hh:mm' format", activateTimeStr, lightGroupKey)
			else
				group.activateMinute = math.max(1, group.activateMinute)
			end
		end

		local deactivateTimeStr = xmlFile:getValue(lightGroupKey .. "#deactivateTime", nil)

		if deactivateTimeStr ~= nil then
			group.deactivateMinute = Utils.getMinuteOfDayFromTime(deactivateTimeStr)

			if group.deactivateMinute == nil then
				Logging.xmlWarning(xmlFile, "Invalid deactivateTime string '%s' given for group '%s'. Use 'hh:mm' format", deactivateTimeStr, lightGroupKey)
			else
				group.deactivateMinute = math.max(1, group.deactivateMinute)
			end
		end

		group.weatherRequiredMask = environmentMaskSystem:getWeatherMaskFromFlagNames(xmlFile:getValue(lightGroupKey .. "#weatherRequiredFlags", nil))
		group.weatherPreventMask = environmentMaskSystem:getWeatherMaskFromFlagNames(xmlFile:getValue(lightGroupKey .. "#weatherPreventFlags", nil))

		if self.isClient then
			group.samples = {
				toggle = g_soundManager:loadSampleFromXML(xmlFile, lightGroupKey .. ".sounds", "toggle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
			}
		end

		if (group.activateMinute ~= nil and group.deactivateMinute) == nil or group.deactivateMinute == nil and group.activateMinute ~= nil then
			Logging.xmlWarning(xmlFile, "Incomplete automatic toggle time in '%s'", lightGroupKey)
		else
			group.hasManualLights = group.triggerNode ~= nil
			group.isActive = false
			group.playerInRange = false

			if #spec.groups < PlaceableLights.MAX_NUM_GROUPS then
				table.insert(spec.groups, group)

				group.index = #spec.groups
			else
				Logging.xmlWarning(xmlFile, "Too many light groups registered. Max. %d are allowed", PlaceableLights.MAX_NUM_GROUPS)
			end
		end
	end)
	xmlFile:iterate("placeable.lights.sharedLight", function (lightIndex, lightKey)
		local sharedLight = {}
		local xmlFilename = xmlFile:getValue(lightKey .. "#filename")

		if xmlFilename ~= nil then
			sharedLight.xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
			sharedLight.groupIndex = xmlFile:getValue(lightKey .. "#groupIndex", 1)
			sharedLight.color = xmlFile:getValue(lightKey .. "#color", nil, true)
			sharedLight.linkNode = xmlFile:getValue(lightKey .. "#linkNode", "0>", self.components, self.i3dMappings)
			local group = spec.groups[sharedLight.groupIndex]

			if group == nil then
				Logging.xmlError("Group index '%d' in '%s' does not exist", sharedLight.groupIndex, lightKey)
			elseif sharedLight.linkNode ~= nil then
				sharedLight.rotations = {}

				xmlFile:iterate(lightKey .. ".rotationNode", function (rotIndex, rotKey)
					local name = xmlFile:getValue(rotKey .. "#name")
					local rotation = xmlFile:getValue(rotKey .. "#rotation", nil, true)

					if name ~= nil then
						sharedLight.rotations[name] = rotation
					end
				end)

				local lightXMLFile = XMLFile.load("sharedLight", sharedLight.xmlFilename, Lights.sharedLightXMLSchema)

				if lightXMLFile ~= nil then
					local filename = lightXMLFile:getValue("light.filename")

					if filename ~= nil then
						local task = self:createLoadingTask(spec)
						filename = Utils.getFilename(filename, self.baseDirectory)
						sharedLight.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.sharedLightLoaded, self, {
							sharedLight,
							lightXMLFile,
							task,
							group,
							filename
						})

						table.insert(spec.sharedLights, sharedLight)
					else
						Logging.xmlWarning(lightXMLFile, "Missing light i3d filename!")
						lightXMLFile:delete()
					end
				end
			end
		end
	end)

	spec.lightShapes = {}

	local function getNodeShaderLightIntensity(node)
		if getHasShaderParameter(node, "lightControl") then
			local x = getShaderParameter(node, "lightControl")

			return x
		end

		return 1
	end

	xmlFile:iterate("placeable.lights.lightShape", function (lightIndex, lightKey)
		local lightShape = {
			groupIndex = xmlFile:getValue(lightKey .. "#groupIndex", 1),
			node = xmlFile:getValue(lightKey .. "#node", "0>", self.components, self.i3dMappings)
		}

		if lightShape.node ~= nil then
			lightShape.intensity = xmlFile:getValue(lightKey .. "#intensity", getNodeShaderLightIntensity(lightShape.node))
			local group = spec.groups[lightShape.groupIndex]

			if group == nil then
				Logging.xmlError(xmlFile, "Group index '%d' in '%s' does not exist", lightShape.groupIndex, lightKey)
			elseif not group.hasManualLights then
				if group.activateMinute ~= nil then
					setVisibilityConditionMinuteOfDay(lightShape.node, group.activateMinute, group.deactivateMinute)
				end

				if group.weatherRequiredMask ~= nil or group.weatherPreventMask ~= nil then
					setVisibilityConditionWeatherMask(lightShape.node, group.weatherRequiredMask or 0, group.weatherPreventMask or 0)
				end

				setVisibilityConditionRenderInvisible(lightShape.node, true)
				setVisibilityConditionVisibleShaderParameter(lightShape.node, lightShape.intensity)
			end

			table.insert(spec.lightShapes, lightShape)
		end
	end)

	spec.realLights = {
		low = {},
		high = {}
	}

	local function loadRealLight(realLightKey, insertTable)
		local realLight = {
			node = xmlFile:getValue(realLightKey .. "#node", nil, self.components, self.i3dMappings)
		}

		if realLight.node ~= nil then
			realLight.groupIndex = xmlFile:getValue(realLightKey .. "#groupIndex", 1)
			local group = spec.groups[realLight.groupIndex]

			if group == nil then
				Logging.xmlError("Group index '%d' in '%s' does not exist", realLight.groupIndex, realLightKey)
			else
				if group.activateMinute ~= nil then
					setVisibilityConditionMinuteOfDay(realLight.node, group.activateMinute, group.deactivateMinute)
				end

				if group.weatherRequiredMask ~= nil or group.weatherPreventMask ~= nil then
					setVisibilityConditionWeatherMask(realLight.node, group.weatherRequiredMask or 0, group.weatherPreventMask or 0)
				end

				table.insert(insertTable, realLight)
			end
		end
	end

	xmlFile:iterate("placeable.lights.realLights.low.light", function (lightIndex, lightKey)
		loadRealLight(lightKey, spec.realLights.low)
	end)
	xmlFile:iterate("placeable.lights.realLights.high.light", function (lightIndex, lightKey)
		loadRealLight(lightKey, spec.realLights.high)
	end)
end

function PlaceableLights:onFinalizePlacement()
	self:lightSetupChanged()
end

function PlaceableLights:sharedLightLoaded(i3dNode, failedReason, args)
	local spec = self.spec_lights
	local sharedLight, lightXMLFile, loadingTask, lightGroup, i3dFilename = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		if self.loadingState == Placeable.LOADING_STATE_OK then
			sharedLight.node = lightXMLFile:getValue("light.rootNode#node", "0", i3dNode)
			sharedLight.i3dFilename = i3dFilename
			sharedLight.lightShapes = {}

			lightXMLFile:iterate("light.defaultLight", function (lightIndex, lightKey)
				local lightShape = {
					node = lightXMLFile:getValue(lightKey .. "#node", nil, i3dNode)
				}

				if lightShape.node ~= nil then
					if getHasShaderParameter(lightShape.node, "lightControl") then
						lightShape.intensity = lightXMLFile:getValue(lightKey .. "#intensity", 25)

						if lightGroup.hasManualLights then
							setShaderParameter(lightShape.node, "lightControl", 0, 0, 0, 0, false)
						else
							if lightGroup.activateMinute ~= nil then
								setVisibilityConditionMinuteOfDay(lightShape.node, lightGroup.activateMinute, lightGroup.deactivateMinute)
							end

							if lightGroup.weatherRequiredMask ~= nil or lightGroup.weatherPreventMask ~= nil then
								setVisibilityConditionWeatherMask(lightShape.node, lightGroup.weatherRequiredMask or 0, lightGroup.weatherPreventMask or 0)
							end

							setVisibilityConditionRenderInvisible(lightShape.node, true)
							setVisibilityConditionVisibleShaderParameter(lightShape.node, lightShape.intensity)
						end

						table.insert(sharedLight.lightShapes, lightShape)
					else
						Logging.xmlWarning(lightXMLFile, "Node '%s' has no shaderparameter 'lightControl'. Ignoring node!", getName(lightShape.node))
					end

					if sharedLight.color ~= nil and getHasShaderParameter(lightShape.node, "colorScale") then
						setShaderParameter(lightShape.node, "colorScale", sharedLight.color[1], sharedLight.color[2], sharedLight.color[3], 0, false)
					end
				else
					Logging.xmlWarning(lightXMLFile, "Could not find node for '%s'!", lightKey)
				end
			end)
			lightXMLFile:iterate("light.rotationNode", function (rotIndex, rotKey)
				local name = lightXMLFile:getValue(rotKey .. "#name")

				if name ~= nil then
					local node = lightXMLFile:getValue(rotKey .. "#node", nil, i3dNode)

					if sharedLight.rotations[name] ~= nil then
						setRotation(node, unpack(sharedLight.rotations[name]))
					end
				end
			end)

			sharedLight.rotations = nil

			link(sharedLight.linkNode, sharedLight.node)
		end

		delete(i3dNode)
	end

	lightXMLFile:delete()
	self:finishLoadingTask(loadingTask)
end

function PlaceableLights:onDelete()
	local spec = self.spec_lights

	if spec.sharedLights ~= nil then
		for _, light in ipairs(spec.sharedLights) do
			if light.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(light.sharedLoadRequestId)

				light.sharedLoadRequestId = nil
			end
		end

		spec.sharedLights = {}
	end

	g_messageCenter:unsubscribeAll(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

	if spec.groups ~= nil then
		for _, group in ipairs(spec.groups) do
			if group.triggerNode ~= nil then
				removeTrigger(group.triggerNode)
			end

			g_soundManager:deleteSamples(group.samples)
		end

		spec.groups = {}
	end
end

function PlaceableLights:onReadStream(streamId, connection)
	local spec = self.spec_lights

	for k, group in ipairs(spec.groups) do
		if group.hasManualLights then
			self:setGroupIsActive(k, streamReadBool(streamId), true)
		end
	end
end

function PlaceableLights:onWriteStream(streamId, connection)
	local spec = self.spec_lights

	for _, group in ipairs(spec.groups) do
		if group.hasManualLights then
			streamWriteBool(streamId, group.isActive)
		end
	end
end

function PlaceableLights:getUseHighProfile()
	local lightsProfile = g_gameSettings:getValue("lightsProfile")
	lightsProfile = Utils.getNoNil(Platform.gameplay.lightsProfile, lightsProfile)

	return lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_HIGH
end

function PlaceableLights:setGroupIsActive(groupIndex, isActive, noEventSend)
	local spec = self.spec_lights
	local group = spec.groups[groupIndex]

	if group ~= nil then
		group.isActive = Utils.getNoNil(isActive, not group.isActive)

		self:updateLightState(groupIndex, group.isActive)
		PlaceableLightsStateEvent.sendEvent(self, groupIndex, group.isActive, noEventSend)

		if self.isClient then
			g_soundManager:playSample(group.samples.toggle, 1)
		end
	end
end

function PlaceableLights:updateLightState(groupIndex, isActive)
	local spec = self.spec_lights
	local group = spec.groups[groupIndex]

	if group.hasManualLights then
		for _, sharedLight in ipairs(spec.sharedLights) do
			if sharedLight.groupIndex == groupIndex then
				for j = 1, #sharedLight.lightShapes do
					local lightShape = sharedLight.lightShapes[j]

					setShaderParameter(lightShape.node, "lightControl", isActive and lightShape.intensity or 0, 0, 0, 0, false)
				end
			end
		end

		for _, lightShape in ipairs(spec.lightShapes) do
			if lightShape.groupIndex == groupIndex then
				setShaderParameter(lightShape.node, "lightControl", isActive and lightShape.intensity or 0, 0, 0, 0, false)
			end
		end
	end

	local activeLightSetup = spec.realLights.low
	local inactiveLightSetup = spec.realLights.high

	if self:getUseHighProfile() then
		activeLightSetup = spec.realLights.high
		inactiveLightSetup = spec.realLights.low
	end

	for _, realLight in ipairs(activeLightSetup) do
		if realLight.groupIndex == groupIndex then
			setVisibility(realLight.node, not group.hasManualLights or isActive)
		end
	end

	for _, realLight in ipairs(inactiveLightSetup) do
		if realLight.groupIndex == groupIndex then
			setVisibility(realLight.node, false)
		end
	end
end

function PlaceableLights:lightsTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local spec = self.spec_lights
	local group = spec.triggerToGroup[triggerId]

	if group ~= nil and (onEnter or onLeave) then
		local player = g_currentMission.player

		if player ~= nil and otherId == player.rootNode then
			if onEnter then
				group.playerInRange = true

				g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
				spec.activatable:setGroupIndex(group.index)
			else
				group.playerInRange = false
				local inRangeOfOtherGroups = false

				for _, otherGroup in ipairs(spec.groups) do
					inRangeOfOtherGroups = inRangeOfOtherGroups or otherGroup.playerInRange
				end

				if not inRangeOfOtherGroups then
					g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
				end
			end
		end
	end
end

function PlaceableLights:lightSetupChanged()
	local spec = self.spec_lights

	for k, group in ipairs(spec.groups) do
		self:updateLightState(k, group.isActive)
	end
end

PlaceableLightsActivatable = {}
local PlaceableLightsActivatable_mt = Class(PlaceableLightsActivatable)

function PlaceableLightsActivatable.new(placeable)
	local self = setmetatable({}, PlaceableLightsActivatable_mt)
	self.placeable = placeable
	self.groupIndex = 1
	self.activateText = ""

	return self
end

function PlaceableLightsActivatable:setGroupIndex(groupIndex)
	self.groupIndex = groupIndex or 1

	self:updateActivateText()
end

function PlaceableLightsActivatable:run()
	self.placeable:setGroupIsActive(self.groupIndex)
	self:updateActivateText()
end

function PlaceableLightsActivatable:updateActivateText()
	local group = self.placeable.spec_lights.groups[self.groupIndex]

	if group.triggerNode ~= nil then
		if group.isActive then
			self.activateText = string.format(group.deactivateText, group.name)
		else
			self.activateText = string.format(group.activateText, group.name)
		end
	end
end

function PlaceableLightsActivatable:getDistance(x, y, z)
	local group = self.placeable.spec_lights.groups[self.groupIndex]

	if group.triggerNode ~= nil then
		local tx, ty, tz = getWorldTranslation(group.triggerNode)

		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	end

	return math.huge
end
