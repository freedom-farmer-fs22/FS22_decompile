TreePlantManager = {
	MAX_NUM_OF_SPLITSHAPES = 7840,
	DECAY_INTERVAL = 60000,
	DECAY_DURATION = 7200000
}
TreePlantManager.DECAY_DURATION_INV = 1 / TreePlantManager.DECAY_DURATION
local TreePlantManager_mt = Class(TreePlantManager, AbstractManager)

function TreePlantManager.new(customMt)
	local self = AbstractManager.new(customMt or TreePlantManager_mt)

	return self
end

function TreePlantManager:initDataStructures()
	self.treeTypes = {}
	self.indexToTreeType = {}
	self.nameToTreeType = {}
	self.treeFileCache = {}
	self.numTreesWithoutSplits = 0
	self.activeDecayingSplitShapes = {}
	self.updateDecayDtGame = 0
end

function TreePlantManager:initialize()
	local rootNode = createTransformGroup("trees")

	link(getRootNode(), rootNode)

	self.treesData = {
		rootNode = rootNode,
		growingTrees = {},
		splitTrees = {},
		clientTrees = {},
		updateDtGame = 0,
		treeCutJoints = {},
		numTreesWithoutSplits = 0
	}
end

function TreePlantManager:deleteTreesData()
	if self.treesData ~= nil then
		delete(self.treesData.rootNode)

		self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - self.treesData.numTreesWithoutSplits, 0)

		self:initDataStructures()
	end
end

