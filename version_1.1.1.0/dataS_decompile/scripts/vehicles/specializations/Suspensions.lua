Suspensions = {
	DEFAULT_MAX_UPDATE_DISTANCE = 40,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function Suspensions.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Suspensions")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.suspensions.suspension(?)#node", "Suspension node")
	schema:register(XMLValueType.BOOL, "vehicle.suspensions.suspension(?)#useCharacterTorso", "Use character torso instead of node")
	schema:register(XMLValueType.FLOAT, "vehicle.suspensions.suspension(?)#weight", "Weight in kg", 500)
	schema:register(XMLValueType.VECTOR_ROT, "vehicle.suspensions.suspension(?)#minRotation", "Min. rotation")
	schema:register(XMLValueType.VECTOR_ROT, "vehicle.suspensions.suspension(?)#maxRotation", "Max. rotation")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.suspensions.suspension(?)#startTranslationOffset", "Custom translation offset")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.suspensions.suspension(?)#minTranslation", "Min. translation")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.suspensions.suspension(?)#maxTranslation", "Max. translation")
	schema:register(XMLValueType.FLOAT, "vehicle.suspensions.suspension(?)#maxVelocityDifference", "Max. velocity difference", 0.1)
	schema:register(XMLValueType.VECTOR_2, "vehicle.suspensions.suspension(?)#suspensionParametersX", "Suspension parameters X", "0 0")
	schema:register(XMLValueType.VECTOR_2, "vehicle.suspensions.suspension(?)#suspensionParametersY", "Suspension parameters Y", "0 0")
	schema:register(XMLValueType.VECTOR_2, "vehicle.suspensions.suspension(?)#suspensionParametersZ", "Suspension parameters Z", "0 0")
	schema:register(XMLValueType.BOOL, "vehicle.suspensions.suspension(?)#inverseMovement", "Invert movement", false)
	schema:register(XMLValueType.BOOL, "vehicle.suspensions.suspension(?)#serverOnly", "Suspension is only calculated on server side", false)
	schema:register(XMLValueType.FLOAT, "vehicle.suspensions#maxUpdateDistance", "Max. distance to vehicle root to update suspension nodes", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:setXMLSpecializationType()
end

function Suspensions.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSuspensionNodeFromIndex", Suspensions.getSuspensionNodeFromIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsSuspensionNodeActive", Suspensions.getIsSuspensionNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "setSuspensionNodeCharacter", Suspensions.setSuspensionNodeCharacter)
end

function Suspensions.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", Suspensions)
end

function Suspensions:onLoad(savegame)
	if self.isClient then
		local spec = self.spec_suspensions
		spec.suspensionNodes = {}
		local i = 0

		while true do
			local key = string.format("vehicle.suspensions.suspension(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local entry = {
				node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
				refNodeOffset = {
					0,
					0,
					0
				}
			}

			if entry.node ~= nil then
				local component = self:getParentComponent(entry.node)

				if component ~= nil then
					entry.component = component
					entry.refNodeOffset = {
						localToLocal(entry.node, component, 0, 0, 0)
					}
				end
			end

			entry.useCharacterTorso = self.xmlFile:getValue(key .. "#useCharacterTorso", false)

			if entry.node ~= nil and entry.component ~= nil or entry.useCharacterTorso then
				entry.weight = self.xmlFile:getValue(key .. "#weight", 500)
				entry.minRotation = self.xmlFile:getValue(key .. "#minRotation", nil, true)
				entry.maxRotation = self.xmlFile:getValue(key .. "#maxRotation", nil, true)
				entry.isRotational = entry.minRotation ~= nil and entry.maxRotation ~= nil

				if not entry.isRotational and not entry.useCharacterTorso then
					entry.baseTranslation = {
						getTranslation(entry.node)
					}
					entry.startTranslationOffset = self.xmlFile:getValue(key .. "#startTranslationOffset", "0 0 0", true)

					for j = 1, 3 do
						entry.baseTranslation[j] = entry.baseTranslation[j] + entry.startTranslationOffset[j]
					end

					entry.minTranslation = self.xmlFile:getValue(key .. "#minTranslation", nil, true)
					entry.maxTranslation = self.xmlFile:getValue(key .. "#maxTranslation", nil, true)
				end

				entry.maxVelocityDifference = self.xmlFile:getValue(key .. "#maxVelocityDifference", 0.1)
				local suspensionParametersX = self.xmlFile:getValue(key .. "#suspensionParametersX", "0 0", true)
				local suspensionParametersY = self.xmlFile:getValue(key .. "#suspensionParametersY", "0 0", true)
				local suspensionParametersZ = self.xmlFile:getValue(key .. "#suspensionParametersZ", "0 0", true)
				entry.suspensionParameters = {
					{},
					{},
					{}
				}

				for j = 1, 2 do
					entry.suspensionParameters[1][j] = suspensionParametersX[j] * 1000
					entry.suspensionParameters[2][j] = suspensionParametersY[j] * 1000
					entry.suspensionParameters[3][j] = suspensionParametersZ[j] * 1000
				end

				entry.inverseMovement = self.xmlFile:getValue(key .. "#inverseMovement", false)
				entry.serverOnly = self.xmlFile:getValue(key .. "#serverOnly", false)
				entry.lastRefNodePosition = nil
				entry.lastRefNodeVelocity = nil
				entry.curRotation = {
					0,
					0,
					0
				}
				entry.curRotationSpeed = {
					0,
					0,
					0
				}
				entry.curTranslation = {
					0,
					0,
					0
				}
				entry.curTranslationSpeed = {
					0,
					0,
					0
				}
				entry.curAcc = {
					0,
					0,
					0
				}
			end

			if not entry.serverOnly or self.isServer then
				table.insert(spec.suspensionNodes, entry)
			end

			i = i + 1
		end

		spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.suspensions#maxUpdateDistance", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)

		if #spec.suspensionNodes > 0 then
			spec.suspensionAvailable = true
		end
	end

	if not self.spec_suspensions.suspensionAvailable then
		SpecializationUtil.removeEventListener(self, "onUpdate", Suspensions)
		SpecializationUtil.removeEventListener(self, "onEnterVehicle", Suspensions)
		SpecializationUtil.removeEventListener(self, "onLeaveVehicle", Suspensions)
		SpecializationUtil.removeEventListener(self, "onVehicleCharacterChanged", Suspensions)
	end
