Basketball = {}
local Basketball_mt = Class(Basketball, PhysicsObject)

InitStaticObjectClass(Basketball, "Basketball", ObjectIds.OBJECT_BASKETBALL)

function Basketball:onCreate(id)
	local basketball = Basketball.new(g_server ~= nil, g_client ~= nil)
	local x, y, z = getWorldTranslation(id)
	local rx, ry, rz = getWorldRotation(id)
	local filename = Utils.getNoNil(getUserAttribute(id, "filename"), "$data/objects/basketball/basketball.i3d")
	filename = Utils.getFilename(filename, g_currentMission.loadingMapBaseDirectory)

	if basketball:load(filename, x, y, z, rx, ry, rz) then
		g_currentMission:addOnCreateLoadedObject(basketball)
		basketball:register(true)
	else
		basketball:delete()
	end
end

function Basketball.new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = Basketball_mt
	end

	local self = PhysicsObject.new(isServer, isClient, mt)
	self.forcedClipDistance = 150
	self.sharedLoadRequestId = nil

	registerObjectClassName(self, "Basketball")

	return self
end

function Basketball:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	unregisterObjectClassName(self)
	Basketball:superClass().delete(self)
end

function Basketball:readStream(streamId, connection)
	if connection:getIsServer() then
		local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		if self.nodeId == 0 then
			self:createNode(i3dFilename)
		end

		Basketball:superClass().readStream(self, streamId, connection)
	end
end

function Basketball:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
		Basketball:superClass().writeStream(self, streamId, connection)
	end
end

function Basketball:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)
	local basketballRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local basketballId = getChildAt(basketballRoot, 0)

	link(getRootNode(), basketballId)
	delete(basketballRoot)
	self:setNodeId(basketballId)
end

function Basketball:load(i3dFilename, x, y, z, rx, ry, rz)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)

	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)

	return true
end
