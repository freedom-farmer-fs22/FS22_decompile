PowerTakeOffs = {
	DEFAULT_MAX_UPDATE_DISTANCE = 40,
	xmlSchema = nil,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
	end
}

function PowerTakeOffs.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("PowerTakeOffs")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(?)")
	PowerTakeOffs.registerXMLPaths(schema, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(?)")
	PowerTakeOffs.registerXMLPaths(schema, "vehicle.powerTakeOffs")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_TOOL_XML_KEY .. ".powerTakeOffs#indices", "PTOs to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_TOOL_XML_KEY .. ".powerTakeOffs#localIndices", "Local PTOs to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_PART_XML_KEY .. ".powerTakeOffs#indices", "PTOs to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_PART_XML_KEY .. ".powerTakeOffs#localIndices", "Local PTOs to update")
	schema:register(XMLValueType.BOOL, "vehicle.powerTakeOffs#ignoreInvalidJointIndices", "Do not display warning if attacher joint index could not be found. Can be useful if attacher joints change due to configurations", false)
	schema:register(XMLValueType.FLOAT, "vehicle.powerTakeOffs#maxUpdateDistance", "Max. distance to vehicle root to update power take offs", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:setXMLSpecializationType()

	local powerTakeOffXMLSchema = XMLSchema.new("powerTakeOff")
	PowerTakeOffs.xmlSchema = powerTakeOffXMLSchema

	powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#filename", "Path to i3d file")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startNode#node", "Start node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.linkNode#node", "Link node")
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#size", "Height of pto", 0.19)
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#minLength", "Minimum length of pto", 0.6)
	powerTakeOffXMLSchema:register(XMLValueType.ANGLE, "powerTakeOff#maxAngle", "Max. angle between start and end", 45)
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#zOffset", "Z axis offset of end node", 0)
	powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#colorShaderParameter", "Color shader parameter")
	powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#decalColorShaderParameter", "Decal color shader parameter")
	AnimationManager.registerAnimationNodesXMLPaths(powerTakeOffXMLSchema, "powerTakeOff.animationNodes")
	powerTakeOffXMLSchema:register(XMLValueType.BOOL, "powerTakeOff#isSingleJoint", "Is single joint PTO", false)
	powerTakeOffXMLSchema:register(XMLValueType.BOOL, "powerTakeOff#isDoubleJoint", "Is double joint PTO", false)
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint#node", "(Single Joint) Start joint node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint#node", "(Single Joint) End joint node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#node", "(Single|Double Joint) Scale part node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#referenceNode", "(Single|Double Joint) Scale part reference node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#node", "(Single|Double Joint) translation part node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#referenceNode", "(Single|Double Joint) translation part reference node")
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart#length", "(Single|Double Joint) translation part length", 0.4)
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart.decal#node", "(Single|Double Joint) translation part decal node")
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#size", "(Single|Double Joint) translation part decal size", 0.1)
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#offset", "(Single|Double Joint) translation part decal offset", 0.05)
	powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#minOffset", "(Single|Double Joint) translation part decal minOffset", 0.01)
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint1#node", "(Double Joint) Start joint 1")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint2#node", "(Double Joint) Start joint 2")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#node", "(Double Joint) End joint 1")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#referenceNode", "(Double Joint) End joint 1 reference node")
	powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint2#node", "(Double Joint) End joint 2")
end

function PowerTakeOffs.registerXMLPaths(schema, basePath)
	PowerTakeOffs.registerOutputXMLPaths(schema, basePath .. ".output(?)")
	PowerTakeOffs.registerInputXMLPaths(schema, basePath .. ".input(?)")
	PowerTakeOffs.registerLocalXMLPaths(schema, basePath .. ".local(?)")
end

function PowerTakeOffs.registerOutputXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#skipToInputAttacherIndex", "Skip to input attacher joint index")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#outputNode", "Output node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
	schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Output name", "DEFAULT_PTO")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function PowerTakeOffs.registerInputXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#inputNode", "Input node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#detachNode", "Detach node")
	schema:register(XMLValueType.BOOL, basePath .. "#aboveAttacher", "Above attacher", true)
	schema:register(XMLValueType.COLOR, basePath .. "#color", "Color")
	schema:register(XMLValueType.COLOR, basePath .. "#decalColor", "Color of decals")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
	schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Pto name", "DEFAULT_PTO")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function PowerTakeOffs.registerLocalXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#startNode", "Start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#endNode", "End node")
	schema:register(XMLValueType.COLOR, basePath .. "#color", "Color")
	schema:register(XMLValueType.COLOR, basePath .. "#decalColor", "Color of decals")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
