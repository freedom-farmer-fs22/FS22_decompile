PlaceableFence = {
	EPSILON = 1e-05
}

source("dataS/scripts/placeables/specializations/events/PlaceableFenceAddGateEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableFenceAddSegmentEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableFenceRemoveSegmentEvent.lua")

function PlaceableFence.prerequisitesPresent(specializations)
	return true
end

function PlaceableFence.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onCreateSegmentPanel")
end

function PlaceableFence.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "addSegment", PlaceableFence.addSegment)
	SpecializationUtil.registerFunction(placeableType, "addSegmentShapesToUpdate", PlaceableFence.addSegmentShapesToUpdate)
	SpecializationUtil.registerFunction(placeableType, "createSegment", PlaceableFence.createSegment)
	SpecializationUtil.registerFunction(placeableType, "deletePanel", PlaceableFence.deletePanel)
	SpecializationUtil.registerFunction(placeableType, "deleteSegment", PlaceableFence.deleteSegment)
	SpecializationUtil.registerFunction(placeableType, "doDeletePanel", PlaceableFence.doDeletePanel)
	SpecializationUtil.registerFunction(placeableType, "fakeRandomValueForPosition", PlaceableFence.fakeRandomValueForPosition)
	SpecializationUtil.registerFunction(placeableType, "findRaycastInfo", PlaceableFence.findRaycastInfo)
	SpecializationUtil.registerFunction(placeableType, "generateSegmentPoles", PlaceableFence.generateSegmentPoles)
	SpecializationUtil.registerFunction(placeableType, "getGate", PlaceableFence.getGate)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalAngle", PlaceableFence.getMaxVerticalAngle)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalAngleAndYForPreview", PlaceableFence.getMaxVerticalAngleAndYForPreview)
	SpecializationUtil.registerFunction(placeableType, "getMaxVerticalGateAngle", PlaceableFence.getMaxVerticalGateAngle)
	SpecializationUtil.registerFunction(placeableType, "getNodesToDeleteForPanel", PlaceableFence.getNodesToDeleteForPanel)
	SpecializationUtil.registerFunction(placeableType, "getNumSequments", PlaceableFence.getNumSequments)
	SpecializationUtil.registerFunction(placeableType, "getPanelLength", PlaceableFence.getPanelLength)
	SpecializationUtil.registerFunction(placeableType, "getIsPanelLengthFixed", PlaceableFence.getIsPanelLengthFixed)
	SpecializationUtil.registerFunction(placeableType, "getPoleNear", PlaceableFence.getPoleNear)
	SpecializationUtil.registerFunction(placeableType, "getPoleNearOverlapCallback", PlaceableFence.getPoleNearOverlapCallback)
	SpecializationUtil.registerFunction(placeableType, "getPolePosition", PlaceableFence.getPolePosition)
	SpecializationUtil.registerFunction(placeableType, "getPoleShapeForPreview", PlaceableFence.getPoleShapeForPreview)
	SpecializationUtil.registerFunction(placeableType, "getPreviewSegment", PlaceableFence.getPreviewSegment)
	SpecializationUtil.registerFunction(placeableType, "getSegment", PlaceableFence.getSegment)
	SpecializationUtil.registerFunction(placeableType, "getSegmentLength", PlaceableFence.getSegmentLength)
	SpecializationUtil.registerFunction(placeableType, "getTotalNumberOfPoles", PlaceableFence.getTotalNumberOfPoles)
	SpecializationUtil.registerFunction(placeableType, "isPoleInAnySegment", PlaceableFence.isPoleInAnySegment)
	SpecializationUtil.registerFunction(placeableType, "recursivelyAddPickingNodes", PlaceableFence.recursivelyAddPickingNodes)
	SpecializationUtil.registerFunction(placeableType, "regeneratePickingNodes", PlaceableFence.regeneratePickingNodes)
	SpecializationUtil.registerFunction(placeableType, "setPreviewSegment", PlaceableFence.setPreviewSegment)
	SpecializationUtil.registerFunction(placeableType, "updatePanelVisuals", PlaceableFence.updatePanelVisuals)
	SpecializationUtil.registerFunction(placeableType, "updateSegmentShapes", PlaceableFence.updateSegmentShapes)
	SpecializationUtil.registerFunction(placeableType, "updateSegmentUpdateQueue", PlaceableFence.updateSegmentUpdateQueue)
	SpecializationUtil.registerFunction(placeableType, "updateDirtyAreas", PlaceableFence.updateDirtyAreas)
	SpecializationUtil.registerFunction(placeableType, "getBoundingCheckWidth", PlaceableFence.getBoundingCheckWidth)
	SpecializationUtil.registerFunction(placeableType, "getAllowExtendingOnly", PlaceableFence.getAllowExtendingOnly)
	SpecializationUtil.registerFunction(placeableType, "getMaxCornerAngle", PlaceableFence.getMaxCornerAngle)
end

