ProductionChainManager = {
	NUM_MAX_PRODUCTION_POINTS = 60
}
local ProductionChainManager_mt = Class(ProductionChainManager, AbstractManager)

function ProductionChainManager.new(isServer, customMt)
	local self = AbstractManager.new(customMt or ProductionChainManager_mt)
	self.isServer = isServer

	addConsoleCommand("gsProductionPointsList", "List all production points on map", "commandListProductionPoints", self)
	addConsoleCommand("gsProductionPointsPrintAutoDeliverMapping", "Prints which fillTypes are required by which production points", "commandPrintAutoDeliverMapping", self)
	addConsoleCommand("gsProductionPointSetOwner", "", "commandSetOwner", self)
	addConsoleCommand("gsProductionPointSetProductionState", "", "commandSetProductionState", self)
	addConsoleCommand("gsProductionPointSetOutputMode", "", "commandSetOutputMode", self)
	addConsoleCommand("gsProductionPointSetFillLevel", "", "commandSetFillLevel", self)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.distributeGoods, self)

	return self
end

function ProductionChainManager:initDataStructures()
	self.productionPoints = {}
	self.reverseProductionPoint = {}
	self.farmIds = {}
	self.currentUpdateIndex = 1
end

function ProductionChainManager:unloadMapData()
	removeConsoleCommand("gsProductionPointsList")
	removeConsoleCommand("gsProductionPointsPrintAutoDeliverMapping")
	removeConsoleCommand("gsProductionPointSetOwner")
	removeConsoleCommand("gsProductionPointSetProductionState")
	removeConsoleCommand("gsProductionPointSetOutputMode")
	removeConsoleCommand("gsProductionPointSetFillLevel")
	g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	ProductionChainManager:superClass().unloadMapData(self)
end

function ProductionChainManager:addProductionPoint(productionPoint)
	if self.reverseProductionPoint[productionPoint] then
		printf("Warning: Production point '%s' already registered.", productionPoint:tableId())

		return false
	end

	if ProductionChainManager.NUM_MAX_PRODUCTION_POINTS <= #self.productionPoints then
		printf("Maximum number of %i Production Points reached.", ProductionChainManager.NUM_MAX_PRODUCTION_POINTS)

		return false
	end

	if #self.productionPoints == 0 then
		g_currentMission:addUpdateable(self)
	end

	self.reverseProductionPoint[productionPoint] = true

	table.insert(self.productionPoints, productionPoint)

	local farmId = productionPoint:getOwnerFarmId()

	if farmId ~= AccessHandler.EVERYONE then
		if not self.farmIds[farmId] then
			self.farmIds[farmId] = {}
		end

		self:addProductionPointToFarm(productionPoint, self.farmIds[farmId])
	end

	return true
end

function ProductionChainManager:addProductionPointToFarm(productionPoint, farmTable)
	if not farmTable.productionPoints then
		farmTable.productionPoints = {}
	end

	table.insert(farmTable.productionPoints, productionPoint)

	if not farmTable.inputTypeToProductionPoints then
		farmTable.inputTypeToProductionPoints = {}
	end

	for inputType in pairs(productionPoint.inputFillTypeIds) do
		if not farmTable.inputTypeToProductionPoints[inputType] then
			farmTable.inputTypeToProductionPoints[inputType] = {}
		end

		table.insert(farmTable.inputTypeToProductionPoints[inputType], productionPoint)
	end
end

function ProductionChainManager:removeProductionPoint(productionPoint)
	self.reverseProductionPoint[productionPoint] = nil

	if table.removeElement(self.productionPoints, productionPoint) then
		local farmId = productionPoint:getOwnerFarmId()

		if farmId ~= AccessHandler.EVERYONE then
			self.farmIds[farmId] = self:removeProductionPointFromFarm(productionPoint, self.farmIds[farmId])
		end
	end

	if #self.productionPoints == 0 then
		g_currentMission:removeUpdateable(self)
	end
end

function ProductionChainManager:removeProductionPointFromFarm(productionPoint, farmTable)
	table.removeElement(farmTable.productionPoints, productionPoint)

	local inputTypeToProductionPoints = farmTable.inputTypeToProductionPoints

	for inputType in pairs(productionPoint.inputFillTypeIds) do
		if inputTypeToProductionPoints[inputType] then
			if not table.removeElement(inputTypeToProductionPoints[inputType], productionPoint) then
				log("Error: ProductionChainManager:removeProductionPoint(): Unable to remove production point from input type mapping")
			end

			if #inputTypeToProductionPoints[inputType] == 0 then
				inputTypeToProductionPoints[inputType] = nil
			end
		end
	end

	if #farmTable.productionPoints == 0 then
		farmTable = nil
	end

	return farmTable
