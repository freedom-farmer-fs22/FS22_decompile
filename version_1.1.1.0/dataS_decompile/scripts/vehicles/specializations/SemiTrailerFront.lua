SemiTrailerFront = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end
}

function SemiTrailerFront.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", SemiTrailerFront.isDetachAllowed)
end

function SemiTrailerFront.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", SemiTrailerFront)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", SemiTrailerFront)
end

function SemiTrailerFront:onLoad(savegame)
	local spec = self.spec_semiTrailerFront
	spec.inputAttacherCurFade = 1
	spec.inputAttacherFadeDir = 1
	spec.inputAttacherFadeDuration = 1000
	spec.joint = self.spec_attachable.inputAttacherJoints[1]
	spec.joint.lowerRotLimitScaleBackup = {
		spec.joint.lowerRotLimitScale[1],
		spec.joint.lowerRotLimitScale[2],
		spec.joint.lowerRotLimitScale[3]
	}
	spec.attachedSemiTrailerBack = nil
	spec.inputAttacherImplement = nil
	spec.doSemiTrailerLockCheck = true
end

function SemiTrailerFront:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_semiTrailerFront

	if spec.doSemiTrailerLockCheck then
		spec.doSemiTrailerLockCheck = false

		if spec.attachedSemiTrailerBack == nil then
			spec.inputAttacherFadeDir = -1
		end
	end

	if self.isServer and spec.inputAttacherImplement ~= nil and (spec.inputAttacherCurFade > 0 and spec.inputAttacherFadeDir < 0 or spec.inputAttacherCurFade < 1 and spec.inputAttacherFadeDir > 0) then
		spec.inputAttacherCurFade = MathUtil.clamp(spec.inputAttacherCurFade + spec.inputAttacherFadeDir * dt / spec.inputAttacherFadeDuration, 0, 1)
		local lowerRotLimitScale = spec.joint.lowerRotLimitScale
		local lowerRotLimitScaleBackup = spec.joint.lowerRotLimitScaleBackup
		lowerRotLimitScale[1] = lowerRotLimitScaleBackup[1] * spec.inputAttacherCurFade
		lowerRotLimitScale[2] = lowerRotLimitScaleBackup[2] * spec.inputAttacherCurFade
		lowerRotLimitScale[3] = lowerRotLimitScaleBackup[3] * spec.inputAttacherCurFade
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			local attacherJoints = attacherVehicle:getAttacherJoints()
			local jointDesc = attacherJoints[spec.inputAttacherImplement.jointDescIndex]
			local lowerRotLimit = spec.inputAttacherImplement.lowerRotLimit
			local x = lowerRotLimit[1] * lowerRotLimitScale[1]
			local y = lowerRotLimit[2] * lowerRotLimitScale[2]
			local z = lowerRotLimit[3] * lowerRotLimitScale[3]

			setJointRotationLimit(jointDesc.jointIndex, 0, true, -x, x)
			setJointRotationLimit(jointDesc.jointIndex, 1, true, -y, y)
			setJointRotationLimit(jointDesc.jointIndex, 2, true, -z, z)
		end
	end
end

function SemiTrailerFront:isDetachAllowed(superFunc)
	local canBeDatached, warning = superFunc(self)

	if not canBeDatached then
		return false, warning
	end

	local spec = self.spec_semiTrailerFront

	return spec.attachedSemiTrailerBack ~= nil, nil
end

function SemiTrailerFront:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_semiTrailerFront
	spec.attachedSemiTrailerBack = attachable
	spec.inputAttacherFadeDir = 1000
end

function SemiTrailerFront:onPreDetachImplement(implement)
	local spec = self.spec_semiTrailerFront
	spec.attachedSemiTrailerBack = nil
	spec.inputAttacherFadeDir = -1
end

function SemiTrailerFront:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_semiTrailerFront
	spec.inputAttacherImplement = nil
end

function SemiTrailerFront:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_semiTrailerFront
	spec.inputAttacherImplement = attacherVehicle:getImplementByObject(self)
end
