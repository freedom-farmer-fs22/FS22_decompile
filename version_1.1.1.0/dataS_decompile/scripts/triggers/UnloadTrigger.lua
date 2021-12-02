UnloadTrigger = {}
local UnloadTrigger_mt = Class(UnloadTrigger, Object)

InitStaticObjectClass(UnloadTrigger, "UnloadTrigger", ObjectIds.OBJECT_UNLOAD_TRIGGER)

function UnloadTrigger.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or UnloadTrigger_mt)
	self.fillTypes = {}
	self.avoidFillTypes = {}
	self.acceptedToolTypes = {}
	self.notAllowedWarningText = nil
	self.extraAttributes = nil

	return self
end

function UnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	local baleTriggerKey = xmlNode .. ".baleTrigger"

	if xmlFile:hasProperty(baleTriggerKey) then
		self.baleTrigger = BaleUnloadTrigger.new(self.isServer, self.isClient)

		if self.baleTrigger:load(components, xmlFile, baleTriggerKey, self, i3dMappings) then
			self.baleTrigger:setTarget(self)
			self.baleTrigger:register(true)
		else
			self.baleTrigger = nil
		end
	end

	local woodTriggerKey = xmlNode .. ".woodTrigger"

	if xmlFile:hasProperty(woodTriggerKey) then
		self.woodTrigger = WoodUnloadTrigger.new(self.isServer, self.isClient)

		if self.woodTrigger:load(components, xmlFile, woodTriggerKey, self, i3dMappings) then
			self.woodTrigger:setTarget(self)
			self.woodTrigger:register(true)
		else
			self.woodTrigger = nil
		end
	end

	self.exactFillRootNode = xmlFile:getValue(xmlNode .. "#exactFillRootNode", nil, components, i3dMappings)

	if self.exactFillRootNode ~= nil then
		if not CollisionFlag.getHasFlagSet(self.exactFillRootNode, CollisionFlag.FILLABLE) then
			Logging.xmlWarning(xmlFile, "Missing collision mask bit '%d'. Please add this bit to exact fill root node '%s' of unloadTrigger", CollisionFlag.getBit(CollisionFlag.FILLABLE), I3DUtil.getNodePath(self.exactFillRootNode))

			return false
		end

		g_currentMission:addNodeObject(self.exactFillRootNode, self)
	end

	self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
	self.supportsAIUnloading = self.aiNode ~= nil
	local priceScale = xmlFile:getValue(xmlNode .. "#priceScale", nil)

	if priceScale ~= nil then
		self.extraAttributes = {
			priceScale = priceScale
		}
	end

	if target ~= nil then
		self:setTarget(target)
	end

	self:loadFillTypes(xmlFile, xmlNode)
	self:loadAcceptedToolType(xmlFile, xmlNode)
	self:loadAvoidFillTypes(xmlFile, xmlNode)

	self.isEnabled = true
	self.extraAttributes = extraAttributes or self.extraAttributes

	return true
end

function UnloadTrigger:delete()
	if self.baleTrigger ~= nil then
		self.baleTrigger:delete()
	end

	if self.woodTrigger ~= nil then
		self.woodTrigger:delete()
	end

	if self.exactFillRootNode ~= nil then
		g_currentMission:removeNodeObject(self.exactFillRootNode)
	end

	UnloadTrigger:superClass().delete(self)
end

function UnloadTrigger:readStream(streamId, connection)
	UnloadTrigger:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		if self.baleTrigger ~= nil then
			local baleTriggerId = NetworkUtil.readNodeObjectId(streamId)

			self.baleTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(self.baleTrigger, baleTriggerId)
		end

		if self.woodTrigger ~= nil then
			local woodTriggerId = NetworkUtil.readNodeObjectId(streamId)

			self.woodTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(self.woodTrigger, woodTriggerId)
		end
	end
end

function UnloadTrigger:writeStream(streamId, connection)
	UnloadTrigger:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		if self.baleTrigger ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.baleTrigger))
			self.baleTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, self.baleTrigger)
		end

		if self.woodTrigger ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.woodTrigger))
			self.woodTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, self.woodTrigger)
		end
	end
end

function UnloadTrigger:loadAcceptedToolType(xmlFile, xmlNode)
	local acceptedToolTypeNames = xmlFile:getValue(xmlNode .. "#acceptedToolTypes")
	local acceptedToolTypes = string.getVector(acceptedToolTypeNames)

	if acceptedToolTypes ~= nil then
		for _, acceptedToolType in pairs(acceptedToolTypes) do
			local toolTypeInt = g_toolTypeManager:getToolTypeIndexByName(acceptedToolType)
			self.acceptedToolTypes[toolTypeInt] = true
		end
	else
		self.acceptedToolTypes = nil
	end
end