end

function ProductionChainManager:getProductionPointsForFarmId(farmId)
	return self.farmIds[farmId] and self.farmIds[farmId].productionPoints or {}
end

function ProductionChainManager:getNumOfProductionPoints()
	return #self.productionPoints
end

function ProductionChainManager:getHasFreeSlots()
	return #self.productionPoints < ProductionChainManager.NUM_MAX_PRODUCTION_POINTS
end

function ProductionChainManager:update()
	if #self.productionPoints == 0 then
		return
	end

	if self.currentUpdateIndex > #self.productionPoints then
		self.currentUpdateIndex = 1
	end

	local prodPoint = self.productionPoints[self.currentUpdateIndex]

	if prodPoint then
		prodPoint:updateProduction()
	end

	self.currentUpdateIndex = self.currentUpdateIndex + 1
end

function ProductionChainManager:distributeGoods()
	if not self.isServer then
		return
	end

	for _, farmTable in pairs(self.farmIds) do
		for i = 1, #farmTable.productionPoints do
			local distributingProdPoint = farmTable.productionPoints[i]

			for fillTypeIdToDistribute in pairs(distributingProdPoint.outputFillTypeIdsAutoDeliver) do
				local amountToDistribute = distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute)

				if amountToDistribute > 0 then
					local prodPointsInDemand = farmTable.inputTypeToProductionPoints[fillTypeIdToDistribute] or {}
					local totalFreeCapacity = 0

					for n = 1, #prodPointsInDemand do
						totalFreeCapacity = totalFreeCapacity + prodPointsInDemand[n].storage:getFreeCapacity(fillTypeIdToDistribute, true)
					end

					if totalFreeCapacity > 0 then
						for n = 1, #prodPointsInDemand do
							local prodPointInDemand = prodPointsInDemand[n]
							local maxAmountToReceive = prodPointInDemand.storage:getFreeCapacity(fillTypeIdToDistribute, true)

							if maxAmountToReceive > 0 then
								local amountToTransfer = math.min(maxAmountToReceive, amountToDistribute * maxAmountToReceive / totalFreeCapacity)

								g_currentMission:addMoney(amountToTransfer * 0.01, prodPointInDemand.ownerFarmId, MoneyType.PROPERTY_MAINTENANCE, true)
								prodPointInDemand.storage:setFillLevel(prodPointInDemand.storage:getFillLevel(fillTypeIdToDistribute) + amountToTransfer, fillTypeIdToDistribute)
								distributingProdPoint.storage:setFillLevel(distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute) - amountToTransfer, fillTypeIdToDistribute)
							end
						end
					end
				end
			end
		end
	end
end

function ProductionChainManager:updateBalance()
end

