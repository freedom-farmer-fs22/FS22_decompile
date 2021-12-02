ConnectionHoseType = nil
ConnectionHoseManager = {
	DEFAULT_HOSES_FILENAME = "data/shared/connectionHoses/connectionHoses.xml",
	xmlSchema = nil
}
local ConnectionHoseManager_mt = Class(ConnectionHoseManager, AbstractManager)

function ConnectionHoseManager.new(customMt)
	local self = AbstractManager.new(customMt or ConnectionHoseManager_mt)

	self:initDataStructures()

	ConnectionHoseManager.xmlSchema = XMLSchema.new("connectionHoses")

	ConnectionHoseManager:registerXMLPaths(ConnectionHoseManager.xmlSchema)

	return self
end

function ConnectionHoseManager:initDataStructures()
	self.xmlFiles = {}
	self.typeByName = {}
	ConnectionHoseType = self.typeByName
	self.basicHoses = {}
	self.sockets = {}
	self.sharedLoadRequestIds = {}
	self.modConnectionHosesToLoad = {}
end

function ConnectionHoseManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	ConnectionHoseManager:superClass().loadMapData(self)

	self.baseDirectory = baseDirectory

	self:loadConnectionHosesFromXML(ConnectionHoseManager.DEFAULT_HOSES_FILENAME, nil, self.baseDirectory)

	for i = #self.modConnectionHosesToLoad, 1, -1 do
		local modConnectionHoseToLoad = self.modConnectionHosesToLoad[i]

		self:loadConnectionHosesFromXML(modConnectionHoseToLoad.xmlFilename, modConnectionHoseToLoad.customEnvironment, modConnectionHoseToLoad.baseDirectory)

		self.modConnectionHosesToLoad[i] = nil
	end
end

function ConnectionHoseManager:unloadMapData()
	for _, entry in ipairs(self.basicHoses) do
		delete(entry.node)
	end

	for _, hoseType in pairs(self.typeByName) do
		for _, adapter in pairs(hoseType.adapters) do
			delete(adapter.node)
			delete(adapter.detachedNode)
		end

		for _, hose in pairs(hoseType.hoses) do
			delete(hose.materialNode)
		end
	end

	for _, entry in pairs(self.sockets) do
		delete(entry.node)
	end

	for i = 1, #self.sharedLoadRequestIds do
		local sharedLoadRequestId = self.sharedLoadRequestIds[i]

		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end

	for xmlFile, _ in pairs(self.xmlFiles) do
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end

	ConnectionHoseManager:superClass().unloadMapData(self)
end

function ConnectionHoseManager:addModConnectionHoses(xmlFilename, customEnvironment, baseDirectory)
	table.insert(self.modConnectionHosesToLoad, {
		xmlFilename = xmlFilename,
		customEnvironment = customEnvironment,
		baseDirectory = baseDirectory
	})
end