function PlaceableFence.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableFence.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableFence.getDestructionMethod)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableFence.performNodeDestruction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableFence.previewNodeDestructionNodes)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableFence.setOwnerFarmId)
end

function PlaceableFence.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableFence)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableFence)
end

function PlaceableFence.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.poles#node", "Group of pole variants")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.panels#node", "Group of panel variants")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.panels#length", "Length of the panels", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".fence.panels#fixedLength", "Panel length is fixed", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxVerticalAngle", "Maximum angle for vertical offset")
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxVerticalGateAngle", "Maximum angle for vertical offset with gates")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence#boundingCheckWidth", "With of the bounding box used to check collision", 0.25)
	schema:register(XMLValueType.BOOL, basePath .. ".fence#extendingOnly", "Whether to only allow extending a segment and no attaching to the center", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".fence#maxCornerAngle", "Maximum angle between two connected segments", 180)
	schema:register(XMLValueType.BOOL, basePath .. ".fence#hasInvisiblePoles", "Poles are not visible so another display method is used", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".fence.gate(?)#node", "Gate node")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.gate(?)#length", "Length of the gate from pole to pole", 1)
	schema:register(XMLValueType.INT, basePath .. ".fence.gate(?)#triggerNode", "Gate trigger node index from gate node")
	schema:register(XMLValueType.STRING, basePath .. ".fence.gate(?)#openText", "Action open text")
	schema:register(XMLValueType.STRING, basePath .. ".fence.gate(?)#closeText", "Action close text")
	schema:register(XMLValueType.FLOAT, basePath .. ".fence.gate(?)#openDuration", "Duration of animation in seconds")
	schema:register(XMLValueType.INT, basePath .. ".fence.gate(?).door(?)#node", "Node of the door")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".fence.gate(?).door(?)#openRotation", "Rotation of the node when fully open")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".fence.gate(?).door(?)#openTranslation", "Translation of the node when fully open")
	AnimatedObjectBuilder.registerXMLPaths(schema, basePath .. ".fence.gate(?)")
	schema:setXMLSpecializationType()
end

function PlaceableFence.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Fence")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".segments.segment(?)#start", "Segment start position")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".segments.segment(?)#end", "Segment end position")
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#first", "Segment has first pole visible", true)
	schema:register(XMLValueType.BOOL, basePath .. ".segments.segment(?)#last", "Segment has last pole visible", true)
	schema:register(XMLValueType.INT, basePath .. ".segments.segment(?)#gateIndex", "Gate index")
	AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".segments.segment(?).animatedObject")
	schema:setXMLSpecializationType()
end

function PlaceableFence:onLoad(savegame)
	local spec = self.spec_fence
	local xmlFile = self.xmlFile
	spec.pickObjects = {}
	spec.segments = {}
	spec.segmentsToUpdate = {}
	spec.animatedObjects = {}
	spec.previewSegment = nil
	spec.panelLength = xmlFile:getValue("placeable.fence.panels#length")
	spec.panelLengthFixed = xmlFile:getValue("placeable.fence.panels#fixedLength")
	spec.maxVerticalAngle = xmlFile:getValue("placeable.fence#maxVerticalAngle", 35)
	spec.maxVerticalGateAngle = xmlFile:getValue("placeable.fence#maxVerticalGateAngle", 5)
	spec.hasInvisiblePoles = xmlFile:getValue("placeable.fence#hasInvisiblePoles", false)
	spec.boundingCheckWidth = xmlFile:getValue("placeable.fence#boundingCheckWidth", 0.25)
	spec.allowExtendingOnly = xmlFile:getValue("placeable.fence#extendingOnly", false)
	spec.maxCornerAngle = xmlFile:getValue("placeable.fence#maxCornerAngle", 180)
	spec.poles = {}
	local polesNode = xmlFile:getValue("placeable.fence.poles#node", nil, self.components, self.i3dMappings)

	if polesNode ~= nil then
		for i = 1, getNumOfChildren(polesNode) do
			spec.poles[i] = getChildAt(polesNode, i - 1)
		end
	end

	spec.panels = {}
	local panelsNode = xmlFile:getValue("placeable.fence.panels#node", nil, self.components, self.i3dMappings)

	if panelsNode ~= nil then
		for i = 1, getNumOfChildren(panelsNode) do
			spec.panels[i] = getChildAt(panelsNode, i - 1)
		end
	end

	spec.gates = {}

	xmlFile:iterate("placeable.fence.gate", function (_, key)
		local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local doors = {}

			xmlFile:iterate(key .. ".door", function (_, doorKey)
				local doorNode = xmlFile:getValue(doorKey .. "#node")

				if doorNode ~= nil then
					table.insert(doors, {
						node = doorNode,
						rotation = xmlFile:getValue(doorKey .. "#openRotation", nil, true),
						translation = xmlFile:getValue(doorKey .. "#openTranslation", nil, true)
					})
				else
					Logging.xmlWarning(xmlFile, "Door node does not exist at %s", doorKey)
				end
			end)
			table.insert(spec.gates, {
				node = node,
				length = xmlFile:getValue(key .. "#length", 1),
				triggerNode = xmlFile:getValue(key .. "#triggerNode"),
				openText = xmlFile:getValue(key .. "#openText", "action_openGate"),
				closeText = xmlFile:getValue(key .. "#closeText", "action_closeGate"),
				animationDuration = xmlFile:getValue(key .. "#openDuration", 3),
				doors = doors
			})

			return
		end

		Logging.xmlWarning(xmlFile, "Gate node does not exist at %s", key)
	end)
