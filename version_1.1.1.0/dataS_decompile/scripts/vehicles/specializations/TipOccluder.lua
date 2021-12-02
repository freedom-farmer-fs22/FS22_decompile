TipOccluder = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("TipOccluder")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#start", "Start node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#width", "Width node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#height", "Height node")
		schema:setXMLSpecializationType()
	end
}

function TipOccluder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getTipOcclusionAreas", TipOccluder.getTipOcclusionAreas)
	SpecializationUtil.registerFunction(vehicleType, "getWheelsWithTipOcclisionAreaGroupId", TipOccluder.getWheelsWithTipOcclisionAreaGroupId)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresTipOcclusionArea", TipOccluder.getRequiresTipOcclusionArea)
end

function TipOccluder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "finalizeWheel", TipOccluder.finalizeWheel)
end

function TipOccluder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TipOccluder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TipOccluder)
end

function TipOccluder:onLoad(savegame)
	local spec = self.spec_tipOccluder

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipOcclusionAreas.tipOcclusionArea", "vehicle.tipOccluder.occlusionArea")

	spec.tipOcclusionAreas = {}
	local i = 0

	while true do
		local key = string.format("vehicle.tipOccluder.occlusionArea(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local entry = {
			start = self.xmlFile:getValue(key .. "#start", nil, self.components, self.i3dMappings),
			width = self.xmlFile:getValue(key .. "#width", nil, self.components, self.i3dMappings),
			height = self.xmlFile:getValue(key .. "#height", nil, self.components, self.i3dMappings)
		}

		if entry.start ~= nil and entry.width ~= nil and entry.height ~= nil then
			table.insert(spec.tipOcclusionAreas, entry)
		end

		i = i + 1
	end

	spec.createdTipOcclusionAreaGroupIds = {}
end

function TipOccluder:getTipOcclusionAreas()
	return self.spec_tipOccluder.tipOcclusionAreas
end

function TipOccluder:getWheelsWithTipOcclisionAreaGroupId(wheels, groupId)
	local returnWheels = {}

	for _, wheel in pairs(wheels) do
		if wheel.tipOcclusionAreaGroupId == groupId then
			table.insert(returnWheels, wheel)
		end
	end

	return returnWheels
end

function TipOccluder:onPostLoad()
	if self:getRequiresTipOcclusionArea() and #self.spec_tipOccluder.tipOcclusionAreas == 0 then
		Logging.xmlDevWarning(self.xmlFile, "No TipOcclusionArea defined")
	end
end

function TipOccluder:getRequiresTipOcclusionArea()
	return false
end

function TipOccluder:finalizeWheel(superFunc, wheel, parentWheel)
	superFunc(self, wheel, parentWheel)

	local spec = self.spec_tipOccluder

	if wheel.tipOcclusionAreaGroupId ~= nil then
		local vehicleRootNode = self.components[1].node
		local doCreate = true
		local area = nil

		for groupId, occluderArea in pairs(spec.createdTipOcclusionAreaGroupIds) do
			if groupId == wheel.tipOcclusionAreaGroupId then
				doCreate = false
				area = occluderArea

				break
			end
		end

		if doCreate then
			local start = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheel.tipOcclusionAreaGroupId))
			local width = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheel.tipOcclusionAreaGroupId))
			local height = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheel.tipOcclusionAreaGroupId))

			link(vehicleRootNode, start)
			link(vehicleRootNode, width)
			link(vehicleRootNode, height)

			area = {
				start = start,
				width = width,
				height = height
			}

			table.insert(spec.tipOcclusionAreas, area)

			spec.createdTipOcclusionAreaGroupIds[wheel.tipOcclusionAreaGroupId] = area
		end

		if area ~= nil then
			local xMax = -math.huge
			local xMin = math.huge
			local zMax = -math.huge
			local zMin = math.huge
			local usedWheels = self:getWheelsWithTipOcclisionAreaGroupId(self:getWheels(), wheel.tipOcclusionAreaGroupId)

			table.insert(usedWheels, wheel)

			local rootNodeToUse = usedWheels[#usedWheels].node

			link(rootNodeToUse, area.start)
			link(rootNodeToUse, area.width)
			link(rootNodeToUse, area.height)

			for _, usedWheel in pairs(usedWheels) do
				local x, _, z = localToLocal(usedWheel.driveNode, rootNodeToUse, usedWheel.wheelShapeWidth - 0.5 * usedWheel.width, 0, -usedWheel.radius)
				xMax = math.max(x, xMax)
				zMin = math.min(z, zMin)
				x, _, z = localToLocal(usedWheel.driveNode, rootNodeToUse, -usedWheel.wheelShapeWidth + 0.5 * usedWheel.width, 0, usedWheel.radius)
				xMin = math.min(x, xMin)
				zMax = math.max(z, zMax)
			end

			setTranslation(area.start, xMax, 0, zMin)
			setTranslation(area.width, xMin, 0, zMin)
			setTranslation(area.height, xMax, 0, zMax)
		end
	end
end
