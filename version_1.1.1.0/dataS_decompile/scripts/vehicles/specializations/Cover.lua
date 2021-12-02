source("dataS/scripts/vehicles/specializations/events/SetCoverStateEvent.lua")

Cover = {
	SEND_NUM_BITS = 4,
	COVER_XML_KEY = "vehicle.cover.coverConfigurations.coverConfiguration(?).cover(?)",
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function Cover.initSpecialization()
	g_configurationManager:addConfigurationType("cover", g_i18n:getText("configuration_cover"), "cover", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Cover")
	schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#openAnimation", "Open animation name")
	schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStopTime", "Open animation stop time")
	schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#openAnimationStartTime", "Open animation start time")
	schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#closeAnimation", "Close animation name")
	schema:register(XMLValueType.FLOAT, Cover.COVER_XML_KEY .. "#closeAnimationStopTime", "Close animation stop time")
	schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#openOnBuy", "Open after buying", false)
	schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#forceOpenOnTip", "Open while tipping", true)
	schema:register(XMLValueType.BOOL, Cover.COVER_XML_KEY .. "#autoReactToTrigger", "Automatically open in triggers", true)
	schema:register(XMLValueType.VECTOR_N, Cover.COVER_XML_KEY .. "#fillUnitIndices", "Fill unit indices to cover")
	schema:register(XMLValueType.STRING, Cover.COVER_XML_KEY .. "#blockedToolTypes", "List with blocked tool types", "dischargeable bale trigger pallet")
	schema:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#closeCoverIfNotAllowed", "Close cover if not allowed to open it", false)
	schema:register(XMLValueType.BOOL, "vehicle.cover.coverConfigurations.coverConfiguration(?)#openCoverWhileTipping", "Open cover while tipping", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.cover.coverConfigurations.coverConfiguration(?)")
	schema:register(XMLValueType.STRING, "vehicle.pipe#coverMinState", "Min. cover state to allow pipe state change", 0)
	schema:register(XMLValueType.STRING, "vehicle.pipe#coverMaxState", "Max. cover state to allow pipe state change", "Max. cover state")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).cover#state", "Current cover state")
end

function Cover.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCoverFromXML", Cover.loadCoverFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowed", Cover.getIsNextCoverStateAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setCoverState", Cover.setCoverState)
	SpecializationUtil.registerFunction(vehicleType, "playCoverAnimation", Cover.playCoverAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getCoverByFillUnitIndex", Cover.getCoverByFillUnitIndex)
end

function Cover.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Cover.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Cover.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPipeNodes", Cover.loadPipeNodes)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPipeStateChangeAllowed", Cover.getIsPipeStateChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiPrepareLoading", Cover.aiPrepareLoading)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiFinishLoading", Cover.aiFinishLoading)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "finishedAIDischarge", Cover.finishedAIDischarge)
end

function Cover.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitTriggerChanged", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Cover)
end

function Cover:onLoad(savegame)
	local spec = self.spec_cover

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cover#animationName", "vehicle.cover.coverConfigurations.coverConfiguration.cover#openAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#closeCoverOnFold", "vehicle.cover.coverConfigurations.coverConfiguration.cover#closeCoverIfNotAllowed")

	local coverConfigurationId = Utils.getNoNil(self.configurations.cover, 1)
	local configKey = string.format("vehicle.cover.coverConfigurations.coverConfiguration(%d)", coverConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.cover.coverConfigurations.coverConfiguration", coverConfigurationId, self.components, self)

	spec.state = 0
	spec.runningAnimations = {}
	spec.covers = {}
	spec.fillUnitIndexToCovers = {}
	spec.isStateSetAutomatically = false
	local i = 0

	while true do
		local key = string.format("%s.cover(%d)", configKey, i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local cover = {}

		if self:loadCoverFromXML(self.xmlFile, key, cover) then
			for j = #cover.fillUnitIndices, 1, -1 do
				local index = cover.fillUnitIndices[j]

				if spec.fillUnitIndexToCovers[index] == nil then
					spec.fillUnitIndexToCovers[index] = {
						cover
					}
				else
					table.insert(spec.fillUnitIndexToCovers[index], cover)
				end
			end

			table.insert(spec.covers, cover)

			cover.index = #spec.covers
		end

		i = i + 1
	end

	spec.closeCoverIfNotAllowed = self.xmlFile:getValue(configKey .. "#closeCoverIfNotAllowed", false)
	spec.openCoverWhileTipping = self.xmlFile:getValue(configKey .. "#openCoverWhileTipping", false)
	spec.hasCovers = #spec.covers > 0
	spec.isDirty = false

	if not spec.hasCovers then
		SpecializationUtil.removeEventListener(self, "onReadStream", Cover)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Cover)
		SpecializationUtil.removeEventListener(self, "onUpdate", Cover)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cover)
		SpecializationUtil.removeEventListener(self, "onStartTipping", Cover)
		SpecializationUtil.removeEventListener(self, "onFillUnitTriggerChanged", Cover)
		SpecializationUtil.removeEventListener(self, "onRemovedFillUnitTrigger", Cover)
	end
end

function Cover:onPostLoad(savegame)
	local spec = self.spec_cover

	if spec.hasCovers then
		local state = 0

		if savegame ~= nil then
			state = savegame.xmlFile:getValue(savegame.key .. ".cover#state", state)
		end

		if state == 0 then
			spec.state = #spec.covers
		end

		self:setCoverState(state, true)

		for i = #spec.runningAnimations, 1, -1 do
			local animation = spec.runningAnimations[i]

			AnimatedVehicle.updateAnimationByName(self, animation.name, 9999999, true)
			table.remove(spec.runningAnimations, i)
		end

		spec.isDirty = false
	end
end

function Cover:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_cover

	if spec.hasCovers then
		xmlFile:setValue(key .. "#state", spec.state)
	end
end

function Cover:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_cover
		local state = streamReadUIntN(streamId, Cover.SEND_NUM_BITS)

		self:setCoverState(state, true)

		for i = #spec.runningAnimations, 1, -1 do
			local animation = spec.runningAnimations[i]

			AnimatedVehicle.updateAnimationByName(self, animation.name, 9999999, true)
			table.remove(spec.runningAnimations, i)
		end

		spec.isDirty = false
	end
end

function Cover:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.spec_cover.state, Cover.SEND_NUM_BITS)
	end
