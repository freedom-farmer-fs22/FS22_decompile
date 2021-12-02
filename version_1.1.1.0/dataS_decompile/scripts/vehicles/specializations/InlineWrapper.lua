InlineWrapper = {
	INTERACTION_RADIUS = 5
}

source("dataS/scripts/vehicles/specializations/events/InlineWrapperPushOffEvent.lua")

function InlineWrapper.prerequisitesPresent(specializations)
	return true
end

function InlineWrapper.initSpecialization()
	g_storeManager:addSpecType("inlineWrapperBaleSizeRound", "shopListAttributeIconBaleWrapperBaleSizeRound", InlineWrapper.loadSpecValueBaleSizeRound, InlineWrapper.getSpecValueBaleSizeRound, "vehicle")
	g_storeManager:addSpecType("inlineWrapperBaleSizeSquare", "shopListAttributeIconBaleWrapperBaleSizeSquare", InlineWrapper.loadSpecValueBaleSizeSquare, InlineWrapper.getSpecValueBaleSizeSquare, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("InlineWrapper")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTrigger#node", "Bale pickup trigger")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#minFoldTime", "Min. folding time for bale pickup", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#maxFoldTime", "Max. folding time for bale pickup", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapTrigger#node", "Wrap trigger")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTypes.baleType(?)#startNode", "Start placement node for bale")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).railing#width", "Railing width to set")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.baleTypes.baleType(?).inlineBale#filename", "Path to inline bale xml file")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#diameter", "Bale diameter")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#width", "Bale width")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#height", "Bale height")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#length", "Bale length")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.railings#animation", "Railing animation")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animStartX", "Railing width at start of animation")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animEndX", "Railing width at end of animation")
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#defaultX", "Default railing width", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapping#startNode", "Reference node for warpping state of bale")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.steeringNodes.steeringNode(?)#node", "Steering node that is aligned to the start wrapping direction")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#node", "Wrapping node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#target", "Target node that is aliged to the bale")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#startTrans", "Start translation")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pusher", "Pusher animation", "pusherAnimation")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#wrapping", "Wrapping animation", "wrappingAnimation")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pushOff", "Push bale off animation", "pushOffAnimation")
	schema:register(XMLValueType.STRING, "vehicle.inlineWrapper.pushing#brakeForce", "Brake force while pushing", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#openBrakeTime", "Pusher animation time to open brake", 0.1)
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#closeBrakeTime", "Pusher animation time to close brake", 0.5)
	schema:register(XMLValueType.INT, "vehicle.inlineWrapper.pushing#minBaleAmount", "Min. bales wrapped to open brake", 4)
	schema:register(XMLValueType.FLOAT, "vehicle.inlineWrapper#baleMovedThreshold", "Bale moved threshold for starting wrappign animation", 0.05)
	schema:register(XMLValueType.INT, "vehicle.inlineWrapper#numObjectBits", "Num bits for sending bales", 4)
	SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "wrap")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "start")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.inlineWrapper.sounds", "stop")
	schema:setXMLSpecializationType()
end

function InlineWrapper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readInlineBales", InlineWrapper.readInlineBales)
	SpecializationUtil.registerFunction(vehicleType, "writeInlineBales", InlineWrapper.writeInlineBales)
	SpecializationUtil.registerFunction(vehicleType, "getIsInlineBalingAllowed", InlineWrapper.getIsInlineBalingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "inlineBaleTriggerCallback", InlineWrapper.inlineBaleTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "inlineWrapTriggerCallback", InlineWrapper.inlineWrapTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateWrappingNodes", InlineWrapper.updateWrappingNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateRoundBaleWrappingNode", InlineWrapper.updateRoundBaleWrappingNode)
	SpecializationUtil.registerFunction(vehicleType, "updateSquareBaleWrappingNode", InlineWrapper.updateSquareBaleWrappingNode)
	SpecializationUtil.registerFunction(vehicleType, "getWrapperBaleType", InlineWrapper.getWrapperBaleType)
	SpecializationUtil.registerFunction(vehicleType, "getAllowBalePushing", InlineWrapper.getAllowBalePushing)
	SpecializationUtil.registerFunction(vehicleType, "updateWrapperRailings", InlineWrapper.updateWrapperRailings)
	SpecializationUtil.registerFunction(vehicleType, "updateInlineSteeringWheels", InlineWrapper.updateInlineSteeringWheels)
	SpecializationUtil.registerFunction(vehicleType, "getCanInteract", InlineWrapper.getCanInteract)
	SpecializationUtil.registerFunction(vehicleType, "getCanPushOff", InlineWrapper.getCanPushOff)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentInlineBale", InlineWrapper.setCurrentInlineBale)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentInlineBale", InlineWrapper.getCurrentInlineBale)
	SpecializationUtil.registerFunction(vehicleType, "pushOffInlineBale", InlineWrapper.pushOffInlineBale)
end

function InlineWrapper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", InlineWrapper.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", InlineWrapper.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", InlineWrapper.getBrakeForce)
end

function InlineWrapper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", InlineWrapper)
end

