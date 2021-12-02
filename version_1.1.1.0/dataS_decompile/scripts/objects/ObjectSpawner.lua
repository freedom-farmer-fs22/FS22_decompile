ObjectSpawner = {}
local ObjectSpawner_mt = Class(ObjectSpawner)

function ObjectSpawner.new(spawnFunction, numObjectsTarget, numSpawnsPerSecond, spawnMinRadius, spawnMaxRadius, destroyRadius, warmupCameraMove, warmupPercentage, updateFunction)
	local self = setmetatable({}, ObjectSpawner_mt)
	self.spawnFunction = spawnFunction
	self.updateFunction = updateFunction
	self.numObjectsTarget = numObjectsTarget
	self.spawnMinRadius = spawnMinRadius
	self.spawnMaxRadius = spawnMaxRadius
	self.destroyRadius = destroyRadius
	self.destroyRadiusSq = self.destroyRadius * self.destroyRadius
	self.warmupCameraMove = warmupCameraMove
	self.warmupCameraMoveSq = warmupCameraMove * warmupCameraMove
	self.warmupPercentage = warmupPercentage
	self.spawnInterval = 1 / (numSpawnsPerSecond * 0.001)
	self.spawnDt = 0
	self.isWarmedUp = false
	self.lastCx = 0
	self.lastCz = 0
	self.objects = {}
	self.numObjects = 0
	self.objectsCache = {}

	return self
end

function ObjectSpawner:delete()
	for _, object in pairs(self.objects) do
		if not object.isDeleted then
			object:delete()
		end
	end

	for _, object in pairs(self.objectsCache) do
		if not object.isDeleted then
			object:delete()
		end
	end
end

function ObjectSpawner:update(dt)
	local camera = getCamera()
	local cx, cy, cz = getWorldTranslation(camera)

	if self.updateFunction ~= nil then
		self:updateFunction(dt)
	else
		for k, object in pairs(self.objects) do
			if not object.isDeleted then
				object:update(dt)
			end
		end
	end

	for k, object in pairs(self.objects) do
		if object.isDeleted then
			self.objects[k] = nil
			self.numObjects = self.numObjects - 1
		elseif object.requestDelete or self.destroyRadiusSq < object:getSquaredDistanceFrom(cx, cz) then
			object:removeFromScene()

			self.objects[k] = nil
			self.numObjects = self.numObjects - 1

			table.insert(self.objectsCache, object)
		end
	end

	local doWarmup = not self.isWarmedUp
	self.isWarmedUp = true

	if not doWarmup then
		local dx = cx - self.lastCx
		local dz = cz - self.lastCz

		if self.warmupCameraMoveSq < dx * dx + dz * dz then
			doWarmup = true
		end
	end

	self.lastCx = cx
	self.lastCz = cz
	self.spawnDt = self.spawnDt + dt

	if doWarmup or self.spawnInterval < self.spawnDt then
		local numAdded = 0
		local numObjectsToAdd = 1

		if doWarmup then
			numObjectsToAdd = math.ceil(self.warmupPercentage * self.numObjectsTarget)
		end

		numObjectsToAdd = math.min(self.numObjectsTarget - self.numObjects, numObjectsToAdd)

		for i = 1, numObjectsToAdd do
			local object = self:spawnFunction(doWarmup, cx, cy, cz)

			if object ~= nil then
				self.objects[object] = object
				self.numObjects = self.numObjects + 1
				numAdded = numAdded + 1
			end
		end

		if numAdded > 0 or numObjectsToAdd == 0 then
			self.spawnDt = 0
		else
			self.spawnDt = self.spawnInterval * 0.75
		end
	end
end

function ObjectSpawner:getObjectFromCache()
	local numObjects = table.getn(self.objectsCache)

	while numObjects > 0 do
		local object = self.objectsCache[numObjects]

		table.remove(self.objectsCache, numObjects)

		numObjects = numObjects - 1

		if not object.isDeleted then
			return object
		end
	end

	return nil
end