end

function Cover:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cover

	if spec.isDirty then
		local animation = spec.runningAnimations[1]

		if animation ~= nil then
			local nextAnim = spec.runningAnimations[2]

			if nextAnim ~= nil and nextAnim.name == animation.name then
				table.remove(spec.runningAnimations, 1)
				self:stopAnimation(animation.name, true)
				self:playCoverAnimation(nextAnim)
			end

			if not self:getIsAnimationPlaying(animation.name) then
				table.remove(spec.runningAnimations, 1)

				local nextAnimation = spec.runningAnimations[1]

				if nextAnimation ~= nil then
					self:playCoverAnimation(nextAnimation)
				else
					spec.isDirty = false
				end
			end
		end
	end

	if spec.closeCoverIfNotAllowed and spec.state ~= 0 then
		local newState = spec.state + 1

		if newState > #spec.covers then
			newState = 0
		end

		if not self:getIsNextCoverStateAllowed(newState) then
			self:setCoverState(0, true)
		end
	end
end

function Cover:loadCoverFromXML(xmlFile, key, cover)
	cover.openAnimation = xmlFile:getValue(key .. "#openAnimation")
	cover.openAnimationStartTime = xmlFile:getValue(key .. "#openAnimationStartTime")
	cover.openAnimationStopTime = xmlFile:getValue(key .. "#openAnimationStopTime")

	if cover.openAnimation == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'openAnimation' for cover '%s'!", key)

		return false
	end

	cover.closeAnimation = xmlFile:getValue(key .. "#closeAnimation")
	cover.closeAnimationStopTime = xmlFile:getValue(key .. "#closeAnimationStopTime")
	cover.startOpenState = xmlFile:getValue(key .. "#openOnBuy", false)
	cover.forceOpenOnTip = xmlFile:getValue(key .. "#forceOpenOnTip", true)
	cover.autoReactToTrigger = xmlFile:getValue(key .. "#autoReactToTrigger", true)
	cover.fillUnitIndices = xmlFile:getValue(key .. "#fillUnitIndices", nil, true)

	if cover.fillUnitIndices == nil then
		Logging.xmlWarning(self.xmlFile, "Missing 'fillUnitIndices' for cover '%s'!", key)

		return false
	end

	cover.blockedToolTypes = {}
	local strBlockedToolTypes = xmlFile:getValue(key .. "#blockedToolTypes", "dischargeable bale trigger pallet")
	strBlockedToolTypes = strBlockedToolTypes:trim():split(" ")

	for _, toolType in ipairs(strBlockedToolTypes) do
		local index = g_toolTypeManager:getToolTypeIndexByName(toolType)

		if index ~= ToolType.UNDEFINED then
			cover.blockedToolTypes[index] = true
		end
	end

	return true
