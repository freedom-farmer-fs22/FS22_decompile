SlopeCompensation = {
	SLOPE_COLLISION_MASK = 223,
	COMPENSATION_NODE_XML_KEY = "vehicle.slopeCompensation.compensationNode(?)",
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Wheels, specializations)
	end
}

function SlopeCompensation.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("SlopeCompensation")
	schema:register(XMLValueType.FLOAT, "vehicle.slopeCompensation#threshold", "Update threshold for animation", 0.002)
	schema:register(XMLValueType.INT, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#wheel1", "Wheel index 1")
	schema:register(XMLValueType.INT, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#wheel2", "Wheel index 2")
	schema:register(XMLValueType.ANGLE, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#maxAngle", "Max. angle")
	schema:register(XMLValueType.ANGLE, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#minAngle", "Min. angle")
	schema:register(XMLValueType.FLOAT, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#speed", "Move speed")
	schema:register(XMLValueType.STRING, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#animationName", "Animation name")
	schema:setXMLSpecializationType()
end

function SlopeCompensation.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCompensationNodeFromXML", SlopeCompensation.loadCompensationNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCompensationAngleScale", SlopeCompensation.getCompensationAngleScale)
	SpecializationUtil.registerFunction(vehicleType, "getCompensationGroundPosition", SlopeCompensation.getCompensationGroundPosition)
	SpecializationUtil.registerFunction(vehicleType, "slopeDetectionCallback", SlopeCompensation.slopeDetectionCallback)
end

function SlopeCompensation.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SlopeCompensation)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SlopeCompensation)
end

function SlopeCompensation:onPostLoad(savegame)
	local spec = self.spec_slopeCompensation
	spec.lastRaycastDistance = 0
	spec.nodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.slopeCompensation.compensationNode(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local compensationNode = {}

		if self:loadCompensationNodeFromXML(compensationNode, self.xmlFile, key) then
			table.insert(spec.nodes, compensationNode)
		end

		i = i + 1
	end

	spec.threshold = self.xmlFile:getValue("vehicle.slopeCompensation#threshold", 0.002)

	if #spec.nodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SlopeCompensation)
	end
end

function SlopeCompensation:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_slopeCompensation

	for _, compensationNode in ipairs(spec.nodes) do
		local x1, y1, z1, valid1 = self:getCompensationGroundPosition(compensationNode, 1)
		local x2, y2, z2, valid2 = self:getCompensationGroundPosition(compensationNode, 2)

		if valid1 and valid2 then
			local h = y1 - y2
			local l = MathUtil.vector2Length(x1 - x2, z1 - z2)
			local angle = math.tan(h / l) * self:getCompensationAngleScale(compensationNode)
			local pos = MathUtil.clamp((angle - compensationNode.minAngle) / (compensationNode.maxAngle - compensationNode.minAngle), 0, 1)

			if spec.threshold < math.abs(compensationNode.lastPos - pos) then
				local dir = MathUtil.sign(pos - compensationNode.lastPos)
				local limit = dir > 0 and math.min or math.max
				compensationNode.lastPos = limit(compensationNode.lastPos + compensationNode.speed * dt * dir, pos)

				if self.setAnimationTime ~= nil and compensationNode.animationName ~= nil then
					self:setAnimationTime(compensationNode.animationName, compensationNode.lastPos, true)
				end
			end
		end
	end
end

function SlopeCompensation:loadCompensationNodeFromXML(compensationNode, xmlFile, key)
	compensationNode.raycastDistance = 0
	compensationNode.lastDistance1 = 0
	compensationNode.lastDistance2 = 0

	for _, name in ipairs({
		"wheel1",
		"wheel2"
	}) do
		local wheelId = self.xmlFile:getValue(key .. "#" .. name)

		if wheelId == nil then
			Logging.xmlWarning(self.xmlFile, "Missing %s for compensation node '%s'", name, key)

			return false
		end

		local wheel = self:getWheels()[wheelId]

		if wheel ~= nil then
			compensationNode[name .. "Node"] = wheel.driveNode
			compensationNode.raycastDistance = math.max(compensationNode.raycastDistance, wheel.radius + 1)
		else
			Logging.xmlWarning(self.xmlFile, "Unable to find wheel index '%d' for compensation node '%s'", wheelId, key)

			return false
		end
	end

	compensationNode.maxAngle = self.xmlFile:getValue(key .. "#maxAngle", 5)
	compensationNode.minAngle = self.xmlFile:getValue(key .. "#minAngle", -math.deg(compensationNode.maxAngle))
	compensationNode.speed = self.xmlFile:getValue(key .. "#speed", 1) / 1000
	compensationNode.lastPos = 0.5
	compensationNode.animationName = self.xmlFile:getValue(key .. "#animationName")

	if compensationNode.animationName ~= nil then
		local updateAnimation = self:getCompensationAngleScale(compensationNode) > 0

		self:setAnimationTime(compensationNode.animationName, 0, updateAnimation)
		self:setAnimationTime(compensationNode.animationName, 1, updateAnimation)
		self:setAnimationTime(compensationNode.animationName, 0.5, updateAnimation)
	end

	return true
end

function SlopeCompensation:getCompensationAngleScale(compensationNode)
	return 1
end

function SlopeCompensation:getCompensationGroundPosition(compensationNode, wheelId)
	local spec = self.spec_slopeCompensation
	local x, y, z = getWorldTranslation(compensationNode["wheel" .. wheelId .. "Node"])
	spec.lastRaycastDistance = 0

	raycastAll(x, y, z, 0, -1, 0, "slopeDetectionCallback", compensationNode.raycastDistance, self, SlopeCompensation.SLOPE_COLLISION_MASK)

	local distance = spec.lastRaycastDistance

	if distance == 0 then
		distance = compensationNode["lastDistance" .. wheelId]
	else
		compensationNode["lastDistance" .. wheelId] = spec.lastRaycastDistance
	end

	return x, y - distance, z, distance ~= 0
end

function SlopeCompensation:slopeDetectionCallback(hitObjectId, x, y, z, distance)
	if getRigidBodyType(hitObjectId) ~= RigidBodyType.STATIC then
		return true
	end

	self.spec_slopeCompensation.lastRaycastDistance = distance

	return false
end
