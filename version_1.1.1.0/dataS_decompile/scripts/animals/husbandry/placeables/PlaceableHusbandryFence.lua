PlaceableHusbandryFence = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHusbandryFence.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateHusbandryFence", PlaceableHusbandryFence.updateHusbandryFence)
	SpecializationUtil.registerFunction(placeableType, "createHusbandryFence", PlaceableHusbandryFence.createHusbandryFence)
	SpecializationUtil.registerFunction(placeableType, "onFenceI3DLoaded", PlaceableHusbandryFence.onFenceI3DLoaded)
	SpecializationUtil.registerFunction(placeableType, "onGateI3DLoaded", PlaceableHusbandryFence.onGateI3DLoaded)
end

function PlaceableHusbandryFence.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onPreFinalizePlacement", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFence)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFence)
end

function PlaceableHusbandryFence.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setPreviewPosition", PlaceableHusbandryFence.setPreviewPosition)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableHusbandryFence.getCanBePlacedAt)
end

function PlaceableHusbandryFence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.fences"

	schema:register(XMLValueType.STRING, basePath .. ".fence(?)#filename", "Fence filename")
	schema:register(XMLValueType.BOOL, basePath .. ".fence(?)#hasStartPole", "Has start pole")
	schema:register(XMLValueType.BOOL, basePath .. ".fence(?)#hasEndPole", "Has end pole")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence(?).node(?)#node", "Fence node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".gate(?)#node", "Gate node")
	schema:register(XMLValueType.STRING, basePath .. ".gate(?)#filename", "Gate filename")
	schema:register(XMLValueType.INT, basePath .. ".gate(?)#gateIndex", "Gate index")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFence:onLoad(savegame)
	local spec = self.spec_husbandryFence
	spec.fences = {}
	spec.canBePlaced = true

	self.xmlFile:iterate("placeable.husbandry.fences.fence", function (_, key)
		local filename = self.xmlFile:getValue(key .. "#filename")

		if filename == nil then
			Logging.xmlWarning(self.xmlFile, "Missing segment filename for '%s'", key)

			return
		end

		local fence = {
			filename = Utils.getFilename(filename, self.baseDirectory),
			nodes = {},
			parts = {},
			rootNode = createTransformGroup("fence")
		}

		link(self.rootNode, fence.rootNode)

		fence.hasStartPole = self.xmlFile:getValue(key .. "#hasStartPole", true)
		fence.hasEndPole = self.xmlFile:getValue(key .. "#hasEndPole", true)

		self.xmlFile:iterate(key .. ".node", function (_, segmentKey)
			local node = self.xmlFile:getValue(segmentKey .. "#node", nil, self.components, self.i3dMappings)

			if node == nil then
				Logging.xmlWarning(self.xmlFile, "Missing fence node for '%s'", segmentKey)

				return false
			end

			table.insert(fence.nodes, node)
		end)

		if #fence.nodes > 0 then
			local fenceXmlFile = XMLFile.load("fence", fence.filename)

			if fenceXmlFile == nil then
				Logging.xmlWarning(self.xmlFile, "Could not load fence xml file for '%s'", key)

				return
			end

			local fenceFilename = fenceXmlFile:getString("placeable.base.filename")

			if fenceFilename == nil then
				Logging.xmlWarning(fenceXmlFile, "Missing fence filename.")

				return
			end

			fence.i3dFilename = Utils.getFilename(fenceFilename, self.baseDirectory)
			local loadingTask = self:createLoadingTask()
			fence.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(fence.i3dFilename, false, false, self.onFenceI3DLoaded, self, {
				fence,
				fenceXmlFile,
				loadingTask
			})
		end

		table.insert(spec.fences, fence)
	end)

	spec.gates = {}

	self.xmlFile:iterate("placeable.husbandry.fences.gate", function (_, key)
		local filename = self.xmlFile:getValue(key .. "#filename")

		if filename == nil then
			Logging.xmlWarning(self.xmlFile, "Missing gate filename for '%s'", key)

			return
		end

		local gate = {
			filename = Utils.getFilename(filename, self.baseDirectory),
			node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		}

		if gate.node == nil then
			Logging.xmlWarning(self.xmlFile, "No gate node defined for '%s'", key)

			return
		end

		gate.gateIndex = self.xmlFile:getValue(key .. "#gateIndex") or 1
		local gateXmlFile = XMLFile.load("gate", gate.filename, Placeable.xmlSchema)

		if gateXmlFile == nil then
			Logging.xmlWarning(self.xmlFile, "Could not load gate xml file for '%s'", key)

			return
		end

		local gateFilename = gateXmlFile:getString("placeable.base.filename")

		if gateFilename == nil then
			Logging.xmlWarning(gateXmlFile, "Missing gate filename.")

			return
		end

		gate.i3dFilename = Utils.getFilename(gateFilename, self.baseDirectory)
		local loadingTask = self:createLoadingTask()
		gate.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(gate.i3dFilename, false, false, self.onGateI3DLoaded, self, {
			gate,
			gateXmlFile,
			loadingTask
		})

		table.insert(spec.gates, gate)
	end)