function UnloadTrigger:loadAvoidFillTypes(xmlFile, xmlNode)
	local avoidFillTypeCategories = xmlFile:getValue(xmlNode .. "#avoidFillTypeCategories")
	local avoidFillTypeNames = xmlFile:getValue(xmlNode .. "#avoidFillTypes")
	local avoidFillTypes = nil

	if avoidFillTypeCategories ~= nil and avoidFillTypeNames == nil then
		avoidFillTypes = g_fillTypeManager:getFillTypesByCategoryNames(avoidFillTypeCategories, "Warning: UnloadTrigger has invalid avoidFillTypeCategory '%s'.")
	elseif avoidFillTypeCategories == nil and avoidFillTypeNames ~= nil then
		avoidFillTypes = g_fillTypeManager:getFillTypesByNames(avoidFillTypeNames, "Warning: UnloadTrigger has invalid avoidFillType '%s'.")
	end

	if avoidFillTypes ~= nil then
		for _, fillType in pairs(avoidFillTypes) do
			self.avoidFillTypes[fillType] = true
		end
	else
		self.avoidFillTypes = nil
	end
end

function UnloadTrigger:loadFillTypes(xmlFile, xmlNode)
	local fillTypeCategories = xmlFile:getValue(xmlNode .. "#fillTypeCategories")
	local fillTypeNames = xmlFile:getValue(xmlNode .. "#fillTypes")
	local fillTypes = nil

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: UnloadTrigger has invalid fillTypeCategory '%s'.")
	elseif fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: UnloadTrigger has invalid fillType '%s'.")
	end

	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			self.fillTypes[fillType] = true
		end
	else
		self.fillTypes = nil
	end
end

function UnloadTrigger:setTarget(object)
	assert(object.getIsFillTypeAllowed ~= nil, "Missing 'getIsFillTypeAllowed' method for given target")
	assert(object.getIsToolTypeAllowed ~= nil, "Missing 'getIsToolTypeAllowed' method for given target")
	assert(object.addFillLevelFromTool ~= nil, "Missing 'addFillLevelFromTool' method for given target")
	assert(object.getFreeCapacity ~= nil, "Missing 'getFreeCapacity' method for given target")

	self.target = object
end

function UnloadTrigger:getTarget()
	return self.target
end

function UnloadTrigger:getFillUnitIndexFromNode(node)
	return 1
end

function UnloadTrigger:getFillUnitExactFillRootNode(fillUnitIndex)
	return self.exactFillRootNode
end

function UnloadTrigger:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, extraAttributes)
	local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta, fillTypeIndex, fillPositionData, toolType, extraAttributes or self.extraAttributes)

	return applied
end

function UnloadTrigger:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	local supported = self:getIsFillTypeSupported(fillType)

	return supported
end

function UnloadTrigger:getFillUnitSupportsToolType(fillUnit, toolType, fillType)
	return true
end

function UnloadTrigger:getFillUnitAllowsFillType(fillUnitIndex, fillType)
	return self:getIsFillTypeAllowed(fillType)
end

function UnloadTrigger:getIsFillTypeAllowed(fillType)
	return self:getIsFillTypeSupported(fillType)
end

function UnloadTrigger:getIsFillTypeSupported(fillType)
	if self.fillTypes ~= nil and not self.fillTypes[fillType] then
		return false
	end

	if self.avoidFillTypes ~= nil and self.avoidFillTypes[fillType] then
		return false
	end

	if self.target ~= nil and not self.target:getIsFillTypeAllowed(fillType, self.extraAttributes) then
		return false
	end

	return true
end

function UnloadTrigger:getIsFillAllowedFromFarm(farmId)
	if self.target ~= nil and self.target.getIsFillAllowedFromFarm ~= nil then
		return self.target:getIsFillAllowedFromFarm(farmId)
	end

	return true
end

function UnloadTrigger:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	if self.target.getFreeCapacity ~= nil then
		return self.target:getFreeCapacity(fillTypeIndex, farmId, self.extraAttributes)
	end

	return 0
end

function UnloadTrigger:getIsToolTypeAllowed(toolType)
	local accepted = true

	if self.acceptedToolTypes ~= nil and self.acceptedToolTypes[toolType] ~= true then
		accepted = false
	end

	if accepted then
		return self.target:getIsToolTypeAllowed(toolType)
	else
		return false
	end
end

function UnloadTrigger:getCustomDischargeNotAllowedWarning()
	return self.notAllowedWarningText
end

function UnloadTrigger:getSupportAIUnloading()
	return self.supportsAIUnloading
end

function UnloadTrigger:getAITargetPositionAndDirection()
	local x, _, z = getWorldTranslation(self.aiNode)
	local xDir, _, zDir = localDirectionToWorld(self.aiNode, 0, 0, 1)

	return x, z, xDir, zDir
end

function UnloadTrigger.registerXMLPaths(schema, basePath)
	BaleUnloadTrigger.registerXMLPaths(schema, basePath .. ".baleTrigger")
	WoodUnloadTrigger.registerXMLPaths(schema, basePath .. ".woodTrigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#exactFillRootNode", "Exact fill root node")
	schema:register(XMLValueType.FLOAT, basePath .. "#priceScale", "Price scale added for sold goods")
	schema:register(XMLValueType.STRING, basePath .. "#acceptedToolTypes", "List of accepted tool types")
	schema:register(XMLValueType.STRING, basePath .. "#avoidFillTypeCategories", "Avoided fill type categories (Even if target would allow the fill type)")
	schema:register(XMLValueType.STRING, basePath .. "#avoidFillTypes", "Avoided fill types (Even if target would allow the fill type)")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported fill type categories")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported fill types")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#aiNode", "AI target node, required for the station to support AI. AI drives to the node in positive Z direction. Height is not relevant.")
end
