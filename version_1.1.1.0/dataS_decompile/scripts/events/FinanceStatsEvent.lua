FinanceStatsEvent = {}
local FinanceStatsEvent_mt = Class(FinanceStatsEvent, Event)

InitStaticEventClass(FinanceStatsEvent, "FinanceStatsEvent", EventIds.EVENT_FINANCE_STATS)

function FinanceStatsEvent.emptyNew()
	local self = Event.new(FinanceStatsEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function FinanceStatsEvent.new(historyIndex, farmId)
	local self = FinanceStatsEvent.emptyNew()
	self.historyIndex = historyIndex
	self.farmId = farmId

	assert(historyIndex >= 0 and historyIndex <= 255)

	return self
end

function FinanceStatsEvent:readStream(streamId, connection)
	self.historyIndex = streamReadUInt8(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local financesHistoryVersionCounter = streamReadUIntN(streamId, 7)
			local readData = {}

			if streamReadBool(streamId) then
				for _, statName in ipairs(FinanceStats.statNames) do
					local money = streamReadFloat32(streamId)
					readData[statName] = money
				end
			end

			local farm = g_farmManager:getFarmById(self.farmId)

			if farm ~= nil then
				local stats = farm.stats
				stats.financesHistoryVersionCounter = financesHistoryVersionCounter
				local finances = nil

				if self.historyIndex == 0 then
					finances = stats.finances
				else
					local numHistoryEntries = #stats.financesHistory

					if numHistoryEntries < self.historyIndex then
						for _ = 1, self.historyIndex - numHistoryEntries do
							table.insert(stats.financesHistory, 1, FinanceStats.new())
						end

						numHistoryEntries = self.historyIndex
					end

					finances = stats.financesHistory[numHistoryEntries - self.historyIndex + 1]
				end

				for statName, money in pairs(readData) do
					finances[statName] = money
				end
			end
		end
	else
		connection:sendEvent(self)
	end
end

function FinanceStatsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.historyIndex)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if not connection:getIsServer() then
		local farm = g_farmManager:getFarmById(self.farmId)

		if streamWriteBool(streamId, farm ~= nil) then
			local stats = farm.stats
			local financesHistoryVersionCounter = stats.financesHistoryVersionCounter

			streamWriteUIntN(streamId, financesHistoryVersionCounter, 7)

			local finances = nil

			if self.historyIndex == 0 then
				finances = stats.finances
			else
				local numHistoryEntries = #stats.financesHistory

				if self.historyIndex <= numHistoryEntries then
					finances = stats.financesHistory[numHistoryEntries - self.historyIndex + 1]
				end
			end

			if streamWriteBool(streamId, finances ~= nil and self.farmId ~= FarmManager.SPECTATOR_FARM_ID) then
				for _, statName in ipairs(FinanceStats.statNames) do
					local money = Utils.getNoNil(finances[statName], 0)

					streamWriteFloat32(streamId, money)
				end
			end
		end
	end
end

function FinanceStatsEvent:run(connection)
	print("Error: FinanceStatsEvent is not allowed to be executed on a local client")
end
