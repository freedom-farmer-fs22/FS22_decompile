ManureBarrel = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("ManureBarrel")
		schema:register(XMLValueType.INT, "vehicle.manureBarrel#attacherJointIndex", "Attacher joint index")
		schema:setXMLSpecializationType()
	end
}

function ManureBarrel.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", ManureBarrel.getAreEffectsVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", ManureBarrel.getIsWorkAreaActive)
end

function ManureBarrel.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManureBarrel)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", ManureBarrel)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", ManureBarrel)
end

function ManureBarrel:onLoad(savegame)
	local spec = self.spec_manureBarrel

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.manureBarrel#toolAttachAnimName", "vehicle.attacherJoints.attacherJoint.objectChange")

	spec.attachToolJointIndex = self.xmlFile:getValue("vehicle.manureBarrel#attacherJointIndex")
end

function ManureBarrel:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_manureBarrel

	if jointDescIndex == spec.attachToolJointIndex then
		spec.attachedTool = attachable
	end
end

function ManureBarrel:onPostDetachImplement(implementIndex)
	local spec = self.spec_manureBarrel
	local object = nil

	if self.getObjectFromImplementIndex ~= nil then
		object = self:getObjectFromImplementIndex(implementIndex)
	end

	if object ~= nil then
		local attachedImplements = self:getAttachedImplements()

		if attachedImplements[implementIndex].jointDescIndex == spec.attachToolJointIndex then
			spec.attachedTool = nil
		end
	end
end

function ManureBarrel:getAreEffectsVisible(superFunc)
	local spec = self.spec_manureBarrel

	if spec.attachedTool ~= nil then
		return false
	end

	return superFunc(self)
end

function ManureBarrel:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_manureBarrel

	if spec.attachedTool ~= nil then
		return false
	end

	return superFunc(self, workArea)
end