end

function PlaceableFence:onDelete()
	local spec = self.spec_fence

	if spec.animatedObjects ~= nil then
		for _, animatedObject in ipairs(spec.animatedObjects) do
			animatedObject:delete()
		end
	end
end

function PlaceableFence:onReadStream(streamId, connection)
	local spec = self.spec_fence
	local numSegments = streamReadInt32(streamId)

	for i = 1, numSegments do
		local segment = {
			x1 = streamReadFloat32(streamId),
			z1 = streamReadFloat32(streamId),
			x2 = streamReadFloat32(streamId),
			z2 = streamReadFloat32(streamId),
			gateIndex = streamReadUInt8(streamId)
		}

		if segment.gateIndex == 0 then
			segment.gateIndex = nil
		end

		segment.renderFirst = streamReadBool(streamId)
		segment.renderLast = streamReadBool(streamId)
		segment.poles = {}

		table.insert(spec.segments, segment)
	end

	for i = 1, numSegments do
		local segment = spec.segments[i]

		self:generateSegmentPoles(segment, true)

		if segment.gateIndex ~= nil and segment.animatedObject ~= nil then
			local animatedObject = segment.animatedObject
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end
	end
end

function PlaceableFence:onWriteStream(streamId, connection)
	local spec = self.spec_fence
	local numSegments = #spec.segments

	streamWriteInt32(streamId, numSegments)

	for i = 1, numSegments do
		local segment = spec.segments[i]

		streamWriteFloat32(streamId, segment.x1)
		streamWriteFloat32(streamId, segment.z1)
		streamWriteFloat32(streamId, segment.x2)
		streamWriteFloat32(streamId, segment.z2)
		streamWriteUInt8(streamId, segment.gateIndex or 0)
		streamWriteBool(streamId, segment.renderFirst)
		streamWriteBool(streamId, segment.renderLast)
	end

	for i = 1, numSegments do
		local segment = spec.segments[i]

		if segment.gateIndex ~= nil and segment.animatedObject ~= nil then
			local animatedObject = segment.animatedObject

			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end
	end
end

function PlaceableFence:onUpdate(dt)
	self:updateSegmentUpdateQueue()
end

function PlaceableFence:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	local spec = self.spec_fence

	superFunc(self, ownerFarmId, noEventSend)

	for _, animatedObject in ipairs(spec.animatedObjects) do
		animatedObject:setOwnerFarmId(ownerFarmId, true)
	end
end

function PlaceableFence:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_fence

	xmlFile:iterate(key .. ".segments.segment", function (index, segmentKey)
		local x1, z1 = xmlFile:getValue(segmentKey .. "#start")
		local x2, z2 = xmlFile:getValue(segmentKey .. "#end")

		if x1 ~= nil and z1 ~= nil and x2 ~= nil and z2 ~= nil then
			local segment = {
				x1 = x1,
				z1 = z1,
				x2 = x2,
				z2 = z2,
				renderFirst = xmlFile:getValue(segmentKey .. "#first", true),
				renderLast = xmlFile:getValue(segmentKey .. "#last", true),
				gateIndex = xmlFile:getValue(segmentKey .. "#gateIndex"),
				poles = {},
				segmentKey = segmentKey
			}

			table.insert(spec.segments, segment)
		else
			Logging.xmlError(xmlFile, "Invalid segment position for '%s'. Ignoring segment!", segmentKey)
		end
	end)

	for i = 1, #spec.segments do
		local segment = spec.segments[i]

		self:generateSegmentPoles(segment, true)

		if segment.gateIndex ~= nil and segment.animatedObject ~= nil then
			segment.animatedObject:loadFromXMLFile(xmlFile, segment.segmentKey .. ".animatedObject")
		end

		segment.segmentKey = nil
	end
end

function PlaceableFence:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_fence

	xmlFile:setTable(key .. ".segments.segment", spec.segments, function (path, segment, _)
		xmlFile:setValue(path .. "#start", segment.x1, segment.z1)
		xmlFile:setValue(path .. "#end", segment.x2, segment.z2)

		if segment.gateIndex ~= nil then
			xmlFile:setValue(path .. "#gateIndex", segment.gateIndex)

			if segment.animatedObject ~= nil then
				segment.animatedObject:saveToXMLFile(xmlFile, path .. ".animatedObject", usedModNames)
			end
		end

		if not segment.renderFirst then
			xmlFile:setValue(path .. "#first", false)
		end

		if not segment.renderLast then
			xmlFile:setValue(path .. "#last", false)
		end
	end)
