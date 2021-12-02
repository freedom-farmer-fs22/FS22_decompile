CameraPath = {}
local CameraPath_mt = Class(CameraPath)

function CameraPath.new(posAnimCurve, rotAnimCurve, speedAnimCurve, speedScale, camera, maxTime, finishedCallback)
	local self = {}

	setmetatable(self, CameraPath_mt)

	self.posAnimCurve = posAnimCurve
	self.rotAnimCurve = rotAnimCurve
	self.speedAnimCurve = speedAnimCurve
	self.speedScale = speedScale
	self.time = 0
	self.camera = camera
	self.overriddenCamera = nil
	self.maxTime = maxTime
	self.finishedCallback = finishedCallback

	return self
end

function CameraPath:delete()
	delete(self.camera)
end

function CameraPath.createFromI3D(filename, speedScale, camera)
	local rootNode = g_i3DManager:loadI3DFile(filename, false, false)
	local positionNodes = getChild(rootNode, "positions")

	if positionNodes == 0 then
		print("Error: failed to load camera path: " .. filename .. ". No positions found.")

		return nil
	end

	local posAnimCurve = AnimCurve.new(catmullRomInterpolator3, 3)
	local rotAnimCurve = AnimCurve.new(quaternionInterpolator2, 3)
	local speedAnimCurve = AnimCurve.new(catmullRomInterpolator1, 3)
	local num = getNumOfChildren(positionNodes)
	local t = 0
	local lastX, lastY, lastZ = nil

	for i = 0, num - 1 do
		local node = getChildAt(positionNodes, i)
		local x, y, z = getTranslation(node)
		local rx, ry, rz = getRotation(node)
		local speed, _, _ = getScale(node)

		if i > 0 then
			local dist = MathUtil.vector3Length(x - lastX, y - lastY, z - lastZ)
			t = t + dist
		end

		lastX = x
		lastY = y
		lastZ = z

		posAnimCurve:addKeyframe({
			time = t,
			x = x,
			y = y,
			z = z
		})

		local qx, qy, qz, qw = mathEulerToQuaternion(rx, ry, rz)

		rotAnimCurve:addKeyframe({
			time = t,
			x = qx,
			y = qy,
			z = qz,
			w = qw
		})
		speedAnimCurve:addKeyframe({
			time = t,
			v = speed
		})
	end

	local numSegments = 32
	local segmentTimes = {}
	t = 0

	for i = 1, table.getn(posAnimCurve.keyframes) - 1 do
		local keyframe1 = posAnimCurve.keyframes[i]
		local keyframe2 = posAnimCurve.keyframes[i + 1]
		local d = 0
		local lastKfX, lastKfY, lastKfZ = posAnimCurve:getFromKeyframes(keyframe1, keyframe2, i, i + 1, 1)
		local segmentOffset = (i - 1) * (numSegments + 1) + 1
		segmentTimes[segmentOffset] = 0

		for a = 1, numSegments do
			local x, y, z = posAnimCurve:getFromKeyframes(keyframe1, keyframe2, i, i + 1, 1 - a / numSegments)
			local dist = MathUtil.vector3Length(x - lastKfX, y - lastKfY, z - lastKfZ)
			d = d + dist
			segmentTimes[segmentOffset + a] = d
			lastKfX = x
			lastKfY = y
			lastKfZ = z
		end

		t = t + d
		posAnimCurve.keyframes[i + 1].time = t
		rotAnimCurve.keyframes[i + 1].time = t
		speedAnimCurve.keyframes[i + 1].time = t
	end

	posAnimCurve.segmentTimes = segmentTimes
	posAnimCurve.numTimesPerKeyframe = numSegments
	rotAnimCurve.segmentTimes = segmentTimes
	rotAnimCurve.numTimesPerKeyframe = numSegments
	speedAnimCurve.segmentTimes = segmentTimes
	speedAnimCurve.numTimesPerKeyframe = numSegments
	posAnimCurve.maxTime = t
	rotAnimCurve.maxTime = t
	speedAnimCurve.maxTime = t

	delete(rootNode)

	return CameraPath.new(posAnimCurve, rotAnimCurve, speedAnimCurve, speedScale, camera, t)
end

function CameraPath:update(dt)
	local speedScale = self.speedScale

	if self.speedAnimCurve ~= nil then
		speedScale = speedScale * self.speedAnimCurve:get(self.time)
	end

	self.time = self.time + dt * speedScale

	self:placeCamera()

	local currentCamera = getCamera()

	if currentCamera ~= self.camera then
		self.overriddenCamera = currentCamera

		setCamera(self.camera)
	end

	if self.finishedCallback ~= nil and self.maxTime < self.time then
		self.finishedCallback()
	end
end

function CameraPath:placeCamera()
	local x, y, z = self.posAnimCurve:get(self.time)
	local qx, qy, qz, qw = self.rotAnimCurve:get(self.time)

	setTranslation(self.camera, x, y, z)
	setQuaternion(self.camera, qx, qy, qz, qw)
end

function CameraPath:activate()
	self:placeCamera()

	self.overriddenCamera = getCamera()

	setCamera(self.camera)
end

function CameraPath:deactivate()
	self.time = 0

	if self.overriddenCamera ~= nil then
		setCamera(self.overriddenCamera)
	end

	g_currentMission:removeUpdateable(self)
end