function InlineWrapper:onLoad(savegame)
	local spec = self.spec_inlineWrapper
	local baseKey = "vehicle.inlineWrapper"
	spec.triggerNode = self.xmlFile:getValue(baseKey .. ".baleTrigger#node", nil, self.components, self.i3dMappings)

	if spec.triggerNode ~= nil then
		addTrigger(spec.triggerNode, "inlineBaleTriggerCallback", self)
	end

	spec.wrapTriggerNode = self.xmlFile:getValue(baseKey .. ".wrapTrigger#node", nil, self.components, self.i3dMappings)

	if spec.wrapTriggerNode ~= nil then
		addTrigger(spec.wrapTriggerNode, "inlineWrapTriggerCallback", self)
	end

	spec.minFoldTime = self.xmlFile:getValue(baseKey .. ".baleTrigger#minFoldTime", 0)
	spec.maxFoldTime = self.xmlFile:getValue(baseKey .. ".baleTrigger#maxFoldTime", 1)
	spec.baleTypes = {}

	self.xmlFile:iterate(baseKey .. ".baleTypes.baleType", function (index, key)
		local entry = {
			startNode = self.xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
		}

		if entry.startNode ~= nil then
			entry.railingWidth = self.xmlFile:getValue(key .. ".railing#width")
			entry.inlineBaleFilename = Utils.getFilename(self.xmlFile:getValue(key .. ".inlineBale#filename"), self.baseDirectory)

			if entry.inlineBaleFilename ~= nil then
				entry.diameter = MathUtil.round(self.xmlFile:getValue(key .. ".size#diameter", 0), 2)
				entry.width = MathUtil.round(self.xmlFile:getValue(key .. ".size#width", 0), 2)
				entry.isRoundBale = entry.diameter ~= 0

				if not entry.isRoundBale then
					entry.height = MathUtil.round(self.xmlFile:getValue(key .. ".size#height", 0), 2)
					entry.length = MathUtil.round(self.xmlFile:getValue(key .. ".size#length", 0), 2)
				end

				entry.index = #spec.baleTypes + 1

				table.insert(spec.baleTypes, entry)
			else
				Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing inline bale filename! '%s'", key)
			end
		else
			Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing start node! '%s'", key)
		end
	end)

	spec.railingsAnimation = self.xmlFile:getValue(baseKey .. ".railings#animation")
	spec.railingsAnimationStartX = self.xmlFile:getValue(baseKey .. ".railings#animStartX")
	spec.railingsAnimationEndX = self.xmlFile:getValue(baseKey .. ".railings#animEndX")
	spec.railingStartX = self.xmlFile:getValue(baseKey .. ".railings#defaultX", 1)
	spec.currentPosition = spec.railingStartX + 0.01
	spec.targetPosition = spec.railingStartX + 0.01
	spec.wrappingStartNode = self.xmlFile:getValue(baseKey .. ".wrapping#startNode", nil, self.components, self.i3dMappings)
	spec.steeringNodes = {}

	self.xmlFile:iterate(baseKey .. ".steeringNodes.steeringNode", function (_, key)
		local entry = {
			node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil then
			entry.startRot = {
				getRotation(entry.node)
			}

			table.insert(spec.steeringNodes, entry)
		end
	end)

	spec.wrappingNodes = {}

	self.xmlFile:iterate(baseKey .. ".wrappingNodes.wrappingNode", function (_, key)
		local entry = {
			node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
			target = self.xmlFile:getValue(key .. "#target", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil and entry.target ~= nil then
			entry.startTrans = self.xmlFile:getValue(key .. "#startTrans", {
				getTranslation(entry.target)
			}, true)

			setTranslation(entry.target, entry.startTrans[1], entry.startTrans[2], entry.startTrans[3])
			table.insert(spec.wrappingNodes, entry)
		end
	end)

	spec.animations = {
		pusher = self.xmlFile:getValue(baseKey .. ".animations#pusher", "pusherAnimation"),
		wrapping = self.xmlFile:getValue(baseKey .. ".animations#wrapping", "wrappingAnimation"),
		pushOff = self.xmlFile:getValue(baseKey .. ".animations#pushOff", "pushOffAnimation")
	}
	spec.pushingBrakeForce = self.xmlFile:getValue(baseKey .. ".pushing#brakeForce", 0)
	spec.pushingOpenBrakeTime = self.xmlFile:getValue(baseKey .. ".pushing#openBrakeTime", 0.1)
	spec.pushingCloseBrakeTime = self.xmlFile:getValue(baseKey .. ".pushing#closeBrakeTime", 0.5)
	spec.pushingMinBaleAmount = self.xmlFile:getValue(baseKey .. ".pushing#minBaleAmount", 4)
	spec.baleMovedThreshold = self.xmlFile:getValue(baseKey .. "#baleMovedThreshold", 0.05)
	spec.pusherAnimationDirty = false
	spec.pendingSingleBales = {}
	spec.enteredInlineBales = {}
	spec.enteredBalesToWrap = {}
	spec.numObjectBits = self.xmlFile:getValue("vehicle.inlineWrapper#numObjectBits", 4)
	spec.inlineBalesDirtyFlag = self:getNextDirtyFlag()
	spec.currentLineDirection = nil
	spec.lineDirection = nil
	spec.activatable = InlineWrapperActivatable.new(self)

	if self.isClient then
		spec.samples = {
			wrap = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			start = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function InlineWrapper:onPostLoad(savegame)
	local spec = self.spec_inlineWrapper

	if spec.railingsAnimation ~= nil then
		self:setAnimationTime(spec.railingsAnimation, 1, true)
	end

	if self.configurations.wrappingColor ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "wrappingColor", self.configurations.wrappingColor)
	end
end

function InlineWrapper:onDelete()
	local spec = self.spec_inlineWrapper

	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode)
	end

	if spec.wrapTriggerNode ~= nil then
		removeTrigger(spec.wrapTriggerNode)
	end

	g_soundManager:deleteSamples(spec.samples)
	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

	local inlineBale = self:getCurrentInlineBale()

	if inlineBale ~= nil then
		inlineBale:wakeUp(50)
		inlineBale:setWrappingState(1)
		inlineBale:setCurrentWrapperInfo(nil, )
		self:setCurrentInlineBale(nil)
	end
end

function InlineWrapper:onReadStream(streamId, connection)
	self:readInlineBales("pendingSingleBales", streamId, connection)
	self:readInlineBales("enteredInlineBales", streamId, connection)
	self:readInlineBales("enteredBalesToWrap", streamId, connection)

	if streamReadBool(streamId) then
		local inlineBale = NetworkUtil.readNodeObjectId(streamId)

		self:setCurrentInlineBale(inlineBale, true)
	else
		self:setCurrentInlineBale(nil, true)
	end

	local spec = self.spec_inlineWrapper

	g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
end

function InlineWrapper:onWriteStream(streamId, connection)
	self:writeInlineBales("pendingSingleBales", streamId, connection)
	self:writeInlineBales("enteredInlineBales", streamId, connection)
	self:writeInlineBales("enteredBalesToWrap", streamId, connection)

	local currentInlineBale = self:getCurrentInlineBale()

	if streamWriteBool(streamId, currentInlineBale ~= nil) then
		NetworkUtil.writeNodeObject(streamId, currentInlineBale)
	end
end

function InlineWrapper:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self:readInlineBales("pendingSingleBales", streamId, connection)
		self:readInlineBales("enteredInlineBales", streamId, connection)
		self:readInlineBales("enteredBalesToWrap", streamId, connection)

		if streamReadBool(streamId) then
			local inlineBale = NetworkUtil.readNodeObjectId(streamId)

			self:setCurrentInlineBale(inlineBale, true)
		else
			self:setCurrentInlineBale(nil, true)
		end

		local spec = self.spec_inlineWrapper

		g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
	end
end

function InlineWrapper:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_inlineWrapper

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.inlineBalesDirtyFlag) ~= 0) then
			self:writeInlineBales("pendingSingleBales", streamId, connection)
			self:writeInlineBales("enteredInlineBales", streamId, connection)
			self:writeInlineBales("enteredBalesToWrap", streamId, connection)

			local currentInlineBale = self:getCurrentInlineBale()

			if streamWriteBool(streamId, currentInlineBale ~= nil) then
				NetworkUtil.writeNodeObject(streamId, currentInlineBale)
			end
		end
	end
