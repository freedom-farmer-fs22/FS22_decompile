SplineVehicle = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("SplineVehicle")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#frontNode", "Front node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#backNode", "Back node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#dolly1Node", "Front dolly node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.splineVehicle.dollies#dolly2Node", "Back dolly node")
		schema:register(XMLValueType.BOOL, "vehicle.splineVehicle.dollies#alignDollys", "Align dollies", true)
		schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. "#needsIsEntered", "Vehicle needs to be entered to do raycasting", true)
		schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. "#needsIsEntered", "Vehicle needs to be entered to do raycasting", true)
		schema:setXMLSpecializationType()
	end
}

function SplineVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getFrontToBackDistance", SplineVehicle.getFrontToBackDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplineTimeFromDistance", SplineVehicle.getSplineTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "getSplinePositionAndTimeFromDistance", SplineVehicle.getSplinePositionAndTimeFromDistance)
	SpecializationUtil.registerFunction(vehicleType, "alignToSplineTime", SplineVehicle.alignToSplineTime)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSplinePosition", SplineVehicle.getCurrentSplinePosition)
end

function SplineVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLastSpeed", SplineVehicle.getLastSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", SplineVehicle.setTrainSystem)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentSurfaceSound", SplineVehicle.getCurrentSurfaceSound)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", SplineVehicle.getAreSurfaceSoundsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", SplineVehicle.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", SplineVehicle.loadDischargeNode)
end

function SplineVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SplineVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SplineVehicle)
end

function SplineVehicle:onLoad(savegame)
	local spec = self.spec_splineVehicle
	spec.frontNode = self.xmlFile:getValue("vehicle.splineVehicle.dollies#frontNode", nil, self.components, self.i3dMappings)
	spec.backNode = self.xmlFile:getValue("vehicle.splineVehicle.dollies#backNode", nil, self.components, self.i3dMappings)
	spec.frontToBackDistance = calcDistanceFrom(spec.frontNode, spec.backNode)
	spec.dolly1Node = self.xmlFile:getValue("vehicle.splineVehicle.dollies#dolly1Node", nil, self.components, self.i3dMappings)
	spec.dolly2Node = self.xmlFile:getValue("vehicle.splineVehicle.dollies#dolly2Node", nil, self.components, self.i3dMappings)
	spec.dollyToDollyDistance = calcDistanceFrom(spec.dolly1Node, spec.dolly2Node)
	spec.rootNodeToBackDistance = calcDistanceFrom(spec.backNode, self.rootNode)
	spec.rootNodeToFrontDistance = calcDistanceFrom(spec.frontNode, self.rootNode)
	spec.alignDollys = self.xmlFile:getValue("vehicle.splineVehicle.dollies#alignDollys", true)
	spec.splinePosition = 0
	spec.lastSplinePosition = 0
	spec.currentSplinePosition = 0
	spec.splinePositionSpeed = 0
	spec.splinePositionSpeedReal = 0
	spec.splineSpeed = 0
	spec.firstUpdate = true
end

function SplineVehicle:setTrainSystem(superFunc, trainSystem)
	superFunc(self, trainSystem)

	local spec = self.spec_splineVehicle
	spec.splineLength = trainSystem:getSplineLength()
	spec.frontToBackSplineTime = spec.frontToBackDistance / spec.splineLength
	spec.dollyToDollySplineTime = spec.dollyToDollyDistance / spec.splineLength
	spec.rootNodeToBackSplineTime = spec.rootNodeToBackDistance / spec.splineLength
	spec.rootNodeToFrontSplineTime = spec.rootNodeToFrontDistance / spec.splineLength
end

function SplineVehicle:getCurrentSplinePosition()
	return self.spec_splineVehicle.splinePosition
end

function SplineVehicle:getFrontToBackDistance()
	return self.spec_splineVehicle.frontToBackDistance
end

function SplineVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_splineVehicle

		if spec.trainSystem ~= nil then
			spec.splinePositionSpeed = spec.splinePositionSpeed * 0.975 + spec.splinePositionSpeedReal * 0.025
		end
	end
end

function SplineVehicle:getSplineTimeFromDistance(t, distance, stepSize)
	if self.trainSystem == nil then
		return
	end

	local positiveTimeOffset = stepSize >= 0
	local _, _, _, t2 = getSplinePositionWithDistance(self.trainSystem:getSpline(), t, distance, positiveTimeOffset, 0.01)

	return SplineUtil.getValidSplineTime(t2)
end

