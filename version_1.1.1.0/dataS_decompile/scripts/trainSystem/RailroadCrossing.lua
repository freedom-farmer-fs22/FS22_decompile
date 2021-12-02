RailroadCrossing = {
	STATE_OPEN = 1,
	STATE_CLOSING = 2,
	STATE_CLOSED = 3,
	STATE_OPENING = 4,
	TRAFFIC_BLOCKING_NODE_MAX_DISTANCE = 2
}
local RailroadCrossing_mt = Class(RailroadCrossing)

function RailroadCrossing.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rootNode", "Root node")
	schema:register(XMLValueType.FLOAT, basePath .. ".activation#startDistance", "Activation start distance", 50)
	schema:register(XMLValueType.FLOAT, basePath .. ".activation#endDistance", "Activation end distance", 50)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".gates.gate(?)#node", "Gate node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".gates.gate(?)#startRot", "Start rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".gates.gate(?)#startTrans", "Start translation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".gates.gate(?)#endRot", "End rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".gates.gate(?)#endTrans", "End translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".gates.gate(?)#duration", "Move duration (sec)", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".gates.gate(?)#closingOffset", "Closing offset (sec)", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".signals.signal(?)#node", "Signal node, can be self-illum shape, add optional real light as child")
	schema:register(XMLValueType.BOOL, basePath .. ".signals.signal(?)#alternatingLights", "True if light should blink in opposite", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trafficBlockers.trafficBlocker(?)#node", "Traffic blocking node. Use one per road lane")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "crossing")
end

function RailroadCrossing.new(isServer, isClient, trainSystem, nodeId, customMt)
	local self = setmetatable({}, customMt or RailroadCrossing_mt)
	self.trainSystem = trainSystem
	self.nodeId = nodeId
	self.isServer = isServer
	self.isClient = isClient
	self.state = RailroadCrossing.STATE_OPEN

	return self
end

function RailroadCrossing:loadFromXML(xmlFile, key, components, i3dMappings)
	self.rootNode = xmlFile:getValue(key .. "#rootNode", nil, components, i3dMappings)
	self.startDistance = xmlFile:getValue(key .. ".activation#startDistance", 50)
	self.endDistance = xmlFile:getValue(key .. ".activation#endDistance", 50)
	self.isActive = false
	self.splinePositionTime = 0
	self.doCloseCrossing = false
	self.gateDirection = 1
	self.gates = {}
	self.signals = {}
	self.trafficBlockers = {}
	self.samples = {}
	local i = 0

	while true do
		local gateKey = string.format("%s.gates.gate(%d)", key, i)

		if not xmlFile:hasProperty(gateKey) then
			break
		end

		local node = xmlFile:getValue(gateKey .. "#node", nil, components, i3dMappings)

		if node ~= nil then
			local animCurve = AnimCurve.new(linearInterpolatorTransRot)
			local rx, ry, rz = xmlFile:getValue(gateKey .. "#startRot", {
				getRotation(node)
			})
			local x, y, z = xmlFile:getValue(gateKey .. "#startTrans", {
				getTranslation(node)
			})

			animCurve:addKeyframe({
				time = 0,
				x = x,
				y = y,
				z = z,
				rx = rx,
				ry = ry,
				rz = rz
			})
			setTranslation(node, x, y, z)
			setRotation(node, rx, ry, rz)

			rx, ry, rz = xmlFile:getValue(gateKey .. "#endRot", {
				rx,
				ry,
				rz
			})
			x, y, z = xmlFile:getValue(gateKey .. "#endTrans", {
				x,
				y,
				z
			})

			animCurve:addKeyframe({
				time = 1,
				x = x,
				y = y,
				z = z,
				rx = rx,
				ry = ry,
				rz = rz
			})

			local duration = xmlFile:getValue(gateKey .. "#duration", 3) * 1000
			local closingOffset = xmlFile:getValue(gateKey .. "#closingOffset", 0) * 1000

			table.insert(self.gates, {
				animTime = 0,
				currentOffset = 0,
				node = node,
				animCurve = animCurve,
				duration = duration,
				closingOffset = closingOffset
			})

			i = i + 1
		end
	end

	local lightsProfile = g_gameSettings:getValue("lightsProfile")
	i = 0

	while true do
		local signalKey = string.format("%s.signals.signal(%d)", key, i)

		if not xmlFile:hasProperty(signalKey) then
			break
		end

		local signalNode = xmlFile:getValue(signalKey .. "#node", nil, components, i3dMappings)

		if signalNode ~= nil then
			setVisibility(signalNode, false)

			local signal = {
				node = signalNode,
				alternatingLights = xmlFile:getValue(signalKey .. "#alternatingLights", false),
				lights = {}
			}

			for j = 0, getNumOfChildren(signal.node) - 1 do
				local light = {
					node = getChildAt(signal.node, j)
				}

				if getNumOfChildren(light.node) > 0 then
					light.realLight = getChildAt(light.node, 0)

					if lightsProfile == GS_PROFILE_HIGH or lightsProfile == GS_PROFILE_VERY_HIGH then
						light.defaultColor = {
							getLightColor(light.realLight)
						}
					else
						setVisibility(light.realLight, false)

						light.realLight = nil
					end
				end

				if signal.alternatingLights and #signal.lights % 2 == 0 then
					if getHasClassId(light.node, ClassIds.SHAPE) then
						setShaderParameter(light.node, "blinkOffset", 0.5, 0, 0, 0, false)
					end

					if light.realLight ~= nil then
						setLightColor(light.realLight, light.defaultColor[1] * 0.2, light.defaultColor[2] * 0.2, light.defaultColor[3] * 0.2)
					end
				end

				table.insert(signal.lights, light)
			end

			table.insert(self.signals, signal)
		end

		i = i + 1
	end

	local trafficSystem = g_currentMission.trafficSystem

	if trafficSystem ~= nil then
		xmlFile:iterate(string.format("%s.trafficBlockers.trafficBlocker", key), function (index, trafficBlockerKey)
			local trafficBlockerNode = xmlFile:getValue(trafficBlockerKey .. "#node", nil, components, i3dMappings)

			if trafficBlockerNode ~= nil then
				local wx, wy, wz = getWorldTranslation(trafficBlockerNode)
				local dx = 0
				local dy = 0
				local dz = 0
				local splineIndex, splineTime = findTrafficSystemBlockingPositionInformation(trafficSystem.trafficSystemId, wx, wy, wz, dx, dy, dz, RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE)

				if splineIndex == -1 then
					Logging.xmlWarning(xmlFile, "Unable to find spline for traffic blocker (%s) at %.1f %.1f %.1f", trafficBlockerKey, wx, wy, wz)

					return
				end

				local spline = trafficSystem:getSplineByIndex(splineIndex)

				if spline == nil then
					Logging.xmlWarning(xmlFile, "Unable to retrieve spline with index %d from traffic system", splineIndex)

					return
				end

				local swx, swy, swz = getSplinePosition(spline, splineTime)

				if swx == nil then
					Logging.xmlWarning(xmlFile, "Unable to retrieve spline position at spline time %.5f for '%s'", splineTime, I3DUtil.getNodePath(spline))

					return
				end

				local distanceBlockerToSpline = MathUtil.vector3Length(wx - swx, wy - swy, wz - swz)

				if distanceBlockerToSpline < RailroadCrossing.TRAFFIC_BLOCKING_NODE_MAX_DISTANCE then
					table.insert(self.trafficBlockers, {
						trafficBlockerNode = trafficBlockerNode,
						splineIndex = splineIndex,
						splineTime = splineTime
					})
				else
					Logging.xmlDevWarning(xmlFile, "Nearest found traffic spline position %.1f %.1f %.1f (spline %s) is %.1fm from traffic blocker %s (node '%s' at %.1f %.1f %.1f). Ignoring this blocker!", swx, swy, swz, getName(spline), distanceBlockerToSpline, trafficBlockerKey, getName(trafficBlockerNode), wx, wy, wz)
				end
			end
		end)
	end

	if self.isClient then
		self.samples.crossing = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "crossing", g_currentMission.loadingMapBaseDirectory, components, 0, AudioGroup.ENVIRONMENT, i3dMappings, self)
		self.isCrossingSamplePlaying = false
	end

	self.trainSystem:addSplinePositionUpdateListener(self)

	return true