function ConnectionHoseManager:loadConnectionHosesFromXML(xmlFilename, customEnvironment, baseDirectory)
	Logging.info("Loading ConnectionHoses from '%s'", xmlFilename)

	local xmlFile = XMLFile.load("TempHoses", xmlFilename, ConnectionHoseManager.xmlSchema)

	if xmlFile ~= nil then
		self.xmlFiles[xmlFile] = true
		xmlFile.references = 1
		local i = 0

		while true do
			local hoseKey = string.format("connectionHoses.basicHoses.basicHose(%d)", i)

			if not xmlFile:hasProperty(hoseKey) then
				break
			end

			local filename = xmlFile:getValue(hoseKey .. "#filename")

			if filename ~= nil then
				xmlFile.references = xmlFile.references + 1
				filename = Utils.getFilename(filename, baseDirectory)
				local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.basicHoseI3DFileLoaded, self, {
					xmlFile,
					hoseKey
				})

				table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
			end

			i = i + 1
		end

		i = 0

		while true do
			local key = string.format("connectionHoses.connectionHoseTypes.connectionHoseType(%d)", i)

			if not xmlFile:hasProperty(key) then
				break
			end

			local name = xmlFile:getValue(key .. "#name")

			if name ~= nil then
				local hoseType = nil

				if self.typeByName[name:upper()] ~= nil then
					hoseType = self.typeByName[name:upper()]
				else
					if customEnvironment ~= nil then
						name = customEnvironment .. "." .. name
					end

					hoseType = {
						name = name,
						adapters = {},
						hoses = {}
					}
					self.typeByName[name:upper()] = hoseType
				end

				local j = 0

				while true do
					local adapterKey = string.format("%s.adapter(%d)", key, j)

					if not xmlFile:hasProperty(adapterKey) then
						break
					end

					local adapterName = xmlFile:getValue(adapterKey .. "#name", "DEFAULT")

					if customEnvironment ~= nil then
						adapterName = customEnvironment .. "." .. adapterName
					end

					local filename = xmlFile:getValue(adapterKey .. "#filename")

					if filename ~= nil then
						xmlFile.references = xmlFile.references + 1
						filename = Utils.getFilename(filename, baseDirectory)
						local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.adapterI3DFileLoaded, self, {
							hoseType,
							adapterName,
							xmlFile,
							adapterKey
						})

						table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
					end

					j = j + 1
				end

				hoseType.hoses = {}
				j = 0

				while true do
					local hoseKey = string.format("%s.material(%d)", key, j)

					if not xmlFile:hasProperty(hoseKey) then
						break
					end

					local hoseName = xmlFile:getValue(hoseKey .. "#name", "DEFAULT")

					if customEnvironment ~= nil then
						hoseName = customEnvironment .. "." .. hoseName
					end

					local filename = xmlFile:getValue(hoseKey .. "#filename")

					if filename ~= nil then
						xmlFile.references = xmlFile.references + 1
						filename = Utils.getFilename(filename, baseDirectory)
						local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.materialI3DFileLoaded, self, {
							hoseType,
							hoseName,
							xmlFile,
							hoseKey
						})

						table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
					end

					j = j + 1
				end
			end

			i = i + 1
		end

		i = 0

		while true do
			local socketKey = string.format("connectionHoses.sockets.socket(%d)", i)

			if not xmlFile:hasProperty(socketKey) then
				break
			end

			local name = xmlFile:getValue(socketKey .. "#name")

			if customEnvironment ~= nil then
				name = customEnvironment .. "." .. name
			end

			local filename = xmlFile:getValue(socketKey .. "#filename")

			if name ~= nil and filename ~= nil then
				xmlFile.references = xmlFile.references + 1
				filename = Utils.getFilename(filename, baseDirectory)
				local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.socketI3DFileLoaded, self, {
					name,
					xmlFile,
					socketKey
				})

				table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
			end

			i = i + 1
		end

		xmlFile.references = xmlFile.references - 1

		if xmlFile.references == 0 then
			self.xmlFiles[xmlFile] = nil

			xmlFile:delete()
		end
	end
end

function ConnectionHoseManager:basicHoseI3DFileLoaded(i3dNode, failedReason, args)
	local xmlFile, hoseKey = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = xmlFile:getValue(hoseKey .. "#node", nil, i3dNode)

		if node ~= nil then
			unlink(node)

			local entry = {
				node = node,
				startStraightening = xmlFile:getValue(hoseKey .. "#startStraightening", 2),
				endStraightening = xmlFile:getValue(hoseKey .. "#endStraightening", 2),
				minCenterPointAngle = xmlFile:getValue(hoseKey .. "#minCenterPointAngle", 90)
			}
			local length = xmlFile:getValue(hoseKey .. "#length")

			if length == nil then
				print(string.format("Warning: Missing length attribute in '%s'", hoseKey))
			end

			local realLength = xmlFile:getValue(hoseKey .. "#realLength")

			if realLength == nil then
				print(string.format("Warning: Missing realLength attribute in '%s'", hoseKey))
			end

			local diameter = xmlFile:getValue(hoseKey .. "#diameter")

			if diameter == nil then
				print(string.format("Warning: Missing diameter attribute in '%s'", hoseKey))
			end

			if length ~= nil and realLength ~= nil and diameter ~= nil then
				entry.length = length
				entry.realLength = realLength
				entry.diameter = diameter

				table.insert(self.basicHoses, entry)
			end
		end

		delete(i3dNode)
	end

	xmlFile.references = xmlFile.references - 1

	if xmlFile.references == 0 then
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end
end

