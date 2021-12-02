AIDischargeable = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Dischargeable")
		schema:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
		schema:register(XMLValueType.BOOL, "vehicle.dischargeable.dischargeableConfigurations.dischargeableConfiguration(?).dischargeNode(?)#allowAIDischarge", "Allows ai discharge", false)
		schema:setXMLSpecializationType()
	end
}

function AIDischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodes", AIDischargeable.getAIDischargeNodes)
	SpecializationUtil.registerFunction(vehicleType, "getAIDischargeNodeZAlignedOffset", AIDischargeable.getAIDischargeNodeZAlignedOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAICanStartDischarge", AIDischargeable.getAICanStartDischarge)
	SpecializationUtil.registerFunction(vehicleType, "startAIDischarge", AIDischargeable.startAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "stoppedAIDischarge", AIDischargeable.stoppedAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "finishedAIDischarge", AIDischargeable.finishedAIDischarge)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasFinishedDischarge", AIDischargeable.getAIHasFinishedDischarge)
end

function AIDischargeable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", AIDischargeable.loadDischargeNode)
end

function AIDischargeable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", AIDischargeable)
end

function AIDischargeable:onPreLoad()
	local spec = self.spec_aiDischargeable
	spec.aiDischargeNodes = {}
end

function AIDischargeable:onLoad()
	local spec = self.spec_aiDischargeable
	spec.currentDischargeNode = nil
end

function AIDischargeable:onPostLoad()
	local spec = self.spec_aiDischargeable

	if spec.aiDischargeNodes ~= nil and self.getInputAttacherJoints ~= nil then
		for _, dischargeNode in ipairs(spec.aiDischargeNodes) do
			dischargeNode.inputAttacherJointOffsets = {}

			for _, inputAttacherJoint in ipairs(self:getInputAttacherJoints()) do
				local x, y, z = localToLocal(dischargeNode.node, inputAttacherJoint.node, 0, 0, 0)

				table.insert(dischargeNode.inputAttacherJointOffsets, {
					x,
					y,
					z
				})
			end

			if self.getAIRootNode ~= nil then
				local aiRootNode = self:getAIRootNode()
				dischargeNode.aiRootNodeOffsets = localToLocal(dischargeNode.node, aiRootNode, 0, 0, 0)
			end
		end
	end
end

function AIDischargeable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiDischargeable

	if spec.currentDischargeNode ~= nil and not spec.isAIDischargeRunning and self:getAIHasFinishedDischarge(spec.currentDischargeNode) then
		self:finishedAIDischarge()
	end
end

function AIDischargeable:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.allowAIDischarge = xmlFile:getValue(key .. "#allowAIDischarge", false)

	if entry.allowAIDischarge then
		local spec = self.spec_aiDischargeable
		local fillUnitAlreadyUsed = false

		for _, dischargeNode in ipairs(spec.aiDischargeNodes) do
			if dischargeNode.fillUnitIndex == entry.fillUnitIndex then
				fillUnitAlreadyUsed = true

				break
			end
		end

		if not fillUnitAlreadyUsed then
			table.insert(spec.aiDischargeNodes, entry)
		else
			Logging.xmlWarning(xmlFile, "Discharge node fill unit index already used. Discharge node will be ignored for '%s'", key)
		end
	end

	return true
end

function AIDischargeable:onDischargeStateChanged(state)
	local spec = self.spec_aiDischargeable

	if spec.currentDischargeNode ~= nil and spec.isAIDischargeRunning and state == Dischargeable.DISCHARGE_STATE_OFF then
		self:stoppedAIDischarge()
	end
end

function AIDischargeable:getAIDischargeNodes()
	local spec = self.spec_aiDischargeable

	return spec.aiDischargeNodes
end

function AIDischargeable:getAIDischargeNodeZAlignedOffset(dischargeNode, targetVehicle)
	if targetVehicle == self then
		return unpack(dischargeNode.aiRootNodeOffsets)
	end

	local index = self:getActiveInputAttacherJointDescIndex()
	local offsetX, offsetY, offsetZ = unpack(dischargeNode.inputAttacherJointOffsets[index])
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

function AIDischargeable:getAICanStartDischarge(dischargeNode)
	return self:getCanDischargeToObject(dischargeNode)
end

function AIDischargeable:startAIDischarge(dischargeNode, task)
	local spec = self.spec_aiDischargeable
	spec.currentDischargeNode = dischargeNode
	spec.task = task
	spec.isAIDischargeRunning = true

	self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
end

function AIDischargeable:stoppedAIDischarge()
	local spec = self.spec_aiDischargeable
	spec.isAIDischargeRunning = false
end

function AIDischargeable:finishedAIDischarge()
	local spec = self.spec_aiDischargeable

	if spec.task ~= nil then
		spec.task:finishedDischarge()
	end

	spec.currentDischargeNode = nil
	spec.task = nil
end

function AIDischargeable:getAIHasFinishedDischarge(dischargeNode)
	return true
end