end

function PowerTakeOffs.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getPowerTakeOffConfigIndex", PowerTakeOffs.getPowerTakeOffConfigIndex)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffsFromXML", PowerTakeOffs.loadPowerTakeOffsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadOutputPowerTakeOff", PowerTakeOffs.loadOutputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadInputPowerTakeOff", PowerTakeOffs.loadInputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadLocalPowerTakeOff", PowerTakeOffs.loadLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "placeLocalPowerTakeOff", PowerTakeOffs.placeLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOff", PowerTakeOffs.updatePowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedPowerTakeOffs", PowerTakeOffs.updateAttachedPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOffLength", PowerTakeOffs.updatePowerTakeOffLength)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffsByJointDescIndex", PowerTakeOffs.getOutputPowerTakeOffsByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffs", PowerTakeOffs.getOutputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffs", PowerTakeOffs.getInputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffsByJointDescIndexAndName", PowerTakeOffs.getInputPowerTakeOffsByJointDescIndexAndName)
	SpecializationUtil.registerFunction(vehicleType, "getIsPowerTakeOffActive", PowerTakeOffs.getIsPowerTakeOffActive)
	SpecializationUtil.registerFunction(vehicleType, "attachPowerTakeOff", PowerTakeOffs.attachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachPowerTakeOff", PowerTakeOffs.detachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "checkPowerTakeOffCollision", PowerTakeOffs.checkPowerTakeOffCollision)
	SpecializationUtil.registerFunction(vehicleType, "parkPowerTakeOff", PowerTakeOffs.parkPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffFromConfigFile", PowerTakeOffs.loadPowerTakeOffFromConfigFile)
	SpecializationUtil.registerFunction(vehicleType, "onPowerTakeOffI3DLoaded", PowerTakeOffs.onPowerTakeOffI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadSingleJointPowerTakeOff", PowerTakeOffs.loadSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateSingleJointPowerTakeOff", PowerTakeOffs.updateSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadDoubleJointPowerTakeOff", PowerTakeOffs.loadDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateDoubleJointPowerTakeOff", PowerTakeOffs.updateDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadBasicPowerTakeOff", PowerTakeOffs.loadBasicPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "attachTypedPowerTakeOff", PowerTakeOffs.attachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachTypedPowerTakeOff", PowerTakeOffs.detachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "validatePowerTakeOffAttachment", PowerTakeOffs.validatePowerTakeOffAttachment)
end

function PowerTakeOffs.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", PowerTakeOffs.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", PowerTakeOffs.updateExtraDependentParts)
end

function PowerTakeOffs.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", PowerTakeOffs)
end

function PowerTakeOffs:onPreLoad(savegame)
	local spec = self.spec_powerTakeOffs
	spec.configIndex = self:getPowerTakeOffConfigIndex()
end

function PowerTakeOffs:onLoad(savegame)
	local spec = self.spec_powerTakeOffs
	local configKey = string.format("vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(%d)", spec.configIndex - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration", spec.configIndex, self.components, self)

	spec.outputPowerTakeOffs = {}
	spec.inputPowerTakeOffs = {}
	spec.localPowerTakeOffs = {}

	self:loadPowerTakeOffsFromXML(self.xmlFile, "vehicle.powerTakeOffs")

	if self.xmlFile:hasProperty(configKey) then
		self:loadPowerTakeOffsFromXML(self.xmlFile, configKey)
	end

	spec.ignoreInvalidJointIndices = self.xmlFile:getValue("vehicle.powerTakeOffs#ignoreInvalidJointIndices", false)
	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.powerTakeOffs#maxUpdateDistance", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.delayedPowerTakeOffsMountings = {}

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onPostUpdate", PowerTakeOffs)
	end
end

function PowerTakeOffs:onPostLoad(savegame)
	local spec = self.spec_powerTakeOffs

	for i = 1, #spec.outputPowerTakeOffs do
		local powerTakeOffOutput = spec.outputPowerTakeOffs[i]

		for index, _ in pairs(powerTakeOffOutput.attacherJointIndices) do
			if self:getAttacherJointByJointDescIndex(index) == nil then
				if not spec.ignoreInvalidJointIndices then
					Logging.xmlWarning(self.xmlFile, "The given attacherJointIndex '%d' for powerTakeOff output '%s' can't be resolved into a valid attacherJoint", index, i)
				end

				powerTakeOffOutput.attacherJointIndices[index] = false
			end
		end
	end

	for i = 1, #spec.inputPowerTakeOffs do
		local inputPowerTakeOff = spec.inputPowerTakeOffs[i]

		for index, _ in pairs(inputPowerTakeOff.inputAttacherJointIndices) do
			if self:getInputAttacherJointByJointDescIndex(index) == nil then
				if not spec.ignoreInvalidJointIndices then
					Logging.xmlWarning(self.xmlFile, "The given inputAttacherJointIndex '%d' for powerTakeOff input '%s' can't be resolved into a valid attacherJoint", index, i)
				end

				inputPowerTakeOff.inputAttacherJointIndices[index] = false
			end
		end
	end
end

function PowerTakeOffs:onDelete()
	local spec = self.spec_powerTakeOffs

	if spec.outputPowerTakeOffs ~= nil then
		for _, output in pairs(spec.outputPowerTakeOffs) do
			if output.xmlFile ~= nil then
				output.xmlFile:delete()

				output.xmlFile = nil
			end

			if output.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(output.sharedLoadRequestId)

				output.sharedLoadRequestId = nil
			end

			if output.rootNode ~= nil then
				delete(output.rootNode)
				delete(output.attachNode)
			end
		end
	end

	if spec.inputPowerTakeOffs ~= nil then
		for _, input in pairs(spec.inputPowerTakeOffs) do
			if input.xmlFile ~= nil then
				input.xmlFile:delete()

				input.xmlFile = nil
			end

			if input.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(input.sharedLoadRequestId)

				input.sharedLoadRequestId = nil
			end

			if input.rootNode ~= nil then
				delete(input.rootNode)
				delete(input.attachNode)
			end

			g_animationManager:deleteAnimations(input.animationNodes)
		end
	end

	if spec.localPowerTakeOffs ~= nil then
		for _, localPto in pairs(spec.localPowerTakeOffs) do
			if localPto.xmlFile ~= nil then
				localPto.xmlFile:delete()

				localPto.xmlFile = nil
			end

			if localPto.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(localPto.sharedLoadRequestId)

				localPto.sharedLoadRequestId = nil
			end

			g_animationManager:deleteAnimations(localPto.animationNodes)
		end
	end
end

function PowerTakeOffs:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_powerTakeOffs

		if self.currentUpdateDistance < spec.maxUpdateDistance then
			for i = 1, #spec.inputPowerTakeOffs do
				local input = spec.inputPowerTakeOffs[i]

				if input.connectedVehicle ~= nil and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex then
					self:updatePowerTakeOff(input, dt)
				end
			end

			if self.getAttachedImplements ~= nil then
				local impements = self:getAttachedImplements()

				for i = 1, #impements do
					local object = impements[i].object

					if object.updateAttachedPowerTakeOffs ~= nil then
						object:updateAttachedPowerTakeOffs(dt, self)
					end
				end
			end

			local isPowerTakeOffActive = self:getIsPowerTakeOffActive()

			if spec.lastIsPowerTakeOffActive ~= isPowerTakeOffActive then
				for i = 1, #spec.inputPowerTakeOffs do
					local input = spec.inputPowerTakeOffs[i]

					if isPowerTakeOffActive and input.connectedVehicle ~= nil then
						g_animationManager:startAnimations(input.animationNodes)
					else
						g_animationManager:stopAnimations(input.animationNodes)
					end
				end

				for i = 1, #spec.localPowerTakeOffs do
					local localPto = spec.localPowerTakeOffs[i]

					if isPowerTakeOffActive then
						g_animationManager:startAnimations(localPto.animationNodes)
					else
						g_animationManager:stopAnimations(localPto.animationNodes)
					end
				end

				spec.lastIsPowerTakeOffActive = isPowerTakeOffActive
			end
		end
	end
end

function PowerTakeOffs:getPowerTakeOffConfigIndex()
	return 1
end

function PowerTakeOffs:loadPowerTakeOffsFromXML(xmlFile, key)
	local spec = self.spec_powerTakeOffs

	if SpecializationUtil.hasSpecialization(AttacherJoints, self.specializations) then
		self.xmlFile:iterate(key .. ".output", function (_, outputKey)
			local powerTakeOffOutput = {}

			if self:loadOutputPowerTakeOff(self.xmlFile, outputKey, powerTakeOffOutput) then
				table.insert(spec.outputPowerTakeOffs, powerTakeOffOutput)
			end
		end)
	end

	if SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
		self.xmlFile:iterate(key .. ".input", function (_, inputKey)
			local powerTakeOffInput = {}

			if self:loadInputPowerTakeOff(self.xmlFile, inputKey, powerTakeOffInput) then
				table.insert(spec.inputPowerTakeOffs, powerTakeOffInput)
			end
		end)
	end

	self.xmlFile:iterate(key .. ".local", function (_, localKey)
		local powerTakeOffLocal = {}

		if self:loadLocalPowerTakeOff(self.xmlFile, localKey, powerTakeOffLocal) then
			table.insert(spec.localPowerTakeOffs, powerTakeOffLocal)
		end
	end)
end

function PowerTakeOffs:loadOutputPowerTakeOff(xmlFile, baseName, powerTakeOffOutput)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#linkNode", baseName .. "#outputNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#filename", "pto file is now defined in the pto input node")

	powerTakeOffOutput.skipToInputAttacherIndex = xmlFile:getValue(baseName .. "#skipToInputAttacherIndex")
	local outputNode = xmlFile:getValue(baseName .. "#outputNode", nil, self.components, self.i3dMappings)

	if outputNode == nil and powerTakeOffOutput.skipToInputAttacherIndex == nil then
		Logging.xmlWarning(self.xmlFile, "Pto output needs to have either a valid 'outputNode' or a 'skipToInputAttacherIndex' in '%s'", baseName)

		return false
	end

	local attacherJointIndices = {}
	local attacherJointIndicesRaw = xmlFile:getValue(baseName .. "#attacherJointIndices", nil, true)

	if attacherJointIndicesRaw == nil then
		Logging.xmlWarning(self.xmlFile, "Pto output needs to have valid 'attacherJointIndices' in '%s'", baseName)

		return false
	else
		for _, index in ipairs(attacherJointIndicesRaw) do
			attacherJointIndices[index] = true
		end
	end

	powerTakeOffOutput.outputNode = outputNode
	powerTakeOffOutput.attacherJointIndices = attacherJointIndices
	powerTakeOffOutput.connectedInput = nil
	powerTakeOffOutput.ptoName = self.xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
	powerTakeOffOutput.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, baseName, powerTakeOffOutput.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(powerTakeOffOutput.objectChanges, false)

	return true
end

function PowerTakeOffs:loadInputPowerTakeOff(xmlFile, baseName, powerTakeOffInput)
	local inputNode = xmlFile:getValue(baseName .. "#inputNode", nil, self.components, self.i3dMappings)

	if inputNode == nil then
		Logging.xmlWarning(self.xmlFile, "Pto input needs to have a valid 'inputNode' in '%s'", baseName)

		return false
	end

	local inputAttacherJointIndices = {}
	local inputAttacherJointIndicesRaw = xmlFile:getValue(baseName .. "#inputAttacherJointIndices", nil, true)

	if inputAttacherJointIndicesRaw == nil then
		Logging.xmlWarning(self.xmlFile, "Pto output needs to have valid 'inputAttacherJointIndices' in '%s'", baseName)

		return false
	else
		for _, index in ipairs(inputAttacherJointIndicesRaw) do
			inputAttacherJointIndices[index] = true
		end
	end

	powerTakeOffInput.inputNode = inputNode
	powerTakeOffInput.detachNode = xmlFile:getValue(baseName .. "#detachNode", nil, self.components, self.i3dMappings)
	powerTakeOffInput.inputAttacherJointIndices = inputAttacherJointIndices
	powerTakeOffInput.aboveAttacher = xmlFile:getValue(baseName .. "#aboveAttacher", true)
	powerTakeOffInput.color = xmlFile:getValue(baseName .. "#color", nil, true)
	powerTakeOffInput.decalColor = xmlFile:getValue(baseName .. "#decalColor", nil, true)
	powerTakeOffInput.ptoName = self.xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
	powerTakeOffInput.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, baseName, powerTakeOffInput.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(powerTakeOffInput.objectChanges, false)

	local filename = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")

	if filename ~= nil then
		self:loadPowerTakeOffFromConfigFile(powerTakeOffInput, filename)
	end

	return true
end

function PowerTakeOffs:loadLocalPowerTakeOff(xmlFile, baseName, powerTakeOffLocal)
	powerTakeOffLocal.isLocal = true
	powerTakeOffLocal.inputNode = xmlFile:getValue(baseName .. "#startNode", nil, self.components, self.i3dMappings)

	if powerTakeOffLocal.inputNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing startNode for local power take off '%s'", baseName)

		return false
	end

	powerTakeOffLocal.endNode = xmlFile:getValue(baseName .. "#endNode", nil, self.components, self.i3dMappings)

	if powerTakeOffLocal.endNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing endNode for local power take off '%s'", baseName)

		return false
	end

	powerTakeOffLocal.color = xmlFile:getValue(baseName .. "#color", nil, true)
	powerTakeOffLocal.decalColor = xmlFile:getValue(baseName .. "#decalColor", nil, true)
	local filename = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")

	if filename ~= nil then
		self:loadPowerTakeOffFromConfigFile(powerTakeOffLocal, filename)
	end

	return true
end

function PowerTakeOffs:placeLocalPowerTakeOff(powerTakeOff)
	if powerTakeOff.i3dLoaded then
		if not powerTakeOff.isPlaced then
			link(powerTakeOff.endNode, powerTakeOff.linkNode)
			setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
			setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
			self:updatePowerTakeOffLength(powerTakeOff)

			powerTakeOff.isPlaced = true
		end

		self:updatePowerTakeOff(powerTakeOff, 0)
	end
end

function PowerTakeOffs:updatePowerTakeOff(input, dt)
	if input.i3dLoaded and input.updateFunc ~= nil then
		input.updateFunc(self, input, dt)
	end
end

function PowerTakeOffs:updateAttachedPowerTakeOffs(dt, attacherVehicle)
	local spec = self.spec_powerTakeOffs

	for _, input in pairs(spec.inputPowerTakeOffs) do
		if input.connectedVehicle ~= nil and input.connectedVehicle == attacherVehicle and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex then
			self:updatePowerTakeOff(input, dt)
		end
	end
end

function PowerTakeOffs:updatePowerTakeOffLength(input)
	if input.i3dLoaded and input.updateDistanceFunc ~= nil then
		input.updateDistanceFunc(self, input)
	end
end

function PowerTakeOffs:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
	local retOutputs = {}
	local spec = self.spec_powerTakeOffs

	for _, output in pairs(spec.outputPowerTakeOffs) do
		if output.attacherJointIndices[jointDescIndex] ~= nil then
			table.insert(retOutputs, output)
		end
	end

	if #retOutputs > 0 then
		for _, output in ipairs(retOutputs) do
			if output.skipToInputAttacherIndex ~= nil then
				local secondAttacherVehicle = self:getAttacherVehicle()

				if secondAttacherVehicle ~= nil then
					local ownImplement = secondAttacherVehicle:getImplementByObject(self)
					retOutputs = secondAttacherVehicle:getOutputPowerTakeOffsByJointDescIndex(ownImplement.jointDescIndex)

					break
				end
			end
		end
	end

	return retOutputs
end

function PowerTakeOffs:getOutputPowerTakeOffs()
	return self.spec_powerTakeOffs.outputPowerTakeOffs
end

function PowerTakeOffs:getInputPowerTakeOffsByJointDescIndexAndName(jointDescIndex, ptoName)
	local retInputs = {}
	local spec = self.spec_powerTakeOffs

	for _, input in pairs(spec.inputPowerTakeOffs) do
		if input.inputAttacherJointIndices[jointDescIndex] ~= nil and input.ptoName == ptoName then
			table.insert(retInputs, input)
		end
	end

	if #retInputs == 0 then
		for _, output in pairs(spec.outputPowerTakeOffs) do
			if output.skipToInputAttacherIndex == jointDescIndex then
				for index, _ in pairs(output.attacherJointIndices) do
					local implement = self:getImplementFromAttacherJointIndex(index)

					if implement ~= nil then
						retInputs = implement.object:getInputPowerTakeOffsByJointDescIndexAndName(implement.inputJointDescIndex, ptoName)
					end
				end
			end
		end
	end

	return retInputs
end

function PowerTakeOffs:getInputPowerTakeOffs()
	return self.spec_powerTakeOffs.inputPowerTakeOffs
end

function PowerTakeOffs:getIsPowerTakeOffActive()
	return false
end

function PowerTakeOffs:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_powerTakeOffs
	local outputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)

	for _, output in ipairs(outputs) do
		if attachableObject.getInputPowerTakeOffsByJointDescIndexAndName ~= nil then
			local inputs = attachableObject:getInputPowerTakeOffsByJointDescIndexAndName(inputJointDescIndex, output.ptoName)

			for _, input in ipairs(inputs) do
				output.connectedInput = input
				output.connectedVehicle = attachableObject
				input.connectedVehicle = self
				input.connectedOutput = output

				table.insert(spec.delayedPowerTakeOffsMountings, {
					jointDescIndex = jointDescIndex,
					input = input,
					output = output
				})
			end
		end
	end

	return true
end

function PowerTakeOffs:detachPowerTakeOff(detachingVehicle, implement, jointDescIndex)
	local spec = self.spec_powerTakeOffs
	spec.delayedPowerTakeOffsMountings = {}
	local outputs = detachingVehicle:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex or implement.jointDescIndex)

	for _, output in ipairs(outputs) do
		if output.connectedInput ~= nil then
			local input = output.connectedInput

			if input.detachFunc ~= nil then
				input.detachFunc(self, input, output)
			end

			input.connectedVehicle = nil
			input.connectedOutput = nil
			output.connectedVehicle = nil
			output.connectedInput = nil

			ObjectChangeUtil.setObjectChanges(input.objectChanges, false)
			ObjectChangeUtil.setObjectChanges(output.objectChanges, false)
		end
	end

	return true