function TreePlantManager:loadDefaultTypes(missionInfo, baseDirectory)
	local xmlFile = loadXMLFile("treeTypes", "data/maps/maps_treeTypes.xml")

	self:loadTreeTypes(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end

function TreePlantManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	TreePlantManager:superClass().loadMapData(self)
	self:loadDefaultTypes(missionInfo, baseDirectory)

	return XMLUtil.loadDataFromMapXML(xmlFile, "treeTypes", baseDirectory, self, self.loadTreeTypes, missionInfo, baseDirectory)
end

function TreePlantManager:unloadMapData()
	for i3dFilename, requestId in pairs(self.treeFileCache) do
		g_i3DManager:releaseSharedI3DFile(requestId)

		self.treeFileCache[i3dFilename] = true
	end

	self:deleteTreesData()
	TreePlantManager:superClass().unloadMapData(self)
end

function TreePlantManager:loadTreeTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.treeTypes.treeType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local nameI18N = getXMLString(xmlFile, key .. "#nameI18N")
		local growthTimeHours = getXMLFloat(xmlFile, key .. "#growthTimeHours")

		if name == nil or nameI18N == nil or growthTimeHours == nil then
			print("Warning: A treetype needs valid values for 'name', 'nameI18N', 'growthTimeHours'. Problem found at '" .. tostring(key) .. "'")
		end

		local filenames = {}
		local j = 0

		while true do
			local stageKey = string.format("%s.stage(%d)", key, j)

			if not hasXMLProperty(xmlFile, stageKey) then
				break
			end

			local filename = getXMLString(xmlFile, stageKey .. "#filename")

			if filename ~= nil then
				local path = Utils.getFilename(filename, baseDirectory)

				table.insert(filenames, path)
			end

			j = j + 1
		end

		if #filenames == 0 then
			print("Warning: A treetype needs valid 'stage#filename' entries. '" .. tostring(key) .. "'")
		end

		self:registerTreeType(name, nameI18N, filenames, growthTimeHours, isBaseType)

		i = i + 1
	end

	return true
end

function TreePlantManager:registerTreeType(name, nameI18N, treeFilenames, growthTimeHours, isBaseType)
	local name = string.upper(name)

	if isBaseType and self.nameToTreeType[name] ~= nil then
		print("Warning: TreeType '" .. tostring(name) .. "' already exists. Ignoring treeType!")

		return nil
	end

	local treeType = self.nameToTreeType[name]

	if treeType == nil then
		treeType = {
			name = name,
			nameI18N = nameI18N,
			index = #self.treeTypes + 1
		}

		table.insert(self.treeTypes, treeType)

		self.indexToTreeType[treeType.index] = treeType
		self.nameToTreeType[name] = treeType
	end

	treeType.treeFilenames = treeFilenames
	treeType.growthTimeHours = growthTimeHours

	return treeType
end

function TreePlantManager:getTreeTypeFilename(treeTypeDesc, growthState)
	if treeTypeDesc == nil then
		return nil
	end

	return treeTypeDesc.treeFilenames[math.min(growthState, #treeTypeDesc.treeFilenames)]
end

function TreePlantManager:canPlantTree()
	local totalNumSplit, numSplit = getNumOfSplitShapes()
	local numUnsplit = totalNumSplit - numSplit

	return numUnsplit + self.numTreesWithoutSplits < TreePlantManager.MAX_NUM_OF_SPLITSHAPES
end

function TreePlantManager:plantTree(treeType, x, y, z, rx, ry, rz, growthState, growthStateI, isGrowing, splitShapeFileId)
	local treesData = self.treesData
	local treeTypeDesc = self.indexToTreeType[treeType]

	if treeTypeDesc ~= nil then
		growthState = MathUtil.clamp(growthState, 0, 1)

		if growthStateI == nil then
			growthStateI = math.floor(growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1
		end

		local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, splitShapeFileId)
		local tree = {
			node = treeId
		}
		isGrowing = Utils.getNoNil(isGrowing, true)

		if table.getn(treeTypeDesc.treeFilenames) <= 1 then
			tree.growthState = 1
			isGrowing = false
		else
			tree.growthState = growthState
		end

		tree.z = z
		tree.y = y
		tree.x = x
		tree.rz = rz
		tree.ry = ry
		tree.rx = rx
		tree.treeType = treeType
		tree.splitShapeFileId = splitShapeFileId
		tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)

		if isGrowing then
			tree.origSplitShape = getChildAt(treeId, 0)

			table.insert(treesData.growingTrees, tree)
		else
			table.insert(treesData.splitTrees, tree)
		end

		if not tree.hasSplitShapes then
			self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
			treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
		end

		g_server:broadcastEvent(TreePlantEvent.new(treeType, x, y, z, rx, ry, rz, growthState, splitShapeFileId, isGrowing))

		return treeId
	end
end

function TreePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, splitShapeLoadingFileId)
	local treesData = self.treesData
	growthStateI = math.min(growthStateI, table.getn(treeTypeDesc.treeFilenames))
	local i3dFilename = treeTypeDesc.treeFilenames[growthStateI]

	if self.treeFileCache[i3dFilename] == nil then
		setSplitShapesLoadingFileId(-1)
		setSplitShapesNextFileId(true)

		local node, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)

		if node ~= 0 then
			delete(node)

			self.treeFileCache[i3dFilename] = requestId
		end
	end

	setSplitShapesLoadingFileId(Utils.getNoNil(splitShapeLoadingFileId, -1))

	local splitShapeFileId = setSplitShapesNextFileId()
	local treeId, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)

	g_i3DManager:releaseSharedI3DFile(requestId)

	if treeId ~= 0 then
		link(treesData.rootNode, treeId)
		setTranslation(treeId, x, y, z)
		setRotation(treeId, rx, ry, rz)

		local numChildren = getNumOfChildren(treeId)

		for i = 0, numChildren - 1 do
			local child = getChildAt(treeId, i)

			if getIsSplitShapeSplit(child) then
				setWorldRotation(child, getRotation(child))
				setWorldTranslation(child, getTranslation(child))
			end
		end

		addToPhysics(treeId)
	end

	return treeId, splitShapeFileId
end

function TreePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthState)
	local treeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, 0, 0, 0, growthState)

	if treeId ~= 0 then
		if getFileIdHasSplitShapes(splitShapeFileId) then
			self.loadTreeTrunkData = {
				offset = 0.5,
				framesLeft = 2,
				shape = treeId + 2,
				x = x,
				y = y,
				z = z,
				length = length,
				dirX = dirX,
				dirY = dirY,
				dirZ = dirZ
			}
		else
			delete(treeId)
		end
	end
end

