FarmlandInitialStateEvent = {}
local FarmlandInitialStateEvent_mt = Class(FarmlandInitialStateEvent, Event)

InitStaticEventClass(FarmlandInitialStateEvent, "FarmlandStateEvent", EventIds.EVENT_FARMLAND_INITIAL_STATE)

function FarmlandInitialStateEvent.emptyNew()
	local self = Event.new(FarmlandInitialStateEvent_mt)

	return self
end

function FarmlandInitialStateEvent.new()
	local self = FarmlandInitialStateEvent.emptyNew()

	return self
end

function FarmlandInitialStateEvent:readStream(streamId, connection)
	for _, farmlandId in ipairs(g_farmlandManager.sortedFarmlandIds) do
		if streamReadBool(streamId) then
			local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

			g_farmlandManager:setLandOwnership(farmlandId, farmId)
		end
	end
end

function FarmlandInitialStateEvent:writeStream(streamId, connection)
	for _, farmlandId in ipairs(g_farmlandManager.sortedFarmlandIds) do
		local owner = g_farmlandManager:getFarmlandOwner(farmlandId)

		if streamWriteBool(streamId, owner ~= FarmlandManager.NO_OWNER_FARM_ID) then
			streamWriteUIntN(streamId, owner, FarmManager.FARM_ID_SEND_NUM_BITS)
		end
	end
end
