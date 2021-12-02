SupportVehicle = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("SupportVehicle")
		schema:register(XMLValueType.STRING, "vehicle.supportVehicle#filename", "Path to support vehicle xml")
		schema:register(XMLValueType.INT, "vehicle.supportVehicle#attacherJointIndex", "Attacher joint index on support vehicle", 1)
		schema:register(XMLValueType.INT, "vehicle.supportVehicle#inputAttacherJointIndex", "Input attacher joint index on own vehicle", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.supportVehicle#minTerrainDistance", "Min. distance from vehicle root to ground (To have enough space for support vehicle)", 0.75)
		schema:register(XMLValueType.FLOAT, "vehicle.supportVehicle#attachedMass", "Mass of vehicle components if attached to support vehicle (kg)", 10)
		schema:register(XMLValueType.STRING, "vehicle.supportVehicle.configuration(?)#name", "Configuration name")
		schema:register(XMLValueType.INT, "vehicle.supportVehicle.configuration(?)#id", "Configuration id")
		schema:setXMLSpecializationType()
	end
}

function SupportVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addSupportVehicle", SupportVehicle.addSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "removeSupportVehicle", SupportVehicle.removeSupportVehicle)
end

function SupportVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowMultipleAttachments", SupportVehicle.getAllowMultipleAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "resolveMultipleAttachments", SupportVehicle.resolveMultipleAttachments)
end

function SupportVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", SupportVehicle)
end

function SupportVehicle:onLoad(savegame)
	local spec = self.spec_supportVehicle
	local baseKey = "vehicle.supportVehicle"
	local filename = self.xmlFile:getValue(baseKey .. "#filename")

	if filename ~= nil then
		spec.filename = Utils.getFilename(filename, self.customEnvironment)
	end

	spec.attacherJointIndex = self.xmlFile:getValue(baseKey .. "#attacherJointIndex", 1)
	spec.inputAttacherJointIndex = self.xmlFile:getValue(baseKey .. "#inputAttacherJointIndex", 1)
	spec.minTerrainDistance = self.xmlFile:getValue(baseKey .. "#minTerrainDistance", 0.75)
	spec.attachedMass = self.xmlFile:getValue(baseKey .. "#attachedMass", 10) / 1000
	spec.heightChecks = {}

	table.insert(spec.heightChecks, {
		x = self.size.width / 2 + self.size.widthOffset,
		z = self.size.length / 2 + self.size.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = -self.size.width / 2 + self.size.widthOffset,
		z = self.size.length / 2 + self.size.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = self.size.width / 2 + self.size.widthOffset,
		z = -self.size.length / 2 + self.size.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = -self.size.width / 2 + self.size.widthOffset,
		z = -self.size.length / 2 + self.size.lengthOffset
	})

	spec.configurations = {}
	local i = 0

	while true do
		local configurationKey = string.format("%s.configuration(%d)", baseKey, i)

		if not self.xmlFile:hasProperty(configurationKey) then
			break
		end

		local name = self.xmlFile:getValue(configurationKey .. "#name")
		local id = self.xmlFile:getValue(configurationKey .. "#id")

		if name ~= nil and id ~= nil then
			spec.configurations[name] = id
		end

		i = i + 1
	end

	spec.firstRun = true

	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onDelete", SupportVehicle)
		SpecializationUtil.removeEventListener(self, "onUpdate", SupportVehicle)
		SpecializationUtil.removeEventListener(self, "onPostDetach", SupportVehicle)
	end
end

function SupportVehicle:onDelete()
	self:removeSupportVehicle()
end

function SupportVehicle:onPostDetach(attacherVehicle, implement)
	if not self.isDeleting then
		local spec = self.spec_supportVehicle

		self:addSupportVehicle(spec.filename, spec.inputAttacherJointIndex, spec.attacherJointIndex)
	end
end

function SupportVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_supportVehicle

	if spec.firstRun then
		if self:getAttacherVehicle() == nil then
			self:addSupportVehicle(spec.filename, spec.inputAttacherJointIndex, spec.attacherJointIndex)
		end

		spec.firstRun = false
	end
end

function SupportVehicle:addSupportVehicle(filename, inputAttacherJointIndex, attacherJointIndex)
	local spec = self.spec_supportVehicle

	if spec.filename ~= nil and spec.supportVehicle == nil then
		local component = self.components[1].node

		for _, check in ipairs(spec.heightChecks) do
			local x, y, z = localToWorld(component, check.x, 0, check.z)
			local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
			local difference = y - height

			if difference < spec.minTerrainDistance then
				for _, comp in ipairs(self.components) do
					local cx, cy, cz = getWorldTranslation(comp.node)

					setWorldTranslation(comp.node, cx, cy + spec.minTerrainDistance - difference, cz)
				end
			end
		end

		local storeItem = g_storeManager:getItemByXMLFilename(filename)

		if storeItem ~= nil then
			local inputAttacherJoint = self:getInputAttacherJoints()[inputAttacherJointIndex]

			if inputAttacherJoint ~= nil then
				local x, y, z = localToWorld(inputAttacherJoint.node, 0, 0, 0)
				local dirX, _, dirZ = localDirectionToWorld(inputAttacherJoint.node, 1, 0, 0)
				local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
				local location = {
					x = x,
					y = y,
					z = z,
					yRot = yRot
				}

				self:removeFromPhysics()

				local vehicle = VehicleLoadingUtil.loadVehicle(storeItem.xmlFilename, location, false, 0, Vehicle.PROPERTY_STATE_NONE, self:getActiveFarm(), spec.configurations, nil, SupportVehicle.supportVehicleLoaded, self, {
					attacherJointIndex,
					inputAttacherJointIndex,
					inputAttacherJoint.node
				})

				if vehicle ~= nil then
					vehicle:setIsSupportVehicle()
				end
			end
		else
			Logging.xmlWarning(self.xmlFile, "Unable to find support vehicle '%s'.", filename)
		end
	end
end

function SupportVehicle:supportVehicleLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK and vehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		self:addToPhysics()

		local spec = self.spec_supportVehicle

		for i = 1, #self.components do
			setMass(self.components[i].node, spec.attachedMass)
		end

		if not self.isDeleted and attacherVehicle == nil then
			local offset = {
				0,
				0,
				0
			}
			local dirOffset = {
				0,
				0,
				0
			}

			if vehicle.getAttacherJoints ~= nil then
				local attacherJoints = vehicle:getAttacherJoints()

				if attacherJoints[asyncCallbackArguments[1]] ~= nil then
					offset = attacherJoints[asyncCallbackArguments[1]].jointOrigOffsetComponent
					dirOffset = attacherJoints[asyncCallbackArguments[1]].jointOrigDirOffsetComponent
				end
			end

			local x, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
			local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], unpack(dirOffset))
			local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)

			vehicle:setAbsolutePosition(x, y, z, 0, yRot, 0)
			vehicle:attachImplement(self, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, , true)
			self.rootVehicle:updateSelectableObjects()
			self.rootVehicle:setSelectedVehicle(self)

			spec.supportVehicle = vehicle
		else
			vehicle:delete()
		end
	end
end

function SupportVehicle:removeSupportVehicle()
	local spec = self.spec_supportVehicle

	if spec.supportVehicle ~= nil then
		spec.supportVehicle:delete()

		spec.supportVehicle = nil
	end

	if self.isServer and self.components ~= nil then
		for i = 1, #self.components do
			local component = self.components[i]

			setMass(component.node, component.defaultMass)
		end
	end
end

function SupportVehicle:getAllowMultipleAttachments(superFunc)
	return true
end

function SupportVehicle:resolveMultipleAttachments(superFunc)
	if self.isServer then
		self:removeSupportVehicle()
	end

	superFunc(self)
end
