FillVolume = {
	SEND_NUM_BITS = 6,
	SEND_MAX_SIZE = 15
}
FillVolume.SEND_PRECISION = FillVolume.SEND_MAX_SIZE / math.pow(2, FillVolume.SEND_NUM_BITS)

function FillVolume.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function FillVolume.initSpecialization()
	g_configurationManager:addConfigurationType("fillVolume", g_i18n:getText("configuration_fillVolume"), "fillVolume", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("FillVolume")

	local basePath = "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?)"

	schema:register(XMLValueType.NODE_INDEX, basePath .. ".volumes.volume(?)#node", "Fill volume node")
	schema:register(XMLValueType.INT, basePath .. ".volumes.volume(?)#fillUnitIndex", "Fill unit index")
	schema:register(XMLValueType.FLOAT, basePath .. ".volumes.volume(?)#fillUnitFactor", "Fill unit factor", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".volumes.volume(?)#allSidePlanes", "All side planes", true)
	schema:register(XMLValueType.BOOL, basePath .. ".volumes.volume(?)#retessellateTop", "Retessellate top plane for better triangulation quality", false)
	schema:register(XMLValueType.STRING, basePath .. ".volumes.volume(?)#defaultFillType", "Default fill type name")
	schema:register(XMLValueType.STRING, basePath .. ".volumes.volume(?)#forcedVolumeFillType", "Forced fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".volumes.volume(?)#maxDelta", "Max. heap size above above input surface [m]", 1)
	schema:register(XMLValueType.ANGLE, basePath .. ".volumes.volume(?)#maxAllowedHeapAngle", "Max. allowed heap surface slope angle [deg]", 35)
	schema:register(XMLValueType.FLOAT, basePath .. ".volumes.volume(?)#maxSurfaceDistanceError", "Max. allowed distance from input mesh surface to created fill plane mesh [m]", 0.05)
	schema:register(XMLValueType.FLOAT, basePath .. ".volumes.volume(?)#maxSubDivEdgeLength", "Max. length of sub division edges [m]", 0.9)
	schema:register(XMLValueType.FLOAT, basePath .. ".volumes.volume(?)#syncMaxSubDivEdgeLength", "Max. length of sub division edges used to sync in multiplayer [m]", 1.35)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".volumes.volume(?).deformNode(?)#node", "Deformer node")
	FillVolume.registerInfoNodeXMLPaths(schema, "vehicle.fillVolume.loadInfos.loadInfo(?)")
	FillVolume.registerInfoNodeXMLPaths(schema, "vehicle.fillVolume.unloadInfos.unloadInfo(?)")
	schema:register(XMLValueType.INT, "vehicle.fillVolume.heightNodes.heightNode(?)#fillVolumeIndex", "Fill volume index")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).refNode(?)#node", "Reference node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#node", "Height node")
	schema:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#baseScale", "Base scale", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleAxis", "Scale axis", "0 0 0")
	schema:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleMax", "Max. scale", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transAxis", "Translation axis", "0 0 0")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transMax", "Max. translation", "0 0 0")
	schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#heightOffset", "Fill plane height offset", 0)
	schema:register(XMLValueType.BOOL, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#orientateToWorldY", "Orientate to world Y", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, Cylindered.MOVING_TOOL_XML_KEY .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_TOOL_XML_KEY .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
	schema:register(XMLValueType.INT, Cylindered.MOVING_PART_XML_KEY .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_PART_XML_KEY .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
	schema:setXMLSpecializationType()
end

function FillVolume.registerInfoNodeXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Info node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#width", "Info width", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#length", "Info length", 1)
	schema:register(XMLValueType.INT, basePath .. ".node(?)#fillVolumeHeightIndex", "Fill volume height index")
	schema:register(XMLValueType.INT, basePath .. ".node(?)#priority", "Priority", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minHeight", "Min. height")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxHeight", "Max. height")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minFillLevelPercentage", "Min. fill level percentage")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxFillLevelPercentage", "Min. fill level percentage")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#heightForTranslation", "Min. height for translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationStart", "Translation start")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationEnd", "Translation end")
end

function FillVolume.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolume", FillVolume.loadFillVolume)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeInfo", FillVolume.loadFillVolumeInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeHeightNode", FillVolume.loadFillVolumeHeightNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeLoadInfo", FillVolume.getFillVolumeLoadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUnloadInfo", FillVolume.getFillVolumeUnloadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeIndicesByFillUnitIndex", FillVolume.getFillVolumeIndicesByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillTypeByFillUnitIndex", FillVolume.setFillVolumeForcedFillTypeByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillType", FillVolume.setFillVolumeForcedFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUVScrollSpeed", FillVolume.getFillVolumeUVScrollSpeed)
end

function FillVolume.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setMovingToolDirty", FillVolume.setMovingToolDirty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", FillVolume.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", FillVolume.updateExtraDependentParts)
end

function FillVolume.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", FillVolume)
end

function FillVolume:onLoad(savegame)
	local spec = self.spec_fillVolume
	local fillVolumeConfigurationId = Utils.getNoNil(self.configurations.fillVolume, 1)
	local configKey = string.format("vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(%d).volumes", fillVolumeConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration", fillVolumeConfigurationId, self.components, self)

	spec.volumes = {}
	spec.fillVolumeDeformersByNode = {}
	spec.fillUnitFillVolumeMapping = {}

	self.xmlFile:iterate(configKey .. ".volume", function (_, key)
		local entry = {}

		if self:loadFillVolume(self.xmlFile, key, entry) then
			table.insert(spec.volumes, entry)

			entry.index = #spec.volumes
		end
	end)

	for _, mapping in ipairs(spec.fillUnitFillVolumeMapping) do
		for _, fillVolume in ipairs(mapping.fillVolumes) do
			fillVolume.fillUnitFactor = fillVolume.fillUnitFactor / mapping.sumFactors
		end
	end

	for _, fillVolume in ipairs(spec.volumes) do
		local capacity = self:getFillUnitCapacity(fillVolume.fillUnitIndex)
		local fillVolumeCapacity = capacity * fillVolume.fillUnitFactor
		fillVolume.volume = createFillPlaneShape(fillVolume.baseNode, "fillPlane", fillVolumeCapacity, fillVolume.maxDelta, fillVolume.maxSurfaceAngle, fillVolume.maxPhysicalSurfaceAngle, fillVolume.maxSurfaceDistanceError, fillVolume.maxSubDivEdgeLength, fillVolume.syncMaxSubDivEdgeLength, fillVolume.allSidePlanes, fillVolume.retessellateTop)

		if fillVolume.volume == nil or fillVolume.volume == 0 then
			print("Warning: fillVolume '" .. tostring(getName(fillVolume.baseNode)) .. "' could not create actual fillVolume in '" .. self.configFileName .. "'! Simplifying the mesh could help")

			fillVolume.volume = nil
		else
			setVisibility(fillVolume.volume, false)

			for i = #fillVolume.deformers, 1, -1 do
				local deformer = fillVolume.deformers[i]
				deformer.polyline = findPolyline(fillVolume.volume, deformer.posX, deformer.posZ)

				if deformer.polyline == nil and deformer.polyline ~= -1 then
					print("Warning: Could not find 'polyline' for '" .. tostring(getName(deformer.node)) .. "' in '" .. self.configFileName .. "'")
					table.remove(fillVolume.deformers, i)
				end
			end

			link(fillVolume.baseNode, fillVolume.volume)

			local fillVolumeMaterial = g_materialManager:getBaseMaterialByName("fillPlane")

			if fillVolumeMaterial ~= nil then
				setMaterial(fillVolume.volume, fillVolumeMaterial, 0)
				g_fillTypeManager:assignFillTypeTextureArrays(fillVolume.volume, true, true, true)
			else
				Logging.error("Failed to assign material to fill volume. Base Material 'fillPlane' not found!")
			end

			fillPlaneAdd(fillVolume.volume, 1, 0, 1, 0, 11, 0, 0, 0, 0, 11)

			fillVolume.heightOffset = getFillPlaneHeightAtLocalPos(fillVolume.volume, 0, 0)

			fillPlaneAdd(fillVolume.volume, -1, 0, 1, 0, 11, 0, 0, 0, 0, 11)
		end
	end

	spec.loadInfos = {}

	self.xmlFile:iterate("vehicle.fillVolume.loadInfos.loadInfo", function (_, key)
		local entry = {}

		if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
			table.insert(spec.loadInfos, entry)
		end
	end)

	spec.unloadInfos = {}

	self.xmlFile:iterate("vehicle.fillVolume.unloadInfos.unloadInfo", function (_, key)
		local entry = {}

		if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
			table.insert(spec.unloadInfos, entry)
		end
	end)

	spec.heightNodes = {}
	spec.fillVolumeIndexToHeightNode = {}

	self.xmlFile:iterate("vehicle.fillVolume.heightNodes.heightNode", function (_, key)
		local entry = {}

		if self:loadFillVolumeHeightNode(self.xmlFile, key, entry) then
			table.insert(spec.heightNodes, entry)

			if spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] == nil then
				spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] = {}
			end

			table.insert(spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex], entry)
		end
	end)

	spec.lastPositionInfo = {
		0,
		0
	}
	spec.lastPositionInfoSent = {
		0,
		0
	}
	spec.availableFillNodes = {}
	spec.dirtyFlag = self:getNextDirtyFlag()

	if not self.isClient or #spec.volumes == 0 and #spec.heightNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", FillVolume)
	end
