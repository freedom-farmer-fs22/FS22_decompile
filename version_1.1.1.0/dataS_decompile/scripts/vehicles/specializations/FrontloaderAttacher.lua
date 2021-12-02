FrontloaderAttacher = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", FrontloaderAttacher)
		SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", FrontloaderAttacher)
		SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", FrontloaderAttacher)
	end,
	initSpecialization = function ()
		g_configurationManager:addConfigurationType("frontloader", g_i18n:getText("configuration_frontloaderAttacher"), nil, , , , ConfigurationUtil.SELECTOR_MULTIOPTION)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FrontloaderAttacher")

		local basePath = "vehicle.frontloaderConfigurations.frontloaderConfiguration(?)"

		AttacherJoints.registerAttacherJointXMLPaths(schema, basePath .. ".attacherJoint")
		schema:register(XMLValueType.BOOL, basePath .. ".attacherJoint#frontAxisLimitJoint", "Front axis joint will be limited while attached", true)
		schema:register(XMLValueType.INT, basePath .. ".attacherJoint#frontAxisJoint", "Front axis joint index", 1)
		ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
		schema:setXMLSpecializationType()
	end,
	onLoad = function (self, savegame)
		if self.configurations.frontloader ~= nil then
			local spec = self.spec_frontloaderAttacher
			local attacherJointsSpec = self.spec_attacherJoints
			spec.attacherJoint = {}
			local key = string.format("vehicle.frontloaderConfigurations.frontloaderConfiguration(%d)", self.configurations.frontloader - 1)

			if self.xmlFile:hasProperty(key .. ".attacherJoint") and self:loadAttacherJointFromXML(spec.attacherJoint, self.xmlFile, key .. ".attacherJoint", 0) then
				table.insert(attacherJointsSpec.attacherJoints, spec.attacherJoint)

				local frontAxisLimitJoint = self.xmlFile:getValue(key .. ".attacherJoint#frontAxisLimitJoint", true)

				if frontAxisLimitJoint then
					local frontAxisJoint = self.xmlFile:getValue(key .. ".attacherJoint#frontAxisJoint", 1)

					if self.componentJoints[frontAxisJoint] ~= nil then
						spec.frontAxisJoint = frontAxisJoint
					else
						print("Warning: Invalid front-axis joint '" .. tostring(frontAxisJoint) .. "' in '" .. self.configFileName .. "'")
					end
				end

				ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.frontloaderConfigurations.frontloaderConfiguration", self.configurations.frontloader, self.components, self)
			else
				ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.frontloaderConfigurations.frontloaderConfiguration", 1, self.components, self)

				spec.attacherJoint = nil
			end
		end
	end,
	onPreDetachImplement = function (self, implement)
		local spec = self.spec_frontloaderAttacher

		if spec.frontAxisJoint ~= nil then
			local attacherJoint = nil
			local attacherJointIndex = implement.jointDescIndex
			local attacherJoints = self:getAttacherJoints()

			if attacherJoints ~= nil then
				attacherJoint = attacherJoints[attacherJointIndex]
			end

			if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER and self.isServer then
				for i = 1, 3 do
					self:setComponentJointRotLimit(self.componentJoints[spec.frontAxisJoint], i, -spec.rotLimit[i], spec.rotLimit[i])
				end
			end
		end
	end,
	onPreAttachImplement = function (self, attachable, inputJointDescIndex, jointDescIndex)
		local spec = self.spec_frontloaderAttacher

		if spec.frontAxisJoint ~= nil then
			local attacherJoint = nil
			local attacherJoints = self:getAttacherJoints()

			if attacherJoints ~= nil then
				attacherJoint = attacherJoints[jointDescIndex]
			end

			if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER and self.isServer then
				spec.rotLimit = {
					unpack(self.componentJoints[spec.frontAxisJoint].rotLimit)
				}

				for i = 1, 3 do
					self:setComponentJointRotLimit(self.componentJoints[spec.frontAxisJoint], i, 0, 0)
				end
			end
		end
	end
}
