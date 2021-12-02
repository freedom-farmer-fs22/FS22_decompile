MissionPhysicsObject = {}
local MissionPhysicsObject_mt = Class(MissionPhysicsObject, MountableObject)

InitStaticObjectClass(MissionPhysicsObject, "MissionPhysicsObject", ObjectIds.OBJECT_MISSION_PHYSICS_OBJECT)

function MissionPhysicsObject.new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = MissionPhysicsObject_mt
	end

	local self = MountableObject.new(isServer, isClient, mt)
	self.forcedClipDistance = 80
	self.meshNodes = {}
	self.sharedLoadRequestId = nil

	return self
end

function MissionPhysicsObject:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	MissionPhysicsObject:superClass().delete(self)
end

function MissionPhysicsObject:readStream(streamId, connection)
	local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	if self.nodeId == 0 then
		self:createNode(i3dFilename)
	end

	MissionPhysicsObject:superClass().readStream(self, streamId, connection)
end

function MissionPhysicsObject:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	MissionPhysicsObject:superClass().writeStream(self, streamId, connection)
end

function MissionPhysicsObject:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local rootNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local nodeId = getChildAt(rootNode, 0)

	link(getRootNode(), nodeId)
	delete(rootNode)
	self:setNodeId(nodeId)
end

function MissionPhysicsObject:setNodeId(nodeId)
	MissionPhysicsObject:superClass().setNodeId(self, nodeId)

	local meshNode = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "meshNode"))

	if meshNode ~= nil then
		self.meshNodes = {
			meshNode
		}
	end
end

function MissionPhysicsObject:load(i3dFilename, x, y, z, rx, ry, rz)
	self.i3dFilename = i3dFilename

	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)

	return true
end

function MissionPhysicsObject:loadFromMemory(nodeId, i3dFilename)
	self.i3dFilename = i3dFilename

	self:setNodeId(nodeId)
end

function MissionPhysicsObject:getSupportsTensionBelts()
	return true
end

function MissionPhysicsObject:getTensionBeltNodeId()
	return self.nodeId
end

function MissionPhysicsObject:getMeshNodes()
	return self.meshNodes
end