end

function FillVolume:onDelete()
	local spec = self.spec_fillVolume

	if spec.volumes ~= nil then
		for _, fillVolume in ipairs(spec.volumes) do
			if fillVolume.volume ~= nil then
				delete(fillVolume.volume)
			end

			fillVolume.volume = nil
		end
	end
end

function FillVolume:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_fillVolume

		if streamReadBool(streamId) then
			local x = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			local z = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			spec.lastPositionInfo[1] = x
			spec.lastPositionInfo[2] = z
		end
	end
end

function FillVolume:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_fillVolume

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			local x = (spec.lastPositionInfoSent[1] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, x, FillVolume.SEND_NUM_BITS)

			local z = (spec.lastPositionInfoSent[2] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, z, FillVolume.SEND_NUM_BITS)

			spec.lastPositionInfoSent[1] = math.floor(x) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			spec.lastPositionInfoSent[2] = math.floor(z) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
		end
	end
end

function FillVolume:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_fillVolume

		for _, volume in pairs(spec.volumes) do
			for _, deformer in ipairs(volume.deformers) do
				if deformer.isDirty and deformer.polyline ~= nil and deformer.polyline ~= -1 then
					deformer.isDirty = false
					local posX, posY, posZ = localToLocal(deformer.node, deformer.baseNode, 0, 0, 0)

					if math.abs(posX - deformer.posX) > 0.0001 or math.abs(posZ - deformer.posZ) > 0.0001 then
						deformer.lastPosX = posX
						deformer.lastPosZ = posZ
						local dx = posX - deformer.initPos[1]
						local dz = posZ - deformer.initPos[3]

						setPolylineTranslation(volume.volume, deformer.polyline, dx, dz)
					end
				end
			end

			local uvScrollSpeedX, uvScrollSpeedY, uvScrollSpeedZ = self:getFillVolumeUVScrollSpeed(volume.index)

			if uvScrollSpeedX ~= 0 or uvScrollSpeedY ~= 0 or uvScrollSpeedZ ~= 0 then
				volume.uvPosition[1] = volume.uvPosition[1] + uvScrollSpeedX * dt / 1000
				volume.uvPosition[2] = volume.uvPosition[2] + uvScrollSpeedY * dt / 1000
				volume.uvPosition[3] = volume.uvPosition[3] + uvScrollSpeedZ * dt / 1000

				setShaderParameter(volume.volume, "uvOffset", volume.uvPosition[1], volume.uvPosition[2], volume.uvPosition[3], 0, false)
			end
		end

		for _, heightNode in pairs(spec.heightNodes) do
			if heightNode.isDirty then
				heightNode.isDirty = false
				local fillVolume = spec.volumes[heightNode.fillVolumeIndex]
				local baseNode = fillVolume.baseNode
				local volumeNode = fillVolume.volume

				if baseNode ~= nil and volumeNode ~= nil then
					local minHeight = math.huge
					local maxHeight = -math.huge
					local maxHeightWorld = -math.huge

					for _, refNode in pairs(heightNode.refNodes) do
						local x, _, z = localToLocal(refNode.refNode, baseNode, 0, 0, 0)
						local height = getFillPlaneHeightAtLocalPos(volumeNode, x, z) - fillVolume.heightOffset
						minHeight = math.min(minHeight, height)
						maxHeight = math.max(maxHeight, height)
						local _, yw, _ = localToWorld(baseNode, x, height, z)
						maxHeightWorld = math.max(maxHeightWorld, yw)
					end

					heightNode.currentMinHeight = minHeight
					heightNode.currentMaxHeight = maxHeight
					heightNode.currentMaxHeightWorld = maxHeightWorld

					for _, node in pairs(heightNode.nodes) do
						local nodeHeight = math.max(minHeight + node.heightOffset, 0)
						local sx = node.scaleAxis[1] * nodeHeight
						local sy = node.scaleAxis[2] * nodeHeight
						local sz = node.scaleAxis[3] * nodeHeight

						if node.scaleMax[1] > 0 then
							sx = math.min(node.scaleMax[1], sx)
						end

						if node.scaleMax[2] > 0 then
							sy = math.min(node.scaleMax[2], sy)
						end

						if node.scaleMax[3] > 0 then
							sz = math.min(node.scaleMax[3], sz)
						end

						local tx = node.transAxis[1] * nodeHeight
						local ty = node.transAxis[2] * nodeHeight
						local tz = node.transAxis[3] * nodeHeight

						if node.transMax[1] > 0 then
							tx = math.min(node.transMax[1], tx)
						end

						if node.transMax[2] > 0 then
							ty = math.min(node.transMax[2], ty)
						end

						if node.transMax[3] > 0 then
							tz = math.min(node.transMax[3], tz)
						end

						setScale(node.node, node.baseScale[1] + sx, node.baseScale[2] + sy, node.baseScale[3] + sz)
						setTranslation(node.node, node.basePosition[1] + tx, node.basePosition[2] + ty, node.basePosition[3] + tz)

						if node.orientateToWorldY then
							local _, dy, _ = localDirectionToWorld(getParent(node.node), 0, 1, 0)
							local alpha = math.acos(dy)

							setRotation(node.node, alpha, 0, 0)
						end
					end
				end
			end
		end
	end
