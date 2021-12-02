FarmDestroyEvent = {}
local FarmDestroyEvent_mt = Class(FarmDestroyEvent, Event)

InitStaticEventClass(FarmDestroyEvent, "FarmDestroyEvent", EventIds.EVENT_FARM_DESTROY)

function FarmDestroyEvent.emptyNew()
	local self = Event.new(FarmDestroyEvent_mt)

	return self
end

function FarmDestroyEvent.new(farmId)
	local self = FarmDestroyEvent.emptyNew()
	self.farmId = farmId

	return self
end

function FarmDestroyEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function FarmDestroyEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function FarmDestroyEvent:run(connection)
	if not connection:getIsServer() and (connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection)) then
		local farm = g_farmManager:getFarmById(self.farmId)

		if farm ~= nil and farm:canBeDestroyed() then
			g_farmManager:destroyFarm(self.farmId)
			g_server:broadcastEvent(self)
		end
	end
end