function ProductionChainManager:commandListProductionPoints()
	if #self.productionPoints > 0 then
		print("available production points:")

		for i = 1, #self.productionPoints do
			local productionPoint = self.productionPoints[i]

			print(string.format("%i: %s", i, productionPoint:toString()))
		end

		return string.format("listed %i production points", #self.productionPoints)
	end

	return "no productions points available"
end

function ProductionChainManager:commandPrintAutoDeliverMapping()
	print("AutoDeliverMapping")

	for farmId, farmTable in pairs(self.farmIds) do
		printf("  Farm %i", farmId)

		for inputType, prodPoints in pairs(farmTable.inputTypeToProductionPoints) do
			print(string.format("    FillType %s distributed to", g_fillTypeManager:getFillTypeNameByIndex(inputType)))

			for _, prodPoint in pairs(prodPoints) do
				print(string.format("      %s", prodPoint:toString()))
			end
		end
	end
end

function ProductionChainManager:commandSetOwner(ppIdentifier, farmId)
	local usage = "Usage: gsProductionPointSetOwner ppIdentifier farmId"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	farmId = tonumber(farmId)

	if productionPoints == false then
		return "Error: no production point given\n" .. usage
	end

	if farmId == nil then
		return "Error: no farmId given\n" .. usage
	end

	productionPoints = table.copy(productionPoints)

	for _, prodPoint in pairs(productionPoints) do
		prodPoint:setOwnerFarmId(farmId, true)
	end
end

function ProductionChainManager:commandSetProductionState(ppIdentifier, productionIdentifier, state)
	local usage = "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	state = Utils.stringToBoolean(state)

	if productionPoints == false then
		return "Error: no production point given\n" .. usage
	end

	if productionIdentifier == nil then
		return "Error: no production identifier given\n" .. usage
	end

	if state == nil then
		return "Error: no valid state given\n" .. usage
	end

	local productions = {}

	for _, prodPoint in pairs(productionPoints) do
		if productionIdentifier:lower() == "all" then
			for _, production in pairs(prodPoint.productions) do
				table.insert(productions, {
					prodPoint,
					production
				})
			end
		else
			local production = prodPoint.productionsIdToObj[productionIdentifier]

			if production then
				table.insert(productions, {
					prodPoint,
					production
				})
			end
		end
	end

	if #productions == 0 then
		return string.format("Error: no productions found for identifier '%s'\n%s", productionIdentifier, usage)
	end

	for _, ppProdPair in pairs(productions) do
		local prodPoint = ppProdPair[1]
		local production = ppProdPair[2]

		prodPoint:setProductionState(production.id, state)
		print(string.format("%s (%s): %s = %s", prodPoint:getName(), prodPoint:tableId(), production.id, state))
	end
end

function ProductionChainManager:commandSetOutputMode(ppIdentifier, outputFillTypeIdentifier, mode)
	local usage = "Usage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"

	local function outputModes()
		local str = {}

		for key, val in pairs(ProductionPoint.OUTPUT_MODE) do
			table.insert(str, val .. "=" .. key)
		end

		return table.concat(str, "\n")
	end

	local productionPoints = self:getProductionPointsFromString(ppIdentifier)

	if productionPoints == false then
		return "Error: no production point given\n" .. usage
	end

	if not outputFillTypeIdentifier then
		return "Error: Missing argument outputFillType.\n" .. usage
	end

	if not table.hasElement(ProductionPoint.OUTPUT_MODE, tonumber(mode)) then
		return string.format("Error: Invalid output mode '%s'. Available modes:\n%s", mode, outputModes())
	end

	if outputFillTypeIdentifier:lower() ~= "all" then
		local outputType = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeIdentifier)

		for _, prodPoint in pairs(productionPoints) do
			if prodPoint.outputFillTypeIds[outputType] then
				prodPoint:setOutputDistributionMode(outputType, mode)
			end
		end
	else
		for _, prodPoint in pairs(productionPoints) do
			for outputType in pairs(prodPoint.outputFillTypeIds) do
				prodPoint:setOutputDistributionMode(outputType, mode)
			end
		end
	end
end

function ProductionChainManager:commandSetFillLevel(ppIdentifier, fillTypeIdentifier, fillLevel)
	local usage = "Usage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)

	if productionPoints == false then
		return "Error: no production point given\n" .. usage
	end

	local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeIdentifier)

	if not fillTypeIdentifier or fillTypeIdentifier:lower() ~= "all" and not fillType then
		return "Error: no valid fillType given\n" .. usage
	end

	fillLevel = tonumber(fillLevel)

	if not fillLevel then
		return "Error: no fillLevel given\n" .. usage
	end

	local numStorageSpaces = 0

	for _, prodPoint in pairs(productionPoints) do
		if fillTypeIdentifier:lower() ~= "all" then
			if fillType and prodPoint.storage:getIsFillTypeSupported(fillType) then
				prodPoint.storage:setFillLevel(fillLevel, fillType)

				numStorageSpaces = numStorageSpaces + 1
			end
		else
			for supportedFillType in pairs(prodPoint.storage:getSupportedFillTypes()) do
				prodPoint.storage:setFillLevel(fillLevel, supportedFillType)

				numStorageSpaces = numStorageSpaces + 1
			end
		end
	end

	return string.format("Filled %i storage spaces", numStorageSpaces)
end

function ProductionChainManager:getProductionPointsFromString(identificationString)
	if not identificationString or identificationString == "" then
		return false
	end

	local prodPoints = {}

	if identificationString:lower() == "all" then
		prodPoints = self.productionPoints
	else
		local prodPoint = self.productionPoints[tonumber(identificationString)]

		if not prodPoint and string.len(identificationString) >= 4 then
			for _, productionPoint in pairs(self.productionPoints) do
				if string.find(productionPoint:tableId(), identificationString) then
					if prodPoint == nil then
						prodPoint = productionPoint
					else
						print(string.format("Error: Multiple production points for index/identifier '%s'. Please provide a longer identifier.", identificationString))
						self:commandListProductionPoints()

						return false
					end
				end
			end
		end

		if not prodPoint then
			print(string.format("Error: No Production Point for index/identifier '%s'", identificationString))
			self:commandListProductionPoints()

			return false
		else
			table.insert(prodPoints, prodPoint)
		end
	end

	return prodPoints
end