end

function FillVolume:loadFillVolume(xmlFile, key, entry)
	local spec = self.spec_fillVolume

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

	entry.baseNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if entry.baseNode == nil then
		print("Warning: fillVolume '" .. tostring(key) .. "' has an invalid 'node' in '" .. self.configFileName .. "'!")

		return false
	end

	local fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")
	entry.fillUnitIndex = fillUnitIndex

	if fillUnitIndex == nil then
		print("Warning: fillVolume '" .. tostring(key) .. "' has no 'fillUnitIndex' given in '" .. self.configFileName .. "'!")

		return false
	end

	if not self:getFillUnitExists(fillUnitIndex) then
		print("Warning: fillVolume '" .. tostring(key) .. "' has an invalid 'fillUnitIndex' in '" .. self.configFileName .. "'!")

		return false
	end

	entry.fillUnitFactor = xmlFile:getValue(key .. "#fillUnitFactor", 1)

	if spec.fillUnitFillVolumeMapping[fillUnitIndex] == nil then
		spec.fillUnitFillVolumeMapping[fillUnitIndex] = {
			sumFactors = 0,
			fillVolumes = {}
		}
	end

	table.insert(spec.fillUnitFillVolumeMapping[fillUnitIndex].fillVolumes, entry)

	spec.fillUnitFillVolumeMapping[fillUnitIndex].sumFactors = entry.fillUnitFactor
	entry.allSidePlanes = xmlFile:getValue(key .. "#allSidePlanes", true)
	entry.retessellateTop = xmlFile:getValue(key .. "#retessellateTop", false)
	local defaultFillTypeStr = xmlFile:getValue(key .. "#defaultFillType")

	if defaultFillTypeStr ~= nil then
		local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeStr)

		if defaultFillTypeIndex == nil then
			print("Warning: Invalid defaultFillType '" .. tostring(defaultFillTypeStr) .. "' for '" .. tostring(key) .. "' in '" .. self.configFileName .. "'")

			return false
		else
			entry.defaultFillType = defaultFillTypeIndex
		end
	else
		entry.defaultFillType = self:getFillUnitFirstSupportedFillType(fillUnitIndex)
	end

	local forcedVolumeFillTypeStr = xmlFile:getValue(key .. "#forcedVolumeFillType")

	if forcedVolumeFillTypeStr ~= nil then
		local forcedVolumeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(forcedVolumeFillTypeStr)

		if forcedVolumeFillTypeIndex ~= nil then
			entry.forcedVolumeFillType = forcedVolumeFillTypeIndex
		else
			print("Warning: Invalid forcedVolumeFillType '" .. tostring(forcedVolumeFillTypeStr) .. "' for '" .. tostring(key) .. "' in '" .. self.configFileName .. "'")

			return false
		end
	end

	entry.maxDelta = xmlFile:getValue(key .. "#maxDelta", 1)
	entry.maxSurfaceAngle = xmlFile:getValue(key .. "#maxAllowedHeapAngle", 35)
	entry.maxPhysicalSurfaceAngle = math.rad(35)
	entry.maxSurfaceDistanceError = xmlFile:getValue(key .. "#maxSurfaceDistanceError", 0.05)
	entry.maxSubDivEdgeLength = xmlFile:getValue(key .. "#maxSubDivEdgeLength", 0.9)
	entry.syncMaxSubDivEdgeLength = xmlFile:getValue(key .. "#syncMaxSubDivEdgeLength", 1.35)
	entry.uvPosition = {
		0,
		0,
		0
	}
	entry.deformers = {}
	local j = 0

	while true do
		local deformerKey = string.format("%s.deformNode(%d)", key, j)

		if not xmlFile:hasProperty(deformerKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, deformerKey .. "#index", deformerKey .. "#node")

		local node = xmlFile:getValue(deformerKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local initPos = {
				localToLocal(node, entry.baseNode, 0, 0, 0)
			}
			local deformer = {
				node = node,
				initPos = initPos,
				posX = initPos[1],
				posZ = initPos[3],
				volume = entry.volume,
				baseNode = entry.baseNode
			}

			table.insert(entry.deformers, deformer)

			spec.fillVolumeDeformersByNode[node] = deformer
		end

		j = j + 1
	end

	entry.lastFillType = FillType.UNKNOWN

	return true
end

function FillVolume:loadFillVolumeInfo(xmlFile, key, entry)
	entry.nodes = {}
	local i = 0

	while true do
		local infoKey = key .. string.format(".node(%d)", i)

		if not xmlFile:hasProperty(infoKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, infoKey .. "#index", infoKey .. "#node")

		local node = xmlFile:getValue(infoKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local nodeEntry = {
				node = node,
				width = xmlFile:getValue(infoKey .. "#width", 1),
				length = xmlFile:getValue(infoKey .. "#length", 1),
				fillVolumeHeightIndex = xmlFile:getValue(infoKey .. "#fillVolumeHeightIndex"),
				priority = xmlFile:getValue(infoKey .. "#priority", 1),
				minHeight = xmlFile:getValue(infoKey .. "#minHeight"),
				maxHeight = xmlFile:getValue(infoKey .. "#maxHeight"),
				minFillLevelPercentage = xmlFile:getValue(infoKey .. "#minFillLevelPercentage"),
				maxFillLevelPercentage = xmlFile:getValue(infoKey .. "#maxFillLevelPercentage"),
				heightForTranslation = xmlFile:getValue(infoKey .. "#heightForTranslation"),
				translationStart = xmlFile:getValue(infoKey .. "#translationStart", nil, true),
				translationEnd = xmlFile:getValue(infoKey .. "#translationEnd", nil, true),
				translationAlpha = 0
			}

			table.insert(entry.nodes, nodeEntry)
		else
			Logging.xmlWarning(self.xmlFile, "Missing node for '%s'", infoKey)
		end

		i = i + 1
	end

	table.sort(entry.nodes, function (a, b)
		return b.priority < a.priority
	end)

	return true
end

function FillVolume:loadFillVolumeHeightNode(xmlFile, key, entry)
	entry.isDirty = false
	entry.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex", 1)

	if self.spec_fillVolume.volumes[entry.fillVolumeIndex] == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid fillVolumeIndex '%d' for heightNode '%s'. Igoring heightNode!", entry.fillVolumeIndex, key)

		return false
	end

	entry.refNodes = {}
	local i = 0

	while true do
		local nodeKey = key .. string.format(".refNode(%d)", i)

		if not xmlFile:hasProperty(nodeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, nodeKey .. "#index", nodeKey .. "#node")

		local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			table.insert(entry.refNodes, {
				refNode = node
			})
		else
			Logging.xmlWarning(self.xmlFile, "Missing node for '%s'", nodeKey)
		end

		i = i + 1
	end

	entry.nodes = {}
	i = 0

	while true do
		local nodeKey = key .. string.format(".node(%d)", i)

		if not xmlFile:hasProperty(nodeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, nodeKey .. "#index", nodeKey .. "#node")

		local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local nodeEntry = {
				node = node,
				baseScale = xmlFile:getValue(nodeKey .. "#baseScale", "1 1 1", true),
				scaleAxis = xmlFile:getValue(nodeKey .. "#scaleAxis", "0 0 0", true),
				scaleMax = xmlFile:getValue(nodeKey .. "#scaleMax", "0 0 0", true),
				basePosition = {
					getTranslation(node)
				},
				transAxis = xmlFile:getValue(nodeKey .. "#transAxis", "0 0 0", true),
				transMax = xmlFile:getValue(nodeKey .. "#transMax", "0 0 0", true),
				heightOffset = xmlFile:getValue(nodeKey .. "#heightOffset", 0),
				orientateToWorldY = xmlFile:getValue(nodeKey .. "#orientateToWorldY", false)
			}

			table.insert(entry.nodes, nodeEntry)
		else
			Logging.xmlWarning(self.xmlFile, "Missing node for '%s'", nodeKey)
		end

		i = i + 1
	end

	return true
end

function FillVolume:getFillVolumeLoadInfo(loadInfoIndex)
	local spec = self.spec_fillVolume

	return spec.loadInfos[loadInfoIndex]
end

function FillVolume:getFillVolumeUnloadInfo(unloadInfoIndex)
	local spec = self.spec_fillVolume

	return spec.unloadInfos[unloadInfoIndex]
end

function FillVolume:getFillVolumeIndicesByFillUnitIndex(fillUnitIndex)
	local spec = self.spec_fillVolume
	local indices = {}

	for i, fillVolume in ipairs(spec.volumes) do
		if fillVolume.fillUnitIndex == fillUnitIndex then
			table.insert(indices, i)
		end
	end

	return indices
end

function FillVolume:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedFillType)
	local spec = self.spec_fillVolume

	for i, fillVolume in ipairs(spec.volumes) do
		if fillVolume.fillUnitIndex == fillUnitIndex then
			self:setFillVolumeForcedFillType(i, forcedFillType)
		end
	end
end

function FillVolume:setFillVolumeForcedFillType(fillVolumeIndex, forcedFillType)
	local spec = self.spec_fillVolume

	if spec.volumes[fillVolumeIndex] ~= nil then
		spec.volumes[fillVolumeIndex].forcedFillType = forcedFillType
	end
end

function FillVolume:getFillVolumeUVScrollSpeed()
	return 0, 0, 0
end

function FillVolume:setMovingToolDirty(superFunc, node, forceUpdate, dt)
	superFunc(self, node, forceUpdate, dt)

	local spec = self.spec_fillVolume

	if spec.fillVolumeDeformersByNode ~= nil then
		local deformer = spec.fillVolumeDeformersByNode[node]

		if deformer ~= nil then
			deformer.isDirty = true
		end
	end
end

function FillVolume:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	local fillVolumeIndex = xmlFile:getValue(baseName .. ".fillVolume#fillVolumeIndex", 1)
	local indices = xmlFile:getValue(baseName .. ".fillVolume#deformerNodeIndices", nil, true)

	if indices ~= nil and #indices > 0 then
		entry.fillVolumeIndex = fillVolumeIndex
		entry.deformerNodes = {}

		for i = 1, table.getn(indices) do
			table.insert(entry.deformerNodes, indices[i])
		end
	end

	return true
end

function FillVolume:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if part.deformerNodes ~= nil then
		if part.fillVolumeIndex ~= nil then
			part.fillVolume = self.spec_fillVolume.volumes[part.fillVolumeIndex]

			if part.fillVolume == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find fillVolume with index '%d' for movingPart/movingTool '%s'", part.fillVolumeIndex, getName(part.node))

				part.deformerNodes = nil
			end

			part.fillVolumeIndex = nil
		end

		if part.fillVolume ~= nil then
			for i, nodeIndex in pairs(part.deformerNodes) do
				local deformerNode = part.fillVolume.deformers[nodeIndex]

				if deformerNode == nil then
					part.deformerNodes[i] = nil
				else
					deformerNode.isDirty = true
				end
			end
		end
	end
end

function FillVolume:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, _, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_fillVolume
	local mapping = spec.fillUnitFillVolumeMapping[fillUnitIndex]

	if mapping == nil then
		return
	end

	local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
	local fillType = self:getFillUnitFillType(fillUnitIndex)

	for _, volume in ipairs(mapping.fillVolumes) do
		local baseNode = volume.baseNode
		local volumeNode = volume.volume

		if baseNode == nil or volumeNode == nil then
			return
		end

		if volume.forcedFillType ~= nil then
			fillType = volume.forcedFillType
		end

		if fillLevel == 0 then
			volume.forcedFillType = nil
		end

		if fillType ~= volume.lastFillType then
			local maxPhysicalSurfaceAngle = nil
			local fillTypeInfo = g_fillTypeManager:getFillTypeByIndex(fillType)

			if fillTypeInfo ~= nil then
				maxPhysicalSurfaceAngle = fillTypeInfo.maxPhysicalSurfaceAngle
			end

			if maxPhysicalSurfaceAngle ~= nil and volume.volume ~= nil then
				setFillPlaneMaxPhysicalSurfaceAngle(volume.volume, maxPhysicalSurfaceAngle)

				volume.maxPhysicalSurfaceAngle = maxPhysicalSurfaceAngle
			end
		end

		setVisibility(volume.volume, fillLevel > 0)

		if fillType ~= FillType.UNKNOWN and fillType ~= volume.lastFillType then
			local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillType)

			if textureArrayIndex ~= nil then
				setShaderParameter(volume.volume, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
			end
		end

		if fillPositionData ~= nil then
			for i = #spec.availableFillNodes, 1, -1 do
				spec.availableFillNodes[i] = nil
			end

			if fillPositionData.nodes ~= nil then
				local neededPriority = fillPositionData.nodes[1].priority

				while #spec.availableFillNodes == 0 and neededPriority >= 1 do
					for _, node in pairs(fillPositionData.nodes) do
						if neededPriority <= node.priority then
							local doInsert = true

							if node.minHeight ~= nil or node.maxHeight ~= nil then
								local height = -math.huge

								if node.fillVolumeHeightIndex ~= nil and spec.heightNodes[node.fillVolumeHeightIndex] ~= nil then
									for _, refNode in pairs(spec.heightNodes[node.fillVolumeHeightIndex].refNodes) do
										local x, _, z = localToLocal(refNode.refNode, baseNode, 0, 0, 0)
										height = math.max(height, getFillPlaneHeightAtLocalPos(volumeNode, x, z) - volume.heightOffset)
									end
								else
									local x, _, z = localToLocal(node.node, baseNode, 0, 0, 0)
									height = math.max(height, getFillPlaneHeightAtLocalPos(volumeNode, x, z) - volume.heightOffset)
								end

								if node.minHeight ~= nil and height < node.minHeight then
									doInsert = false
								end

								if node.maxHeight ~= nil and node.maxHeight < height then
									doInsert = false
								end

								if node.heightForTranslation ~= nil then
									if node.heightForTranslation < height then
										node.translationAlpha = node.translationAlpha + 0.01
										local x, y, z = MathUtil.vector3ArrayLerp(node.translationStart, node.translationEnd, node.translationAlpha)

										setTranslation(node.node, x, y, z)
									else
										node.translationAlpha = node.translationAlpha - 0.01
									end

									node.translationAlpha = MathUtil.clamp(node.translationAlpha, 0, 1)
								end
							end

							if node.minFillLevelPercentage ~= nil or node.maxFillLevelPercentage ~= nil then
								local percentage = fillLevel / self:getFillUnitCapacity(fillUnitIndex)

								if node.minFillLevelPercentage ~= nil and percentage < node.minFillLevelPercentage then
									doInsert = false
								end

								if node.maxFillLevelPercentage ~= nil and node.maxFillLevelPercentage < percentage then
									doInsert = false
								end
							end

							if doInsert then
								table.insert(spec.availableFillNodes, node)
							end
						end
					end

					if #spec.availableFillNodes > 0 then
						break
					end

					neededPriority = neededPriority - 1
				end
			else
				table.insert(spec.availableFillNodes, fillPositionData)
			end

			local numFillNodes = #spec.availableFillNodes
			local avgX = 0
			local avgZ = 0

			for i = 1, numFillNodes do
				local node = spec.availableFillNodes[i]
				local x0, y0, z0 = getWorldTranslation(node.node)
				local d1x, d1y, d1z = localDirectionToWorld(node.node, node.width, 0, 0)
				local d2x, d2y, d2z = localDirectionToWorld(node.node, 0, 0, node.length)

				if VehicleDebug.state == VehicleDebug.DEBUG then
					drawDebugLine(x0, y0, z0, 1, 0, 0, x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0)
					drawDebugLine(x0, y0, z0, 0, 0, 1, x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1)
					drawDebugPoint(x0, y0, z0, 1, 1, 1, 1)
					drawDebugPoint(x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0, 1)
					drawDebugPoint(x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1, 1)
				end

				x0 = x0 - (d1x + d2x) / 2
				y0 = y0 - (d1y + d2y) / 2
				z0 = z0 - (d1z + d2z) / 2

				fillPlaneAdd(volume.volume, appliedDelta / numFillNodes, x0, y0, z0, d1x, d1y, d1z, d2x, d2y, d2z)

				local newX, _, newZ = localToLocal(node.node, volume.volume, 0, 0, 0)
				avgZ = avgZ + newZ
				avgX = avgX + newX
			end

			local newX = avgX / numFillNodes
			local newZ = avgZ / numFillNodes

			if FillVolume.SEND_PRECISION < math.abs(newX - spec.lastPositionInfoSent[1]) or FillVolume.SEND_PRECISION < math.abs(newZ - spec.lastPositionInfoSent[2]) then
				spec.lastPositionInfoSent[1] = newX
				spec.lastPositionInfoSent[2] = newZ

				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		else
			local loadSize = 0.1

			if volume.maxPhysicalSurfaceAngle == 0 or volume.maxSurfaceAngle == 0 then
				loadSize = 10
			end

			local x, y, z = localToWorld(volume.volume, -loadSize * 0.5, 0, -loadSize * 0.5)
			local d1x, d1y, d1z = localDirectionToWorld(volume.volume, loadSize, 0, 0)
			local d2x, d2y, d2z = localDirectionToWorld(volume.volume, 0, 0, loadSize)

			if not self.isServer and spec.lastPositionInfo[1] ~= 0 and spec.lastPositionInfo[2] ~= 0 then
				x, y, z = localToWorld(volume.volume, spec.lastPositionInfo[1], 0, spec.lastPositionInfo[2])
			end

			local steps = MathUtil.clamp(math.floor(appliedDelta / 400), 1, 25)

			for _ = 1, steps do
				fillPlaneAdd(volume.volume, appliedDelta / steps, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
			end
		end

		local heightNodes = spec.fillVolumeIndexToHeightNode[volume.index]

		if heightNodes ~= nil then
			for _, heightNode in ipairs(heightNodes) do
				heightNode.isDirty = true
			end
		end

		for _, deformer in pairs(volume.deformers) do
			deformer.isDirty = true
		end

		volume.lastFillType = fillType
	end
end