end

function Suspensions:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_suspensions

	if self.currentUpdateDistance < spec.maxUpdateDistance then
		local timeDelta = 0.001 * g_physicsDt

		for _, suspension in ipairs(spec.suspensionNodes) do
			if suspension.node ~= nil and entityExists(suspension.node) then
				suspension.curAcc[3] = 0
				suspension.curAcc[2] = 0
				suspension.curAcc[1] = 0

				if self:getIsSuspensionNodeActive(suspension) then
					local wx, wy, wz = localToWorld(suspension.component, unpack(suspension.refNodeOffset))

					if suspension.lastRefNodePosition == nil then
						suspension.lastRefNodePosition = {
							wx,
							wy,
							wz
						}
						suspension.lastRefNodeVelocity = {
							0,
							0,
							0
						}
					end

					local direction = suspension.inverseMovement and -1 or 1
					local newVelX = (wx - suspension.lastRefNodePosition[1]) / timeDelta * direction
					local newVelY = (wy - suspension.lastRefNodePosition[2]) / timeDelta * direction
					local newVelZ = (wz - suspension.lastRefNodePosition[3]) / timeDelta * direction
					local oldVelX, oldVelY, oldVelZ = unpack(suspension.lastRefNodeVelocity)
					local velDiffX, velDiffY, velDiffZ = worldDirectionToLocal(getParent(suspension.node), newVelX - oldVelX, newVelY - oldVelY, newVelZ - oldVelZ)
					velDiffX = MathUtil.clamp(velDiffX, -suspension.maxVelocityDifference, suspension.maxVelocityDifference)
					velDiffY = MathUtil.clamp(velDiffY, -suspension.maxVelocityDifference, suspension.maxVelocityDifference)
					velDiffZ = MathUtil.clamp(velDiffZ, -suspension.maxVelocityDifference, suspension.maxVelocityDifference)

					if suspension.isRotational then
						if suspension.useCharacterTorso then
							suspension.curAcc[1], suspension.curAcc[2], suspension.curAcc[3] = MathUtil.crossProduct(velDiffX / timeDelta, velDiffY / timeDelta, velDiffZ / timeDelta, 1, 0, 0)
						else
							suspension.curAcc[1], suspension.curAcc[2], suspension.curAcc[3] = MathUtil.crossProduct(velDiffX / timeDelta, velDiffY / timeDelta, velDiffZ / timeDelta, 0, 1, 0)
						end
					else
						suspension.curAcc[3] = -velDiffZ / timeDelta
						suspension.curAcc[2] = -velDiffY / timeDelta
						suspension.curAcc[1] = -velDiffX / timeDelta
					end

					suspension.lastRefNodePosition[1] = wx
					suspension.lastRefNodePosition[2] = wy
					suspension.lastRefNodePosition[3] = wz
					suspension.lastRefNodeVelocity[1] = newVelX
					suspension.lastRefNodeVelocity[2] = newVelY
					suspension.lastRefNodeVelocity[3] = newVelZ
				end

				for i = 1, 3 do
					local suspensionParameter = suspension.suspensionParameters[i]

					if suspensionParameter[1] > 0 and suspensionParameter[2] > 0 then
						local f = suspension.weight * suspension.curAcc[i]
						local k = suspensionParameter[1]
						local c = suspensionParameter[2]

						if suspension.isRotational then
							local x = suspension.curRotation[i]
							local vx = suspension.curRotationSpeed[i]
							local force = f - k * x - c * vx
							local m = suspension.weight
							local h = timeDelta
							local numerator = h * (force + h * -k * vx) / m
							local denumerator = 1 - (-c + h * -k) * h / m
							local curRotationSpeed = vx + numerator / denumerator
							local newRotation = x + curRotationSpeed * timeDelta
							newRotation = MathUtil.clamp(newRotation, suspension.minRotation[i], suspension.maxRotation[i])
							suspension.curRotationSpeed[i] = (newRotation - x) / timeDelta
							suspension.curRotation[i] = newRotation
						else
							local x = suspension.curTranslation[i]
							local vx = suspension.curTranslationSpeed[i]
							local force = f - k * x - c * vx
							local m = suspension.weight
							local h = timeDelta
							local numerator = h * (force + h * -k * vx) / m
							local denumerator = 1 - (-c + h * -k) * h / m
							local curTranslationSpeed = vx + numerator / denumerator
							local newTranslation = x + curTranslationSpeed * timeDelta
							newTranslation = MathUtil.clamp(newTranslation, suspension.minTranslation[i], suspension.maxTranslation[i])
							suspension.curTranslationSpeed[i] = (newTranslation - x) / timeDelta
							suspension.curTranslation[i] = newTranslation
						end
					end
				end

				if suspension.isRotational then
					setRotation(suspension.node, suspension.curRotation[1], suspension.curRotation[2], suspension.curRotation[3])
				else
					setTranslation(suspension.node, suspension.baseTranslation[1] + suspension.curTranslation[1], suspension.baseTranslation[2] + suspension.curTranslation[2], suspension.baseTranslation[3] + suspension.curTranslation[3])
				end

				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(suspension.node)
				end
			elseif suspension.node ~= nil then
				Logging.xmlError(self.xmlFile, "Failed to update suspension node %d. Node does not exist anymore!", suspension.node)

				suspension.node = nil
			end
		end
	end