end

function PlaceableFence:getPoleNear(x, y, z, maxDistance)
	local spec = self.spec_fence
	spec.getPoleNearResult = nil
	spec.getPoleNearResultSegment = nil

	overlapSphere(x, y, z, maxDistance, "getPoleNearOverlapCallback", self, CollisionFlag.STATIC_OBJECTS, false, true, true, false)

	if spec.getPoleNearResult ~= nil then
		local x, y, z = getWorldTranslation(spec.getPoleNearResult)

		return x, y, z, spec.getPoleNearResult, spec.getPoleNearResultSegment
	end
end

function PlaceableFence:getPoleNearOverlapCallback(hitObjectId)
	if hitObjectId == 0 or hitObjectId == g_currentMission.terrainRootNode then
		return
	end

	local sGroup = getParent(getParent(hitObjectId))
	local spec = self.spec_fence

	for _, segment in ipairs(spec.segments) do
		if segment.group == sGroup then
			if getNumOfChildren(hitObjectId) < 3 then
				spec.getPoleNearResult = hitObjectId
				spec.getPoleNearResultSegment = segment
			end

			return
		end
	end
end

function PlaceableFence:getPolePosition(node, allowPanel)
	local spec = self.spec_fence
	local collision = node
	local item = getParent(collision)
	local parent = getParent(item)
	local parent2 = nil

	if allowPanel and parent ~= getRootNode() then
		parent2 = getParent(parent)
	end

	for i = 1, #spec.segments do
		local segment = spec.segments[i]

		if parent == segment.group then
			local x, y, z = getWorldTranslation(item)

			return x, y, z, segment
		elseif parent2 == segment.group then
			local x, y, z = getWorldTranslation(parent)

			return x, y, z, segment
		end
	end

	return nil
end

function PlaceableFence:getPoleShapeForPreview()
	local spec = self.spec_fence

	if spec.hasInvisiblePoles then
		return nil
	end

	if #spec.poles > 0 then
		if getNumOfChildren(spec.poles[1]) == 0 then
			return nil
		end

		local pole = clone(spec.poles[1], false, false, false)

		if pole == 0 then
			return nil
		end

		return pole
	else
		return nil
	end
end

function PlaceableFence:getMaxVerticalAngleAndYForPreview()
	local spec = self.spec_fence
	local segment = spec.previewSegment
	local maxAngle = 0
	local minY = 1000
	local maxY = -1000

	for i = 1, #segment.poles - 2, 2 do
		local x1 = segment.poles[i]
		local z1 = segment.poles[i + 1]
		local x2 = segment.poles[i + 2]
		local z2 = segment.poles[i + 3]
		local horizontalDifference = MathUtil.getPointPointDistance(x1, z1, x2, z2)
		local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
		local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)
		local heightDifference = math.abs(y1 - y2)
		minY = math.min(minY, y1, y2)
		maxY = math.max(maxY, y1, y2)

		if horizontalDifference > 0 then
			local angle = math.atan(heightDifference / horizontalDifference)

			if maxAngle < angle then
				maxAngle = angle
			end
		end
	end

	return maxAngle, minY, maxY
end

function PlaceableFence:getSegmentLength(segment)
	return MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
end

function PlaceableFence:getPanelLength()
	return self.spec_fence.panelLength
end

function PlaceableFence:getIsPanelLengthFixed()
	return self.spec_fence.panelLengthFixed
end

function PlaceableFence:getTotalNumberOfPoles()
	local spec = self.spec_fence
	local total = 0

	for s = 1, #spec.segments do
		total = total + spec.segments[s].poles / 2
	end

	return total
end

function PlaceableFence:createSegment(x1, z1, x2, z2, renderFirst, gateIndex)
	return {
		renderLast = true,
		x1 = x1,
		z1 = z1,
		x2 = x2,
		z2 = z2,
		renderFirst = renderFirst,
		gateIndex = gateIndex,
		poles = {}
	}
end

function PlaceableFence:addSegment(segment, sync)
	local spec = self.spec_fence
	spec.segments[#spec.segments + 1] = segment

	self:generateSegmentPoles(segment, sync)
	self:regeneratePickingNodes()
end

function PlaceableFence:deleteSegment(segment)
	local spec = self.spec_fence

	if segment.animatedObject ~= nil then
		segment.animatedObject:delete()

		segment.animatedObject = nil
	end

	if segment.group ~= nil then
		delete(segment.group)

		segment.group = nil
	end

	table.removeElement(spec.segments, segment)
	self:updateDirtyAreas(segment)
end

function PlaceableFence:updateDirtyAreas(segment)
	local minX = math.min(segment.x1, segment.x2)
	local maxX = math.max(segment.x1, segment.x2)
	local minZ = math.min(segment.z1, segment.z2)
	local maxZ = math.max(segment.z1, segment.z2)

	g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ)
	g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
