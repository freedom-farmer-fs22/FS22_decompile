Bale = {
	INTERACTION_RADIUS = 3
}

source("dataS/scripts/events/BaleOpenEvent.lua")

local Bale_mt = Class(Bale, MountableObject)

InitStaticObjectClass(Bale, "Bale", ObjectIds.OBJECT_BALE)
g_xmlManager:addInitSchemaFunction(function ()
	local savegameSchema = ItemSystem.xmlSchemaSavegame
	local basePath = "items.item(?)"

	Bale.registerSavegameXMLPaths(savegameSchema, basePath)
end)

function Bale.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to bale xml file")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Bale position")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Bale rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current bale fill level")
	schema:register(XMLValueType.STRING, basePath .. "#fillType", "Current bale fill type")
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of owner farm")
	schema:register(XMLValueType.STRING, basePath .. ".textures#wrapDiffuse", "Current wrap diffuse file")
	schema:register(XMLValueType.STRING, basePath .. ".textures#wrapNormal", "Current wrap normal file")
	schema:register(XMLValueType.BOOL, basePath .. ".fermentation#isFermenting", "Bale is fermenting")
	schema:register(XMLValueType.FLOAT, basePath .. ".fermentation#time", "Current fermentation time")
	schema:register(XMLValueType.FLOAT, basePath .. "#wrappingState", "Current wrapping state")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#wrappingColor", "Wrapping color")
	schema:register(XMLValueType.FLOAT, basePath .. "#valueScale", "Bale value scale")
	schema:register(XMLValueType.BOOL, basePath .. "#isMissionBale", "Bale was produced in mission context", false)
end

function Bale.new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = Bale_mt
	end

	local self = MountableObject.new(isServer, isClient, mt)
	self.forcedClipDistance = 300

	registerObjectClassName(self, "Bale")

	self.fillType = FillType.STRAW
	self.fillLevel = 0
	self.supportsWrapping = false
	self.wrappingState = 0
	self.wrappingColor = {
		1,
		1,
		1,
		1
	}
	self.baleValueScale = 1
	self.defaultMass = 0.25
	self.isFermenting = false
	self.fermentingPercentage = 0
	self.canBeSold = true
	self.allowPickup = true
	self.isMissionBale = false
	self.activatable = BaleActivatable.new(self)
	self.fillTypeDirtyFlag = self:getNextDirtyFlag()
	self.fillLevelDirtyFlag = self:getNextDirtyFlag()
	self.texturesDirtyFlag = self:getNextDirtyFlag()
	self.wrapStateDirtyFlag = self:getNextDirtyFlag()
	self.wrapColorDirtyFlag = self:getNextDirtyFlag()
	self.fermentingDirtyFlag = self:getNextDirtyFlag()
	self.obstacleNodeId = nil
	self.sharedLoadRequestId = nil

	g_currentMission:addLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, self)

	return self
end

function Bale:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

	if self.isFermenting then
		g_baleManager:removeFermentation(self)
	end

	if self.obstacleNodeId ~= nil then
		g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)

		self.obstacleNodeId = nil
	end

	g_currentMission:removeLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, self)
	unregisterObjectClassName(self)
	g_currentMission.itemSystem:removeItemToSave(self)
	Bale:superClass().delete(self)
end

