TreePlantEvent = {}
local TreePlantEvent_mt = Class(TreePlantEvent, Event)

InitStaticEventClass(TreePlantEvent, "TreePlantEvent", EventIds.EVENT_TREE_PLANT)

function TreePlantEvent.emptyNew()
	local self = Event.new(TreePlantEvent_mt)

	return self
end

function TreePlantEvent.new(treeType, x, y, z, rx, ry, rz, growthState, splitShapeFileId, isGrowing, price, farmId)
	local self = TreePlantEvent.emptyNew()
	self.treeType = treeType
	self.z = z
	self.y = y
	self.x = x
	self.rz = rz
	self.ry = ry
	self.rx = rx
	self.growthState = growthState
	self.splitShapeFileId = splitShapeFileId
	self.isGrowing = isGrowing
	self.price = price or 0
	self.farmId = farmId or 0

	return self
end

function TreePlantEvent:readStream(streamId, connection)
	local treeType = streamReadInt32(streamId)
	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)
	local rx = streamReadFloat32(streamId)
	local ry = streamReadFloat32(streamId)
	local rz = streamReadFloat32(streamId)

	if not connection:getIsServer() then
		local growthState = streamReadFloat32(streamId)
		local isGrowing = streamReadBool(streamId)
		local price = streamReadInt32(streamId)
		local farmId = streamReadUInt8(streamId)

		g_treePlantManager:plantTree(treeType, x, y, z, rx, ry, rz, growthState, nil, isGrowing)

		if price > 0 then
			g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_PROPERTY_BUY, true)
		end
	else
		local growthStateI = streamReadInt8(streamId)
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(treeType)

		if treeTypeDesc ~= nil then
			local nodeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, -1)

			setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
			g_treePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
		end
	end
end

function TreePlantEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.treeType)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rx)
	streamWriteFloat32(streamId, self.ry)
	streamWriteFloat32(streamId, self.rz)

	if connection:getIsServer() then
		streamWriteFloat32(streamId, self.growthState)
		streamWriteBool(streamId, self.isGrowing)
		streamWriteInt32(streamId, self.price)
		streamWriteUInt8(streamId, self.farmId)
	else
		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(self.treeType)
		local growthStateI = math.floor(self.growthState * (table.getn(treeTypeDesc.treeFilenames) - 1)) + 1

		streamWriteInt8(streamId, growthStateI)
		streamWriteInt32(streamId, self.splitShapeFileId)
	end
end

function TreePlantEvent:run(connection)
	print("Error: TreePlantEvent is not allowed to be executed on a local client")
end
