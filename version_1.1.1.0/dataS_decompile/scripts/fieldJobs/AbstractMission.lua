AbstractMission = {}
local AbstractMission_mt = Class(AbstractMission, Object)

InitStaticObjectClass(AbstractMission, "AbstractMission", ObjectIds.MISSION)

AbstractMission.STATUS_STOPPED = 0
AbstractMission.STATUS_RUNNING = 1
AbstractMission.STATUS_FINISHED = 2
AbstractMission.SUCCESS_FACTOR = 0.95

function AbstractMission.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or AbstractMission_mt)
	self.status = AbstractMission.STATUS_STOPPED
	self.reward = 0
	self.completion = 0
	self.missionDirtyFlag = self:getNextDirtyFlag()

	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)

	return self
end

function AbstractMission:delete()
	AbstractMission:superClass().delete(self)
	g_messageCenter:unsubscribeAll(self)
	g_messageCenter:publish(MessageType.MISSION_DELETED, self)
end

function AbstractMission:saveToXMLFile(xmlFile, key)
	setXMLInt(xmlFile, key .. "#reward", self.reward)
	setXMLInt(xmlFile, key .. "#status", self.status)
	setXMLBool(xmlFile, key .. "#success", self.success or false)

	if self.farmId ~= nil then
		setXMLInt(xmlFile, key .. "#farmId", self.farmId)
	end

	if self.stealingCost ~= nil then
		setXMLFloat(xmlFile, key .. "#stealingCost", self.stealingCost)
	end
end

function AbstractMission:loadFromXMLFile(xmlFile, key)
	self.reward = getXMLInt(xmlFile, key .. "#reward")
	self.status = getXMLInt(xmlFile, key .. "#status")
	self.farmId = getXMLInt(xmlFile, key .. "#farmId")
	self.success = getXMLBool(xmlFile, key .. "#success") or false
	self.stealingCost = getXMLFloat(xmlFile, key .. "#stealingCost")

	return true
end

function AbstractMission:writeStream(streamId, connection)
	AbstractMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.type.typeId)
	streamWriteFloat32(streamId, self.reward)
	streamWriteUInt8(streamId, self.status)

	if self.status == AbstractMission.STATUS_RUNNING then
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteInt32(streamId, self.activeMissionId)
	elseif self.status == AbstractMission.STATUS_FINISHED then
		streamWriteFloat32(streamId, self.stealingCost or 0)
		streamWriteBool(streamId, self.success)
	end
end

function AbstractMission:readStream(streamId, connection)
	AbstractMission:superClass().readStream(self, streamId, connection)

	self.type = g_missionManager:getMissionTypeById(streamReadUInt8(streamId))
	self.reward = streamReadFloat32(streamId)
	self.status = streamReadUInt8(streamId)

	if self.status == AbstractMission.STATUS_RUNNING then
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.activeMissionId = streamReadInt32(streamId)
	elseif self.status == AbstractMission.STATUS_FINISHED then
		self.stealingCost = streamReadFloat32(streamId)
		self.success = streamReadBool(streamId)
	end

	g_missionManager:assignGenerationTime(self)
	table.insert(g_missionManager.missions, self)
	g_messageCenter:publishDelayed(MessageType.MISSION_GENERATED, self)
end

function AbstractMission:writeUpdateStream(streamId, connection, dirtyMask)
	streamWriteUInt8(streamId, self.status)
	streamWriteFloat32(streamId, self.completion)
end

function AbstractMission:readUpdateStream(streamId, timestamp, connection)
	self.status = streamReadUInt8(streamId)
	self.completion = streamReadFloat32(streamId)
end

function AbstractMission:init()
	return true
end

function AbstractMission:updateTick(dt)
	if self.isServer and self.status == AbstractMission.STATUS_RUNNING then
		if self.lastCompletion == nil then
			self.lastCompletion = self.mission.time
		elseif self.lastCompletion < self.mission.time - 2500 then
			self.completion = self:getCompletion()

			if self.completion >= 0.995 then
				self:finish(true)
			end
		end

		if self.lastCompletion ~= self.completion then
			self:raiseDirtyFlags(self.missionDirtyFlag)
		end
	end
end

function AbstractMission:update(dt)
	if self.status == AbstractMission.STATUS_RUNNING then
		self:raiseActive()
	end
end

function AbstractMission:start(spawnVehicles)
	self.status = AbstractMission.STATUS_RUNNING

	self:raiseActive()
	g_server:broadcastEvent(MissionStartedEvent.new(self))

	return true
end

function AbstractMission:started()
end

function AbstractMission:finish(success)
	self.status = AbstractMission.STATUS_FINISHED
	self.success = success

	if self.isServer then
		self.stealingCost = self:calculateStealingCost()

		g_server:broadcastEvent(MissionFinishedEvent.new(self, success, self.stealingCost))
	end

	g_messageCenter:publish(MissionFinishedEvent, self, success)
end

function AbstractMission:hasLeasableVehicles()
	return false
end

function AbstractMission:hasField()
	return false
end

function AbstractMission:calculateStealingCost()
	return 0
end

function AbstractMission:dismiss()
	if self.isServer then
		local change = nil

		if self.success then
			change = self:getReward()
		else
			change = -self.stealingCost
		end

		if change ~= 0 then
			self.mission:addMoney(change, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end

function AbstractMission:validate(event)
	return true
end

function AbstractMission:getData()
	return self:getReward(), "none", "none"
end

function AbstractMission:getNPC()
	return nil
end

function AbstractMission:getIsAvailable()
	return self.timeLeft == nil or self.timeLeft > 0
end

function AbstractMission:getExtraProgressText()
	return ""
end

function AbstractMission:getCompletion()
	return 0
end

function AbstractMission:farmDestroyed(farmId)
	if farmId == self.farmId then
		self:delete()
	end
end