function TreePlantManager:cutTreeTrunkCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	self:addingSplitShape(shape, self.shapeBeingCut)
	table.insert(self.loadTreeTrunkData.parts, {
		shape = shape,
		isBelow = isBelow,
		isAbove = isAbove,
		minY = minY,
		maxY = maxY,
		minZ = minZ,
		maxZ = maxZ
	})
end

function TreePlantManager:updateTrees(dt, dtGame)
	local treesData = self.treesData
	treesData.updateDtGame = treesData.updateDtGame + dtGame

	if treesData.updateDtGame > 3600000 then
		self:cleanupDeletedTrees()

		local time = treesData.updateDtGame
		local dtHours = time / 3600000
		treesData.updateDtGame = 0
		local numGrowingTrees = #treesData.growingTrees
		local i = 1

		while numGrowingTrees >= i do
			local tree = treesData.growingTrees[i]

			if getChildAt(tree.node, 0) ~= tree.origSplitShape then
				table.remove(treesData.growingTrees, i)

				numGrowingTrees = numGrowingTrees - 1
				tree.origSplitShape = nil

				table.insert(treesData.splitTrees, tree)
			else
				local treeTypeDesc = self.indexToTreeType[tree.treeType]
				local numTreeFiles = table.getn(treeTypeDesc.treeFilenames)
				local growthState = tree.growthState
				local oldGrowthStateI = math.floor(growthState * (numTreeFiles - 1)) + 1
				growthState = math.min(growthState + dtHours / treeTypeDesc.growthTimeHours, 1)
				local growthStateI = math.floor(growthState * (numTreeFiles - 1)) + 1
				tree.growthState = growthState

				if oldGrowthStateI ~= growthStateI and treeTypeDesc.treeFilenames[oldGrowthStateI] ~= treeTypeDesc.treeFilenames[growthStateI] then
					delete(tree.node)

					if not tree.hasSplitShapes then
						self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
						treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
					end

					local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, growthStateI, -1)

					g_server:broadcastEvent(TreeGrowEvent.new(tree.treeType, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthState, splitShapeFileId, tree.splitShapeFileId))

					tree.origSplitShape = getChildAt(treeId, 0)
					tree.splitShapeFileId = splitShapeFileId
					tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
					tree.node = treeId
					local range = 2.5
					local x, _, z = getWorldTranslation(treeId)

					g_densityMapHeightManager:setCollisionMapAreaDirty(x - range, z - range, x + range, z + range)

					if not tree.hasSplitShapes then
						self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
						treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
					end
				end

				if numTreeFiles <= growthStateI then
					table.remove(treesData.growingTrees, i)

					numGrowingTrees = numGrowingTrees - 1
					tree.origSplitShape = nil

					table.insert(treesData.splitTrees, tree)
				else
					i = i + 1
				end
			end
		end
	end

	local curTime = g_currentMission.time

	for joint in pairs(treesData.treeCutJoints) do
		if joint.destroyTime <= curTime or not entityExists(joint.shape) then
			removeJoint(joint.jointIndex)

			treesData.treeCutJoints[joint] = nil
		else
			local x1, y1, z1 = localDirectionToWorld(joint.shape, joint.lnx, joint.lny, joint.lnz)

			if x1 * joint.nx + y1 * joint.ny + z1 * joint.nz < joint.maxCosAngle then
				removeJoint(joint.jointIndex)

				treesData.treeCutJoints[joint] = nil
			end
		end
	end

	if self.loadTreeTrunkData ~= nil then
		self.loadTreeTrunkData.framesLeft = self.loadTreeTrunkData.framesLeft - 1

		if self.loadTreeTrunkData.framesLeft == 1 then
			local nx = 0
			local ny = 1
			local nz = 0
			local yx = -1
			local yy = 0
			local yz = 0
			local x = self.loadTreeTrunkData.x + 1
			local y = self.loadTreeTrunkData.y
			local z = self.loadTreeTrunkData.z - 1
			self.loadTreeTrunkData.parts = {}
			local shape = self.loadTreeTrunkData.shape

			if shape ~= nil and shape ~= 0 then
				self.shapeBeingCut = shape

				splitShape(shape, x, y + self.loadTreeTrunkData.length + self.loadTreeTrunkData.offset, z, nx, ny, nz, yx, yy, yz, 4, 4, "cutTreeTrunkCallback", self)
				self:removingSplitShape(shape)

				for _, p in pairs(self.loadTreeTrunkData.parts) do
					if p.isAbove then
						delete(p.shape)
					else
						self.loadTreeTrunkData.shape = p.shape
					end
				end
			end
		elseif self.loadTreeTrunkData.framesLeft == 0 then
			local nx = 0
			local ny = 1
			local nz = 0
			local yx = -1
			local yy = 0
			local yz = 0
			local x = self.loadTreeTrunkData.x + 1
			local y = self.loadTreeTrunkData.y
			local z = self.loadTreeTrunkData.z - 1
			self.loadTreeTrunkData.parts = {}
			local shape = self.loadTreeTrunkData.shape

			if shape ~= nil and shape ~= 0 then
				splitShape(shape, x, y + self.loadTreeTrunkData.offset, z, nx, ny, nz, yx, yy, yz, 4, 4, "cutTreeTrunkCallback", self)

				local finalShape = nil

				for _, p in pairs(self.loadTreeTrunkData.parts) do
					if p.isBelow then
						delete(p.shape)
					else
						finalShape = p.shape
					end
				end

				if finalShape ~= nil then
					removeFromPhysics(finalShape)
					setDirection(finalShape, 0, -1, 0, self.loadTreeTrunkData.dirX, self.loadTreeTrunkData.dirY, self.loadTreeTrunkData.dirZ)
					addToPhysics(finalShape)
				else
					Logging.error("Unable to cut tree trunk with length '%s'. Try using a different value", self.loadTreeTrunkData.length)
				end
			end

			self.loadTreeTrunkData = nil
		end
	end

	self.updateDecayDtGame = self.updateDecayDtGame + dtGame

	if TreePlantManager.DECAY_INTERVAL < self.updateDecayDtGame then
		for shape, data in pairs(self.activeDecayingSplitShapes) do
			if not entityExists(shape) then
				self.activeDecayingSplitShapes[shape] = nil
			elseif data.state > 0 then
				local newState = math.max(data.state - TreePlantManager.DECAY_DURATION_INV * self.updateDecayDtGame, 0)

				self:setSplitShapeLeafScaleAndVariation(shape, newState, data.variation)

				self.activeDecayingSplitShapes[shape].state = newState
			end
		end

		self.updateDecayDtGame = 0
	end
