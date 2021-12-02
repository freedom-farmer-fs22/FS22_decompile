PlaceableAI = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableAI.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadAIUpdateArea", PlaceableAI.loadAIUpdateArea)
	SpecializationUtil.registerFunction(placeableType, "loadAISpline", PlaceableAI.loadAISpline)
	SpecializationUtil.registerFunction(placeableType, "updateAIUpdateAreas", PlaceableAI.updateAIUpdateAreas)
end

function PlaceableAI.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAI)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAI)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableAI)
end

function PlaceableAI.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("AI")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#startNode", "Start node of ai update area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#endNode", "End node of ai update area")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.splines.spline(?)#node", "Spline node or transform group containing splines. Spline direction not relevant")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.splines.spline(?)#maxWidth", "Maximum vehicle width supported by the spline")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai.splines.spline(?)#maxTurningRadius", "Maxmium vehicle turning supported by the spline")
	schema:setXMLSpecializationType()
end

function PlaceableAI:onLoad(savegame)
	local spec = self.spec_ai
	local xmlFile = self.xmlFile
	spec.updateAreaOnDelete = false
	spec.areas = {}

	xmlFile:iterate("placeable.ai.updateAreas.updateArea", function (_, key)
		local area = {}

		if self:loadAIUpdateArea(xmlFile, key, area) then
			table.insert(spec.areas, area)
		end
	end)

	if not self.xmlFile:hasProperty("placeable.ai.updateAreas") then
		Logging.xmlWarning(self.xmlFile, "Missing ai update areas")
	end

	spec.splines = {}

	xmlFile:iterate("placeable.ai.splines.spline", function (_, key)
		local spline = {}

		if self:loadAISpline(xmlFile, key, spline) then
			table.insert(spec.splines, spline)
		end
	end)
end

function PlaceableAI:onDelete()
	if self.isServer then
		local spec = self.spec_ai

		if spec.updateAreaOnDelete then
			self:updateAIUpdateAreas()
		end

		if g_currentMission.aiSystem ~= nil and spec.splines ~= nil then
			for _, spline in pairs(spec.splines) do
				g_currentMission.aiSystem:removeRoadSpline(spline.splineNode)
			end
		end
	end
end

function PlaceableAI:loadAIUpdateArea(xmlFile, key, area)
	local startNode = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	local endNode = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)

	if startNode == nil then
		Logging.xmlWarning(xmlFile, "Missing ai update area start node for '%s'", key)

		return false
	end

	if endNode == nil then
		Logging.xmlWarning(xmlFile, "Missing ai update area end node for '%s'", key)

		return false
	end

	local startX, _, startZ = localToLocal(startNode, self.rootNode, 0, 0, 0)
	local endX, _, endZ = localToLocal(endNode, self.rootNode, 0, 0, 0)
	local sizeX = math.abs(endX - startX)
	local sizeZ = math.abs(endZ - startZ)
	area.center = {
		x = (endX + startX) * 0.5,
		z = (endZ + startZ) * 0.5
	}
	area.size = {
		x = sizeX,
		z = sizeZ
	}
	area.startNode = startNode
	area.endNode = endNode

	return true
end

function PlaceableAI:loadAISpline(xmlFile, key, spline)
	local splineNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if splineNode == nil then
		return false
	end

	setVisibility(splineNode, false)

	local maxWidth = xmlFile:getValue(key .. "#maxWidth")
	local maxTurningRadius = xmlFile:getValue(key .. "#maxTurningRadius")
	spline.splineNode = splineNode
	spline.maxWidth = maxWidth
	spline.maxTurningRadius = maxTurningRadius

	return true
end

function PlaceableAI:onFinalizePlacement()
	if self.isServer then
		local spec = self.spec_ai
		local missionInfo = g_currentMission.missionInfo
		spec.updateAreaOnDelete = true

		if not self.isLoadedFromSavegame or not missionInfo.isValid then
			self:updateAIUpdateAreas()
		end

		if g_currentMission.aiSystem ~= nil then
			for _, spline in pairs(spec.splines) do
				g_currentMission.aiSystem:addRoadSpline(spline.splineNode, spline.maxWidth, spline.maxTurningRadius)
			end
		end
	end
end

function PlaceableAI:updateAIUpdateAreas()
	if self.isServer then
		local spec = self.spec_ai

		for _, area in pairs(spec.areas) do
			local x = area.center.x
			local z = area.center.z
			local sizeX = area.size.x
			local sizeZ = area.size.z
			local x1, _, z1 = localToWorld(self.rootNode, x + sizeX * 0.5, 0, z + sizeZ * 0.5)
			local x2, _, z2 = localToWorld(self.rootNode, x - sizeX * 0.5, 0, z + sizeZ * 0.5)
			local x3, _, z3 = localToWorld(self.rootNode, x + sizeX * 0.5, 0, z - sizeZ * 0.5)
			local x4, _, z4 = localToWorld(self.rootNode, x - sizeX * 0.5, 0, z - sizeZ * 0.5)
			local minX = math.min(x1, x2, x3, x4)
			local maxX = math.max(x1, x2, x3, x4)
			local minZ = math.min(z1, z2, z3, z4)
			local maxZ = math.max(z1, z2, z3, z4)

			g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
		end
	end
end
