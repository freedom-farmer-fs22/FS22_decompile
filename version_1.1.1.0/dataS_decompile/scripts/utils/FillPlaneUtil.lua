FillPlaneUtil = {
	registerFillPlaneXMLPaths = function (schema, key)
		schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Node")
		schema:register(XMLValueType.FLOAT, key .. "#maxDelta", "Max. heap size above above input surface [m]", 1)
		schema:register(XMLValueType.ANGLE, key .. "#maxAllowedHeapAngle", "Max. allowed heap surface slope angle [deg]", 35)
		schema:register(XMLValueType.FLOAT, key .. "#maxSurfaceDistanceError", "Max. allowed distance from input mesh surface to created fill plane mesh [m]", 0.05)
		schema:register(XMLValueType.FLOAT, key .. "#maxSubDivEdgeLength", "Max. length of sub division edges [m]", 0.9)
		schema:register(XMLValueType.FLOAT, key .. "#syncMaxSubDivEdgeLength", "Max. length of sub division edges used to sync in multiplayer [m]", 1.35)
		schema:register(XMLValueType.BOOL, key .. "#allSidePlanes", "All side planes", true)
		schema:register(XMLValueType.BOOL, key .. "#retessellateTop", "Retessellate top plane for better triangulation quality", false)
		schema:register(XMLValueType.BOOL, key .. "#changeColor", "Fillplane supports color change", false)
	end,
	createFromXML = function (xmlFile, key, baseNode, capacity)
		if baseNode == nil then
			Logging.xmlWarning(xmlFile, "Missing node for fillplane for '%s'", key)

			return nil
		end

		local maxDelta = xmlFile:getValue(key .. "#maxDelta", 1)
		local maxAllowedHeapAngle = xmlFile:getValue(key .. "#maxAllowedHeapAngle", 35)
		local maxPhysicalSurfaceAngle = math.rad(35)
		local maxSurfaceDistanceError = xmlFile:getValue(key .. "#maxSurfaceDistanceError", 0.05)
		local maxSubDivEdgeLength = xmlFile:getValue(key .. "#maxSubDivEdgeLength", 0.9)
		local syncMaxSubDivEdgeLength = xmlFile:getValue(key .. "#syncMaxSubDivEdgeLength", 1.35)
		local allSidePlanes = xmlFile:getValue(key .. "#allSidePlanes", true)
		local retessellateTop = xmlFile:getValue(key .. "#retessellateTop", false)
		local fillPlane = createFillPlaneShape(baseNode, "fillPlane", capacity, maxDelta, maxAllowedHeapAngle, maxPhysicalSurfaceAngle, maxSurfaceDistanceError, maxSubDivEdgeLength, syncMaxSubDivEdgeLength, allSidePlanes, retessellateTop)

		if fillPlane == 0 or fillPlane == nil then
			Logging.xmlWarning(xmlFile, "Failed to create fillplane for '%s'", key)

			return nil
		end

		link(baseNode, fillPlane)

		return fillPlane
	end,
	assignDefaultMaterials = function (fillPlane)
		local fillPlaneMaterial = g_materialManager:getBaseMaterialByName("fillPlane")

		if fillPlaneMaterial ~= nil then
			setMaterial(fillPlane, fillPlaneMaterial, 0)
			g_fillTypeManager:assignFillTypeTextureArrays(fillPlane, true, true, true)
		else
			Logging.error("Failed to assign material to fillplane. Base Material 'fillPlane' not found!")
		end
	end,
	setFillType = function (fillPlane, fillTypeIndex)
		local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillTypeIndex)

		if textureArrayIndex ~= nil then
			setShaderParameter(fillPlane, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
		end
	end
}