end

function InlineWrapper:readInlineBales(name, streamId, connection)
	local spec = self.spec_inlineWrapper
	local sum = streamReadUIntN(streamId, spec.numObjectBits)
	spec[name] = {}

	for _ = 1, sum do
		local object = NetworkUtil.readNodeObjectId(streamId)
		spec[name][object] = object
	end
end

function InlineWrapper:writeInlineBales(name, streamId, connection)
	local spec = self.spec_inlineWrapper
	local num = table.size(spec[name])

	streamWriteUIntN(streamId, num, spec.numObjectBits)

	local objectIndex = 0

	for object, _ in pairs(spec[name]) do
		objectIndex = objectIndex + 1

		if num >= objectIndex then
			NetworkUtil.writeNodeObjectId(streamId, object)
		else
			Logging.xmlWarning(self.xmlFile, "Not enough bits to send all inline objects. Please increase '%s'", "vehicle.inlineWrapper#numObjectBits")
		end
	end
end

function InlineWrapper:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_inlineWrapper

	if self:getIsAnimationPlaying(spec.animations.wrapping) then
		self:updateWrappingNodes()
	end
end

function InlineWrapper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_inlineWrapper

	if self.isServer then
		local pendingBaleId = next(spec.pendingSingleBales)
		local pendingBale = NetworkUtil.getObject(pendingBaleId)

		if pendingBale ~= nil and self:getIsInlineBalingAllowed() then
			local baleType = self:getWrapperBaleType(pendingBale)
			local lastBaleId = next(spec.enteredInlineBales)
			local lastBale = NetworkUtil.getObject(lastBaleId)
			local inlineBale = nil
			local success = false

			if lastBale == nil then
				inlineBale = InlineBale.new(self.isServer, self.isClient)

				if inlineBale:loadFromConfigXML(baleType.inlineBaleFilename) then
					inlineBale:setOwnerFarmId(self:getActiveFarm(), true)
					inlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
					inlineBale:register()

					success = inlineBale:addBale(pendingBale, baleType)
				else
					inlineBale:delete()
				end
			elseif lastBale:isa(InlineBaleSingle) then
				inlineBale = lastBale:getConnectedInlineBale()

				if inlineBale ~= nil then
					success = inlineBale:addBale(pendingBale, baleType)

					if success then
						local currentInlineBale = self:getCurrentInlineBale()

						currentInlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
					end
				end
			end

			if success then
				spec.pendingSingleBales[pendingBaleId] = nil
				spec.enteredInlineBales[pendingBaleId] = pendingBaleId
				spec.pusherAnimationDirty = true

				self:setCurrentInlineBale(inlineBale)
				g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
				self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
			end
		end
	end

	local inlineBaleId = next(spec.enteredInlineBales)
	local bale = NetworkUtil.getObject(inlineBaleId)

	if bale ~= nil then
		if self:getCurrentInlineBale() == nil and bale:isa(InlineBaleSingle) then
			local inlineBale = bale:getConnectedInlineBale()

			if inlineBale ~= nil then
				self:setCurrentInlineBale(inlineBale)
				g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
				self:updateWrappingNodes()

				local currentInlineBale = self:getCurrentInlineBale()

				currentInlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
			end
		end
	else
		self:setCurrentInlineBale(nil)
	end

	local needsSteering = (next(spec.enteredInlineBales) ~= nil or spec.pushOffStarted) and self:getAttacherVehicle() == nil
	local steeringActive = needsSteering and not self:getIsControlled()

	if spec.lineDirection == nil and needsSteering then
		local x, _, z = localDirectionToWorld(self.components[1].node, 0, 0, -1)
		spec.lineDirection = {
			x,
			z
		}
	elseif spec.lineDirection ~= nil and not needsSteering then
		spec.lineDirection = nil
	end

	if not steeringActive then
		if spec.currentLineDirection ~= nil then
			spec.currentLineDirection = nil

			self:updateInlineSteeringWheels()
		end
	else
		spec.currentLineDirection = spec.lineDirection
	end

	if spec.currentLineDirection ~= nil then
		self:updateInlineSteeringWheels(spec.currentLineDirection[1], spec.currentLineDirection[2])
	end

	if self.isServer then
		spec.releaseBrake = false
		local currentInlineBale = self:getCurrentInlineBale()

		if spec.pusherAnimationDirty then
			local allowedToPush = true

			for _, baleId in pairs(spec.pendingSingleBales) do
				if not self:getAllowBalePushing(NetworkUtil.getObject(baleId)) then
					allowedToPush = false

					break
				end
			end

			if allowedToPush then
				for _, baleId in pairs(spec.enteredInlineBales) do
					if not self:getAllowBalePushing(NetworkUtil.getObject(baleId)) then
						allowedToPush = false

						break
					end
				end
			end

			if allowedToPush and currentInlineBale ~= nil then
				local pendingBale = currentInlineBale:getPendingBale()
				local pendingBaleId = NetworkUtil.getObjectId(pendingBale)
				local baleType = self:getWrapperBaleType(pendingBale)
				local replaced, newBaleId = currentInlineBale:replacePendingBale(baleType.startNode, ConfigurationUtil.getColorByConfigId(self, "wrappingColor", self.configurations.wrappingColor))

				if replaced then
					spec.enteredInlineBales[pendingBaleId] = nil
					spec.enteredInlineBales[newBaleId] = newBaleId
				end

				self:playAnimation(spec.animations.pusher, 1, 0)

				spec.pusherAnimationDirty = false

				currentInlineBale:connectPendingBale()
				self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
			end

			self:raiseActive()
		end

		if self:getAttacherVehicle() == nil then
			local allowBrakeOpening = true

			if currentInlineBale ~= nil and currentInlineBale:getNumberOfBales() < spec.pushingMinBaleAmount then
				allowBrakeOpening = false
			end

			local animTime = self:getAnimationTime(spec.animations.pusher)
			local isPushing = self:getIsAnimationPlaying(spec.animations.pusher) and spec.pushingOpenBrakeTime < animTime and animTime < spec.pushingCloseBrakeTime
			local currentSpeed = self:getAnimationSpeed(spec.animations.pushOff)
			local isPushingOff = self:getIsAnimationPlaying(spec.animations.pushOff) and currentSpeed > 0
			local releaseBrake = isPushing or isPushingOff

			if allowBrakeOpening then
				spec.releaseBrake = releaseBrake
			end
		end
	end

	local playWrapAnimation = false

	for _, wrapBaleId in pairs(spec.enteredBalesToWrap) do
		local wrapBale = NetworkUtil.getObject(wrapBaleId)

		if wrapBale ~= nil and entityExists(wrapBale.nodeId) then
			local x, y, z = localToLocal(wrapBale.nodeId, self.components[1].node, 0, 0, 0)

			if wrapBale.lastWrapTranslation ~= nil and wrapBale.lastWrapMoveTime ~= nil then
				if spec.baleMovedThreshold < math.abs(wrapBale.lastWrapTranslation[1] - x) + math.abs(wrapBale.lastWrapTranslation[2] - y) + math.abs(wrapBale.lastWrapTranslation[3] - z) then
					wrapBale.lastWrapMoveTime = g_currentMission.time
					wrapBale.lastWrapTranslation = {
						x,
						y,
						z
					}
				end
			else
				wrapBale.lastWrapMoveTime = -math.huge
				wrapBale.lastWrapTranslation = {
					x,
					y,
					z
				}
			end

			if g_currentMission.time < wrapBale.lastWrapMoveTime + 1500 then
				playWrapAnimation = true

				break
			end

			self:raiseActive()
		end
	end

	if playWrapAnimation then
		if not self:getIsAnimationPlaying(spec.animations.wrapping) then
			self:playAnimation(spec.animations.wrapping, 1, self:getAnimationTime(spec.animations.wrapping), true)
		end

		if self.isClient and not g_soundManager:getIsSamplePlaying(spec.samples.start) and not g_soundManager:getIsSamplePlaying(spec.samples.wrap) then
			g_soundManager:playSample(spec.samples.start)
			g_soundManager:playSample(spec.samples.wrap, 0, spec.samples.start)
		end
	else
		self:stopAnimation(spec.animations.wrapping, true)

		if self.isClient and (g_soundManager:getIsSamplePlaying(spec.samples.start) or g_soundManager:getIsSamplePlaying(spec.samples.wrap)) then
			g_soundManager:stopSample(spec.samples.start)
			g_soundManager:stopSample(spec.samples.wrap)
			g_soundManager:playSample(spec.samples.stop)
		end
	end

	local baleId = next(spec.pendingSingleBales) or next(spec.enteredInlineBales)
	bale = NetworkUtil.getObject(baleId)

	if bale ~= nil then
		local baleType = self:getWrapperBaleType(bale)
		local currentInlineBale = self:getCurrentInlineBale()

		if currentInlineBale ~= nil and not currentInlineBale:getIsBaleAllowed(bale, baleType) then
			baleType = nil
		end

		if baleType ~= nil then
			spec.targetPosition = baleType.railingWidth

			self:updateWrapperRailings(spec.targetPosition, dt)
		end
	else
		self:updateWrapperRailings(spec.railingStartX, dt)
	end

	if self.isServer and spec.pushOffStarted ~= nil and spec.pushOffStarted and not self:getIsAnimationPlaying(spec.animations.pushOff) then
		self:playAnimation(spec.animations.pushOff, -1, 1)

		spec.pushOffStarted = nil
	end

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.ACTIVATE_OBJECT]

		if actionEvent ~= nil then
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getCanPushOff())
		end
	end