end

function TreePlantManager:addTreeCutJoint(jointIndex, shape, nx, ny, nz, maxAngle, maxLifetime)
	local treesData = self.treesData
	local lnx, lny, lnz = worldDirectionToLocal(shape, nx, ny, nz)
	local joint = {
		jointIndex = jointIndex,
		shape = shape,
		nx = nx,
		ny = ny,
		nz = nz,
		lnx = lnx,
		lny = lny,
		lnz = lnz,
		maxCosAngle = math.cos(maxAngle),
		destroyTime = g_currentMission.time + maxLifetime
	}
	treesData.treeCutJoints[joint] = joint
end

function TreePlantManager:cleanupDeletedTrees()
	local treesData = self.treesData
	local numGrowingTrees = #treesData.growingTrees
	local i = 1

	while numGrowingTrees >= i do
		local tree = treesData.growingTrees[i]

		if getNumOfChildren(tree.node) == 0 then
			table.remove(treesData.growingTrees, i)

			numGrowingTrees = numGrowingTrees - 1

			delete(tree.node)

			if not tree.hasSplitShapes then
				self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
				treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
			end
		else
			i = i + 1
		end
	end

	local numSplitTrees = #treesData.splitTrees
	local i = 1

	while numSplitTrees >= i do
		local tree = treesData.splitTrees[i]

		if getNumOfChildren(tree.node) == 0 then
			table.remove(treesData.splitTrees, i)

			numSplitTrees = numSplitTrees - 1

			delete(tree.node)

			if not tree.hasSplitShapes then
				self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
				treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
			end
		else
			i = i + 1
		end
	end
end

function TreePlantManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end

	local xmlFile = loadXMLFile("treePlantXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local i = 0

	while true do
		local key = string.format("treePlant.tree(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local x, y, z = string.getVector(getXMLString(xmlFile, key .. "#position"))
		local rx, ry, rz = string.getVector(getXMLString(xmlFile, key .. "#rotation"))
		rx = math.rad(rx)
		ry = math.rad(ry)
		rz = math.rad(rz)
		local treeTypeName = getXMLString(xmlFile, key .. "#treeType")
		local treeType = self.nameToTreeType[treeTypeName]

		if x ~= nil and y ~= nil and z ~= nil and rx ~= nil and ry ~= nil and rz ~= nil and treeType ~= nil then
			local growthState = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#growthState"), 0)
			local isGrowing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isGrowing"), true)
			local growthStateI = getXMLInt(xmlFile, key .. "#growthStateI")
			local splitShapeFileId = getXMLInt(xmlFile, key .. "#splitShapeFileId")

			self:plantTree(treeType.index, x, y, z, rx, ry, rz, growthState, growthStateI, isGrowing, splitShapeFileId)
		end

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function TreePlantManager:saveToXMLFile(xmlFilename)
	local xmlFile = createXMLFile("treePlantXML", xmlFilename, "treePlant")

	if xmlFile ~= nil then
		self:cleanupDeletedTrees()

		local index = 0

		for _, tree in pairs(self.treesData.growingTrees) do
			local treeTypeDesc = self:getTreeTypeDescFromIndex(tree.treeType)
			local treeTypeName = treeTypeDesc.name
			local isGrowing = getChildAt(tree.node, 0) == tree.origSplitShape
			local growthStateI = math.floor(tree.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1
			local splitShapeFileId = Utils.getNoNil(tree.splitShapeFileId, -1)
			local treeKey = string.format("treePlant.tree(%d)", index)

			setXMLString(xmlFile, treeKey .. "#treeType", treeTypeName)
			setXMLString(xmlFile, treeKey .. "#position", string.format("%.4f %.4f %.4f", tree.x, tree.y, tree.z))
			setXMLString(xmlFile, treeKey .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(tree.rx), math.deg(tree.ry), math.deg(tree.rz)))
			setXMLFloat(xmlFile, treeKey .. "#growthState", tree.growthState)
			setXMLInt(xmlFile, treeKey .. "#growthStateI", growthStateI)
			setXMLBool(xmlFile, treeKey .. "#isGrowing", isGrowing)
			setXMLInt(xmlFile, treeKey .. "#splitShapeFileId", splitShapeFileId)

			index = index + 1
		end

		for _, tree in pairs(self.treesData.splitTrees) do
			local treeTypeDesc = self:getTreeTypeDescFromIndex(tree.treeType)
			local treeTypeName = treeTypeDesc.name
			local isGrowing = false
			local growthStateI = math.floor(tree.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1
			local splitShapeFileId = Utils.getNoNil(tree.splitShapeFileId, -1)
			local treeKey = string.format("treePlant.tree(%d)", index)

			setXMLString(xmlFile, treeKey .. "#treeType", treeTypeName)
			setXMLString(xmlFile, treeKey .. "#position", string.format("%.4f %.4f %.4f", tree.x, tree.y, tree.z))
			setXMLString(xmlFile, treeKey .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(tree.rx), math.deg(tree.ry), math.deg(tree.rz)))
			setXMLFloat(xmlFile, treeKey .. "#growthState", tree.growthState)
			setXMLInt(xmlFile, treeKey .. "#growthStateI", growthStateI)
			setXMLBool(xmlFile, treeKey .. "#isGrowing", isGrowing)
			setXMLInt(xmlFile, treeKey .. "#splitShapeFileId", splitShapeFileId)

			index = index + 1
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)

		return true
	end

	return false
end

function TreePlantManager:readFromServerStream(streamId)
	local treesData = self.treesData
	local numTrees = streamReadInt32(streamId)

	for i = 1, numTrees do
		local treeType = streamReadInt32(streamId)
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local rx = streamReadFloat32(streamId)
		local ry = streamReadFloat32(streamId)
		local rz = streamReadFloat32(streamId)
		local growthStateI = streamReadInt8(streamId)
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local treeTypeDesc = self.indexToTreeType[treeType]

		if treeTypeDesc ~= nil then
			local nodeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, -1)

			setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)

			treesData.clientTrees[serverSplitShapeFileId] = nodeId
		end
	end