function ConnectionHoseManager:adapterI3DFileLoaded(i3dNode, failedReason, args)
	local hoseType, adapterName, xmlFile, adapterKey = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = xmlFile:getValue(adapterKey .. "#node", nil, i3dNode)
		local hoseReferenceNode = getChildAt(node, 0)

		unlink(node)

		local detachedNode = xmlFile:getValue(adapterKey .. "#detachedNode", nil, i3dNode)

		if detachedNode ~= nil then
			unlink(detachedNode)
		end

		if hoseReferenceNode ~= 0 then
			local entry = {
				node = node,
				detachedNode = detachedNode,
				hoseReferenceNode = hoseReferenceNode
			}
			hoseType.adapters[adapterName:upper()] = entry
		else
			print(string.format("Warning: Missing hose reference node as child from adapter '%s' in connection type '%s'", adapterName, hoseType.name))
		end

		delete(i3dNode)
	end

	xmlFile.references = xmlFile.references - 1

	if xmlFile.references == 0 then
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end
end

function ConnectionHoseManager:materialI3DFileLoaded(i3dNode, failedReason, args)
	local hoseType, hoseName, xmlFile, hoseKey = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local materialNode = xmlFile:getValue(hoseKey .. "#materialNode", nil, i3dNode)

		unlink(materialNode)

		if materialNode ~= nil then
			local entry = {
				materialNode = materialNode,
				defaultColor = xmlFile:getValue(hoseKey .. "#defaultColor", nil, true),
				uvOffset = xmlFile:getValue(hoseKey .. "#uvOffset", nil, true),
				uvScale = xmlFile:getValue(hoseKey .. "#uvScale", nil, true)
			}
			hoseType.hoses[hoseName:upper()] = entry
		end

		delete(i3dNode)
	end

	xmlFile.references = xmlFile.references - 1

	if xmlFile.references == 0 then
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end
end

function ConnectionHoseManager:socketI3DFileLoaded(i3dNode, failedReason, args)
	local name, xmlFile, socketKey = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = xmlFile:getValue(socketKey .. "#node", nil, i3dNode)

		if node ~= nil then
			unlink(node)

			local entry = {
				node = node,
				referenceNode = xmlFile:getValue(socketKey .. "#referenceNode"),
				shaderParameterColor = xmlFile:getValue(socketKey .. "#shaderParameterColor"),
				caps = {}
			}
			local j = 0

			while true do
				local capKey = string.format(socketKey .. ".cap(%d)", j)

				if not xmlFile:hasProperty(capKey) then
					break
				end

				local cap = {
					node = xmlFile:getValue(capKey .. "#node")
				}

				if cap.node ~= nil then
					cap.openedRotation = xmlFile:getValue(capKey .. "#openedRotation", nil, true)
					cap.closedRotation = xmlFile:getValue(capKey .. "#closedRotation", nil, true)
					cap.openedVisibility = xmlFile:getValue(capKey .. "#openedVisibility", true)
					cap.closedVisibility = xmlFile:getValue(capKey .. "#closedVisibility", true)

					table.insert(entry.caps, cap)
				end

				j = j + 1
			end

			if self.sockets[name:upper()] == nil then
				self.sockets[name:upper()] = entry
			else
				Logging.xmlError(xmlFile, "Socket '%s' already exists", name)
			end
		end

		delete(i3dNode)
	end

	xmlFile.references = xmlFile.references - 1

	if xmlFile.references == 0 then
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end
end

function ConnectionHoseManager:getHoseTypeByName(typeName, customEnvironment)
	if typeName == nil then
		return nil
	end

	if customEnvironment ~= nil then
		local customTypeName = (customEnvironment .. "." .. typeName):upper()

		if self.typeByName[customTypeName] ~= nil then
			return self.typeByName[customTypeName]
		end
	end

	return self.typeByName[typeName:upper()]
end

function ConnectionHoseManager:getHoseAdapterByName(hoseType, adapterName, customEnvironment)
	if hoseType == nil or adapterName == nil then
		return nil
	end

	if customEnvironment ~= nil then
		local customTypeName = (customEnvironment .. "." .. adapterName):upper()

		if hoseType.adapters[customTypeName] ~= nil then
			return hoseType.adapters[customTypeName]
		end
	end

	return hoseType.adapters[adapterName:upper()]
end

function ConnectionHoseManager:getHoseMaterialByName(hoseType, materialName, customEnvironment)
	if hoseType == nil or materialName == nil then
		return nil
	end

	if customEnvironment ~= nil then
		local customTypeName = (customEnvironment .. "." .. materialName):upper()

		if hoseType.hoses[customTypeName] ~= nil then
			return hoseType.hoses[customTypeName]
		end
	end

	return hoseType.hoses[materialName:upper()]
