ChainsawDelimbEvent = {}
local ChainsawDelimbEvent_mt = Class(ChainsawDelimbEvent, Event)

InitStaticEventClass(ChainsawDelimbEvent, "ChainsawDelimbEvent", EventIds.EVENT_CHAINSAW_DELIMB)

function ChainsawDelimbEvent.emptyNew()
	local self = Event.new(ChainsawDelimbEvent_mt)

	return self
end

function ChainsawDelimbEvent.new(player, x, y, z, nx, ny, nz, yx, yy, yz, onDelimb)
	local self = ChainsawDelimbEvent.emptyNew()
	self.player = player
	self.z = z
	self.y = y
	self.x = x
	self.nz = nz
	self.ny = ny
	self.nx = nx
	self.yz = yz
	self.yy = yy
	self.yx = yx
	self.onDelimb = onDelimb

	return self
end

function ChainsawDelimbEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.player = NetworkUtil.readNodeObject(streamId)
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.nx = streamReadFloat32(streamId)
		self.ny = streamReadFloat32(streamId)
		self.nz = streamReadFloat32(streamId)
		self.yx = streamReadFloat32(streamId)
		self.yy = streamReadFloat32(streamId)
		self.yz = streamReadFloat32(streamId)
		self.onDelimb = false

		if self.player ~= nil then
			local chainsaw = self.player.baseInformation.currentHandtool

			if chainsaw ~= nil then
				local ret = findAndRemoveSplitShapeAttachments(self.x, self.y, self.z, self.nx, self.ny, self.nz, self.yx, self.yy, self.yz, 0.7, chainsaw.cutSizeY, chainsaw.cutSizeZ)

				if ret then
					self.onDelimb = true

					connection:sendEvent(self)
				end
			end
		end
	end
end

function ChainsawDelimbEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.player)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.nx)
		streamWriteFloat32(streamId, self.ny)
		streamWriteFloat32(streamId, self.nz)
		streamWriteFloat32(streamId, self.yx)
		streamWriteFloat32(streamId, self.yy)
		streamWriteFloat32(streamId, self.yz)
	else
		NetworkUtil.writeNodeObject(streamId, self.player)
		streamWriteBool(streamId, self.onDelimb)
	end
end

function ChainsawDelimbEvent:run(connection)
	print("Error: ChainsawDelimbEvent is not allowed to be executed on a local client")
end