function Bale:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

			self:setFillType(fillType)
		end

		if streamReadBool(streamId) then
			self:setFillLevel(streamReadFloat32(streamId))
		end

		if streamReadBool(streamId) then
			if streamReadBool(streamId) then
				local wrapDiffuse = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

				self:setWrapTextures(wrapDiffuse, nil)
			end

			if streamReadBool(streamId) then
				local wrapNormal = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

				self:setWrapTextures(nil, wrapNormal)
			end
		end

		if streamReadBool(streamId) then
			self:setWrappingState(streamReadUInt8(streamId) / 255, false)
		end

		if streamReadBool(streamId) then
			local r = streamReadFloat32(streamId)
			local g = streamReadFloat32(streamId)
			local b = streamReadFloat32(streamId)
			local a = streamReadFloat32(streamId)

			self:setColor(r, g, b, a)
		end

		if streamReadBool(streamId) then
			self.isFermenting = streamReadBool(streamId)
			self.fermentingPercentage = streamReadUInt8(streamId) / 255
		end
	end

	Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function Bale:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.fillTypeDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.fillLevel)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.texturesDirtyFlag) ~= 0) then
			if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
			end

			if streamWriteBool(streamId, self.wrapNormal ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
			end
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapStateDirtyFlag) ~= 0) then
			streamWriteUInt8(streamId, MathUtil.clamp(self.wrappingState * 255, 0, 255))
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapColorDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.wrappingColor[1])
			streamWriteFloat32(streamId, self.wrappingColor[2])
			streamWriteFloat32(streamId, self.wrappingColor[3])
			streamWriteFloat32(streamId, self.wrappingColor[4])
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.fermentingDirtyFlag) ~= 0) then
			streamWriteBool(streamId, self.isFermenting)
			streamWriteUInt8(streamId, MathUtil.clamp(self.fermentingPercentage * 255, 0, 255))
		end
	end

	Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end

function Bale:readStream(streamId, connection)
	local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	if self.nodeId == 0 then
		self:loadFromConfigXML(xmlFilename)
	end

	local fillLevel = streamReadFloat32(streamId)

	self:setFillLevel(fillLevel)

	local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:setFillType(fillType)

	if streamReadBool(streamId) then
		local wrapDiffuse = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		self:setWrapTextures(wrapDiffuse, nil)
	end

	if streamReadBool(streamId) then
		local wrapNormal = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		self:setWrapTextures(nil, wrapNormal)
	end

	Bale:superClass().readStream(self, streamId, connection)
	g_currentMission.itemSystem:addItemToSave(self)

	self.baleValueScale = streamReadFloat32(streamId)

	self:setWrappingState(streamReadUInt8(streamId) / 255, false)

	local r = streamReadFloat32(streamId)
	local g = streamReadFloat32(streamId)
	local b = streamReadFloat32(streamId)
	local a = streamReadFloat32(streamId)

	self:setColor(r, g, b, a)

	self.isFermenting = streamReadBool(streamId)

	if self.isFermenting then
		self.fermentingPercentage = streamReadUInt8(streamId) / 255
	else
		self.fermentingPercentage = 0
	end
end

function Bale:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
	streamWriteFloat32(streamId, self.fillLevel)
	streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)

	if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
	end

	if streamWriteBool(streamId, self.wrapNormal ~= nil) then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
	end

	Bale:superClass().writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.baleValueScale)
	streamWriteUInt8(streamId, MathUtil.clamp(self.wrappingState * 255, 0, 255))
	streamWriteFloat32(streamId, self.wrappingColor[1])
	streamWriteFloat32(streamId, self.wrappingColor[2])
	streamWriteFloat32(streamId, self.wrappingColor[3])
	streamWriteFloat32(streamId, self.wrappingColor[4])

	if streamWriteBool(streamId, self.isFermenting) then
		streamWriteUInt8(streamId, MathUtil.clamp(self.fermentingPercentage * 255, 0, 255))
	end
end

function Bale:mount(object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItemToSave(self)
	Bale:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
end

function Bale:unmount()
	if Bale:superClass().unmount(self) then
		g_currentMission.itemSystem:addItemToSave(self)
		self:setReducedComponentMass(false)

		return true
	end

	return false
end

function Bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
	g_currentMission.itemSystem:removeItemToSave(self)
	Bale:superClass().mountKinematic(self, object, node, x, y, z, rx, ry, rz)
end

function Bale:unmountKinematic()
	if Bale:superClass().unmountKinematic(self) then
		g_currentMission.itemSystem:addItemToSave(self)
		self:setReducedComponentMass(false)

		return true
	end

	return false
end

function Bale:unmountDynamic(isDelete)
	Bale:superClass().unmountDynamic(self, isDelete)
	self:setReducedComponentMass(false)
end

function Bale:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)
	local baleRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId
	local baleId = getChildAt(baleRoot, 0)

	link(getRootNode(), baleId)
	delete(baleRoot)
	self:setNodeId(baleId)