end

function RailroadCrossing:delete()
	if self.isClient then
		g_soundManager:deleteSample(self.samples.crossing)

		self.samples.crossing = nil
	end

	local trafficSystem = g_currentMission.trafficSystem

	if trafficSystem ~= nil then
		for _, trafficBlocker in ipairs(self.trafficBlockers) do
			setTrafficSystemBlockingPositionState(trafficSystem.trafficSystemId, trafficBlocker.splineIndex, trafficBlocker.splineTime, false)
		end
	end

	self.trainSystem:removeSplinePositionUpdateListener(self)
end

function RailroadCrossing:setSplineTimeByPosition(t, splineLength)
	t = SplineUtil.getValidSplineTime(t)
	self.splinePositionTime = t
	self.startTime = t - self.startDistance / splineLength
	self.endTime = t + self.endDistance / splineLength
end

function RailroadCrossing:update(dt)
	if self.state == RailroadCrossing.STATE_CLOSING or self.state == RailroadCrossing.STATE_OPENING then
		local isAnimDone = self:updateGates(dt, self.gateDirection)

		if isAnimDone then
			if self.state == RailroadCrossing.STATE_CLOSING then
				self.state = RailroadCrossing.STATE_CLOSED
			elseif self.state == RailroadCrossing.STATE_OPENING then
				self:finishOpenGates()
			end
		end
	end

	if self.state ~= RailroadCrossing.STATE_OPEN then
		local shaderTime = getShaderTimeSec()
		local alpha = MathUtil.clamp(math.cos(7 * shaderTime) + 0.2, 0, 1)
		local alpha2 = MathUtil.clamp(math.cos(7 * shaderTime + math.pi) + 0.2, 0, 1)

		for _, signal in pairs(self.signals) do
			for k, light in pairs(signal.lights) do
				if light.realLight ~= nil then
					local currentAlpha = alpha

					if signal.alternatingLights and k % 2 == 1 then
						currentAlpha = alpha2
					end

					setLightColor(light.realLight, light.defaultColor[1] * currentAlpha, light.defaultColor[2] * currentAlpha, light.defaultColor[3] * currentAlpha)
				end
			end
		end
	end