end

function PowerTakeOffs:checkPowerTakeOffCollision(attacherJointNode, jointDescIndex, isTrailerAttacher)
	if isTrailerAttacher then
		local ptoOutputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)

		if ptoOutputs ~= nil and #ptoOutputs > 0 then
			local ptoOutput = ptoOutputs[1]
			local ptoInput = ptoOutput.connectedInput

			if ptoInput ~= nil then
				local _, y, _ = localToLocal(ptoOutput.outputNode, attacherJointNode, 0, 0, 0)

				if ptoInput.aboveAttacher and y < 0 or not ptoInput.aboveAttacher and y > 0 then
					self:detachPowerTakeOff(self, nil, jointDescIndex)
				end
			end
		end
	end
end

function PowerTakeOffs:parkPowerTakeOff(input)
	if input.detachNode ~= nil then
		link(input.detachNode, input.linkNode)
		link(input.inputNode, input.startNode)
		self:updatePowerTakeOff(input, 0)
		self:updatePowerTakeOffLength(input)
	else
		link(input.inputNode, input.linkNode)
		link(input.inputNode, input.startNode)
		setVisibility(input.linkNode, false)
		setVisibility(input.startNode, false)
	end

	setTranslation(input.linkNode, 0, 0, input.zOffset)
	setTranslation(input.startNode, 0, 0, -input.zOffset)