end

function PlaceableFence:setPreviewSegment(segment)
	local spec = self.spec_fence

	if spec.previewSegment ~= nil and spec.previewSegment.group ~= nil and segment ~= spec.previewSegment then
		delete(spec.previewSegment.group)

		spec.previewSegment.group = nil
	end

	spec.previewSegment = segment

	if segment ~= nil then
		self:generateSegmentPoles(segment, false)
	end
end

function PlaceableFence:getPreviewSegment()
	local spec = self.spec_fence

	return spec.previewSegment
end

function PlaceableFence:getGate(index)
	local spec = self.spec_fence

	return spec.gates[index]
end

function PlaceableFence:getSegment(index)
	local spec = self.spec_fence

	return spec.segments[index]
end

function PlaceableFence:getNumSequments()
	local spec = self.spec_fence

	return #spec.segments
end

function PlaceableFence:getMaxVerticalAngle()
	local spec = self.spec_fence

	return spec.maxVerticalAngle
end

function PlaceableFence:getMaxVerticalGateAngle()
	local spec = self.spec_fence

	return spec.maxVerticalGateAngle
end

function PlaceableFence:getBoundingCheckWidth()
	return self.spec_fence.boundingCheckWidth
end

function PlaceableFence:getAllowExtendingOnly()
	return self.spec_fence.allowExtendingOnly
end

function PlaceableFence:getMaxCornerAngle()
	return self.spec_fence.maxCornerAngle
end

function PlaceableFence:deletePanel(node)
	if node == nil or node == 0 or getCollisionMask(node) == 0 then
		return
	end

	local spec = self.spec_fence
	local panel, _, segment, _, poleIndex = self:findRaycastInfo(node)

	if panel == nil then
		return nil
	end

	local segmentIndex = 1

	for i = 1, #spec.segments do
		if spec.segments[i] == segment then
			segmentIndex = i

			break
		end
	end

	if self.isServer then
		self:doDeletePanel(segment, segmentIndex, poleIndex)
		g_server:broadcastEvent(PlaceableFenceRemoveSegmentEvent.new(self, segmentIndex, poleIndex), false)
	else
		setCollisionMask(node, 0)
		g_client:getServerConnection():sendEvent(PlaceableFenceRemoveSegmentEvent.new(self, segmentIndex, poleIndex))
	end

	return true
end