end

function Cover:setCoverState(state, noEventSend)
	local spec = self.spec_cover

	if spec.hasCovers and state >= 0 and state <= #spec.covers then
		SetCoverStateEvent.sendEvent(self, state, noEventSend)

		local startAnim = #spec.runningAnimations == 0

		if spec.state > 0 then
			local cover = spec.covers[spec.state]
			local animation = cover.closeAnimation
			local stopTime = cover.closeAnimationStopTime or 1

			if animation == nil then
				animation = cover.openAnimation
				stopTime = cover.openAnimationStopTime or 0
			end

			if self:getAnimationExists(animation) then
				table.insert(spec.runningAnimations, {
					name = animation,
					stopTime = stopTime
				})
			end
		end

		if state > 0 then
			local cover = spec.covers[state]

			table.insert(spec.runningAnimations, {
				name = cover.openAnimation,
				startTime = cover.openAnimationStartTime,
				stopTime = cover.openAnimationStopTime or 1
			})
		end

		spec.state = state
		spec.isDirty = #spec.runningAnimations > 0

		if startAnim and #spec.runningAnimations > 0 then
			self:playCoverAnimation(spec.runningAnimations[1])
		end

		Cover.updateActionText(self)
	end
end

function Cover:playCoverAnimation(animation)
	if animation.startTime ~= nil then
		log("anim", animation.startTime)
		self:setAnimationTime(animation.name, animation.startTime, true)
	end

	local dir = MathUtil.sign(animation.stopTime - self:getAnimationTime(animation.name))

	self:setAnimationStopTime(animation.name, animation.stopTime)
	self:playAnimation(animation.name, dir, animation.startTime or self:getAnimationTime(animation.name), true)
end

function Cover:getCoverByFillUnitIndex(fillUnitIndex)
	local covers = self.spec_cover.fillUnitIndexToCovers[fillUnitIndex]

	if covers ~= nil then
		return covers[1]
	end

	return nil
end

function Cover:getIsNextCoverStateAllowed(nextState)
	return true
end

function Cover:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	local spec = self.spec_cover

	if spec.hasCovers then
		local covers = spec.fillUnitIndexToCovers[fillUnitIndex]

		if covers ~= nil and #covers > 0 then
			local isOpen = false

			for i = 1, #covers do
				local cover = covers[i]

				if spec.state == cover.index then
					isOpen = true

					break
				end
			end

			if not isOpen and covers[1].blockedToolTypes[toolType] then
				return false
			end
		end
	end

	return superFunc(self, fillUnitIndex, toolType)
end

function Cover:getCanBeSelected(superFunc)
	return true
end

