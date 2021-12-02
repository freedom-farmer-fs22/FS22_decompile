ChainsawCutEvent = {}
local ChainsawCutEvent_mt = Class(ChainsawCutEvent, Event)

InitStaticEventClass(ChainsawCutEvent, "ChainsawCutEvent", EventIds.EVENT_CHAINSAW_CUT)

function ChainsawCutEvent.emptyNew()
	local self = Event.new(ChainsawCutEvent_mt)

	return self
end

function ChainsawCutEvent.new(splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
	local self = ChainsawCutEvent.emptyNew()
	self.splitShapeId = splitShapeId
	self.z = z
	self.y = y
	self.x = x
	self.nz = nz
	self.ny = ny
	self.nx = nx
	self.yz = yz
	self.yy = yy
	self.yx = yx
	self.cutSizeZ = cutSizeZ
	self.cutSizeY = cutSizeY
	self.farmId = farmId

	return self
end

function ChainsawCutEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		local splitShapeId = readSplitShapeIdFromStream(streamId)
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local nx = streamReadFloat32(streamId)
		local ny = streamReadFloat32(streamId)
		local nz = streamReadFloat32(streamId)
		local yx = streamReadFloat32(streamId)
		local yy = streamReadFloat32(streamId)
		local yz = streamReadFloat32(streamId)
		local cutSizeY = streamReadFloat32(streamId)
		local cutSizeZ = streamReadFloat32(streamId)
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

		if splitShapeId ~= 0 then
			ChainsawUtil.cutSplitShape(splitShapeId, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
		end
	end
end

function ChainsawCutEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		writeSplitShapeIdToStream(streamId, self.splitShapeId)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.nx)
		streamWriteFloat32(streamId, self.ny)
		streamWriteFloat32(streamId, self.nz)
		streamWriteFloat32(streamId, self.yx)
		streamWriteFloat32(streamId, self.yy)
		streamWriteFloat32(streamId, self.yz)
		streamWriteFloat32(streamId, self.cutSizeY)
		streamWriteFloat32(streamId, self.cutSizeZ)
		streamWriteFloat32(streamId, self.farmId)
	end
end

function ChainsawCutEvent:run(connection)
	print("Error: ChainsawCutEvent is not allowed to be executed on a local client")
end