end

function InlineWrapper:updateWrappingNodes()
	local spec = self.spec_inlineWrapper
	local inlineBale = self:getCurrentInlineBale()

	if inlineBale ~= nil then
		local bales = spec.enteredBalesToWrap

		for _, wrappingNode in ipairs(spec.wrappingNodes) do
			local x, y, z = getWorldTranslation(wrappingNode.node)
			local minDistance = math.huge
			local minBale = nil

			for _, baleId in pairs(bales) do
				local bale = NetworkUtil.getObject(baleId)

				if bale ~= nil and bale ~= inlineBale:getPendingBale() then
					local bx, _, bz = worldToLocal(bale.nodeId, x, y, z)
					local x1, y1, z1, x2, y2, z2 = nil

					if bale.isRoundbale then
						if bz >= -bale.width / 2 then
							x1, y1, z1 = localToWorld(bale.nodeId, 0, 0, bale.width / 2)
							x2, y2, z2 = localToWorld(bale.nodeId, 0, 0, -bale.width / 2)
						end
					elseif bx >= -bale.width / 2 then
						x1, y1, z1 = localToWorld(bale.nodeId, bale.width / 2, 0, 0)
						x2, y2, z2 = localToWorld(bale.nodeId, -bale.width / 2, 0, 0)
					end

					if x1 ~= nil then
						local distance = math.min(MathUtil.vector3Length(x - x1, y - y1, z - z1), MathUtil.vector3Length(x - x2, y - y2, z - z2))

						if distance < minDistance then
							minDistance = distance
							minBale = bale
						end
					end
				end
			end

			if minBale ~= nil then
				local targetX, targetY, targetZ = nil

				if minBale.isRoundbale then
					targetX, targetY, targetZ = self:updateRoundBaleWrappingNode(minBale, wrappingNode.node, x, y, z)
				else
					targetX, targetY, targetZ = self:updateSquareBaleWrappingNode(minBale, wrappingNode.node, x, y, z)
				end

				if targetX ~= nil then
					targetX, targetY, targetZ = worldToLocal(getParent(wrappingNode.target), targetX, targetY, targetZ)

					setTranslation(wrappingNode.target, targetX, targetY, targetZ)
				else
					setTranslation(wrappingNode.target, wrappingNode.startTrans[1], wrappingNode.startTrans[2], wrappingNode.startTrans[3])
				end
			else
				setTranslation(wrappingNode.target, wrappingNode.startTrans[1], wrappingNode.startTrans[2], wrappingNode.startTrans[3])
			end
		end

		spec.resetWrappingNodes = true
	elseif spec.resetWrappingNodes then
		for _, wrappingNode in ipairs(spec.wrappingNodes) do
			setTranslation(wrappingNode.target, wrappingNode.startTrans[1], wrappingNode.startTrans[2], wrappingNode.startTrans[3])
		end

		spec.resetWrappingNodes = nil
	end
