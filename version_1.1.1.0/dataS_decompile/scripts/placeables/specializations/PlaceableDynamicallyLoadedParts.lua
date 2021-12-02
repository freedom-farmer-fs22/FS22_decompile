PlaceableDynamicallyLoadedParts = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableDynamicallyLoadedParts.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onDynamicallyPartI3DLoaded", PlaceableDynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end

function PlaceableDynamicallyLoadedParts.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDynamicallyLoadedParts)
end

function PlaceableDynamicallyLoadedParts.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("DynamicallyLoadedParts")

	basePath = basePath .. ".dynamicallyLoadedParts.dynamicallyLoadedPart(?)"

	schema:register(XMLValueType.STRING, basePath .. "#filename", "Filename to i3d file")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node in external i3d file", "0")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Link node", "0>")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Position")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rotationNode", "Rotation node", "node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation node rotation")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderParameter", "Shader parameter to apply")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableDynamicallyLoadedParts:onLoad(savegame)
	local spec = self.spec_dynamicallyLoadedParts
	spec.sharedLoadRequestIds = {}
	spec.parts = {}

	self.xmlFile:iterate("placeable.dynamicallyLoadedParts.dynamicallyLoadedPart", function (_, partKey)
		local filename = self.xmlFile:getValue(partKey .. "#filename")

		if filename ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)
			local args = {
				xmlFile = self.xmlFile,
				key = partKey,
				loadingTask = self:createLoadingTask(spec),
				filename = filename
			}
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onDynamicallyPartI3DLoaded, self, args)

			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		else
			Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part '%s'", partKey)
		end
	end)
end

function PlaceableDynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_dynamicallyLoadedParts
	local loadingTask = args.loadingTask
	local filename = args.filename
	local xmlFile = args.xmlFile
	local partKey = args.key

	if i3dNode ~= 0 then
		local node = xmlFile:getValue(partKey .. "#node", "0", i3dNode)

		if node == nil then
			Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart '%s'. Unable to find node in loaded i3d", partKey)

			return false
		end

		local linkNode = xmlFile:getValue(partKey .. "#linkNode", "0>", self.components, self.i3dMappings)

		if linkNode == nil then
			Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart '%s'. Unable to find linkNode", partKey)

			return false
		end

		local x, y, z = xmlFile:getValue(partKey .. "#position")

		if x ~= nil and y ~= nil and z ~= nil then
			setTranslation(node, x, y, z)
		end

		local rotationNode = xmlFile:getValue(partKey .. "#rotationNode", node, i3dNode)
		local rotX, rotY, rotZ = xmlFile:getValue(partKey .. "#rotation")

		if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
			setRotation(rotationNode, rotX, rotY, rotZ)
		end

		local shaderParameterName = xmlFile:getValue(partKey .. "#shaderParameterName")
		local sx, sy, sz, sw = xmlFile:getValue(partKey .. "#shaderParameter")

		if shaderParameterName ~= nil and sx ~= nil and sy ~= nil and sz ~= nil and sw ~= nil then
			setShaderParameter(node, shaderParameterName, sx, sy, sz, sw, false)
		end

		local objects = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, partKey, objects, i3dNode, nil)
		ObjectChangeUtil.setObjectChanges(objects, true, nil)
		link(linkNode, node)
		delete(i3dNode)

		local dynamicallyLoadedPart = {
			filename = filename,
			node = node
		}

		table.insert(spec.parts, dynamicallyLoadedPart)
	end

	self:finishLoadingTask(loadingTask)
end

function PlaceableDynamicallyLoadedParts:onDelete()
	local spec = self.spec_dynamicallyLoadedParts

	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end

		spec.sharedLoadRequestIds = nil
	end

	if spec.parts ~= nil then
		for _, part in pairs(spec.parts) do
			delete(part.node)
		end
	end
end