end

function Bale:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz)
	if xmlFilename == nil or not fileExists(xmlFilename) then
		return false
	end

	local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
	self.xmlFilename = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFilename)
	self.i3dFilename = xmlFile:getValue("bale.filename")

	if self.i3dFilename ~= nil then
		self.i3dFilename = Utils.getFilename(self.i3dFilename, self.baseDirectory)

		self:createNode(self.i3dFilename)

		if x ~= nil and y ~= nil and z ~= nil and ry ~= nil and ry ~= nil and rz ~= nil then
			setTranslation(self.nodeId, x, y, z)
			setRotation(self.nodeId, rx, ry, rz)
		end

		if not self:loadBaleAttributesFromXML(xmlFile) then
			return false
		end
	end

	xmlFile:delete()
	g_currentMission.itemSystem:addItemToSave(self)
	g_currentMission.aiSystem:addObstacle(self.nodeId, nil, , , , , , )

	self.obstacleNodeId = self.nodeId

	return true
end

function Bale:loadBaleAttributesFromXML(xmlFile)
	local triggerId = xmlFile:getValue("bale.mountableObject#triggerNode", nil, self.nodeId)
	local forceAcceleration = xmlFile:getValue("bale.mountableObject#forceAcceleration", 4)
	local forceLimitScale = xmlFile:getValue("bale.mountableObject#forceLimitScale", 1)
	local axisFreeY = xmlFile:getValue("bale.mountableObject#axisFreeY", false)
	local axisFreeX = xmlFile:getValue("bale.mountableObject#axisFreeX", false)

	self:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)

	self.fillTypes = {}

	Bale.loadFillTypesFromXML(self.fillTypes, xmlFile, self.baseDirectory)

	self.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
	self.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
	self.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
	self.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
	self.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)
	self.centerOffsetZ = 0
	self.centerOffsetY = 0
	self.centerOffsetX = 0
	self.uvId = xmlFile:getValue("bale.uvId", "DEFAULT")
	self.meshes, self.tensionBeltMeshes = Bale.loadVisualMeshesFromXML(self.nodeId, xmlFile, self.baseDirectory)

	return true
end

function Bale:getBaleMatchesSize(diameter, width, height, length)
	if self.isRoundbale then
		return diameter == self.diameter and width == self.width
	else
		return width == self.width and height == self.height and length == self.length
	end
end

function Bale:getSupportsWrapping()
	return self.supportsWrapping
end

function Bale:loadFromXMLFile(xmlFile, key, resetVehicles)
	local x, y, z = xmlFile:getValue(key .. "#position")
	local rx, ry, rz = xmlFile:getValue(key .. "#rotation")

	if x == nil or y == nil or z == nil or rx == nil or ry == nil or rz == nil then
		return false
	end

	local xmlFilename = xmlFile:getValue(key .. "#filename")

	if xmlFilename == nil then
		return false
	end

	xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFilename)

	if not fileExists(xmlFilename) then
		return false
	end

	if not self:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz) then
		return false
	end

	local attributes = {}

	Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
	self:applyBaleAttributes(attributes)

	return true
end

function Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
	attributes.farmId = xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE)
	attributes.fillLevel = xmlFile:getValue(key .. "#fillLevel")
	attributes.fillTypeName = xmlFile:getValue(key .. "#fillType")
	local wrapDiffuse = xmlFile:getValue(key .. ".textures#wrapDiffuse")

	if wrapDiffuse ~= nil then
		attributes.wrapDiffuse = NetworkUtil.convertFromNetworkFilename(wrapDiffuse)
	end

	local wrapNormal = xmlFile:getValue(key .. ".textures#wrapNormal")

	if wrapNormal ~= nil then
		attributes.wrapNormal = NetworkUtil.convertFromNetworkFilename(wrapNormal)
	end

	attributes.isFermenting = xmlFile:getValue(key .. ".fermentation#isFermenting", false)
	attributes.fermentationTime = xmlFile:getValue(key .. ".fermentation#time", 0)
	attributes.wrappingState = xmlFile:getValue(key .. "#wrappingState", 0)
	attributes.wrappingColor = xmlFile:getValue(key .. "#wrappingColor", {
		1,
		1,
		1,
		1
	}, true)
	attributes.baleValueScale = xmlFile:getValue(key .. "#valueScale", 1)
	attributes.isMissionBale = xmlFile:getValue(key .. "#isMissionBale", false)

	return true
end

function Bale:getBaleAttributes()
	local attributes = {
		xmlFilename = self.xmlFilename,
		farmId = self:getOwnerFarmId(),
		fillLevel = self.fillLevel,
		fillType = self.fillType,
		wrapDiffuse = self.wrapDiffuse,
		wrapNormal = self.wrapNormal,
		supportsWrapping = self.supportsWrapping,
		wrappingState = self.wrappingState,
		wrappingColor = self.wrappingColor,
		baleValueScale = self.baleValueScale,
		isMissionBale = self.isMissionBale,
		isFermenting = self.isFermenting
	}

	if self.isFermenting then
		attributes.fermentationTime = g_baleManager:getFermentationTime(self) or 0
	end

	return attributes
end

function Bale:applyBaleAttributes(attributes)
	self:setOwnerFarmId(attributes.farmId or AccessHandler.EVERYONE)
	self:setFillLevel(attributes.fillLevel or self.fillLevel)

	if attributes.fillTypeName ~= nil then
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName)

		self:setFillType(fillTypeIndex or self.fillType)
	elseif attributes.fillType ~= nil then
		self:setFillType(attributes.fillType)
	end

	self:setWrapTextures(attributes.wrapDiffuse, attributes.wrapNormal)
	self:setWrappingState(attributes.wrappingState, false)
	self:setColor(unpack(attributes.wrappingColor))

	self.baleValueScale = attributes.baleValueScale or self.baleValueScale
	self.isMissionBale = Utils.getNoNil(attributes.isMissionBale, self.isMissionBale)

	if self.isServer and attributes.isFermenting then
		local fillTypeInfo = self:getFillTypeInfo(self.fillType)

		if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
			local maxTime = fillTypeInfo.fermenting.time * 86400000

			if self.isMissionBale then
				maxTime = 0
			end

			g_baleManager:registerFermentation(self, attributes.fermentationTime, maxTime)

			self.isFermenting = true

			self:raiseDirtyFlags(self.fermentingDirtyFlag)
		end
	end

	return true
end