end

function InlineWrapper:updateRoundBaleWrappingNode(bale, wrappingNode, x, y, z)
	local baleNode = bale.nodeId
	local baleRadius = bale.diameter / 2
	local steps = 32
	local intersectOffset = 0.01
	local foilOffset = -0.03
	local w1x, w1y, w1z = worldToLocal(baleNode, x, y, z)
	local distanceToCenter = MathUtil.vector3Length(w1x, w1y, 0)
	local maxDirY = -math.huge
	local targetX, targetY, targetZ = nil

	for i = 1, steps do
		local a = i / steps * 2 * math.pi
		local c = math.cos(a) * (baleRadius + intersectOffset)
		local s = math.sin(a) * (baleRadius + intersectOffset)
		local distance = MathUtil.vector2Length(c - w1x, s - w1y)

		if distance < distanceToCenter then
			local intersect, _, _, _, _ = MathUtil.getCircleLineIntersection(0, 0, baleRadius, w1x, w1y, c, s)

			if not intersect then
				local px, py, pz = localToWorld(baleNode, c, s, 0)
				local _, wrapDirY, _ = worldToLocal(wrappingNode, px, py, pz)

				if maxDirY < wrapDirY then
					maxDirY = wrapDirY
					targetX, targetY, targetZ = localToWorld(baleNode, math.cos(a) * (baleRadius + foilOffset), math.sin(a) * (baleRadius + foilOffset), w1z)
				end
			end
		end
	end

	return targetX, targetY, targetZ
