HookLiftTrailer = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Foldable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("HookLiftTrailer")
		schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.jointLimits.key(?)#time", "Key time")
		schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotLimit", "Rotation limit", "0 0 0")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transLimit", "Translation limit", "0 0 0")
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.jointLimits#refAnimation", "Reference animation", "unfoldHand")
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.unloadingAnimation#name", "Unload animation", "unloading")
		schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#speed", "Unload animation speed", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", "Unload animation reverse speed", -1)
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadContainer", "Unload container text", "unload_container")
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadContainer", "Load container text", "load_container")
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadArm", "Unload arm text", "unload_arm")
		schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadArm", "Load arm text", "load_arm")
		schema:setXMLSpecializationType()
	end
}

function HookLiftTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "startTipping", HookLiftTrailer.startTipping)
	SpecializationUtil.registerFunction(vehicleType, "stopTipping", HookLiftTrailer.stopTipping)
	SpecializationUtil.registerFunction(vehicleType, "getIsTippingAllowed", HookLiftTrailer.getIsTippingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getCanDetachContainer", HookLiftTrailer.getCanDetachContainer)
end

function HookLiftTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", HookLiftTrailer.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", HookLiftTrailer.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", HookLiftTrailer.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPtoRpm", HookLiftTrailer.getPtoRpm)
end

function HookLiftTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", HookLiftTrailer)
end

function HookLiftTrailer:onLoad(savegame)
	local spec = self.spec_hookLiftTrailer
	spec.jointLimits = AnimCurve.new(linearInterpolatorN)
	local i = 0

	while true do
		local key = string.format("vehicle.hookLiftTrailer.jointLimits.key(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			if i == 0 then
				spec.jointLimits = nil
			end

			break
		end

		local t = self.xmlFile:getValue(key .. "#time")
		local rx, ry, rz = self.xmlFile:getValue(key .. "#rotLimit", "0 0 0")
		local tx, ty, tz = self.xmlFile:getValue(key .. "#transLimit", "0 0 0")

		spec.jointLimits:addKeyframe({
			rx,
			ry,
			rz,
			tx,
			ty,
			tz,
			time = t
		})

		i = i + 1
	end

	spec.refAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.jointLimits#refAnimation", "unfoldHand")
	spec.unloadingAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#name", "unloading")
	spec.unloadingAnimationSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#speed", 1)
	spec.unloadingAnimationReverseSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", -1)
	spec.texts = {
		unloadContainer = self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadContainer", "unload_container"),
		loadContainer = self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadContainer", "load_container"),
		unloadArm = self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadArm", "unload_arm"),
		loadArm = self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadArm", "load_arm")
	}
end

function HookLiftTrailer:onPostLoad(savegame)
	local spec = self.spec_hookLiftTrailer
	local foldableSpec = self.spec_foldable
	foldableSpec.posDirectionText = spec.texts.unloadArm
	foldableSpec.negDirectionText = spec.texts.loadArm
end

function HookLiftTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_hookLiftTrailer

	if spec.attachedContainer ~= nil then
		local animTime = self:getAnimationTime(spec.refAnimation)
		spec.attachedContainer.object.allowsDetaching = animTime > 0.95

		if (self:getIsAnimationPlaying(spec.refAnimation) or not spec.attachedContainer.limitLocked) and spec.jointLimits ~= nil and not spec.attachedContainer.implement.attachingIsInProgress then
			local v = spec.jointLimits:get(animTime)

			for i = 1, 3 do
				setJointRotationLimit(spec.attachedContainer.jointIndex, i - 1, true, -v[i], v[i])
				setJointTranslationLimit(spec.attachedContainer.jointIndex, i + 2, true, -v[i + 3], v[i + 3])
			end

			if animTime >= 0.99 then
				spec.attachedContainer.limitLocked = true
			end
		end
	end
end

function HookLiftTrailer:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_hookLiftTrailer
	local attacherJoint = attachable:getActiveInputAttacherJoint()

	if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_HOOKLIFT then
		local jointDesc = self:getAttacherJointByJointDescIndex(jointDescIndex)
		spec.attachedContainer = {
			jointIndex = jointDesc.jointIndex,
			implement = self:getImplementByObject(attachable),
			object = attachable,
			limitLocked = false
		}
		local foldableSpec = self.spec_foldable
		foldableSpec.posDirectionText = spec.texts.unloadContainer
		foldableSpec.negDirectionText = spec.texts.loadContainer
	end
end

function HookLiftTrailer:onPreDetachImplement(implement)
	local spec = self.spec_hookLiftTrailer

	if spec.attachedContainer ~= nil and implement == spec.attachedContainer.implement then
		local foldableSpec = self.spec_foldable
		foldableSpec.posDirectionText = spec.texts.unloadArm
		foldableSpec.negDirectionText = spec.texts.loadArm
		spec.attachedContainer = nil
	end
end

function HookLiftTrailer:startTipping()
	local spec = self.spec_hookLiftTrailer

	self:playAnimation(spec.unloadingAnimation, spec.unloadingAnimationSpeed, self:getAnimationTime(spec.unloadingAnimation), true)
end

function HookLiftTrailer:stopTipping()
	local spec = self.spec_hookLiftTrailer

	self:playAnimation(spec.unloadingAnimation, spec.unloadingAnimationReverseSpeed, self:getAnimationTime(spec.unloadingAnimation), true)
end

function HookLiftTrailer:getIsTippingAllowed()
	local spec = self.spec_hookLiftTrailer

	return self:getAnimationTime(spec.refAnimation) == 0
end

function HookLiftTrailer:getCanDetachContainer()
	local spec = self.spec_hookLiftTrailer

	return self:getAnimationTime(spec.refAnimation) == 1
end

function HookLiftTrailer:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_hookLiftTrailer

	if self:getAnimationTime(spec.unloadingAnimation) > 0 then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function HookLiftTrailer:isDetachAllowed(superFunc)
	if self:getAnimationTime(self.spec_hookLiftTrailer.unloadingAnimation) == 0 then
		return superFunc(self)
	else
		return false, nil
	end
end

function HookLiftTrailer:getDoConsumePtoPower(superFunc)
	local spec = self.spec_hookLiftTrailer
	local doConsume = superFunc(self)

	return doConsume or self:getIsAnimationPlaying(spec.refAnimation) or self:getIsAnimationPlaying(spec.unloadingAnimation)
end

function HookLiftTrailer:getPtoRpm(superFunc)
	local spec = self.spec_hookLiftTrailer
	local rpm = superFunc(self)

	if self:getIsAnimationPlaying(spec.refAnimation) or self:getIsAnimationPlaying(spec.unloadingAnimation) then
		return self.spec_powerConsumer.ptoRpm
	else
		return rpm
	end
end