end

function Suspensions:getSuspensionNodeFromIndex(suspensionIndex)
	local spec = self.spec_suspensions

	if spec.suspensionAvailable then
		return self.spec_suspensions.suspensionNodes[suspensionIndex]
	end
end

function Suspensions:getIsSuspensionNodeActive(suspensionNode)
	return suspensionNode.node ~= nil and suspensionNode.component ~= nil
end

function Suspensions:setSuspensionNodeCharacter(suspensionNode, character)
	if suspensionNode.useCharacterTorso then
		suspensionNode.node = character.thirdPersonSuspensionNode

		if suspensionNode.node ~= nil then
			local component = self:getParentComponent(suspensionNode.node)

			if component ~= nil then
				suspensionNode.refNodeOffset = {
					localToLocal(character.characterNode, component, 0, 0, 0)
				}
				suspensionNode.component = component
			end
		end
	end
end

function Suspensions:onEnterVehicle(isControlling)
	if self.getVehicleCharacter ~= nil then
		local vehicleCharacter = self:getVehicleCharacter()

		if vehicleCharacter ~= nil then
			local spec = self.spec_suspensions

			for _, suspensionNode in ipairs(spec.suspensionNodes) do
				self:setSuspensionNodeCharacter(suspensionNode, vehicleCharacter)
			end
		end
	end
end

function Suspensions:onLeaveVehicle()
	local spec = self.spec_suspensions

	for _, suspension in ipairs(spec.suspensionNodes) do
		if suspension.useCharacterTorso then
			suspension.node = nil
		end
	end
end

function Suspensions:onVehicleCharacterChanged(character)
	local spec = self.spec_suspensions

	for _, suspensionNode in ipairs(spec.suspensionNodes) do
		self:setSuspensionNodeCharacter(suspensionNode, character)
	end
end

function Suspensions:getSuspensionModfier()
	local spec = self.spec_suspensions
	local index = 1

	if #spec.suspensionNodes >= 2 and not spec.suspensionNodes[2].useCharacterTorso and not spec.suspensionNodes[2].isRotational then
		index = 2
	end

	local suspensionNode = spec.suspensionNodes[index]

	if suspensionNode ~= nil and not suspensionNode.isRotational then
		return suspensionNode.curTranslation[2]
	end

	return 0
end

g_soundManager:registerModifierType("SUSPENSION", Suspensions.getSuspensionModfier)
