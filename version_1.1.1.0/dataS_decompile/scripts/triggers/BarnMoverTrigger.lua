BarnMoverTrigger = {}
local BarnMoverTrigger_mt = Class(BarnMoverTrigger)

function BarnMoverTrigger:onCreate(id)
	g_currentMission:addUpdateable(BarnMoverTrigger.new(id))
end

function BarnMoverTrigger.new(id, customMt)
	local instance = {}

	if customMt ~= nil then
		setmetatable(instance, customMt)
	else
		setmetatable(instance, BarnMoverTrigger_mt)
	end

	instance.triggerId = getChildAt(id, 0)
	instance.triggerTargetId = getChildAt(id, 1)

	if g_currentMission:getIsServer() then
		addTrigger(instance.triggerId, "triggerCallback", instance)
	end

	addTrigger(instance.triggerTargetId, "triggerCallbackTarget", instance)

	instance.dirLength = 0.008
	instance.dirX, instance.dirY, instance.dirZ = localDirectionToWorld(instance.triggerId, 0, 0, 1)
	instance.dirX = instance.dirX * instance.dirLength
	instance.dirY = instance.dirY * instance.dirLength
	instance.dirZ = instance.dirZ * instance.dirLength
	instance.targetVelocity = 2
	instance.touched = {}

	return instance
end

function BarnMoverTrigger:delete()
	if g_currentMission:getIsServer() then
		removeTrigger(self.triggerId)
	end

	removeTrigger(self.triggerTargetId)
end

function BarnMoverTrigger:update(dt)
	for k, _ in pairs(self.touched) do
		local vx, vy, vz = getLinearVelocity(k)
		local dot = vx * self.dirX + vy * self.dirY + vz * self.dirZ
		local v = dot / self.dirLength

		if v < self.targetVelocity then
			addForce(k, self.dirX * dt, self.dirY * dt, self.dirZ * dt, 0, 0, 0, true)
		end
	end
end

function BarnMoverTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		local touched = self.touched[otherId]

		if touched ~= nil then
			touched.count = touched.count + 1
		else
			local mass = getMass(otherId)
			self.touched[otherId] = {
				count = 1,
				mass = mass
			}
		end
	elseif onLeave then
		local touched = self.touched[otherId]

		if touched ~= nil then
			if touched.count > 1 then
				touched.count = touched.count - 1
			else
				self.touched[otherId] = nil
			end
		end
	end
end

function BarnMoverTrigger:triggerCallbackTarget(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and otherId ~= 0 then
		local object = g_currentMission:getNodeObject(otherId)
		self.touched[otherId] = nil

		if object ~= nil then
			if object:isa(Bale) then
				if g_currentMission:getIsServer() then
					local difficultyMultiplier = g_currentMission.missionInfo.sellPriceMultiplier
					local baseValue = object:getValue()
					local price = baseValue * difficultyMultiplier
					local farmId = object:getOwnerFarmId()

					g_currentMission:addMoney(price, farmId, MoneyType.SOLD_BALES, true, true)
					object:delete()
				end
			elseif not object:isa(Vehicle) and g_currentMission:getIsServer() then
				object:delete()
			end
		end
	end
end