end

function PlaceableHusbandryFence:onFenceI3DLoaded(i3dNode, failedReason, args)
	local fence, fenceXmlFile, loadingTask = unpack(args)

	if i3dNode ~= 0 then
		local components = {}
		local i3dMappings = {}

		I3DUtil.loadI3DComponents(i3dNode, components)
		I3DUtil.loadI3DMapping(fenceXmlFile, i3dNode, components, i3dMappings)

		local polesRootNode = I3DUtil.indexToObject(components, fenceXmlFile:getString("placeable.fence.poles#node"), i3dMappings)
		local panelsRootNode = I3DUtil.indexToObject(components, fenceXmlFile:getString("placeable.fence.panels#node"), i3dMappings)
		local panelLength = fenceXmlFile:getFloat("placable.fence.panels#length", 2)
		fence.maxAngle = math.rad(fenceXmlFile:getFloat("placeable.fence#maxVerticalAngle", 45))

		self:createHusbandryFence(fence, polesRootNode, panelsRootNode, panelLength)
		delete(i3dNode)
	end

	fenceXmlFile:delete()
	self:finishLoadingTask(loadingTask)
end

function PlaceableHusbandryFence:onGateI3DLoaded(i3dNode, failedReason, args)
	local gate, gateXmlFile, loadingTask = unpack(args)

	if i3dNode ~= 0 then
		local components = {}
		local i3dMappings = {}

		I3DUtil.loadI3DComponents(i3dNode, components)
		I3DUtil.loadI3DMapping(gateXmlFile, i3dNode, components, i3dMappings)

		local gateKey = string.format("placeable.fence.gate(%d)", gate.gateIndex - 1)
		local gateRootNode = I3DUtil.indexToObject(components, gateXmlFile:getString(gateKey .. "#node"), i3dMappings)

		if gateRootNode ~= nil then
			local animatedObject = AnimatedObject.new(self.isServer, self.isClient)

			animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)

			local saveId = "test"
			local builder = animatedObject:builder(gate.filename, saveId)

			gateXmlFile:iterate(gateKey .. ".door", function (_, doorKey)
				local doorNode = I3DUtil.indexToObject(gateRootNode, gateXmlFile:getString(doorKey .. "#node"), i3dMappings)

				if doorNode ~= nil then
					local rotation = gateXmlFile:getValue(doorKey .. "#openRotation", nil, true)
					local translation = gateXmlFile:getValue(doorKey .. "#openTranslation", nil, true)

					builder:addSimplePart(doorNode, rotation, translation)
				end
			end)

			local duration = gateXmlFile:getValue(gateKey .. "#openDuration") * 1000

			builder:setDuration(duration)

			local triggerNode = I3DUtil.indexToObject(gateRootNode, gateXmlFile:getString(gateKey .. "#triggerNode"), i3dMappings)

			builder:setTrigger(triggerNode)
			builder:setSounds(gateXmlFile.handle, gateKey .. ".sounds", gateRootNode)

			local openText = gateXmlFile:getString(gateKey .. "#openText", "action_openGate")
			local closeText = gateXmlFile:getString(gateKey .. "#closeText", "action_closeGate")

			builder:setActions("ACTIVATE_HANDTOOL", openText, nil, closeText)

			if builder:build() then
				animatedObject:register(true)

				gate.animatedObject = animatedObject
			else
				animatedObject:delete()
			end

			link(gate.node, gateRootNode)
		end

		delete(i3dNode)
	end

	gateXmlFile:delete()
	self:finishLoadingTask(loadingTask)
end

function PlaceableHusbandryFence:onDelete()
	local spec = self.spec_husbandryFence

	if spec.fences ~= nil then
		for _, fence in ipairs(spec.fences) do
			if fence.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(fence.sharedLoadRequestId)
			end

			if fence.rootNode ~= nil then
				delete(fence.rootNode)

				fence.rootNode = nil
			end
		end
	end

	if spec.gates ~= nil then
		for _, gate in ipairs(spec.gates) do
			if gate.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(gate.sharedLoadRequestId)
			end

			if gate.animatedObject ~= nil then
				gate.animatedObject:delete()

				gate.animatedObject = nil
			end
		end
	end
end

function PlaceableHusbandryFence:onPreFinalizePlacement()
	local spec = self.spec_husbandryFence

	for _, fence in ipairs(spec.fences) do
		self:updateHusbandryFence(fence, true)
	end
end

function PlaceableHusbandryFence:onReadStream(streamId, connection)
	local spec = self.spec_husbandryFence

	for _, gate in ipairs(spec.gates) do
		if gate.animatedObject ~= nil then
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

			gate.animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(gate.animatedObject, animatedObjectId)
		end
	end
end

function PlaceableHusbandryFence:onWriteStream(streamId, connection)
	local spec = self.spec_husbandryFence

	for _, gate in ipairs(spec.gates) do
		if gate.animatedObject ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(gate.animatedObject))
			gate.animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, gate.animatedObject)
		end
	end
end