function Bale:saveToXMLFile(xmlFile, key)
	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)

	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.xmlFilename)))
	xmlFile:setValue(key .. "#position", x, y, z)
	xmlFile:setValue(key .. "#rotation", xRot, yRot, zRot)
	xmlFile:setValue(key .. "#valueScale", self.baleValueScale)
	xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
	xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
	xmlFile:setValue(key .. "#isMissionBale", self.isMissionBale)
	xmlFile:setValue(key .. "#wrappingState", self.wrappingState)
	xmlFile:setValue(key .. "#wrappingColor", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], self.wrappingColor[4])

	if self.wrapDiffuse ~= nil then
		xmlFile:setValue(key .. ".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapDiffuse)))
	end

	if self.wrapNormal ~= nil then
		xmlFile:setValue(key .. ".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapNormal)))
	end

	if self.isFermenting then
		xmlFile:setValue(key .. ".fermentation#isFermenting", true)
		xmlFile:setValue(key .. ".fermentation#time", g_baleManager:getFermentationTime(self))
	end
end

function Bale:removeFromPhysics()
	removeFromPhysics(self.nodeId)
end

function Bale:getValue()
	local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType)

	return self.fillLevel * pricePerLiter * self.baleValueScale
end

function Bale:getMass()
	return getMass(self.nodeId)
end

function Bale:getDefaultMass()
	return self.defaultMass
end

function Bale:getFillType()
	return self.fillType
end

function Bale:setReducedComponentMass(state)
	if state then
		setMass(self.nodeId, 0.1)
	else
		setMass(self.nodeId, self.defaultMass)
	end
end

function Bale:getAllowComponentMassReduction()
	return true
end

function Bale:setFillType(fillTypeIndex, fillBale)
	Bale.setFillTypeTextures(self.nodeId, self.fillTypes, fillTypeIndex)

	self.fillType = fillTypeIndex
	self.supportsWrapping = false
	local fillTypeInfo = self:getFillTypeInfo(self.fillType)

	if fillTypeInfo ~= nil then
		self.supportsWrapping = fillTypeInfo.supportsWrapping

		setMass(self.nodeId, fillTypeInfo.mass)

		self.defaultMass = fillTypeInfo.mass

		if self.isServer and fillTypeInfo.fermenting ~= nil and not fillTypeInfo.fermenting.requiresWrapping then
			if self.isFermenting then
				g_baleManager:removeFermentation(self)
			end

			local maxTime = fillTypeInfo.fermenting.time * 86400000

			g_baleManager:registerFermentation(self, 0, maxTime)

			self.isFermenting = true

			self:raiseDirtyFlags(self.fermentingDirtyFlag)
		end

		if fillBale == true then
			self:setFillLevel(fillTypeInfo.capacity)
		end
	end

	Bale.updateVisualMeshVisibility(self.meshes, self.fillType, self.wrappingState ~= 0)

	if self.isServer then
		self:raiseDirtyFlags(self.fillTypeDirtyFlag)
	end
end

function Bale:getFillLevel()
	return self.fillLevel
end

function Bale:setFillLevel(fillLevel)
	local fillTypeInfo = self:getFillTypeInfo(self.fillType)

	if fillTypeInfo ~= nil then
		fillLevel = math.min(fillLevel, fillTypeInfo.capacity)
	end

	self.fillLevel = fillLevel

	if self.isServer then
		self:raiseDirtyFlags(self.fillLevelDirtyFlag)
	end
end

function Bale:getFillTypeInfo(fillTypeIndex)
	for i = 1, #self.fillTypes do
		if self.fillTypes[i].fillTypeIndex == self.fillType then
			return self.fillTypes[i]
		end
	end

	return nil
end

function Bale:setCanBeSold(canBeSold)
	self.canBeSold = canBeSold
end

function Bale:getCanBeSold()
	return self.canBeSold
end

function Bale:setWrappingState(wrappingState, updateFermentation)
	if self.isServer and self.wrappingState ~= wrappingState then
		self:raiseDirtyFlags(self.wrapStateDirtyFlag)
	end

	self.wrappingState = wrappingState

	for i = 1, #self.meshes do
		local meshData = self.meshes[i]
		local visibility = (meshData.supportsWrapping or wrappingState == 0) and meshData.fillTypeVisibility

		setVisibility(meshData.node, visibility)

		if visibility then
			setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
		end
	end

	if self.isServer and updateFermentation ~= false and self.wrappingState >= 1 then
		local fillTypeInfo = self:getFillTypeInfo(self.fillType)

		if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil and fillTypeInfo.fermenting.requiresWrapping and not self.isFermenting then
			local maxTime = fillTypeInfo.fermenting.time * 86400000

			if self.isMissionBale then
				maxTime = 0
			end

			g_baleManager:registerFermentation(self, 0, maxTime)

			self.isFermenting = true

			self:raiseDirtyFlags(self.fermentingDirtyFlag)
		end
	end

	if wrappingState > 0 then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	else
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

function Bale:setWrapTextures(diffuse, normal)
	self.wrapDiffuse = diffuse or self.wrapDiffuse
	self.wrapNormal = normal or self.wrapNormal

	for i = 1, #self.meshes do
		local meshData = self.meshes[i]
		local materialId = getMaterial(meshData.node, 0)

		if self.wrapDiffuse ~= nil then
			if fileExists(self.wrapDiffuse) then
				materialId = setMaterialCustomMapFromFile(materialId, "wrapDiffuseMap", self.wrapDiffuse, false, true, false)
			else
				Logging.warning("Unknown bale wrapping texture '%s'. Using default texture.", self.wrapDiffuse)
			end
		end

		if self.wrapNormal ~= nil then
			if fileExists(self.wrapNormal) then
				materialId = setMaterialCustomMapFromFile(materialId, "wrapNormalMap", self.wrapNormal, false, false, false)
			else
				Logging.warning("Unknown bale wrapping texture '%s'. Using default texture.", self.wrapNormal)
			end
		end

		setMaterial(meshData.node, materialId, 0)
		setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
		setShaderParameter(meshData.node, "colorScale", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], self.wrappingColor[4], false)
	end

	if self.isServer and (diffuse ~= nil or normal ~= nil) then
		self:raiseDirtyFlags(self.texturesDirtyFlag)
	end
