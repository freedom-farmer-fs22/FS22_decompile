CCTDrivable = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Enterable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("CCTDrivable")
		schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctRadius", "CCT radius", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctHeight", "CCT height", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#customOffset", "CCT custom offset", 0)
		schema:setXMLSpecializationType()
	end
}

function CCTDrivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "moveCCT", CCTDrivable.moveCCT)
	SpecializationUtil.registerFunction(vehicleType, "getIsCCTOnGround", CCTDrivable.getIsCCTOnGround)
	SpecializationUtil.registerFunction(vehicleType, "getCCTCollisionMask", CCTDrivable.getCCTCollisionMask)
	SpecializationUtil.registerFunction(vehicleType, "getCCTWorldTranslation", CCTDrivable.getCCTWorldTranslation)
end

function CCTDrivable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPosition", CCTDrivable.setWorldPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", CCTDrivable.setWorldPositionQuaternion)
end

function CCTDrivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CCTDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", CCTDrivable)
end

function CCTDrivable:onLoad(savegame)
	local spec = self.spec_cctdrivable
	spec.cctRadius = self.xmlFile:getValue("vehicle.cctDrivable#cctRadius", 1)
	spec.cctHeight = self.xmlFile:getValue("vehicle.cctDrivable#cctHeight", 1)
	spec.customOffset = self.xmlFile:getValue("vehicle.cctDrivable#customOffset", 0)
	spec.cctCenterOffset = spec.cctRadius + spec.cctHeight * 0.5
	spec.kinematicCollisionMask = 4
	spec.movementCollisionMask = 31

	if self.isServer then
		local mass = self.components[1].defaultMass * 1000
		spec.cctNode = createTransformGroup("cctDrivable")

		link(getRootNode(), spec.cctNode)

		spec.controllerIndex = createCCT(spec.cctNode, spec.cctRadius, spec.cctHeight, 0.6, 45, 0.1, spec.kinematicCollisionMask, mass)
	end
end

function CCTDrivable:onDelete()
	local spec = self.spec_cctdrivable

	if spec.controllerIndex ~= nil then
		removeCCT(spec.controllerIndex)
		delete(spec.cctNode)
	end
end

function CCTDrivable:moveCCT(moveX, moveY, moveZ)
	if self.isServer then
		local spec = self.spec_cctdrivable

		moveCCT(spec.controllerIndex, moveX, moveY, moveZ, spec.movementCollisionMask)
		self:raiseActive()
	end
end

function CCTDrivable:getIsCCTOnGround()
	local spec = self.spec_cctdrivable

	if self.isServer then
		local _, _, isOnGround = getCCTCollisionFlags(spec.controllerIndex)

		return isOnGround
	end

	return false
end

function CCTDrivable:getCCTCollisionMask()
	local spec = self.spec_cctdrivable

	return spec.kinematicCollisionMask
end

function CCTDrivable:getCCTWorldTranslation()
	local spec = self.spec_cctdrivable
	local cctX, cctY, cctZ = getTranslation(spec.cctNode)
	cctY = cctY - spec.cctCenterOffset

	return cctX, cctY, cctZ
end

function CCTDrivable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
	superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)

	if self.isServer and i == 1 then
		local spec = self.spec_cctdrivable

		setTranslation(spec.cctNode, x, y + spec.cctCenterOffset, z)
	end
end

function CCTDrivable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)

	if self.isServer and i == 1 then
		local spec = self.spec_cctdrivable

		setTranslation(spec.cctNode, x, y + spec.cctCenterOffset, z)
	end
end