function PlaceableHusbandryFence:createHusbandryFence(fence, poleRoot, panelRoot, panelLength)
	local numPoleVariations = 0

	if poleRoot ~= nil then
		numPoleVariations = getNumOfChildren(poleRoot)
	end

	local numPanelVariations = 0

	if panelRoot ~= nil then
		numPanelVariations = getNumOfChildren(panelRoot)
	end

	for k, node in ipairs(fence.nodes) do
		local sx, sy, sz = localToLocal(node, fence.rootNode, 0, 0, 0)
		local posX = sx
		local posY = sy
		local posZ = sz
		local rotY = 0
		local nextNode = fence.nodes[k + 1]

		if nextNode ~= nil then
			local ex, _, ez = localToLocal(nextNode, fence.rootNode, 0, 0, 0)
			local distance = MathUtil.vector2Length(ex - sx, ez - sz)
			local dirX, dirZ = MathUtil.vector2Normalize(ex - sx, ez - sz)
			rotY = math.atan2(dirX, dirZ) + math.pi
			local usedNumPanels = math.floor(distance / panelLength)

			if distance % panelLength > panelLength * 0.5 then
				usedNumPanels = usedNumPanels + 1
			end

			local usedPanelLength = distance / usedNumPanels

			while distance > 0.001 do
				local part = {}
				local pole = nil

				if poleRoot ~= nil and (#fence.parts > 0 or fence.hasStartPole) then
					pole = clone(getChildAt(poleRoot, math.random(0, numPoleVariations - 1)), false, false, false)
				else
					pole = createTransformGroup("startPole")
				end

				part.pole = pole

				link(fence.rootNode, pole)
				setRotation(pole, 0, rotY, 0)
				setTranslation(pole, posX, posY, posZ)

				if panelRoot ~= nil then
					local panel = clone(getChildAt(panelRoot, math.random(0, numPanelVariations - 1)), false, false, false)

					link(fence.rootNode, panel)
					setTranslation(panel, posX, posY, posZ)
					setDirection(panel, dirX, 0, dirZ, 0, 1, 0)
					setScale(panel, 1, 1, usedPanelLength / panelLength)

					part.collision = getChildAt(panel, 0)
					part.visual = getChildAt(panel, 1)
					part.panel = panel
				end

				posX = posX + dirX * usedPanelLength
				posZ = posZ + dirZ * usedPanelLength
				distance = distance - usedPanelLength
				part.length = usedPanelLength

				table.insert(fence.parts, part)
			end
		else
			local pole = nil

			if poleRoot ~= nil and fence.hasEndPole then
				pole = clone(getChildAt(poleRoot, math.random(0, numPoleVariations - 1)), false, false, false)
			else
				pole = createTransformGroup("endPole")
			end

			link(fence.rootNode, pole)
			setRotation(pole, 0, rotY, 0)
			setTranslation(pole, posX, posY, posZ)
			table.insert(fence.parts, {
				pole = pole
			})
		end
	end

	self:updateHusbandryFence(fence, false)
end

function PlaceableHusbandryFence:updateHusbandryFence(fence, updateCollision)
	local success = true

	for index, part in ipairs(fence.parts) do
		local pole = part.pole
		local x, y, z = getWorldTranslation(pole)
		y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

		setWorldTranslation(pole, x, y, z)

		local panel = part.panel

		if panel ~= nil then
			setWorldTranslation(panel, x, y, z)
		end

		local lastPart = fence.parts[index - 1]

		if lastPart ~= nil and lastPart.panel ~= nil then
			local _, yDif, zDif = localToLocal(pole, lastPart.pole, 0, 0, 0)
			local angle = math.atan2(math.abs(yDif), math.abs(zDif))

			if fence.maxAngle < angle then
				success = false
			end

			I3DUtil.setShaderParameterRec(lastPart.visual, "yOffset", yDif, 0, 0, 0, false, nil)

			if updateCollision then
				x, y, z = getTranslation(lastPart.collision)
				local xDir = 0
				local yDir = yDif
				local zDir = lastPart.length
				local length = MathUtil.vector3Length(xDir, yDir, zDir)
				xDir, yDir, zDir = MathUtil.vector3Normalize(xDir, yDir, zDir)
				local offset = (length - lastPart.length) * 0.5
				x = x + xDir * offset
				y = y + yDir * offset
				z = z + zDir * offset

				setDirection(lastPart.collision, xDir, yDir, zDir, 0, 1, 0)
				setTranslation(lastPart.collision, x, y, z)
			end
		end
	end

	return success
end

function PlaceableHusbandryFence:setPreviewPosition(superFunc, x, y, z, rotX, rotY, rotZ)
	superFunc(self, x, y, z, rotX, rotY, rotZ)

	local spec = self.spec_husbandryFence
	spec.canBePlaced = true

	for _, fence in ipairs(spec.fences) do
		local canBePlaced = self:updateHusbandryFence(fence, false)
		spec.canBePlaced = spec.canBePlaced and canBePlaced
	end
end

function PlaceableHusbandryFence:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if not self.spec_husbandryFence.canBePlaced then
		return false, g_i18n:getText("warning_canNotPlaceFence")
	end

	return superFunc(self, x, y, z, farmId)
end