end

function ConnectionHoseManager:getSocketByName(socketName, customEnvironment)
	if socketName == nil then
		return nil
	end

	if customEnvironment ~= nil then
		local customTypeName = (customEnvironment .. "." .. socketName):upper()

		if self.sockets[customTypeName] ~= nil then
			return self.sockets[customTypeName]
		end
	end

	return self.sockets[socketName:upper()]
end

function ConnectionHoseManager:getClonedAdapterNode(typeName, adapterName, customEnvironment, detached)
	local hoseType = self:getHoseTypeByName(typeName, customEnvironment)

	if hoseType ~= nil then
		local adapter = self:getHoseAdapterByName(hoseType, adapterName, customEnvironment)

		if adapter ~= nil then
			if not detached then
				local adapterNodeClone = clone(adapter.node, true)
				local hoseReferenceNodeClone = getChildAt(adapterNodeClone, 0)

				return adapterNodeClone, hoseReferenceNodeClone
			elseif adapter.detachedNode ~= nil then
				return clone(adapter.detachedNode, true)
			end
		end
	end

	return nil
end

function ConnectionHoseManager:getClonedHoseNode(typeName, hoseName, length, diameter, color, customEnvironment)
	local hoseType = self:getHoseTypeByName(typeName, customEnvironment)

	if hoseType ~= nil then
		local material = self:getHoseMaterialByName(hoseType, hoseName, customEnvironment)

		if material ~= nil then
			local hoseNodeClone, realLength, startStraightening, endStraightening, minCenterPointAngle, closestDiameter = self:getClonedBasicHose(length, diameter)

			if hoseNodeClone ~= nil then
				local mat = getMaterial(material.materialNode, 0)

				setMaterial(hoseNodeClone, mat, 0)

				if color ~= nil or material.defaultColor ~= nil then
					for i = 1, 8 do
						local parameter = string.format("colorMat%d", i - 1)

						if getHasShaderParameter(hoseNodeClone, parameter) then
							local r, g, b, _ = unpack(color or material.defaultColor)
							local _, _, _, w = getShaderParameter(hoseNodeClone, parameter)

							setShaderParameter(hoseNodeClone, parameter, r, g, b, w, false)
						end
					end
				end

				local _, _, z, w = getShaderParameter(hoseNodeClone, "lengthAndDiameter")

				setShaderParameter(hoseNodeClone, "lengthAndDiameter", realLength, diameter / closestDiameter, z, w, false)

				local scaleFactorX = 1
				local scaleFactorY = 1

				if material.uvScale ~= nil then
					scaleFactorY = material.uvScale[2]
					scaleFactorX = material.uvScale[1]
				end

				local y = nil
				_, y, z, w = getShaderParameter(hoseNodeClone, "uvScale")

				setShaderParameter(hoseNodeClone, "uvScale", length / realLength * scaleFactorX, y * scaleFactorY, z, w, false)

				if material.uvOffset ~= nil then
					_, _, z, w = getShaderParameter(hoseNodeClone, "offsetUV")

					setShaderParameter(hoseNodeClone, "offsetUV", material.uvOffset[1], material.uvOffset[2], z, w, false)
				end

				return hoseNodeClone, startStraightening, endStraightening, minCenterPointAngle
			end
		end
	end
end

function ConnectionHoseManager:getClonedBasicHose(length, diameter)
	local minDiameterDiff = math.huge
	local closestDiameter = math.huge

	for _, hose in pairs(self.basicHoses) do
		local diff = math.abs(hose.diameter - diameter)

		if diff < minDiameterDiff then
			minDiameterDiff = diff
			closestDiameter = hose.diameter
		end
	end

	local foundHoses = {}

	for _, hose in pairs(self.basicHoses) do
		local diff = math.abs(hose.diameter - closestDiameter)

		if diff <= 0.0001 then
			table.insert(foundHoses, hose)
		end
	end

	local minLengthDiff = math.huge
	local foundHose = nil

	for _, hose in pairs(foundHoses) do
		local diff = math.abs(hose.length - length)

		if diff < minLengthDiff then
			minLengthDiff = diff
			foundHose = hose
		end
	end

	if foundHose ~= nil then
		return clone(foundHose.node, true), foundHose.realLength, foundHose.startStraightening, foundHose.endStraightening, foundHose.minCenterPointAngle, closestDiameter
	end