end

function PowerTakeOffs:onPreAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex)
	self:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
end

function PowerTakeOffs:onPostAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_powerTakeOffs

	for i = #spec.delayedPowerTakeOffsMountings, 1, -1 do
		local delayedMounting = spec.delayedPowerTakeOffsMountings[i]

		if delayedMounting.jointDescIndex == jointDescIndex then
			local input = delayedMounting.input
			local output = delayedMounting.output

			if input.attachFunc ~= nil then
				input.attachFunc(self, input, output)
			end

			ObjectChangeUtil.setObjectChanges(input.objectChanges, true)
			ObjectChangeUtil.setObjectChanges(output.objectChanges, true)
			table.remove(spec.delayedPowerTakeOffsMountings, i)
		end
	end
end

function PowerTakeOffs:onPreDetachImplement(implement)
	self:detachPowerTakeOff(self, implement)
end

function PowerTakeOffs:loadPowerTakeOffFromConfigFile(powerTakeOff, xmlFilename)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = XMLFile.load("PtoConfig", xmlFilename, PowerTakeOffs.xmlSchema)

	if xmlFile ~= nil then
		local i3dFilename = xmlFile:getValue("powerTakeOff#filename")

		if i3dFilename ~= nil then
			i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
			powerTakeOff.sharedLoadRequestId = self:loadSubSharedI3DFile(i3dFilename, false, false, self.onPowerTakeOffI3DLoaded, self, {
				xmlFile,
				powerTakeOff
			})
			powerTakeOff.xmlFile = xmlFile
		else
			Logging.xmlWarning(self.xmlFile, "Failed to open powerTakeOff i3d file '%s' in '%s'", i3dFilename, xmlFilename)
			xmlFile:delete()
		end
	else
		Logging.warning("Failed to open powerTakeOff config file '%s'", xmlFilename)
	end