function PlaceableFence:doDeletePanel(segment, segmentIndex, poleIndex)
	if segment == nil or poleIndex > #segment.poles then
		return
	end

	local deletedPoles = {}
	local originalSegment = {
		x1 = segment.x1,
		x2 = segment.x2,
		z1 = segment.x1,
		z2 = segment.z1
	}
	local segmentSizeChanged = false

	if poleIndex == 1 then
		if segment.renderFirst then
			deletedPoles[#deletedPoles + 1] = segment.poles[1]
			deletedPoles[#deletedPoles + 1] = segment.poles[2]
		end

		if poleIndex + 2 == #segment.poles - 1 then
			if segment.renderLast then
				deletedPoles[#deletedPoles + 1] = segment.poles[3]
				deletedPoles[#deletedPoles + 1] = segment.poles[4]
			end

			self:deleteSegment(segment)
		else
			segment.x1 = segment.poles[3]
			segment.z1 = segment.poles[4]
			segmentSizeChanged = true
			segment.renderFirst = true
		end
	elseif poleIndex + 2 == #segment.poles - 1 then
		if segment.renderLast then
			deletedPoles[#deletedPoles + 1] = segment.poles[#segment.poles - 1]
			deletedPoles[#deletedPoles + 1] = segment.poles[#segment.poles]
		end

		segment.x2 = segment.poles[#segment.poles - 3]
		segment.z2 = segment.poles[#segment.poles - 2]
		segment.renderLast = true
		segmentSizeChanged = true
	else
		local newSegment = self:createSegment(segment.poles[poleIndex + 2], segment.poles[poleIndex + 3], segment.x2, segment.z2, true, nil)
		newSegment.renderLast = segment.renderLast
		newSegment.renderFirst = true
		segment.x2 = segment.poles[poleIndex]
		segment.z2 = segment.poles[poleIndex + 1]
		segment.renderLast = true

		self:addSegment(newSegment)

		segmentSizeChanged = true
	end

	if segmentSizeChanged then
		self:generateSegmentPoles(segment, true)
	end

	for i = 1, #deletedPoles, 2 do
		local x = deletedPoles[i]
		local z = deletedPoles[i + 1]
		local neighborSegment, isStart = self:isPoleInAnySegment(x, z, segment)

		if neighborSegment ~= nil then
			if isStart then
				neighborSegment.renderFirst = true
			else
				neighborSegment.renderLast = true
			end

			self:generateSegmentPoles(neighborSegment, true)
		end
	end

	self:updateDirtyAreas(originalSegment)
	self:regeneratePickingNodes()

	return true
end

function PlaceableFence:findRaycastInfo(node)
	local spec = self.spec_fence
	local collision = node
	local panel = getParent(collision)
	local panelVisuals = getChildAt(panel, 1)
	local segment = nil
	local pole = getParent(panel)
	local sGroup = getParent(pole)

	for si = 1, #spec.segments do
		local seg = spec.segments[si]

		if seg.group == sGroup then
			segment = seg

			break
		elseif seg.group == pole and seg.gateIndex ~= nil then
			segment = seg
			sGroup = pole
			pole = panel
			panel = getChildAt(sGroup, getNumOfChildren(sGroup) - 1)
			panelVisuals = getChildAt(panel, 1)

			break
		end
	end

	if segment == nil then
		collision = node
		pole = getParent(collision)
		local sGroup = getParent(pole)

		for si = 1, #spec.segments do
			local seg = spec.segments[si]

			if seg.group == sGroup then
				segment = seg

				break
			end
		end

		if segment == nil then
			return nil
		end

		local poleIndex = getChildIndex(pole) * 2 + 1

		return nil, , segment, pole, poleIndex
	end

	local poleIndex = nil

	if segment.gateIndex ~= nil then
		poleIndex = 1
	else
		poleIndex = getChildIndex(pole) * 2 + 1
	end

	return panel, panelVisuals, segment, pole, poleIndex
end

function PlaceableFence:getNodesToDeleteForPanel(node)
	local spec = self.spec_fence
	local panel, panelVisuals, segment, pole, poleIndex = self:findRaycastInfo(node)

	if panel == nil or node == 0 then
		return nil
	end

	local nodes = {}

	if segment.gateIndex ~= nil then
		local gateInfo = spec.gates[segment.gateIndex]

		for _, door in ipairs(gateInfo.doors) do
			local doorNode = getChildAt(panel, door.node)
			nodes[#nodes + 1] = getChildAt(doorNode, 0)
		end
	else
		nodes[1] = panelVisuals
	end

	local function addPole(poleNode, x, z)
		if self:isPoleInAnySegment(x, z, segment) == nil then
			local visualPole = getChildAt(poleNode, 1)

			if visualPole ~= 0 then
				table.insert(nodes, visualPole)
			end
		end
	end

	if poleIndex == 1 and segment.renderFirst then
		addPole(pole, segment.poles[1], segment.poles[2])
	end

	if poleIndex + 2 == #segment.poles - 1 and segment.renderLast then
		addPole(getChildAt(segment.group, #segment.poles / 2 - 1), segment.poles[#segment.poles - 1], segment.poles[#segment.poles])
	end

	return nodes
end

function PlaceableFence:isPoleInAnySegment(x, z, ignoreSegment)
	local spec = self.spec_fence

	for i = 1, #spec.segments do
		local segment = spec.segments[i]

		if segment ~= ignoreSegment then
			if math.abs(segment.x1 - x) < PlaceableFence.EPSILON and math.abs(segment.z1 - z) < PlaceableFence.EPSILON then
				return segment, true, false
			elseif math.abs(segment.x2 - x) < PlaceableFence.EPSILON and math.abs(segment.z2 - z) < PlaceableFence.EPSILON then
				return segment, false, true
			end
		end
	end

	return nil
end

function PlaceableFence:fakeRandomValueForPosition(x, y, z, n)
	local alpha = (x * 0.13 + z * 0.23) % 1

	if n == nil then
		return alpha
	end

	return math.floor(alpha * (n - 1) + 0.5) + 1
end

function PlaceableFence:generateSegmentPoles(segment, sync)
	local spec = self.spec_fence
	local totalDistance = MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
	local numWholeFences = math.max(math.floor(totalDistance / spec.panelLength) - 1, 0)

	for i = 1, #segment.poles do
		segment.poles[i] = nil
	end

	if totalDistance < 0.01 then
		return
	end

	if segment.gateIndex ~= nil then
		segment.poles[1] = segment.x1
		segment.poles[2] = segment.z1
		segment.poles[3] = segment.x2
		segment.poles[4] = segment.z2
	else
		local nextPole = 1

		for j = 0, numWholeFences do
			local alpha = spec.panelLength * j / totalDistance
			segment.poles[nextPole] = MathUtil.lerp(segment.x1, segment.x2, alpha)
			segment.poles[nextPole + 1] = MathUtil.lerp(segment.z1, segment.z2, alpha)
			nextPole = nextPole + 2
		end

		local restDistance = totalDistance - numWholeFences * spec.panelLength
		local numRestFences = restDistance <= spec.panelLength * 1.2 and 1 or 2
		local restFenceSize = restDistance / numRestFences

		for j = 0, numRestFences - 1 do
			local alpha = (numWholeFences * spec.panelLength + (j + 1) * restFenceSize) / totalDistance
			segment.poles[nextPole] = MathUtil.lerp(segment.x1, segment.x2, alpha)
			segment.poles[nextPole + 1] = MathUtil.lerp(segment.z1, segment.z2, alpha)
			nextPole = nextPole + 2
		end
	end

	if sync then
		self:updateSegmentShapes(segment)
		self:regeneratePickingNodes()
	else
		self:addSegmentShapesToUpdate(segment)
	end

	if spec.previewSegment ~= segment then
		self:updateDirtyAreas(segment)
	end
end

function PlaceableFence:updateSegmentShapes(segment)
	local spec = self.spec_fence
	local isPreviewSegment = segment == spec.previewSegment
	local enablePhysics = not isPreviewSegment
	local gateTime = nil

	if segment.animatedObject ~= nil then
		gateTime = segment.animatedObject.animation.time

		segment.animatedObject:delete()

		segment.animatedObject = nil
	end

	if segment.group ~= nil then
		delete(segment.group)
	end

	segment.group = createTransformGroup("fence_segment")

	link(self.rootNode, segment.group)

	for i = 1, #segment.poles, 2 do
		local x = segment.poles[i]
		local z = segment.poles[i + 1]
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
		local pole = nil
		local poleIsFake = false

		if #spec.poles > 0 and (i > 1 or segment.renderFirst) and (i < #segment.poles - 2 or segment.renderLast) then
			local poleIndex = self:fakeRandomValueForPosition(x, y, z, #spec.poles)
			pole = clone(spec.poles[poleIndex], false, false, false)
		else
			pole = createTransformGroup("fence_firstPole")
			poleIsFake = true
		end

		link(segment.group, pole)
		setWorldTranslation(pole, x, y, z)

		if segment.gateIndex ~= nil then
			local prevX = segment.poles[(i + 2) % 4]
			local prevZ = segment.poles[(i + 2) % 4 + 1]
			local dx = x - prevX
			local dz = z - prevZ
			local rotY = math.atan2(dx, dz) + math.pi

			setWorldRotation(pole, 0, rotY, 0)

			if enablePhysics and not poleIsFake then
				addToPhysics(getChildAt(pole, 0))
			end
		elseif i < #segment.poles - 2 then
			local nextX = segment.poles[i + 2]
			local nextZ = segment.poles[i + 3]
			local nextY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, nextX, 0, nextZ)
			local dx = x - nextX
			local dy = y - nextY
			local dz = z - nextZ
			local rotY = math.atan2(dx, dz) + math.pi

			setWorldRotation(pole, 0, rotY, 0)

			local panelIndex = self:fakeRandomValueForPosition(x, y, z, #spec.panels)
			local panel = clone(spec.panels[panelIndex], false, false, false)

			link(pole, panel)

			local fenceLength = MathUtil.getPointPointDistance(x, z, nextX, nextZ)

			self:updatePanelVisuals(panel, dy, segment, i, fenceLength)

			local col = getChildAt(panel, 0)
			local xDir = 0
			local yDir = -dy
			local zDir = fenceLength
			xDir, yDir, zDir = MathUtil.vector3Normalize(xDir, yDir, zDir)
			local length = math.sqrt(dx * dx + dy * dy + dz * dz)
			local offset = (length - fenceLength) * 0.5
			local colX, colY, colZ = getTranslation(col)
			colX = colX + xDir * offset
			colY = colY + yDir * offset
			colZ = colZ + zDir * offset

			setDirection(col, xDir, yDir, zDir, 0, 1, 0)
			setTranslation(col, colX, colY, colZ)

			if enablePhysics then
				addToPhysics(col)
			end

			SpecializationUtil.raiseEvent(self, "onCreateSegmentPanel", isPreviewSegment, segment, panel, i, dy)

			if enablePhysics and not poleIsFake then
				addToPhysics(getChildAt(pole, 0))
			end
		elseif segment.renderLast and i > 2 then
			local prevX = segment.poles[i - 2]
			local prevZ = segment.poles[i - 1]
			local dx = x - prevX
			local dz = z - prevZ
			local rotY = math.atan2(dx, dz) + math.pi

			setWorldRotation(pole, 0, rotY, 0)

			if enablePhysics and not poleIsFake then
				addToPhysics(getChildAt(pole, 0))
			end
		end
	end

	if segment.gateIndex ~= nil then
		local gateInfo = spec.gates[segment.gateIndex]
		local gate = clone(gateInfo.node, false, false, false)

		link(segment.group, gate)

		local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, segment.x1, 0, segment.z1)

		setWorldTranslation(gate, segment.x1, y1, segment.z1)

		local dx = segment.x1 - segment.x2
		local dz = segment.z1 - segment.z2
		local rotY = math.atan2(dx, dz) + math.pi

		setWorldRotation(gate, 0, rotY, 0)

		if not isPreviewSegment then
			local animatedObject = AnimatedObject.new(self.isServer, self.isClient)

			animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)

			local saveId = string.format("AnimatedObject_%s_gate_%d_%d_%d_%d", self.configFileName, segment.x1, segment.z1, segment.x2, segment.x2)
			local builder = animatedObject:builder(self.configFileName, saveId)

			for _, door in ipairs(gateInfo.doors) do
				local doorNode = getChildAt(gate, door.node)

				builder:addSimplePart(doorNode, door.rotation, door.translation)
				addToPhysics(doorNode)
			end

			local triggerNode = getChildAt(gate, gateInfo.triggerNode)

			builder:setTrigger(triggerNode)
			addToPhysics(triggerNode)
			builder:setActions("ACTIVATE_HANDTOOL", gateInfo.openText, nil, gateInfo.closeText)
			builder:setDuration(gateInfo.animationDuration * 1000)

			if self.xmlFile == nil then
				self.xmlFile = XMLFile.load("fence", self.configFileName)
			end

			builder:setSounds(self.xmlFile.handle, string.format("placeable.fence.gate(%d).sounds", segment.gateIndex - 1), gate)

			if not builder:build() then
				animatedObject:delete()
			else
				animatedObject:register(true)
				table.insert(spec.animatedObjects, animatedObject)

				segment.animatedObject = animatedObject

				if gateTime ~= nil then
					animatedObject:setAnimTime(gateTime, true)
				end

				if self.isServer then
					for i = 1, #spec.segments do
						if spec.segments[i] == segment then
							g_server:broadcastEvent(PlaceableFenceAddGateEvent.new(self, i, animatedObject), false, nil, self)

							break
						end
					end
				end
			end
		else
			for _, door in ipairs(gateInfo.doors) do
				local doorNode = getChildAt(gate, door.node)
				local alpha = 0.3

				if door.translation ~= nil then
					local x1, y1, z1 = getTranslation(doorNode)
					local x2, y2, z2 = unpack(door.translation)

					setTranslation(doorNode, x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha)
				end

				if door.rotation ~= nil then
					local x1, y1, z1 = getRotation(doorNode)
					local x2, y2, z2 = unpack(door.rotation)

					setRotation(doorNode, x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha)
				end
			end
		end
	end
end

function PlaceableFence:updatePanelVisuals(panelNode, dy, segment, polesIndex, length)
	local spec = self.spec_fence

	if length ~= spec.panelLength then
		setScale(panelNode, 1, 1, length / spec.panelLength)
	end

	local function updateNode(node)
		if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "yOffset") then
			setShaderParameter(node, "yOffset", -dy, 0, 0, 0, false)
		end

		for v = 0, getNumOfChildren(node) - 1 do
			local child = getChildAt(node, v)

			updateNode(child)
		end
	end

	updateNode(getChildAt(panelNode, 1))
end

function PlaceableFence:addSegmentShapesToUpdate(segment)
	local spec = self.spec_fence
	spec.segmentsToUpdate[#spec.segmentsToUpdate + 1] = segment

	self:raiseActive()
end

function PlaceableFence:updateSegmentUpdateQueue()
	local spec = self.spec_fence

	if #spec.segmentsToUpdate > 0 then
		local segment = spec.segmentsToUpdate[1]

		table.remove(spec.segmentsToUpdate, 1)
		self:updateSegmentShapes(segment)

		if #spec.segmentsToUpdate == 0 then
			self:regeneratePickingNodes()
		end

		self:raiseActive()
	end
end

function PlaceableFence:regeneratePickingNodes()
	local spec = self.spec_fence

	for i = 1, #spec.pickObjects do
		g_currentMission:removeNodeObject(spec.pickObjects[i])

		spec.pickObjects[i] = nil
	end

	for _, segment in ipairs(spec.segments) do
		if segment.group ~= nil then
			self:recursivelyAddPickingNodes(segment.group)
		end
	end

	for _, node in ipairs(spec.pickObjects) do
		g_currentMission:addNodeObject(node, self)
	end

	self.overlayColorNodes = nil
end

function PlaceableFence:recursivelyAddPickingNodes(node)
	local spec = self.spec_fence

	if getRigidBodyType(node) ~= RigidBodyType.NONE then
		table.insert(spec.pickObjects, node)
	end

	local numChildren = getNumOfChildren(node)

	for i = 1, numChildren do
		self:recursivelyAddPickingNodes(getChildAt(node, i - 1))
	end
end

function PlaceableFence:getDestructionMethod(superFunc)
	return Placeable.DESTRUCTION.PER_NODE
end

function PlaceableFence:previewNodeDestructionNodes(superFunc, node)
	return self:getNodesToDeleteForPanel(node)
end

function PlaceableFence:performNodeDestruction(superFunc, node)
	self:deletePanel(node)

	return true
end

function PlaceableFence:collectPickObjects(superFunc, node)
end