end

function InlineWrapper:updateSquareBaleWrappingNode(bale, wrappingNode, x, y, z)
	local baleNode = bale.nodeId
	local minAngle = math.huge
	local targetX, targetY, targetZ = nil
	local height = bale.height / 2
	local length = bale.length / 2
	local intersectOffset = 0.01
	local foilOffset = -0.05
	local w1x, w1y, w1z = worldToLocal(baleNode, x, y, z)

	if bale.wrappingEdges == nil then
		bale.wrappingEdges = {
			{
				0,
				height,
				-length
			},
			{
				0,
				-height,
				-length
			},
			{
				0,
				-height,
				length
			},
			{
				0,
				height,
				length
			}
		}
	end

	for _, edge in ipairs(bale.wrappingEdges) do
		local edgeY = edge[2] + MathUtil.sign(edge[2]) * intersectOffset
		local edgeZ = edge[3] + MathUtil.sign(edge[3]) * intersectOffset
		local intersect = false

		for i = 1, 4 do
			local i2 = i <= 3 and i + 1 or 1
			intersect = intersect or MathUtil.getLineBoundingVolumeIntersect(edgeY, edgeZ, w1y, w1z, bale.wrappingEdges[i][2], bale.wrappingEdges[i][3], bale.wrappingEdges[i2][2], bale.wrappingEdges[i2][3])
		end

		if not intersect then
			local px, py, pz = localToWorld(baleNode, w1x, edgeY, edgeZ)
			local _, wrapDirY, wrapDirZ = worldToLocal(wrappingNode, px, py, pz)
			local angle = MathUtil.getYRotationFromDirection(wrapDirY, wrapDirZ)

			if angle < 0 then
				angle = math.pi + math.pi + angle
			end

			if minAngle > angle then
				minAngle = angle
				targetX, targetY, targetZ = localToWorld(baleNode, w1x, edge[2] + MathUtil.sign(edge[2]) * foilOffset, edge[3] + MathUtil.sign(edge[3]) * foilOffset)
			end
		end
	end

	return targetX, targetY, targetZ
end

function InlineWrapper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_inlineWrapper

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInput then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ACTIVATE_OBJECT, self, InlineWrapper.pushOffInlineBaleEvent, false, false, true, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventActive(actionEventId, self:getCanPushOff())
			g_inputBinding:setActionEventTextVisibility(actionEventId, true)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_baleloaderUnload"))
		end
	end
end

function InlineWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_inlineWrapper

	if next(spec.enteredInlineBales) ~= nil then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function InlineWrapper:getIsActive(superFunc)
	local spec = self.spec_inlineWrapper

	if spec.releaseBrake or spec.releaseBrake ~= spec.releaseBrakeSet then
		return true
	end

	return superFunc(self)
end

function InlineWrapper:getBrakeForce(superFunc)
	local spec = self.spec_inlineWrapper

	if spec.releaseBrake then
		spec.releaseBrakeSet = spec.releaseBrake

		return 0
	end

	return superFunc(self)
end