end

function PowerTakeOffs:onPowerTakeOffI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, powerTakeOff = unpack(args)

	if i3dNode ~= 0 then
		powerTakeOff.startNode = xmlFile:getValue("powerTakeOff.startNode#node", nil, i3dNode)
		powerTakeOff.size = xmlFile:getValue("powerTakeOff#size", 0.19)
		powerTakeOff.minLength = xmlFile:getValue("powerTakeOff#minLength", 0.6)
		powerTakeOff.maxAngle = xmlFile:getValue("powerTakeOff#maxAngle", 45)
		powerTakeOff.zOffset = xmlFile:getValue("powerTakeOff#zOffset", 0)
		powerTakeOff.animationNodes = g_animationManager:loadAnimations(xmlFile, "powerTakeOff.animationNodes", i3dNode, self)

		if xmlFile:getValue("powerTakeOff#isSingleJoint") then
			self:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
		elseif xmlFile:getValue("powerTakeOff#isDoubleJoint") then
			self:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
		else
			self:loadBasicPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
		end

		if powerTakeOff.color ~= nil and #powerTakeOff.color >= 3 then
			local colorShaderParameter = xmlFile:getValue("powerTakeOff#colorShaderParameter")

			if colorShaderParameter ~= nil then
				I3DUtil.setShaderParameterRec(powerTakeOff.startNode, colorShaderParameter, powerTakeOff.color[1], powerTakeOff.color[2], powerTakeOff.color[3])
			end
		end

		if powerTakeOff.decalColor ~= nil and #powerTakeOff.decalColor >= 3 then
			local decalColorShaderParameter = xmlFile:getValue("powerTakeOff#decalColorShaderParameter")

			if decalColorShaderParameter ~= nil then
				I3DUtil.setShaderParameterRec(powerTakeOff.startNode, decalColorShaderParameter, powerTakeOff.decalColor[1], powerTakeOff.decalColor[2], powerTakeOff.decalColor[3])
			end
		end

		link(powerTakeOff.inputNode, powerTakeOff.startNode)

		powerTakeOff.i3dLoaded = true

		if powerTakeOff.isLocal then
			self:placeLocalPowerTakeOff(powerTakeOff)
		else
			self:parkPowerTakeOff(powerTakeOff)
		end

		self:updatePowerTakeOff(powerTakeOff, 0)
		delete(i3dNode)
	elseif not self.isDeleted and not self.isDeleting then
		Logging.xmlWarning(self.xmlFile, "Failed to find powerTakeOff in i3d file '%s'", powerTakeOff.filename)
	end

	xmlFile:delete()

	powerTakeOff.xmlFile = nil
