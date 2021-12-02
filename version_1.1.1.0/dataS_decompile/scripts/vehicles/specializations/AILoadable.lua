AILoadable = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FillUnit")
		schema:register(XMLValueType.BOOL, FillUnit.FILL_UNIT_XML_KEY .. "#allowAILoading", "Allows ai loading", false)
		schema:register(XMLValueType.NODE_INDEX, FillUnit.FILL_UNIT_XML_KEY .. "#aiLoadingNode", "AI loading node", "exactFillRootNode")
		schema:setXMLSpecializationType()
	end
}

function AILoadable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAILoadingNodeZAlignedOffset", AILoadable.getAILoadingNodeZAlignedOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIFillUnits", AILoadable.getAIFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "aiPrepareLoading", AILoadable.aiPrepareLoading)
	SpecializationUtil.registerFunction(vehicleType, "aiFinishLoading", AILoadable.aiFinishLoading)
	SpecializationUtil.registerFunction(vehicleType, "aiStartLoadingFromTrigger", AILoadable.aiStartLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "aiStoppedLoadingFromTrigger", AILoadable.aiStoppedLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "aiFinishedLoadingFromTrigger", AILoadable.aiFinishedLoadingFromTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasFinishedLoading", AILoadable.getAIHasFinishedLoading)
end

function AILoadable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", AILoadable.loadFillUnitFromXML)
end

function AILoadable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AILoadable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AILoadable)
end

function AILoadable:onPreLoad()
	local spec = self.spec_aiLoadable
	spec.aiFillUnits = {}
end

function AILoadable:onLoad()
	local spec = self.spec_aiLoadable
	spec.currentFillUnitIndex = nil
end

function AILoadable:onPostLoad()
	local spec = self.spec_aiLoadable

	if spec.aiFillUnits ~= nil and self.getInputAttacherJoints ~= nil then
		for _, aiFillUnit in ipairs(spec.aiFillUnits) do
			aiFillUnit.inputAttacherJointOffsets = {}

			for _, inputAttacherJoint in ipairs(self:getInputAttacherJoints()) do
				local x, y, z = localToLocal(aiFillUnit.aiLoadingNode, inputAttacherJoint.node, 0, 0, 0)

				table.insert(aiFillUnit.inputAttacherJointOffsets, {
					x,
					y,
					z
				})
			end

			if self.getAIRootNode ~= nil then
				local aiRootNode = self:getAIRootNode()
				aiFillUnit.aiRootNodeOffsets = localToLocal(aiFillUnit.aiLoadingNode, aiRootNode, 0, 0, 0)
			end
		end
	end
end

function AILoadable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiLoadable

	if spec.currentFillUnitIndex ~= nil and not spec.isAILoadingRunning and self:getAIHasFinishedLoading(spec.currentFillUnitIndex) then
		self:aiFinishedLoadingFromTrigger()
	end
end

function AILoadable:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
	if not superFunc(self, xmlFile, key, entry, index) then
		return false
	end

	entry.allowAILoading = xmlFile:getValue(key .. "#allowAILoading", false)

	if entry.allowAILoading then
		entry.aiLoadingNode = xmlFile:getValue(key .. "#aiLoadingNode", nil, self.components, self.i3dMappings) or entry.exactFillRootNode

		if entry.aiLoadingNode ~= nil then
			local spec = self.spec_aiLoadable

			table.insert(spec.aiFillUnits, entry)
		else
			Logging.xmlWarning(self.xmlFile, "AILoadingNode not found for fillUnit '%s'!", key)
		end
	end

	return true
end

function AILoadable:getAIFillUnits()
	local spec = self.spec_aiLoadable

	return spec.aiFillUnits
end

function AILoadable:getAILoadingNodeZAlignedOffset(fillUnitIndex, targetVehicle)
	local fillUnit = self:getFillUnitByIndex(fillUnitIndex)

	if targetVehicle == self then
		return unpack(fillUnit.aiRootNodeOffsets)
	end

	local index = self:getActiveInputAttacherJointDescIndex()
	local offsetX, offsetY, offsetZ = unpack(fillUnit.inputAttacherJointOffsets[index])
	local currentVehicle = self
	local nextVehicle = currentVehicle:getAttacherVehicle()

	while targetVehicle ~= nextVehicle do
		local attacherJoint = nextVehicle:getAttacherJointDescFromObject(currentVehicle)
		local nextInputAttacherJointIndex = nextVehicle:getActiveInputAttacherJointDescIndex()
		local offsets = attacherJoint.inputAttacherJointOffsets[nextInputAttacherJointIndex]
		local x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm = unpack(offsets)
		local nextOffsetX = x + xNorm * offsetX + xUp * offsetY + xDir * offsetZ
		local nextOffsetY = y + yNorm * offsetX + yUp * offsetY + yDir * offsetZ
		local nextOffsetZ = z + zNorm * offsetX + zUp * offsetY + zDir * offsetZ
		offsetZ = nextOffsetZ
		offsetY = nextOffsetY
		offsetX = nextOffsetX
		currentVehicle = nextVehicle
		nextVehicle = currentVehicle:getAttacherVehicle()
	end

	local attacherJoint = targetVehicle:getAttacherJointDescFromObject(currentVehicle)
	local offsets = attacherJoint.aiRootNodeOffset
	local x, y, z, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm = unpack(offsets)
	local targetOffsetX = x + xNorm * offsetX + xUp * offsetY + xDir * offsetZ
	local targetOffsetY = y + yNorm * offsetX + yUp * offsetY + yDir * offsetZ
	local targetOffsetZ = z + zNorm * offsetX + zUp * offsetY + zDir * offsetZ

	return targetOffsetX, targetOffsetY, targetOffsetZ
end

function AILoadable:aiPrepareLoading(fillUnitIndex, task)
end

function AILoadable:aiStartLoadingFromTrigger(loadTrigger, fillUnitIndex, fillType, task)
	local spec = self.spec_aiLoadable
	spec.task = task
	spec.isAILoadingRunning = true
	spec.currentFillUnitIndex = fillUnitIndex

	loadTrigger:setIsLoading(true, self, fillUnitIndex, fillType, false)
end

function AILoadable:aiStoppedLoadingFromTrigger()
	local spec = self.spec_aiLoadable
	spec.isAILoadingRunning = false
end

function AILoadable:aiFinishedLoadingFromTrigger()
	local spec = self.spec_aiLoadable

	if spec.task ~= nil then
		spec.task:finishedLoading()
	end

	spec.currentFillUnitIndex = nil
	spec.task = nil
end

function AILoadable:aiFinishLoading(fillUnitIndex, task)
end

function AILoadable:getAIHasFinishedLoading(fillUnitIndex)
	return true
end