end

function RailroadCrossing:updateGates(dt, direction)
	local isAnimDone = true

	for _, gate in pairs(self.gates) do
		if gate.currentOffset == 0 then
			gate.animTime = MathUtil.clamp(gate.animTime + direction * dt / gate.duration, 0, 1)
			local sx, sy, sz, rx, ry, rz = gate.animCurve:get(gate.animTime)

			setTranslation(gate.node, sx, sy, sz)
			setRotation(gate.node, rx, ry, rz)

			isAnimDone = isAnimDone and (gate.animTime == 0 or gate.animTime == 1)
		else
			gate.currentOffset = math.max(gate.currentOffset - dt, 0)
			isAnimDone = false
		end
	end

	return isAnimDone
end

function RailroadCrossing:startClosingGates()
	self.state = RailroadCrossing.STATE_CLOSING

	for _, signal in pairs(self.signals) do
		setVisibility(signal.node, true)
	end

	for _, gate in pairs(self.gates) do
		if gate.animTime == 0 then
			gate.currentOffset = gate.closingOffset
		end
	end

	self.gateDirection = 1

	if g_client ~= nil and not self.isCrossingSamplePlaying then
		g_soundManager:playSample(self.samples.crossing)

		self.isCrossingSamplePlaying = true
	end

	local trafficSystem = g_currentMission.trafficSystem

	if trafficSystem ~= nil then
		for _, trafficBlocker in ipairs(self.trafficBlockers) do
			setTrafficSystemBlockingPositionState(trafficSystem.trafficSystemId, trafficBlocker.splineIndex, trafficBlocker.splineTime, true)
		end
	end
end

function RailroadCrossing:startOpeningGates()
	self.state = RailroadCrossing.STATE_OPENING
	self.gateDirection = -1
end

function RailroadCrossing:finishOpenGates()
	self.state = RailroadCrossing.STATE_OPEN

	for _, signal in pairs(self.signals) do
		setVisibility(signal.node, false)
	end

	if g_client ~= nil and self.isCrossingSamplePlaying then
		g_soundManager:stopSample(self.samples.crossing)

		self.isCrossingSamplePlaying = false
	end

	local trafficSystem = g_currentMission.trafficSystem

	if trafficSystem ~= nil then
		for _, trafficBlocker in ipairs(self.trafficBlockers) do
			setTrafficSystemBlockingPositionState(trafficSystem.trafficSystemId, trafficBlocker.splineIndex, trafficBlocker.splineTime, false)
		end
	end
end

function RailroadCrossing:onSplinePositionTimeUpdate(startTime, endTime)
	startTime = SplineUtil.getValidSplineTime(startTime)
	endTime = SplineUtil.getValidSplineTime(endTime)
	local inRange = self.startTime < startTime and startTime < self.endTime or self.startTime < endTime and endTime < self.endTime

	if inRange then
		if self.state == RailroadCrossing.STATE_OPEN or self.state == RailroadCrossing.STATE_OPENING then
			self:startClosingGates()
		end
	elseif self.state == RailroadCrossing.STATE_CLOSED or self.state == RailroadCrossing.STATE_CLOSING then
		self:startOpeningGates()
	end
end