function SplineVehicle:getSplinePositionAndTimeFromDistance(t, distance, stepSize)
	if self.trainSystem == nil then
		return
	end

	local positiveTimeOffset = stepSize >= 0
	local x, y, z, t2 = getSplinePositionWithDistance(self.trainSystem:getSpline(), t, distance, positiveTimeOffset, 0.01)

	return x, y, z, SplineUtil.getValidSplineTime(t2)
end

function SplineVehicle:alignToSplineTime(spline, yOffset, tFront)
	if self.trainSystem == nil then
		return
	end

	local spec = self.spec_splineVehicle
	local maxDiff = math.max(self.trainSystem:getLengthSplineTime(), 0.25)
	local delta = tFront - spec.splinePosition

	if maxDiff < math.abs(delta) then
		if delta > 0 then
			delta = delta - 1
		else
			delta = delta + 1
		end
	end

	self.movingDirection = 1

	if delta < 0 then
		self.movingDirection = -1
	end

	local p1x, p1y, p1z, t = self:getSplinePositionAndTimeFromDistance(tFront, spec.rootNodeToFrontDistance, -1.2 * spec.rootNodeToFrontSplineTime)
	local wp1x, wp1y, wp1z = localToWorld(getParent(spline), p1x, p1y, p1z)
	local p2x, p2y, p2z, t2 = self:getSplinePositionAndTimeFromDistance(t, spec.dollyToDollyDistance, -1.2 * spec.dollyToDollySplineTime)
	local wp2x, wp2y, wp2z = localToWorld(getParent(spline), p2x, p2y, p2z)

	setDirection(self.rootNode, wp1x - wp2x, wp1y - wp2y, wp1z - wp2z, 0, 1, 0)

	local qx, qy, qz, qw = getWorldQuaternion(self.rootNode)

	setWorldTranslation(self.rootNode, wp1x, wp1y + yOffset, wp1z)

	local networkInterpolators = self.components[1].networkInterpolators

	networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	networkInterpolators.position:setPosition(wp1x, wp1y + yOffset, wp1z)

	if spec.alignDollys then
		local d1x, d1y, d1z = getSplineDirection(spline, t)
		local d2x, d2y, d2z = getSplineDirection(spline, t2)
		d1x, d1y, d1z = localDirectionToLocal(spline, getParent(spec.dolly1Node), d1x, d1y, d1z)
		d2x, d2y, d2z = localDirectionToLocal(spline, getParent(spec.dolly2Node), d2x, d2y, d2z)

		setDirection(spec.dolly1Node, d1x, d1y, d1z, 0, 1, 0)
		setDirection(spec.dolly2Node, d2x, d2y, d2z, 0, 1, 0)
	end

	local interpDt = g_physicsDt

	if g_server == nil then
		interpDt = g_physicsDtUnclamped
	end

	spec.splinePositionSpeedReal = delta * spec.trainSystem:getSplineLength() * 1000 / interpDt

	if self.isServer then
		spec.splinePositionSpeed = spec.splinePositionSpeedReal
	end

	spec.splinePosition = tFront

	if spec.firstUpdate then
		spec.splinePositionSpeedReal = 0
		spec.splinePositionSpeed = 0
		spec.firstUpdate = false
	end

	local tBack = self:getSplineTimeFromDistance(tFront, spec.frontToBackDistance, -1.2 * spec.frontToBackSplineTime)

	return tBack
end

function SplineVehicle:getLastSpeed(superFunc, useAttacherVehicleSpeed)
	return math.abs(self.spec_splineVehicle.splinePositionSpeed * 3.6)
end

function SplineVehicle:getCurrentSurfaceSound()
	return self.spec_wheels.surfaceNameToSound.railroad
end

function SplineVehicle:getAreSurfaceSoundsActive(superFunc)
	local rootVehicle = self.rootVehicle

	if rootVehicle ~= nil then
		return rootVehicle:getAreSurfaceSoundsActive()
	end

	return true
end

function SplineVehicle:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.needsIsEntered = xmlFile:getValue(key .. "#needsIsEntered", true)

	return true
end

function SplineVehicle:getIsDischargeNodeActive(superFunc, dischargeNode)
	if dischargeNode.needsIsEntered then
		local rootVehicle = self:getRootVehicle()

		if rootVehicle ~= nil and rootVehicle.getIsEntered ~= nil and not rootVehicle:getIsEntered() then
			return false
		end
	end

	return superFunc(self, dischargeNode)
end
