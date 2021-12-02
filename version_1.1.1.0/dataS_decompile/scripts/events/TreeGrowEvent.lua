TreeGrowEvent = {}
local TreeGrowEvent_mt = Class(TreeGrowEvent, Event)

InitStaticEventClass(TreeGrowEvent, "TreeGrowEvent", EventIds.EVENT_TREE_GROW)

function TreeGrowEvent.emptyNew()
	local self = Event.new(TreeGrowEvent_mt)

	return self
end

function TreeGrowEvent.new(treeType, x, y, z, rx, ry, rz, growthState, splitShapeFileId, oldSplitShapeFileId)
	local self = TreeGrowEvent.emptyNew()
	self.treeType = treeType
	self.z = z
	self.y = y
	self.x = x
	self.rz = rz
	self.ry = ry
	self.rx = rx
	self.growthState = growthState
	self.splitShapeFileId = splitShapeFileId
	self.oldSplitShapeFileId = oldSplitShapeFileId

	return self
end

function TreeGrowEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local treeType = streamReadInt32(streamId)
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local rx = streamReadFloat32(streamId)
		local ry = streamReadFloat32(streamId)
		local rz = streamReadFloat32(streamId)
		local growthStateI = streamReadInt8(streamId)
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local oldServerSplitShapeFileId = streamReadInt32(streamId)
		local oldNodeId = g_treePlantManager:getClientTree(oldServerSplitShapeFileId)

		if oldNodeId ~= nil then
			delete(oldNodeId)
			g_treePlantManager:removeClientTree(serverSplitShapeFileId)
		end

		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(treeType)

		if treeTypeDesc ~= nil then
			local nodeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, -1)

			setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
			g_treePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
		end
	end
end

function TreeGrowEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteInt32(streamId, self.treeType)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rx)
		streamWriteFloat32(streamId, self.ry)
		streamWriteFloat32(streamId, self.rz)

		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(self.treeType)
		local growthStateI = math.floor(self.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1

		streamWriteInt8(streamId, growthStateI)
		streamWriteInt32(streamId, self.splitShapeFileId)
		streamWriteInt32(streamId, self.oldSplitShapeFileId)
	end
end

function TreeGrowEvent:run(connection)
	print("Error: TreeGrowEvent is not allowed to be executed on a local client")
end