end

function PowerTakeOffs:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startJoint = xmlFile:getValue("powerTakeOff.startJoint#node", nil, rootNode)
	powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, rootNode)
	powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, rootNode)
	local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = dis
	powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, rootNode)
	powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, rootNode)
	powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
	powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, rootNode)
	powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
	powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
	powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
	powerTakeOff.endJoint = xmlFile:getValue("powerTakeOff.endJoint#node", nil, rootNode)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, rootNode)
	local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(betweenLength)
	powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)

	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)

	powerTakeOff.updateFunc = PowerTakeOffs.updateSingleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateSingleJointPowerTakeOff(powerTakeOff, dt)
	local x, y, z = getWorldTranslation(powerTakeOff.linkNode)
	local dx, dy, dz = worldToLocal(powerTakeOff.startNode, x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint, dx, dy, dz, 0, 1, 0)

	dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint), x, y, z)

	setTranslation(powerTakeOff.endJoint, 0, 0, MathUtil.vector3Length(dx, dy, dz))

	local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)

	setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end

function PowerTakeOffs:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startJoint1 = xmlFile:getValue("powerTakeOff.startJoint1#node", nil, rootNode)
	powerTakeOff.startJoint2 = xmlFile:getValue("powerTakeOff.startJoint2#node", nil, rootNode)
	powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, rootNode)
	powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, rootNode)
	local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = dis
	powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, rootNode)
	powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, rootNode)
	powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
	powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, rootNode)
	powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
	powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
	powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
	powerTakeOff.endJoint1 = xmlFile:getValue("powerTakeOff.endJoint1#node", nil, rootNode)
	powerTakeOff.endJoint1Ref = xmlFile:getValue("powerTakeOff.endJoint1#referenceNode", nil, rootNode)
	powerTakeOff.endJoint2 = xmlFile:getValue("powerTakeOff.endJoint2#node", nil, rootNode)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, rootNode)
	local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(betweenLength)
	powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)

	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)

	powerTakeOff.updateFunc = PowerTakeOffs.updateDoubleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateDoubleJointPowerTakeOff(powerTakeOff, dt)
	local x, y, z = getWorldTranslation(powerTakeOff.startNode)
	local dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint2), x, y, z)

	I3DUtil.setDirection(powerTakeOff.endJoint2, dx * 0.5, dy * 0.5, dz, 0, 1, 0)

	x, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
	dx, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint1), x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint1, dx * 0.5, dy * 0.5, dz, 0, 1, 0)

	x, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
	dx, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint2), x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint2, dx, dy, dz, 0, 1, 0)

	dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint1), x, y, z)

	setTranslation(powerTakeOff.endJoint1, 0, 0, MathUtil.vector3Length(dx, dy, dz))

	local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)

	setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end