end

function Bale:setColor(r, g, b, a)
	a = a or 1
	b = b or 1
	g = g or 1
	r = r or 1

	if r ~= self.wrappingColor[1] or g ~= self.wrappingColor[2] or b ~= self.wrappingColor[3] or a ~= self.wrappingColor[4] then
		if self.isServer then
			self:raiseDirtyFlags(self.wrapColorDirtyFlag)
		end

		self.wrappingColor[1] = r
		self.wrappingColor[2] = g
		self.wrappingColor[3] = b
		self.wrappingColor[4] = a

		for i = 1, #self.meshes do
			local meshData = self.meshes[i]

			if getHasShaderParameter(meshData.node, "colorScale") then
				setShaderParameter(meshData.node, "colorScale", r, g, b, a, false)
			end
		end
	end
end

function Bale:setIsMissionBale(state)
	self.isMissionBale = state
end

function Bale:getMeshNodes()
	return self.tensionBeltMeshes
end

function Bale:getSupportsTensionBelts()
	return true
end

function Bale:getTensionBeltNodeId()
	return self.nodeId
end

function Bale:getBaleSupportsBaleLoader()
	return true
end

function Bale:getAllowPickup()
	return self.allowPickup
end

function Bale:getIsFermenting()
	return self.isFermenting
end

function Bale:getFermentingPercentage()
	if self.isFermenting then
		return self.fermentingPercentage
	end

	return 0
end

function Bale:onFermentationUpdate(percentage)
	self.fermentingPercentage = percentage

	self:raiseDirtyFlags(self.fermentingDirtyFlag)
end

function Bale:onFermentationEnd()
	if self.isServer and self.isFermenting then
		local fillTypeInfo = self:getFillTypeInfo(self.fillType)

		if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
			self:setFillType(fillTypeInfo.fermenting.outputFillTypeIndex)
		end

		self.isFermenting = false

		self:raiseDirtyFlags(self.fermentingDirtyFlag)
	end
end

function Bale:getCanBeOpened()
	if self.wrappingState <= 0 then
		return false
	end

	if self.isFermenting then
		return false
	end

	return true
end

function Bale:getInteractionPosition()
	if not g_currentMission.controlPlayer then
		return
	end

	return getWorldTranslation(g_currentMission.player.rootNode)
end

function Bale:getCanInteract()
	local px, py, pz = self:getInteractionPosition()

	if px ~= nil then
		local x, y, z = getWorldTranslation(self.nodeId)
		local distance = MathUtil.vector3Length(x - px, y - py, z - pz)

		return distance <= Bale.INTERACTION_RADIUS
	end

	return false