function InlineWrapper:getIsInlineBalingAllowed()
	local spec = self.spec_inlineWrapper

	if self.getFoldAnimTime ~= nil then
		local foldTime = self:getFoldAnimTime()

		if foldTime < spec.minFoldTime or spec.maxFoldTime < foldTime then
			return false
		end
	end

	if self:getIsAnimationPlaying(spec.animations.pusher) then
		return false
	end

	if self:getIsAnimationPlaying(spec.animations.pushOff) or self:getAnimationTime(spec.animations.pushOff) > 0 then
		return false
	end

	return true
end

function InlineWrapper:inlineBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and object:isa(Bale) then
			local objectId = NetworkUtil.getObjectId(object)
			local spec = self.spec_inlineWrapper

			if onEnter then
				if not object:isa(InlineBaleSingle) then
					if self:getWrapperBaleType(object) ~= nil then
						spec.pendingSingleBales[objectId] = objectId
					end
				else
					spec.enteredInlineBales[objectId] = objectId
					local connectedInlineBale = object:getConnectedInlineBale()

					if connectedInlineBale ~= nil then
						connectedInlineBale:setCurrentWrapperInfo(self, spec.wrappingStartNode)
					else
						object.inlineWrapperToAdd = {
							wrapper = self,
							wrappingNode = spec.wrappingStartNode
						}
					end
				end
			elseif onLeave then
				spec.pendingSingleBales[objectId] = nil
				spec.enteredInlineBales[objectId] = nil

				if object:isa(InlineBaleSingle) then
					local connectedInlineBale = object:getConnectedInlineBale()

					if connectedInlineBale ~= nil then
						local bales = connectedInlineBale:getBales()
						local removeFromWrapper = true

						for _, bale in ipairs(bales) do
							local baleId = NetworkUtil.getObjectId(bale)

							if spec.pendingSingleBales[baleId] ~= nil or spec.enteredInlineBales[baleId] ~= nil then
								removeFromWrapper = false

								break
							end
						end

						if removeFromWrapper then
							connectedInlineBale:setCurrentWrapperInfo(nil, )
							self:setCurrentInlineBale(nil)
						end
					end
				end
			end

			self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
		end
	end
end

function InlineWrapper:inlineWrapTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and object:isa(Bale) then
			local spec = self.spec_inlineWrapper
			local objectId = NetworkUtil.getObjectId(object)

			if onEnter then
				spec.enteredBalesToWrap[objectId] = objectId
			elseif onLeave then
				spec.enteredBalesToWrap[objectId] = nil
			end

			self:raiseActive()
			self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
		end
	end
end

function InlineWrapper:getWrapperBaleType(bale)
	local spec = self.spec_inlineWrapper

	for _, baleType in pairs(spec.baleTypes) do
		if bale:getSupportsWrapping() then
			if bale.isRoundbale then
				if baleType.isRoundBale and bale.diameter == baleType.diameter and bale.width == baleType.width then
					return baleType
				end
			elseif not baleType.isRoundBale and bale.width == baleType.width and bale.height == baleType.height and bale.length == baleType.length then
				return baleType
			end
		end
	end

	return nil
end

function InlineWrapper:getAllowBalePushing(bale)
	if bale.dynamicMountJointIndex ~= nil then
		return false
	end

	return true
end

function InlineWrapper:updateWrapperRailings(targetPosition, dt)
	local spec = self.spec_inlineWrapper

	if targetPosition ~= spec.currentPosition then
		local dir = MathUtil.sign(targetPosition - spec.currentPosition)
		spec.currentPosition = spec.currentPosition + 0.0001 * dt * dir

		if dir > 0 then
			spec.currentPosition = math.min(spec.currentPosition, targetPosition)
		else
			spec.currentPosition = math.max(spec.currentPosition, targetPosition)
		end

		local animTime = (spec.currentPosition - spec.railingsAnimationStartX) / (spec.railingsAnimationEndX - spec.railingsAnimationStartX)

		self:setAnimationTime(spec.railingsAnimation, animTime, true)
	end
end

function InlineWrapper:updateInlineSteeringWheels(dirX, dirZ)
	local spec = self.spec_inlineWrapper

	for _, steeringNode in ipairs(spec.steeringNodes) do
		if dirX == nil or dirZ == nil then
			setRotation(steeringNode.node, unpack(steeringNode.startRot))
		else
			local px, py, pz = getWorldTranslation(steeringNode.node)
			local targetX, _, targetZ = worldToLocal(getParent(steeringNode.node), px + dirX * 10, py, pz + dirZ * 10)
			targetX, _, targetZ = MathUtil.vector3Normalize(targetX, 0, targetZ)
			local upX, upY, upZ = localDirectionToWorld(getParent(steeringNode.node), 0, 1, 0)

			setDirection(steeringNode.node, targetX, 0, targetZ, upX, upY, upZ)
		end

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(steeringNode.node)
		end
	end
end

function InlineWrapper:onLeaveVehicle()
	self.rotatedTime = 0
end

function InlineWrapper:onEnterVehicle()
	local spec = self.spec_inlineWrapper

	for _, steeringNode in ipairs(spec.steeringNodes) do
		setRotation(steeringNode.node, unpack(steeringNode.startRot))

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(steeringNode.node)
		end
	end