function PowerTakeOffs:loadBasicPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startNode = xmlFile:getValue("powerTakeOff.startNode#node", nil, rootNode)
	powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, rootNode)
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateDistanceOfTypedPowerTakeOff(powerTakeOff)
	local attachLength = calcDistanceFrom(powerTakeOff.linkNode, powerTakeOff.startNode)
	local transPartScale = math.max(attachLength - powerTakeOff.connectorLength, 0) / powerTakeOff.betweenLength

	setScale(powerTakeOff.translationPart, 1, 1, transPartScale)

	if powerTakeOff.decal ~= nil then
		local transPartLength = transPartScale * powerTakeOff.translationPartLength

		if transPartLength > powerTakeOff.decalMinOffset * 2 + powerTakeOff.decalSize then
			local offset = math.min((transPartLength - powerTakeOff.decalSize) / 2, powerTakeOff.decalOffset)
			local decalTranslation = offset + powerTakeOff.decalSize * 0.5
			local x, y, _ = getTranslation(powerTakeOff.decal)

			setTranslation(powerTakeOff.decal, x, y, -decalTranslation / transPartScale)
			setScale(powerTakeOff.decal, 1, 1, 1 / transPartScale)
		else
			setVisibility(powerTakeOff.decal, false)
		end
	end