end

function Bale:open()
	self:setWrappingState(0)
end

function Bale:showInfo(box)
	local fillType = self:getFillType()
	local fillLevel = self:getFillLevel()
	local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)

	box:addLine(fillTypeDesc.title, g_i18n:formatVolume(fillLevel, 0))

	if self:getIsFermenting() then
		box:addLine(g_i18n:getText("info_fermenting"), string.format("%d%%", self:getFermentingPercentage() * 100))
	end

	box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(self:getMass()))
end

function Bale.createDummyBale(xmlFilename, fillTypeIndex)
	local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
	local baleId, baleRoot, sharedLoadRequestId = nil
	local i3dFilename = xmlFile:getValue("bale.filename")

	if i3dFilename ~= nil then
		local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
		i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)
		baleRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)

		if baleRoot ~= 0 then
			baleId = getChildAt(baleRoot, 0)

			setRigidBodyType(baleId, RigidBodyType.NONE)
			unlink(baleId)

			local fillTypes = {}

			Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
			Bale.setFillTypeTextures(baleId, fillTypes, fillTypeIndex)

			local meshes = Bale.loadVisualMeshesFromXML(baleId, xmlFile, baseDirectory)

			Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, false)
			delete(baleRoot)
		end
	end

	xmlFile:delete()

	return baleId, sharedLoadRequestId
end

function Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
	xmlFile:iterate("bale.fillTypes.fillType", function (index, key)
		local fillTypeName = xmlFile:getValue(key .. "#name")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex ~= nil then
			local fillTypeInfo = {
				fillTypeIndex = fillTypeIndex,
				capacity = xmlFile:getValue(key .. "#capacity", 1000),
				mass = xmlFile:getValue(key .. "#mass", 500) / 1000,
				supportsWrapping = xmlFile:getValue(key .. "#supportsWrapping", false)
			}
			local diffuseFilename = xmlFile:getValue(key .. ".diffuse#filename")

			if diffuseFilename ~= nil then
				fillTypeInfo.diffuseFilename = Utils.getFilename(diffuseFilename, baseDirectory)
			end

			local normalFilename = xmlFile:getValue(key .. ".normal#filename")

			if normalFilename ~= nil then
				fillTypeInfo.normalFilename = Utils.getFilename(normalFilename, baseDirectory)
			end

			local specularFilename = xmlFile:getValue(key .. ".specular#filename")

			if specularFilename ~= nil then
				fillTypeInfo.specularFilename = Utils.getFilename(specularFilename, baseDirectory)
			end

			local alphaFilename = xmlFile:getValue(key .. ".alpha#filename")

			if alphaFilename ~= nil then
				fillTypeInfo.alphaFilename = Utils.getFilename(alphaFilename, baseDirectory)
			end

			local outputFillTypeName = xmlFile:getValue(key .. ".fermenting#outputFillType")
			local outputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeName)

			if outputFillTypeIndex ~= nil then
				fillTypeInfo.fermenting = {
					outputFillTypeIndex = outputFillTypeIndex,
					requiresWrapping = xmlFile:getValue(key .. ".fermenting#requiresWrapping", true),
					time = xmlFile:getValue(key .. ".fermenting#time", 0)
				}
			end

			table.insert(fillTypes, fillTypeInfo)
		end
	end)
end

function Bale.setFillTypeTextures(nodeId, fillTypes, fillTypeIndex)
	for i = 1, #fillTypes do
		if fillTypes[i].fillTypeIndex == fillTypeIndex then
			Bale.setFillTypeTexturesForNode(nodeId, fillTypes[i])

			break
		end
	end
end