function Cover:loadPipeNodes(superFunc, pipeNodes, xmlFile, baseKey)
	superFunc(self, pipeNodes, xmlFile, baseKey)

	local spec = self.spec_pipe
	spec.coverMinState = xmlFile:getValue("vehicle.pipe#coverMinState", 0)
	spec.coverMaxState = xmlFile:getValue("vehicle.pipe#coverMaxState", #self.spec_cover.covers)
end

function Cover:getIsPipeStateChangeAllowed(superFunc)
	if not superFunc(self) then
		return false
	end

	local spec = self.spec_pipe
	local specCover = self.spec_cover

	if specCover.state < spec.coverMinState or spec.coverMaxState < specCover.state then
		return false
	end

	return true
end

function Cover:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_cover

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local state, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_COVER, self, Cover.actionEventToggleCover, false, true, false, true, nil, , true, true)

			if not state then
				local _ = nil
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Cover.actionEventToggleCover, false, true, false, true, nil, , true, true)
			end

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			Cover.updateActionText(self)
		end
	end
end

function Cover:onStartTipping(tipSide)
	if self.spec_cover.openCoverWhileTipping then
		local trailerSpec = self.spec_trailer
		local tipSideDesc = trailerSpec.tipSides[tipSide]
		local dischargeNode = self:getDischargeNodeByIndex(tipSideDesc.dischargeNodeIndex)
		local cover = self:getCoverByFillUnitIndex(dischargeNode.fillUnitIndex)

		if cover ~= nil then
			self:setCoverState(cover.index, true)
		end
	end
end

function Cover:finishedAIDischarge(superFunc)
	local spec = self.spec_cover

	if spec.hasCovers then
		self:setCoverState(0)
	end

	superFunc(self)
end

function Cover:aiPrepareLoading(superFunc, fillUnitIndex, task)
	local cover = self:getCoverByFillUnitIndex(fillUnitIndex)

	if cover ~= nil then
		self:setCoverState(cover.index)
	end

	superFunc(self, fillUnitIndex, task)
end

function Cover:aiFinishLoading(superFunc, fillUnitIndex, task)
	local spec = self.spec_cover

	if spec.hasCovers then
		self:setCoverState(0)
	end

	superFunc(self, fillUnitIndex, task)
end

function Cover:onFillUnitTriggerChanged(fillTrigger, fillTypeIndex, fillUnitIndex, numTriggers)
	local spec = self.spec_cover
	local covers = spec.fillUnitIndexToCovers[fillUnitIndex]

	if covers ~= nil then
		local isDifferentState = true

		for _, cover in pairs(covers) do
			isDifferentState = isDifferentState and spec.state ~= cover.index
		end

		local isStateChangedAllowed = self:getIsNextCoverStateAllowed(covers[1].index)

		if covers[1].autoReactToTrigger and isDifferentState and isStateChangedAllowed then
			self:setCoverState(covers[1].index, true)

			spec.isStateSetAutomatically = true
		end
	end
end

function Cover:onRemovedFillUnitTrigger(numTriggers)
	local spec = self.spec_cover

	if numTriggers == 0 then
		local cover = spec.covers[spec.state]

		if cover ~= nil and spec.isStateSetAutomatically and cover.autoReactToTrigger then
			self:setCoverState(0, true)

			spec.isStateSetAutomatically = false
		end
	end
end

function Cover:updateActionText()
	local spec = self.spec_cover

	if next(spec.actionEvents) ~= nil then
		local actionEvent = spec.actionEvents[next(spec.actionEvents)]

		if actionEvent ~= nil then
			local text = g_i18n:getText("action_nextCover")

			if spec.state == #spec.covers then
				text = g_i18n:getText("action_closeCover")
			elseif spec.state == 0 then
				text = g_i18n:getText("action_openCover")
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function Cover:actionEventToggleCover(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_cover
	local newState = spec.state + 1

	if newState > #spec.covers then
		newState = 0
	end

	if self:getIsNextCoverStateAllowed(newState) then
		self:setCoverState(newState)

		spec.isStateSetAutomatically = false
	end
end
