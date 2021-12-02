AutoLoader = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("AutoLoader")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.trigger#node", "Trigger node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.pickupTrigger#node", "Pickup trigger node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoader.loadPlaces.loadPlace(?)#node", "Load place node")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.autoLoader.loadPlaces#checkOffset", "Check offset from load place node")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.autoLoader.loadPlaces#checkSize", "Check size around load place node")
		schema:register(XMLValueType.STRING, "vehicle.autoLoader#supportedObject", "Path to xml of supported object")
		schema:register(XMLValueType.INT, "vehicle.autoLoader#fillUnitIndex", "Fill unit index to check fill type")
		schema:register(XMLValueType.INT, "vehicle.autoLoader#maxObjects", "Max. number of objects to load", "Number of load places")
		schema:register(XMLValueType.BOOL, "vehicle.autoLoader#useBales", "Use for bales", false)
		schema:register(XMLValueType.BOOL, "vehicle.autoLoader#useTensionBelts", "Automatically mount tension belts", "False for mobile, otherwise true")
		schema:setXMLSpecializationType()
	end
}

function AutoLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsValidObject", AutoLoader.getIsValidObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutoLoadingAllowed", AutoLoader.getIsAutoLoadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getFirstValidLoadPlace", AutoLoader.getFirstValidLoadPlace)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderOverlapCallback", AutoLoader.autoLoaderOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderTriggerCallback", AutoLoader.autoLoaderTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "autoLoaderPickupTriggerCallback", AutoLoader.autoLoaderPickupTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteAutoLoaderObject", AutoLoader.onDeleteAutoLoaderObject)
end

function AutoLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDynamicMountTimeToMount", AutoLoader.getDynamicMountTimeToMount)
end

function AutoLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoader)
end

function AutoLoader:onLoad(savegame)
	if self.isServer then
		local spec = self.spec_autoLoader
		spec.triggerId = self.xmlFile:getValue("vehicle.autoLoader.trigger#node", nil, self.components, self.i3dMappings)

		if spec.triggerId ~= nil then
			addTrigger(spec.triggerId, "autoLoaderTriggerCallback", self)
		end

		spec.pickupTriggerId = self.xmlFile:getValue("vehicle.autoLoader.pickupTrigger#node", nil, self.components, self.i3dMappings)

		if spec.pickupTriggerId ~= nil then
			addTrigger(spec.pickupTriggerId, "autoLoaderPickupTriggerCallback", self)
		end

		spec.triggeredObjects = {}
		spec.numTriggeredObjects = 0
		spec.loadPlaces = {}
		local i = 0

		while true do
			local placeKey = string.format("vehicle.autoLoader.loadPlaces.loadPlace(%d)", i)

			if not self.xmlFile:hasProperty(placeKey) then
				break
			end

			local entry = {
				node = self.xmlFile:getValue(placeKey .. "#node", nil, self.components, self.i3dMappings)
			}

			if entry.node ~= nil then
				table.insert(spec.loadPlaces, entry)
			end

			i = i + 1
		end

		spec.loadPlaceOffset = self.xmlFile:getValue("vehicle.autoLoader.loadPlaces#checkOffset", "0 0 0")
		spec.loadPlaceSize = self.xmlFile:getValue("vehicle.autoLoader.loadPlaces#checkSize", "1 1 1")
		spec.supportedObject = self.xmlFile:getValue("vehicle.autoLoader#supportedObject")
		spec.fillUnitIndex = self.xmlFile:getValue("vehicle.autoLoader#fillUnitIndex")
		spec.maxObjects = self.xmlFile:getValue("vehicle.autoLoader#maxObjects") or #spec.loadPlaces
		spec.useBales = self.xmlFile:getValue("vehicle.autoLoader#useBales", false)
		spec.useTensionBelts = self.xmlFile:getValue("vehicle.autoLoader#useTensionBelts", not GS_IS_MOBILE_VERSION)
	end
end

function AutoLoader:onDelete()
	local spec = self.spec_autoLoader

	if self.isServer then
		if spec.triggerId ~= nil then
			removeTrigger(spec.triggerId)
		end

		if spec.pickupTriggerId ~= nil then
			removeTrigger(spec.pickupTriggerId)
		end
	end
end

function AutoLoader:getIsValidObject(object)
	local spec = self.spec_autoLoader

	if spec.supportedObject ~= nil then
		local objectFilename = object.configFileName or object.i3dFilename

		if objectFilename ~= nil then
			if not string.endsWith(objectFilename, spec.supportedObject) then
				return false
			end
		else
			return false
		end
	end

	if object == self then
		return false
	end

	if spec.useBales and (not object:isa(Bale) or not object:getAllowPickup()) then
		return false
	end

	if not g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) then
		return false
	end

	if spec.fillUnitIndex ~= nil and object.getFillType ~= nil and not self:getFillUnitSupportsFillType(spec.fillUnitIndex, object:getFillType()) then
		return false
	end

	return true