end

function InlineWrapper:getCanInteract()
	if not g_currentMission.controlPlayer then
		return false
	end

	local x1, y1, z1 = getWorldTranslation(g_currentMission.player.rootNode)
	local x2, y2, z2 = getWorldTranslation(self.components[1].node)
	local distance = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

	return distance < InlineWrapper.INTERACTION_RADIUS
end

function InlineWrapper:getCanPushOff()
	local spec = self.spec_inlineWrapper
	local currentInlineBale = self:getCurrentInlineBale()

	if currentInlineBale == nil then
		return false
	end

	if currentInlineBale:getPendingBale() ~= nil then
		return false
	end

	if self:getIsAnimationPlaying(spec.animations.pusher) then
		return false
	end

	if self:getIsAnimationPlaying(spec.animations.pushOff) then
		return false
	end

	return true
end

function InlineWrapper:setCurrentInlineBale(inlineBale, isClient)
	local spec = self.spec_inlineWrapper

	if self.isServer then
		local newInlineBale = NetworkUtil.getObjectId(inlineBale)

		if newInlineBale ~= spec.currentInlineBale then
			spec.currentInlineBale = newInlineBale

			self:raiseDirtyFlags(spec.inlineBalesDirtyFlag)
		end
	end

	if isClient then
		spec.currentInlineBale = inlineBale
	end
end

function InlineWrapper:getCurrentInlineBale()
	return NetworkUtil.getObject(self.spec_inlineWrapper.currentInlineBale)
end

function InlineWrapper:pushOffInlineBaleEvent(actionName, inputValue, callbackState, isAnalog)
	if inputValue == 1 then
		if g_server ~= nil then
			self:pushOffInlineBale()
		else
			g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self))
		end
	end
end

function InlineWrapper:pushOffInlineBale()
	local spec = self.spec_inlineWrapper

	if not self:getIsAnimationPlaying(spec.animations.pushOff) then
		self:playAnimation(spec.animations.pushOff, 1)

		spec.pushOffStarted = true
	end
end

function InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, roundBaleWrapper)
	local rootName = xmlFile:getRootName()
	local baleSizeAttributes = {
		maxDiameter = -math.huge,
		minDiameter = math.huge,
		maxLength = -math.huge,
		minLength = math.huge
	}

	xmlFile:iterate(rootName .. ".inlineWrapper.baleTypes.baleType", function (_, key)
		local diameter = MathUtil.round(xmlFile:getValue(key .. ".size#diameter", 0), 2)

		if roundBaleWrapper and diameter ~= 0 then
			baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter)
			baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter)
		end

		local length = MathUtil.round(xmlFile:getValue(key .. ".size#length", 0), 2)

		if not roundBaleWrapper and length ~= 0 then
			baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, length)
			baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length)
		end
	end)

	if baleSizeAttributes.minDiameter ~= math.huge or baleSizeAttributes.minLength ~= math.huge then
		return baleSizeAttributes
	end
end

function InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBaleWrapper)
	local baleSizeAttributes = roundBaleWrapper and storeItem.specs.inlineWrapperBaleSizeRound or storeItem.specs.inlineWrapperBaleSizeSquare

	if baleSizeAttributes ~= nil then
		local minValue = roundBaleWrapper and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength
		local maxValue = roundBaleWrapper and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength

		if returnValues == nil or not returnValues then
			local unit = g_i18n:getText("unit_cmShort")
			local size = nil

			if maxValue ~= minValue then
				size = string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
			else
				size = string.format("%d%s", minValue * 100, unit)
			end

			return size
		elseif returnRange == true and maxValue ~= minValue then
			return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
		else
			return minValue * 100, g_i18n:getText("unit_cmShort")
		end
	elseif returnValues and returnRange then
		return 0, 0, ""
	elseif returnValues then
		return 0, ""
	else
		return ""
	end
end

function InlineWrapper.loadSpecValueBaleSizeRound(xmlFile, customEnvironment)
	return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, true)
end

function InlineWrapper.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment)
	return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, false)
end

function InlineWrapper.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.inlineWrapperBaleSizeRound ~= nil then
		return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function InlineWrapper.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.inlineWrapperBaleSizeSquare ~= nil then
		return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end

InlineWrapperActivatable = {}
local InlineWrapperActivatable_mt = Class(InlineWrapperActivatable)

function InlineWrapperActivatable.new(inlineWrapper)
	local self = {}

	setmetatable(self, InlineWrapperActivatable_mt)

	self.inlineWrapper = inlineWrapper
	self.activateText = g_i18n:getText("action_baleloaderUnload")

	return self
end

function InlineWrapperActivatable:getIsActivatable()
	if self.inlineWrapper:getCanInteract() and self.inlineWrapper:getCanPushOff() then
		return true
	end

	return false
end

function InlineWrapperActivatable:run()
	if g_server ~= nil then
		self.inlineWrapper:pushOffInlineBale()
	else
		g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self.inlineWrapper))
	end
end