end

function ConnectionHoseManager:linkSocketToNode(socketName, node, customEnvironment, socketColor)
	local socket = self:getSocketByName(socketName, customEnvironment)

	if socket ~= nil and node ~= nil then
		local linkedSocket = {
			node = clone(socket.node, true)
		}
		linkedSocket.referenceNode = I3DUtil.indexToObject(linkedSocket.node, socket.referenceNode)
		linkedSocket.caps = {}

		for _, cap in ipairs(socket.caps) do
			local clonedCap = {}

			for i, v in pairs(cap) do
				clonedCap[i] = v
			end

			clonedCap.node = I3DUtil.indexToObject(linkedSocket.node, clonedCap.node)

			table.insert(linkedSocket.caps, clonedCap)
		end

		if socket.shaderParameterColor ~= nil and socketColor ~= nil and #socketColor >= 3 then
			I3DUtil.setShaderParameterRec(linkedSocket.node, socket.shaderParameterColor, socketColor[1], socketColor[2], socketColor[3], nil)
		end

		link(node, linkedSocket.node)
		self:closeSocket(linkedSocket)

		return linkedSocket
	end
end

function ConnectionHoseManager:getSocketTarget(socket, defaultTarget)
	if socket ~= nil and socket.referenceNode ~= nil then
		return socket.referenceNode
	end

	return defaultTarget
end

function ConnectionHoseManager:openSocket(socket)
	if socket ~= nil and #socket.caps > 0 then
		for _, cap in ipairs(socket.caps) do
			if cap.openedRotation ~= nil then
				setRotation(cap.node, unpack(cap.openedRotation))
			end

			setVisibility(cap.node, cap.openedVisibility)
		end
	end
end

function ConnectionHoseManager:closeSocket(socket)
	if socket ~= nil and #socket.caps > 0 then
		for _, cap in ipairs(socket.caps) do
			if cap.openedRotation ~= nil then
				setRotation(cap.node, unpack(cap.closedRotation))
			end

			setVisibility(cap.node, cap.closedVisibility)
		end
	end
end

function ConnectionHoseManager:registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "connectionHoses.basicHoses.basicHose(?)#filename", "I3d filename")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.basicHoses.basicHose(?)#node", "Path to hose node")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#startStraightening", "Straightening factor on start side", 2)
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#endStraightening", "Straightening factor on end side", 2)
	schema:register(XMLValueType.ANGLE, "connectionHoses.basicHoses.basicHose(?)#minCenterPointAngle", "Min. bending angle at the center of the hose", 90)
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#length", "Reference length of hose")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#realLength", "Real length of hose in i3d")
	schema:register(XMLValueType.FLOAT, "connectionHoses.basicHoses.basicHose(?)#diameter", "Diameter of hose")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?)#name", "Name of type")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#name", "Name of adapter")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#node", "Adapter node in i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).adapter(?)#detachedNode", "Detached adapter node in i3d file")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#name", "Name of material")
	schema:register(XMLValueType.STRING, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#materialNode", "Material node in i3d file")
	schema:register(XMLValueType.VECTOR_4, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#defaultColor", "Default color")
	schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvOffset", "UV offset")
	schema:register(XMLValueType.VECTOR_2, "connectionHoses.connectionHoseTypes.connectionHoseType(?).material(?)#uvScale", "UV scale")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#name", "Socket name")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, "connectionHoses.sockets.socket(?)#node", "Socket node in i3d")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#referenceNode", "Index of reference node inside socket")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?)#shaderParameterColor", "Name of coloring shader parameter")
	schema:register(XMLValueType.STRING, "connectionHoses.sockets.socket(?).cap(?)#node", "Index of cap node inside socket")
	schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#openedRotation", "Opened rotation")
	schema:register(XMLValueType.VECTOR_ROT, "connectionHoses.sockets.socket(?).cap(?)#closedRotation", "Closed rotation")
	schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#openedVisibility", "Opened visibility", true)
	schema:register(XMLValueType.BOOL, "connectionHoses.sockets.socket(?).cap(?)#closedVisibility", "Closed visibility", true)
end

g_connectionHoseManager = ConnectionHoseManager.new()