end

function PowerTakeOffs:attachTypedPowerTakeOff(powerTakeOff, output)
	if self:validatePowerTakeOffAttachment(powerTakeOff, output) then
		link(output.outputNode, powerTakeOff.linkNode)
		link(powerTakeOff.inputNode, powerTakeOff.startNode)
		setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
		setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
		self:updatePowerTakeOff(powerTakeOff, 0)
		self:updatePowerTakeOffLength(powerTakeOff)
		setVisibility(powerTakeOff.linkNode, true)
		setVisibility(powerTakeOff.startNode, true)
	end
end

function PowerTakeOffs:detachTypedPowerTakeOff(powerTakeOff, output)
	self:parkPowerTakeOff(powerTakeOff)
end

function PowerTakeOffs:validatePowerTakeOffAttachment(powerTakeOff, output)
	if output.outputNode == nil or powerTakeOff.inputNode == nil then
		return false
	end

	local x1, y1, z1 = getWorldTranslation(output.outputNode)
	local x2, y2, z2 = getWorldTranslation(powerTakeOff.inputNode)
	local length = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

	if length < powerTakeOff.minLength then
		return false
	end

	local length2D = MathUtil.vector2Length(x1 - x2, z1 - z2)
	local angle = math.acos(length2D / length)

	if powerTakeOff.maxAngle < angle then
		return false
	end

	return true
end

function PowerTakeOffs:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	local indices = xmlFile:getValue(baseName .. ".powerTakeOffs#indices", nil, true)

	if indices ~= nil then
		entry.powerTakeOffs = {}

		for i = 1, #indices do
			table.insert(entry.powerTakeOffs, indices[i])
		end
	end

	local localIndices = xmlFile:getValue(baseName .. ".powerTakeOffs#localIndices", nil, true)

	if localIndices ~= nil then
		entry.localPowerTakeOffs = {}

		for i = 1, #localIndices do
			table.insert(entry.localPowerTakeOffs, localIndices[i])
		end
	end

	return true
end

function PowerTakeOffs:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if part.powerTakeOffs ~= nil then
		local spec = self.spec_powerTakeOffs

		for i, index in ipairs(part.powerTakeOffs) do
			if spec.inputPowerTakeOffs[index] == nil then
				part.powerTakeOffs[i] = nil

				Logging.xmlWarning(self.xmlFile, "Unable to find powerTakeOff index '%d' for movingPart/movingTool '%s'", index, getName(part.node))
			else
				self:updatePowerTakeOff(spec.inputPowerTakeOffs[index], dt)
			end
		end
	end

	if part.localPowerTakeOffs ~= nil then
		local spec = self.spec_powerTakeOffs

		for i, index in ipairs(part.localPowerTakeOffs) do
			if spec.localPowerTakeOffs[index] == nil then
				part.localPowerTakeOffs[i] = nil

				Logging.xmlWarning(self.xmlFile, "Unable to find local powerTakeOff index '%d' for movingPart/movingTool '%s'", index, getName(part.node))
			else
				self:placeLocalPowerTakeOff(spec.localPowerTakeOffs[index], dt)
			end
		end
	end
end