end

function TreePlantManager:writeToClientStream(streamId)
	local treesData = self.treesData

	self:cleanupDeletedTrees()

	local numTrees = #treesData.growingTrees + #treesData.splitTrees

	streamWriteInt32(streamId, numTrees)

	for _, tree in pairs(treesData.growingTrees) do
		streamWriteInt32(streamId, tree.treeType)
		streamWriteFloat32(streamId, tree.x)
		streamWriteFloat32(streamId, tree.y)
		streamWriteFloat32(streamId, tree.z)
		streamWriteFloat32(streamId, tree.rx)
		streamWriteFloat32(streamId, tree.ry)
		streamWriteFloat32(streamId, tree.rz)

		local treeTypeDesc = self.indexToTreeType[tree.treeType]
		local growthStateI = math.floor(tree.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1

		streamWriteInt8(streamId, growthStateI)
		streamWriteInt32(streamId, tree.splitShapeFileId)
	end

	for _, tree in pairs(treesData.splitTrees) do
		streamWriteInt32(streamId, tree.treeType)
		streamWriteFloat32(streamId, tree.x)
		streamWriteFloat32(streamId, tree.y)
		streamWriteFloat32(streamId, tree.z)
		streamWriteFloat32(streamId, tree.rx)
		streamWriteFloat32(streamId, tree.ry)
		streamWriteFloat32(streamId, tree.rz)

		local treeTypeDesc = self.indexToTreeType[tree.treeType]
		local growthStateI = math.floor(tree.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1

		streamWriteInt8(streamId, growthStateI)
		streamWriteInt32(streamId, tree.splitShapeFileId)
	end
end

function TreePlantManager:getTreeTypeDescFromIndex(index)
	if self.treeTypes ~= nil then
		return self.treeTypes[index]
	end

	return nil
end

function TreePlantManager:getTreeTypeDescFromName(name)
	if self.nameToTreeType ~= nil and name ~= nil then
		name = name:upper()

		return self.nameToTreeType[name]
	end

	return nil
end

function TreePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
	if self.treesData ~= nil then
		self.treesData.clientTrees[serverSplitShapeFileId] = nodeId
	end
end

function TreePlantManager:removeClientTree(serverSplitShapeFileId)
	if self.treesData ~= nil then
		self.treesData.clientTrees[serverSplitShapeFileId] = nil
	end
end

function TreePlantManager:getClientTree(serverSplitShapeFileId)
	if self.treesData ~= nil then
		return self.treesData.clientTrees[serverSplitShapeFileId]
	end
end

function TreePlantManager:addingSplitShape(shape, oldShape, fromTree)
	local state, variation = nil

	if oldShape ~= nil and self.activeDecayingSplitShapes[oldShape] ~= nil then
		state = self.activeDecayingSplitShapes[oldShape].state
		variation = self.activeDecayingSplitShapes[oldShape].variation
	elseif fromTree then
		state = 1
		local x, y, z = getWorldTranslation(shape)
		variation = x + y + z
	else
		state = 0
		variation = 80
	end

	if state ~= nil and getNumOfChildren(shape) > 0 then
		self.activeDecayingSplitShapes[shape] = {
			state = state,
			variation = variation
		}

		self:setSplitShapeLeafScaleAndVariation(shape, state, variation)
	end

	g_messageCenter:publish(MessageType.TREE_SHAPE_CUT, oldShape, shape)
end

function TreePlantManager:removingSplitShape(shape)
	self.activeDecayingSplitShapes[shape] = nil
end

function TreePlantManager:setSplitShapeLeafScaleAndVariation(shape, scale, variation)
	I3DUtil.setShaderParameterRec(shape, "windSnowLeafScale", 0, 0, scale, variation)
end

g_treePlantManager = TreePlantManager.new()
