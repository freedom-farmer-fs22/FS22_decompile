DogBall = {
	RESET_DISTANCE = 100
}
local DogBall_mt = Class(DogBall, PhysicsObject)

InitStaticObjectClass(DogBall, "DogBall", ObjectIds.OBJECT_DOGBALL)

function DogBall.new(isServer, isClient, customMt)
	local self = PhysicsObject.new(isServer, isClient, customMt or DogBall_mt)
	self.forcedClipDistance = 150

	registerObjectClassName(self, "DogBall")

	self.sharedLoadRequestId = nil

	return self
end

function DogBall:delete()
	self.isDeleted = true

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end

	unregisterObjectClassName(self)
	DogBall:superClass().delete(self)
end

function DogBall:readStream(streamId, connection)
	if connection:getIsServer() then
		local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local isNew = self.i3dFilename == nil

		if isNew then
			self:load(i3dFilename, 0, 0, 0, 0, 0, 0)
		end
	end

	DogBall:superClass().readStream(self, streamId, connection)
end

function DogBall:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	end

	DogBall:superClass().writeStream(self, streamId, connection)
end

function DogBall:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)
	local dogBallRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local dogBallId = getChildAt(dogBallRoot, 0)

	link(getRootNode(), dogBallId)
	delete(dogBallRoot)
	self:setNodeId(dogBallId)
end

function DogBall:getTerrainHeightWithProps(x, z)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	local offset = 1
	local distance = 20
	local collisionMask = 63
	self.groundY = -1

	raycastClosest(x, terrainY + offset, z, 0, -1, 0, "groundRaycastCallback", 5, self, collisionMask)

	return math.max(terrainY, self.groundY)
end

function DogBall:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= nil then
		local objectType = getRigidBodyType(hitObjectId)

		if objectType ~= RigidBodyType.DYNAMIC and objectType ~= RigidBodyType.KINEMATIC then
			self.groundY = y

			return false
		end
	end

	return true
end

function DogBall:updateTick(dt)
	if self.isServer then
		local x, y, z = getWorldTranslation(self.nodeId)

		if self:getTerrainHeightWithProps(x, z) > y + 1 then
			self:reset()
		end

		local parentNode = getParent(self.nodeId)

		if parentNode ~= nil and (parentNode == getRootNode() or parentNode == g_currentMission.terrainRootNode) then
			local distSq = MathUtil.vector3LengthSq(x - self.spawnPos[1], y - self.spawnPos[2], z - self.spawnPos[3])

			if distSq > DogBall.RESET_DISTANCE * DogBall.RESET_DISTANCE then
				self:reset()
			end
		else
			local distSq = MathUtil.vector3LengthSq(x - self.throwPos[1], y - self.throwPos[2], z - self.throwPos[3])

			if distSq > DogBall.RESET_DISTANCE * DogBall.RESET_DISTANCE then
				self:reset()
			end
		end
	end

	DogBall:superClass().updateTick(self, dt)
end

function DogBall:load(i3dFilename, x, y, z, rx, ry, rz)
	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)

	if self.isServer then
		self.spawnPos = {
			x,
			y,
			z
		}
		self.throwPos = {
			x,
			y,
			z
		}
		self.startRot = {
			rx,
			ry,
			rz
		}
	end

	return true
end

function DogBall:reset()
	if self.isServer then
		removeFromPhysics(self.nodeId)
		setTranslation(self.nodeId, unpack(self.spawnPos))
		setRotation(self.nodeId, unpack(self.startRot))
		addToPhysics(self.nodeId)
	end
end