function Bale.setFillTypeTexturesForNode(nodeId, fillTypeInfo)
	local numChildren = getNumOfChildren(nodeId)

	for i = 1, numChildren do
		Bale.setFillTypeTexturesForNode(getChildAt(nodeId, i - 1), fillTypeInfo)
	end

	if getHasClassId(nodeId, ClassIds.SHAPE) then
		local materialId = getMaterial(nodeId, 0)

		if materialId ~= 0 then
			local shaderFilename = getMaterialCustomShaderFilename(materialId)

			if shaderFilename:contains("silageBaleShader") then
				local oldWrappingState, _, _, _ = getShaderParameter(nodeId, "wrappingState")
				local oldWrapR, oldWrapG, oldWrapB, oldWrapA = getShaderParameter(nodeId, "colorScale")

				if fillTypeInfo.diffuseFilename ~= nil then
					materialId = setMaterialDiffuseMapFromFile(materialId, fillTypeInfo.diffuseFilename, true, true, false)
				end

				if fillTypeInfo.normalFilename ~= nil then
					materialId = setMaterialNormalMapFromFile(materialId, fillTypeInfo.normalFilename, true, false, false)
				end

				if fillTypeInfo.specularFilename ~= nil then
					materialId = setMaterialGlossMapFromFile(materialId, fillTypeInfo.specularFilename, true, true, false)
				end

				if fillTypeInfo.alphaFilename ~= nil then
					materialId = setMaterialCustomMapFromFile(materialId, "alphaMap", fillTypeInfo.alphaFilename, true, false, false)
				end

				setMaterial(nodeId, materialId, 0)
				setShaderParameter(nodeId, "wrappingState", oldWrappingState, 0, 0, 0, false)
				setShaderParameter(nodeId, "colorScale", oldWrapR, oldWrapG, oldWrapB, oldWrapA, false)
			end
		end
	end
end

function Bale.loadVisualMeshesFromXML(rootNode, xmlFile, baseDirectory)
	local meshes = {}
	local tensionBeltMeshes = {}

	xmlFile:iterate("bale.baleMeshes.baleMesh", function (index, key)
		local meshData = {
			node = xmlFile:getValue(key .. "#node", nil, rootNode),
			supportsWrapping = xmlFile:getValue(key .. "#supportsWrapping", true)
		}
		local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")
		meshData.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames)
		meshData.fillTypeVisibility = true
		meshData.isTensionBeltMesh = xmlFile:getValue(key .. "#isTensionBeltMesh", false)

		if meshData.isTensionBeltMesh then
			table.insert(tensionBeltMeshes, meshData.node)
		end

		table.insert(meshes, meshData)
	end)

	return meshes, tensionBeltMeshes
end

function Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, isWrapped)
	for i = 1, #meshes do
		local meshData = meshes[i]

		if meshData.fillTypes ~= nil and #meshData.fillTypes > 0 then
			setVisibility(meshData.node, false)

			meshData.fillTypeVisibility = false

			for j = 1, #meshData.fillTypes do
				if meshData.fillTypes[j] == fillTypeIndex then
					if meshData.supportsWrapping or not isWrapped then
						setVisibility(meshData.node, true)
					end

					meshData.fillTypeVisibility = true

					break
				end
			end
		end
	end
end

BaleActivatable = {}
local BaleActivatable_mt = Class(BaleActivatable)

function BaleActivatable.new(bale)
	local self = {}

	setmetatable(self, BaleActivatable_mt)

	self.bale = bale
	self.activateText = g_i18n:getText("action_cutBale")

	return self
end

function BaleActivatable:getIsActivatable()
	if self.bale:getCanInteract() and self.bale:getCanBeOpened() then
		return true
	end

	return false
end

function BaleActivatable:getDistance(posX, posY, posZ)
	if self.bale.nodeId ~= 0 then
		local x, _, z = getWorldTranslation(self.bale.nodeId)
		local distance = MathUtil.vector2Length(posX - x, posZ - z)

		return distance
	end

	return math.huge
end

function BaleActivatable:run()
	if g_server ~= nil then
		self.bale:open()
	else
		g_client:getServerConnection():sendEvent(BaleOpenEvent.new(self.bale))
	end
end