end

function AutoLoader:getIsAutoLoadingAllowed()
	local _, y1, _ = getWorldTranslation(self.components[1].node)
	local _, y2, _ = localToWorld(self.components[1].node, 0, 1, 0)

	if y2 - y1 < 0.5 then
		return false
	end

	return true
end

function AutoLoader:getDynamicMountTimeToMount(superFunc)
	return self:getIsAutoLoadingAllowed() and -1 or math.huge
end

function AutoLoader:getFirstValidLoadPlace()
	local spec = self.spec_autoLoader

	for i = 1, #spec.loadPlaces do
		local loadPlace = spec.loadPlaces[i]
		local x, y, z = getWorldTranslation(loadPlace.node)
		local rx, ry, rz = getWorldRotation(loadPlace.node)
		local offsetX, offsetY, offsetZ = unpack(spec.loadPlaceOffset)
		local sizeX, sizeY, sizeZ = unpack(spec.loadPlaceSize)
		spec.foundObject = false

		overlapBox(x + offsetX, y + offsetY + offsetZ, z, rx, ry, rz, sizeX / 2, sizeY / 2, sizeZ / 2, "autoLoaderOverlapCallback", self, 3212828671.0, true, false, true)

		if not spec.foundObject then
			return i
		end
	end

	return -1
end

function AutoLoader:autoLoaderOverlapCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local spec = self.spec_autoLoader
		local object = g_currentMission:getNodeObject(transformId)

		if object ~= nil and object ~= self then
			spec.foundObject = true
		end
	end

	return true
end

function AutoLoader:autoLoaderPickupTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter and otherActorId ~= 0 then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and self:getIsAutoLoadingAllowed() and self:getIsValidObject(object) then
			local spec = self.spec_autoLoader

			if spec.triggeredObjects[object] == nil and spec.numTriggeredObjects < spec.maxObjects then
				local firstValidLoadPlace = self:getFirstValidLoadPlace()

				if firstValidLoadPlace ~= -1 then
					local loadPlace = spec.loadPlaces[firstValidLoadPlace]
					local x, y, z = getWorldTranslation(loadPlace.node)
					local objectNodeId = object.nodeId or object.components[1].node

					removeFromPhysics(objectNodeId)
					setTranslation(objectNodeId, x, y, z)
					setWorldRotation(objectNodeId, getWorldRotation(loadPlace.node))
					addToPhysics(objectNodeId)

					local vx, vy, vz = getLinearVelocity(self:getParentComponent(loadPlace.node))

					setLinearVelocity(objectNodeId, vx, vy, vz)

					spec.triggeredObjects[object] = 0
					spec.numTriggeredObjects = spec.numTriggeredObjects + 1

					if spec.useTensionBelts and self.setAllTensionBeltsActive ~= nil then
						self:setAllTensionBeltsActive(false, false)
						self:setAllTensionBeltsActive(true, false)
					end
				end
			end
		end
	end
end

function AutoLoader:autoLoaderTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_autoLoader

	if onEnter then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and self:getIsValidObject(object) then
			if spec.triggeredObjects[object] == nil then
				spec.triggeredObjects[object] = 0
				spec.numTriggeredObjects = spec.numTriggeredObjects + 1
			end

			if spec.triggeredObjects[object] == 0 and object.addDeleteListener ~= nil then
				object:addDeleteListener(self, "onDeleteAutoLoaderObject")
			end

			spec.triggeredObjects[object] = spec.triggeredObjects[object] + 1
		end
	elseif onLeave then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and self:getIsValidObject(object) and spec.triggeredObjects[object] ~= nil then
			spec.triggeredObjects[object] = spec.triggeredObjects[object] - 1

			if spec.triggeredObjects[object] == 0 then
				spec.triggeredObjects[object] = nil
				spec.numTriggeredObjects = spec.numTriggeredObjects - 1

				if object.removeDeleteListener ~= nil then
					object:removeDeleteListener(self)
				end
			end

			if next(spec.triggeredObjects) == nil then
				spec.currentPlace = 1
			end
		end
	end
end

function AutoLoader:onDeleteAutoLoaderObject(object)
	local spec = self.spec_autoLoader

	if spec.triggeredObjects[object] ~= nil then
		spec.triggeredObjects[object] = nil
		spec.numTriggeredObjects = spec.numTriggeredObjects - 1

		if next(spec.triggeredObjects) == nil then
			spec.currentPlace = 1
		end
	end
end
