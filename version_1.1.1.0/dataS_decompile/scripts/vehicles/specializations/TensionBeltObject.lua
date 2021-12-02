TensionBeltObject = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("TensionBeltObject")
		schema:register(XMLValueType.BOOL, "vehicle.tensionBeltObject#supportsTensionBelts", "Supports tension belts", true)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.tensionBeltObject.meshNodes.meshNode(?)#node", "Mesh node for tension belt calculation")
		schema:setXMLSpecializationType()
	end
}

function TensionBeltObject.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsTensionBelts", TensionBeltObject.getSupportsTensionBelts)
	SpecializationUtil.registerFunction(vehicleType, "getMeshNodes", TensionBeltObject.getMeshNodes)
	SpecializationUtil.registerFunction(vehicleType, "getTensionBeltNodeId", TensionBeltObject.getTensionBeltNodeId)
end

function TensionBeltObject.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBeltObject)
end

function TensionBeltObject:onLoad(savegame)
	local spec = self.spec_tensionBeltObject
	spec.supportsTensionBelts = self.xmlFile:getValue("vehicle.tensionBeltObject#supportsTensionBelts", true)
	spec.meshNodes = {}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.tensionBeltObject.meshNodes.meshNode(%d)", i)

		if not self.xmlFile:hasProperty(baseKey) then
			break
		end

		local node = self.xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			if not getShapeIsCPUMesh(node) then
				Logging.xmlWarning(self.xmlFile, "Mesh node %s (%s) does not have the CPU-Mesh flag set required for tension belts", self.xmlFile:getString(baseKey .. "#node"), I3DUtil.getNodePath(node))
			end

			table.insert(spec.meshNodes, node)
		end

		i = i + 1
	end
end

function TensionBeltObject:getSupportsTensionBelts()
	return self.spec_tensionBeltObject.supportsTensionBelts
end

function TensionBeltObject:getMeshNodes()
	return self.spec_tensionBeltObject.meshNodes
end

function TensionBeltObject:getTensionBeltNodeId()
	return self.components[1].node
end
