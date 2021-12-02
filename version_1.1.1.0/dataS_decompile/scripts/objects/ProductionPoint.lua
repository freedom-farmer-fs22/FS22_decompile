ProductionPoint = {
	NO_PALLET_SPACE_COOLDOWN = 15000,
	DIRECT_SELL_PRICE_FACTOR = 0.8,
	OUTPUT_MODE = {}
}
ProductionPoint.OUTPUT_MODE.KEEP = 0
ProductionPoint.OUTPUT_MODE.DIRECT_SELL = 1
ProductionPoint.OUTPUT_MODE.AUTO_DELIVER = 2
ProductionPoint.OUTPUT_MODE_NUM_BITS = 2
ProductionPoint.PROD_STATUS = {
	INACTIVE = 0,
	RUNNING = 1,
	MISSING_INPUTS = 2,
	NO_OUTPUT_SPACE = 3
}
ProductionPoint.PROD_STATUS_NUM_BITS = 2
ProductionPoint.PROD_STATUS_TO_L10N = {
	[ProductionPoint.PROD_STATUS.INACTIVE] = "ui_production_status_inactive",
	[ProductionPoint.PROD_STATUS.RUNNING] = "ui_production_status_running",
	[ProductionPoint.PROD_STATUS.MISSING_INPUTS] = "ui_production_status_materialsMissing",
	[ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE] = "ui_production_status_outOfSpace"
}
ProductionPoint.debugEnabled = false

function ProductionPoint.consoleCommandToggleProdPointDebug()
	ProductionPoint.debugEnabled = not ProductionPoint.debugEnabled

	return "ProductionPoint.debugEnabled=" .. tostring(ProductionPoint.debugEnabled)
end

addConsoleCommand("gsProductionPointToggleDebug", "Toggle production point debugging", "consoleCommandToggleProdPointDebug", ProductionPoint)

local ProductionPoint_mt = Class(ProductionPoint, Object)

function ProductionPoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of the Production Point", "unnamed production point")
	schema:register(XMLValueType.BOOL, basePath .. ".productions#sharedThroughputCapacity", "Productions slow each other down if active at the same time", true)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#id", "Unique string used for identifying the production", nil, true)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".productions.production(?)#name", "Name of the production used inside the UI", "unnamed production")
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?)#params", "Optional parameters formatted into #name")
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerHour", "Number of performed production cycles per ingame hour (divided by the number of enabled productions, unless sharedThroughputCapacity is set to false)", 60)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#cyclesPerMinute", "Number of performed production cycles per ingame minute (divided by the number of enabled productions)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveHour", "Costs per ingame hour if this production is enabled (regardless of whether it is producing or not)", 60)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?)#costsPerActiveMinute", "Costs per ingame minute if this production is enabled (regardless of whether it is producing or not)", 1)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).inputs.input(?)#fillType", "Input fillType", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).inputs.input(?)#amount", "Used amount per cycle", 1)
	schema:register(XMLValueType.STRING, basePath .. ".productions.production(?).outputs.output(?)#fillType", "Output fillType", nil, true)
	schema:register(XMLValueType.FLOAT, basePath .. ".productions.production(?).outputs.output(?)#amount", "Produced amount per cycle", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".productions.production(?).outputs.output(?)#sellDirectly", "Directly sell produced amount", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".playerTrigger#node", "", "")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".productions.production(?).sounds", "active")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".productions.production(?).animationNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".productions.production(?).effectNodes")
	SellingStation.registerXMLPaths(schema, basePath .. ".sellingStation")
	LoadingStation.registerXMLPaths(schema, basePath .. ".loadingStation")
	PalletSpawner.registerXMLPaths(schema, basePath .. ".palletSpawner")
	Storage.registerXMLPaths(schema, basePath .. ".storage")
end

function ProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#palletSpawnCooldown", "remaining cooldown duration of pallet spawner")
	schema:register(XMLValueType.FLOAT, basePath .. "#productionCostsToClaim", "production costs yet to be claimed from the owning player")
	schema:register(XMLValueType.STRING, basePath .. ".directSellFillType(?)", "fillType currently configured to be directly sold")
	schema:register(XMLValueType.STRING, basePath .. ".autoDeliverFillType(?)", "fillType currently configured to be automatically delivered")
	schema:register(XMLValueType.STRING, basePath .. ".production(?)#id", "Unique id of the production")
	schema:register(XMLValueType.BOOL, basePath .. ".production(?)#isEnabled", "State of the production")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
end

InitStaticObjectClass(ProductionPoint, "ProductionPoint", ObjectIds.OBJECT_PRODUCTION_POINT)

function ProductionPoint.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or ProductionPoint_mt)
	self.owningPlaceable = nil
	self.isOwned = false
	self.mission = g_currentMission
	self.activeProductions = {}
	self.minuteFactorTimescaled = self.mission:getEffectiveTimeScale() / 1000 / 60
	self.waitingForPalletToSpawn = false
	self.palletSpawnCooldown = 0
	self.inputFillLevels = {}
	self.productionCostsToClaim = 0
	self.soldFillTypesToPayOut = {}
	self.activatable = ProductionPointActivatable.new(self)

	g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimescaleChanged, self)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)

	self.infoTables = {
		activeProds = {
			accentuate = true,
			title = g_i18n:getText("infohud_activeProductions")
		},
		noActiveProd = {
			accentuate = true,
			title = g_i18n:getText("infohud_noActiveProduction")
		},
		storage = {
			accentuate = true,
			title = g_i18n:getText("ui_productions_buildingStorage")
		},
		storageEmpty = {
			title = "-",
			text = g_i18n:getText("infohud_storageIsEmpty")
		}
	}

	return self
end

function ProductionPoint:load(components, xmlFile, key, customEnv, i3dMappings)
	self.node = components[1].node
	local name = xmlFile:getValue(key .. "#name")
	self.name = name and g_i18n:convertText(name)
	self.productions = {}
	self.productionsIdToObj = {}
	self.inputFillTypeIds = {}
	self.inputFillTypeIdsArray = {}
	self.outputFillTypeIds = {}
	self.outputFillTypeIdsArray = {}
	self.outputFillTypeIdsDirectSell = {}
	self.outputFillTypeIdsAutoDeliver = {}
	self.outputFillTypeIdsToPallets = {}
	self.sharedThroughputCapacity = xmlFile:getValue(key .. ".productions#sharedThroughputCapacity", true)
	local usedProdIds = {}

	xmlFile:iterate(key .. ".productions.production", function (index, productionKey)
		local production = {
			id = xmlFile:getValue(productionKey .. "#id"),
			name = xmlFile:getValue(productionKey .. "#name")
		}
		local params = xmlFile:getValue(productionKey .. "#params")

		if params ~= nil then
			params = params:split("|")

			for i = 1, #params do
				params[i] = g_i18n:convertText(params[i])
			end

			production.name = string.format(production.name, unpack(params))
		end

		if not production.id then
			Logging.xmlError(xmlFile, "missing id for production '%s'", production.name or index)

			return false
		end

		for i = 1, #usedProdIds do
			if usedProdIds[i] == production.id then
				Logging.xmlError(xmlFile, "production id '%s' already in use", production.id)

				return false
			end
		end

		table.insert(usedProdIds, production.id)

		local cyclesPerHour = xmlFile:getValue(productionKey .. "#cyclesPerHour")
		production.cyclesPerMinute = cyclesPerHour and cyclesPerHour / 60 or xmlFile:getValue(productionKey .. "#cyclesPerMinute") or 1
		production.cyclesPerHour = cyclesPerHour or production.cyclesPerMinute * 60
		local costsPerActiveMinute = xmlFile:getValue(productionKey .. "#costsPerActiveHour")
		production.costsPerActiveMinute = costsPerActiveMinute and costsPerActiveMinute / 60 or xmlFile:getValue(productionKey .. "#costsPerActiveMinute") or 1
		production.costsPerActiveHour = costsPerActiveMinute or costsPerActiveMinute / 60
		production.status = ProductionPoint.PROD_STATUS.INACTIVE
		production.inputs = {}

		xmlFile:iterate(productionKey .. ".inputs.input", function (inputIndex, inputKey)
			local input = {}
			local fillTypeString = xmlFile:getValue(inputKey .. "#fillType")
			input.type = g_fillTypeManager:getFillTypeIndexByName(fillTypeString)

			if input.type == nil then
				Logging.xmlError(xmlFile, "Unable to load fillType '%s' for '%s'", fillTypeString, inputKey)
			else
				self.inputFillTypeIds[input.type] = true

				table.addElement(self.inputFillTypeIdsArray, input.type)

				input.amount = xmlFile:getValue(inputKey .. "#amount", 1)

				table.insert(production.inputs, input)
			end
		end)

		if #production.inputs == 0 then
			Logging.xmlError(xmlFile, "No inputs for production '%s'", productionKey)

			return
		end

		production.outputs = {}
		production.primaryProductFillType = nil
		local maxOutputAmount = 0

		xmlFile:iterate(productionKey .. ".outputs.output", function (outputIndex, outputKey)
			local output = {}
			local fillTypeString = xmlFile:getValue(outputKey .. "#fillType")
			output.type = g_fillTypeManager:getFillTypeIndexByName(fillTypeString)

			if output.type == nil then
				Logging.xmlError(xmlFile, "Unable to load fillType '%s' for '%s'", fillTypeString, outputKey)
			else
				output.sellDirectly = xmlFile:getValue(outputKey .. "#sellDirectly", false)

				if not output.sellDirectly then
					self.outputFillTypeIds[output.type] = true

					table.addElement(self.outputFillTypeIdsArray, output.type)
				else
					self.soldFillTypesToPayOut[output.type] = 0
				end

				output.amount = xmlFile:getValue(outputKey .. "#amount", 1)

				table.insert(production.outputs, output)

				if maxOutputAmount < output.amount then
					production.primaryProductFillType = output.type
					maxOutputAmount = output.amount
				end
			end
		end)

		if #production.outputs == 0 then
			Logging.xmlError(xmlFile, "No outputs for production '%s'", productionKey)
		end

		if self.isClient then
			production.samples = {
				active = g_soundManager:loadSampleFromXML(xmlFile, productionKey .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
			}
			production.animationNodes = g_animationManager:loadAnimations(xmlFile, productionKey .. ".animationNodes", components, self, i3dMappings)
			production.effects = g_effectManager:loadEffect(xmlFile, productionKey .. ".effectNodes", components, self, i3dMappings)
		end

		if self.productionsIdToObj[production.id] ~= nil then
			Logging.xmlError(xmlFile, "Error: production id '%s' already used", production.id)

			return false
		end

		self.productionsIdToObj[production.id] = production

		table.insert(self.productions, production)
	end)

	if #self.productions == 0 then
		Logging.xmlError(xmlFile, "No valid productions defined")
	end

	if self.owningPlaceable == nil then
		print("Error: ProductionPoint.owningPlaceable was not set before load()")

		return false
	end

	self.interactionTriggerNode = xmlFile:getValue(key .. ".playerTrigger#node", nil, components, i3dMappings)

	if self.interactionTriggerNode ~= nil then
		addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
	end

	if self.isClient then
		self.samples = {
			idle = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil),
			active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		}
		self.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
	end

	self.unloadingStation = SellingStation.new(self.isServer, self.isClient)

	self.unloadingStation:load(components, xmlFile, key .. ".sellingStation", self.customEnvironment, i3dMappings, components[1].node)

	self.unloadingStation.storeSoldGoods = true
	self.unloadingStation.skipSell = self.owningPlaceable:getOwnerFarmId() ~= AccessHandler.EVERYONE

	function self.unloadingStation.getIsFillAllowedFromFarm(_, farmId)
		return g_currentMission.accessHandler:canFarmAccess(farmId, self.owningPlaceable)
	end

	self.unloadingStation:register(true)

	local loadingStationKey = key .. ".loadingStation"

	if xmlFile:hasProperty(loadingStationKey) then
		self.loadingStation = LoadingStation.new(self.isServer, self.isClient)

		if not self.loadingStation:load(components, xmlFile, loadingStationKey, self.customEnvironment, i3dMappings, components[1].node) then
			Logging.xmlError(xmlFile, "Unable to load loading station %s", loadingStationKey)

			return false
		end

		function self.loadingStation.hasFarmAccessToStorage(_, farmId)
			return farmId == self.owningPlaceable:getOwnerFarmId()
		end

		self.loadingStation.owningPlaceable = self.owningPlaceable

		self.loadingStation:register(true)
	end

	local palletSpawnerKey = key .. ".palletSpawner"

	if xmlFile:hasProperty(palletSpawnerKey) then
		self.palletSpawner = PalletSpawner.new()

		if not self.palletSpawner:load(components, xmlFile, key .. ".palletSpawner", self.customEnvironment, i3dMappings) then
			Logging.xmlError(xmlFile, "Unable to load pallet spawner %s", palletSpawnerKey)

			return false
		end
	end

	if self.loadingStation == nil and self.palletSpawner == nil then
		Logging.xmlError(xmlFile, "No loading station or pallet spawner for production point")

		return false
	end

	if self.palletSpawner ~= nil then
		for fillTypeId, pallet in pairs(self.palletSpawner:getSupportedFillTypes()) do
			if self.outputFillTypeIds[fillTypeId] then
				self.outputFillTypeIdsToPallets[fillTypeId] = pallet
			end
		end
	end

	self.storage = Storage.new(self.isServer, self.isClient)

	self.storage:load(components, xmlFile, key .. ".storage", i3dMappings)
	self.storage:register(true)

	if self.loadingStation ~= nil then
		self.loadingStation:addSourceStorage(self.storage)
		g_currentMission.storageSystem:addLoadingStation(self.loadingStation, self.owningPlaceable)
	end

	self.unloadingStation:addTargetStorage(self.storage)

	for inputFillTypeIndex in pairs(self.inputFillTypeIds) do
		if not self.unloadingStation:getIsFillTypeSupported(inputFillTypeIndex) then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(inputFillTypeIndex)

			Logging.xmlWarning(xmlFile, "Input filltype '%s' is not supported by unloading station", fillTypeName)
		end
	end

	for outputFillTypeIndex in pairs(self.outputFillTypeIds) do
		if (self.loadingStation == nil or not self.loadingStation:getIsFillTypeSupported(outputFillTypeIndex)) and self.outputFillTypeIdsToPallets[outputFillTypeIndex] == nil then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(outputFillTypeIndex)

			Logging.xmlWarning(xmlFile, "Output filltype '%s' is not supported by loading station or pallet spawner", fillTypeName)
		end
	end

	self.unloadingStation.owningPlaceable = self.owningPlaceable

	g_currentMission.storageSystem:addUnloadingStation(self.unloadingStation, self.owningPlaceable)
	g_currentMission.economyManager:addSellingStation(self.unloadingStation)

	for i = 1, #self.productions do
		local production = self.productions[i]

		for x = 1, #production.inputs do
			local input = production.inputs[x]

			if not self.storage:getIsFillTypeSupported(input.type) then
				Logging.xmlError(xmlFile, "production point storage does not support fillType '%s' used as in input in production '%s'", g_fillTypeManager:getFillTypeNameByIndex(input.type), production.name)

				return false
			end
		end

		for x = 1, #production.outputs do
			local output = production.outputs[x]

			if not output.sellDirectly and not self.storage:getIsFillTypeSupported(output.type) then
				Logging.xmlError(xmlFile, "production point storage does not support fillType '%s' used as an output in production '%s'", g_fillTypeManager:getFillTypeNameByIndex(output.type), production.name)

				return false
			end
		end
	end

	for supportedFillType, _ in pairs(self.storage:getSupportedFillTypes()) do
		if not self.inputFillTypeIds[supportedFillType] and not self.outputFillTypeIds[supportedFillType] then
			Logging.xmlWarning(xmlFile, "storage fillType '%s' not used as a production input or ouput", g_fillTypeManager:getFillTypeNameByIndex(supportedFillType))
		end
	end

	return true
end

function ProductionPoint:delete()
	g_messageCenter:unsubscribeAll(self)
	self.mission.activatableObjectsSystem:removeActivatable(self.activatable)

	self.activatable = nil

	g_currentMission.productionChainManager:removeProductionPoint(self)

	if self.interactionTriggerNode ~= nil then
		removeTrigger(self.interactionTriggerNode)

		self.interactionTriggerNode = nil
	end

	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
	end

	if self.animationNodes ~= nil then
		g_animationManager:deleteAnimations(self.animationNodes)
	end

	if self.effects ~= nil then
		g_effectManager:deleteEffects(self.effects)
	end

	if self.loadingStation ~= nil then
		g_currentMission.storageSystem:removeLoadingStation(self.loadingStation, self.owningPlaceable)
		self.loadingStation:delete()
	end

	if self.unloadingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.unloadingStation, self.owningPlaceable)
		g_currentMission.economyManager:removeSellingStation(self.unloadingStation)
		self.unloadingStation:delete()
	end

	if self.palletSpawner ~= nil then
		self.palletSpawner:delete()
	end

	if self.storage ~= nil then
		self.storage:delete()
	end

	for i = 1, #self.productions do
		local production = self.productions[i]

		g_soundManager:deleteSamples(production.samples)
		g_animationManager:deleteAnimations(production.animationNodes)
		g_effectManager:deleteEffects(production.effects)
	end

	ProductionPoint:superClass().delete(self)
end

function ProductionPoint:readStream(streamId, connection)
	ProductionPoint:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for i = 1, streamReadUInt8(streamId) do
			self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.DIRECT_SELL)
		end

		for i = 1, streamReadUInt8(streamId) do
			self:setOutputDistributionMode(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), ProductionPoint.OUTPUT_MODE.AUTO_DELIVER)
		end

		local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadingStation, unloadingStationId)

		if self.loadingStation ~= nil then
			local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

			self.loadingStation:readStream(streamId, connection)
			g_client:finishRegisterObject(self.loadingStation, loadingStationId)
		end

		local storageId = NetworkUtil.readNodeObjectId(streamId)

		self.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(self.storage, storageId)

		for i = 1, streamReadUInt8(streamId) do
			local productionId = streamReadString(streamId)

			self:setProductionState(productionId, true)
			self:setProductionStatus(productionId, streamReadUIntN(streamId, ProductionPoint.PROD_STATUS_NUM_BITS))
		end
	end
end

function ProductionPoint:writeStream(streamId, connection)
	ProductionPoint:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsDirectSell))

		for directSellFillTypeId in pairs(self.outputFillTypeIdsDirectSell) do
			streamWriteUIntN(streamId, directSellFillTypeId, FillTypeManager.SEND_NUM_BITS)
		end

		streamWriteUInt8(streamId, table.size(self.outputFillTypeIdsAutoDeliver))

		for autoDeliverFillTypeId in pairs(self.outputFillTypeIdsAutoDeliver) do
			streamWriteUIntN(streamId, autoDeliverFillTypeId, FillTypeManager.SEND_NUM_BITS)
		end

		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadingStation))
		self.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadingStation)

		if self.loadingStation ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadingStation))
			self.loadingStation:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, self.loadingStation)
		end

		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.storage))
		self.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.storage)
		streamWriteUInt8(streamId, #self.activeProductions)

		for i = 1, #self.activeProductions do
			local production = self.activeProductions[i]

			streamWriteString(streamId, production.id)
			streamWriteUIntN(streamId, production.status, ProductionPoint.PROD_STATUS_NUM_BITS)
		end
	end
end

function ProductionPoint:setOwnerFarmId(farmId, noEventSend)
	if self.isServer then
		self:claimProductionCosts()
	end

	g_currentMission.productionChainManager:removeProductionPoint(self)
	ProductionPoint:superClass().setOwnerFarmId(self, farmId, noEventSend)

	self.isOwned = farmId ~= AccessHandler.EVERYONE

	if not self.isOwned then
		for _, production in pairs(self.productions) do
			self:setProductionState(production.id, true)
		end
	end

	if self.unloadingStation ~= nil then
		self.unloadingStation.skipSell = self.isOwned

		self.unloadingStation:setOwnerFarmId(farmId)
	end

	if self.loadingStation ~= nil then
		self.loadingStation:setOwnerFarmId(farmId)
	end

	if self.storage ~= nil then
		self.storage:setOwnerFarmId(farmId)
	end

	g_currentMission.productionChainManager:addProductionPoint(self)
end

function ProductionPoint:palletSpawnRequestCallback(pallet, status, fillType)
	self.waitingForPalletToSpawn = false

	if pallet ~= nil and pallet.addFillUnitFillLevel and fillType ~= nil then
		local fillUnitIndex = pallet:getFirstValidFillUnitToFill(fillType)

		if fillUnitIndex then
			local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, self.storage:getFillLevel(fillType), fillType, ToolType.UNDEFINED)

			if delta > 0 then
				self.storage:setFillLevel(self.storage:getFillLevel(fillType) - delta, fillType)
			end
		else
			printf("Error: No fillUnitIndex for fillType %s found, pallet:", g_fillTypeManager:getFillTypeNameByIndex(fillType), pallet.xmlFile.filename)
		end
	end

	if status == PalletSpawner.RESULT_NO_SPACE then
		self.palletSpawnCooldown = g_time + ProductionPoint.NO_PALLET_SPACE_COOLDOWN
	end
end

function ProductionPoint:updateFxState()
	if self.isClient then
		if #self.activeProductions > 0 then
			g_soundManager:stopSample(self.samples.idle)
			g_soundManager:playSample(self.samples.active)
			g_animationManager:startAnimations(self.animationNodes)
			g_effectManager:startEffects(self.effects)
		else
			g_soundManager:playSample(self.samples.idle)
			g_soundManager:stopSample(self.samples.active)
			g_animationManager:stopAnimations(self.animationNodes)
			g_effectManager:stopEffects(self.effects)
		end
	end
end

function ProductionPoint:update(dt)
end

function ProductionPoint:updateProduction()
	if self.lastUpdatedTime == nil then
		self.lastUpdatedTime = g_time

		return
	end

	local dt = MathUtil.clamp(g_time - self.lastUpdatedTime, 0, 30000)
	local numActiveProductions = #self.activeProductions

	if numActiveProductions > 0 then
		local minuteFactorTimescaledDt = dt * self.minuteFactorTimescaled
		local minuteFactorDt = dt / 60000

		for n = 1, numActiveProductions do
			local production = self.activeProductions[n]
			local cyclesPerMinuteMinuteFactor = production.cyclesPerMinute * minuteFactorTimescaledDt * g_currentMission.environment.timeAdjustment
			local cyclesPerMinuteFactorNoTimescale = production.cyclesPerMinute * minuteFactorDt
			local enoughInputResources = true
			local enoughOutputSpace = true

			for x = 1, #production.inputs do
				local input = production.inputs[x]
				local fillLevel = self.storage:getFillLevel(input.type)
				self.inputFillLevels[input] = fillLevel

				if self.isOwned and fillLevel < input.amount * cyclesPerMinuteFactorNoTimescale then
					enoughInputResources = false

					if production.status ~= ProductionPoint.PROD_STATUS.MISSING_INPUTS then
						production.status = ProductionPoint.PROD_STATUS.MISSING_INPUTS

						self.owningPlaceable:productionStatusChanged(production, ProductionPoint.PROD_STATUS.MISSING_INPUTS)
						self:setProductionStatus(production.id, production.status)
					end

					break
				end
			end

			if enoughInputResources and self.isOwned then
				for x = 1, #production.outputs do
					local output = production.outputs[x]

					if not output.sellDirectly then
						local freeCapacity = self.storage:getFreeCapacity(output.type)

						if freeCapacity < output.amount * cyclesPerMinuteMinuteFactor then
							enoughOutputSpace = false

							if production.status ~= ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
								production.status = ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE

								self:setProductionStatus(production.id, production.status)
							end

							break
						end
					end
				end
			end

			if self.isOwned then
				self.productionCostsToClaim = self.productionCostsToClaim + production.costsPerActiveMinute * minuteFactorTimescaledDt
			end

			if not self.isOwned or enoughInputResources and enoughOutputSpace then
				local factor = cyclesPerMinuteMinuteFactor / (self.sharedThroughputCapacity and numActiveProductions or 1)

				for y = 1, #production.inputs do
					local input = production.inputs[y]
					local fillLevel = self.inputFillLevels[input]

					if fillLevel and fillLevel > 0 then
						self.storage:setFillLevel(fillLevel - input.amount * factor, input.type)
					end
				end

				if self.isOwned then
					for y = 1, #production.outputs do
						local output = production.outputs[y]

						if output.sellDirectly then
							if self.isServer then
								self.soldFillTypesToPayOut[output.type] = self.soldFillTypesToPayOut[output.type] + output.amount * factor
							end
						else
							local fillLevel = self.storage:getFillLevel(output.type)

							self.storage:setFillLevel(fillLevel + output.amount * factor, output.type)
						end
					end
				end

				if production.status ~= ProductionPoint.PROD_STATUS.RUNNING then
					production.status = ProductionPoint.PROD_STATUS.RUNNING

					self.owningPlaceable:productionStatusChanged(production, production.status)
					ProductionPointProductionStatusEvent.sendEvent(self, production.id, production.status)
				end

				table.clear(self.inputFillLevels)
			end
		end
	end

	if self.isServer and self.isOwned and self.palletSpawnCooldown < g_time then
		for fillTypeId, pallet in pairs(self.outputFillTypeIdsToPallets) do
			if self.outputFillTypeIdsDirectSell[fillTypeId] == nil and self.outputFillTypeIdsAutoDeliver[fillTypeId] == nil then
				local fillLevel = self.storage:getFillLevel(fillTypeId)

				if fillLevel > 0 and pallet and pallet.capacity <= fillLevel and not self.waitingForPalletToSpawn then
					self.waitingForPalletToSpawn = true

					self.palletSpawner:spawnPallet(self:getOwnerFarmId(), fillTypeId, self.palletSpawnRequestCallback, self)
				end
			end
		end
	end

	self.lastUpdatedTime = g_time
end

function ProductionPoint:updateTick(dt)
end

function ProductionPoint:renderDebugTexts()
	local playerNode = (self.mission.controlledVehicle or {}).rootNode or (self.mission.player or {}).rootNode
	local px, py, pz = getWorldTranslation(playerNode)
	local ppx, ppy, ppz = getWorldTranslation(self.node)
	local distance = MathUtil.vector3Length(px - ppx, py - ppy, pz - ppz)

	if distance < 40 then
		local text = {}

		table.insert(text, string.format("PP %s (%s); ownerFarmId: %s; isOwned: %s", self:getName(), self:tableId(), self.ownerFarmId, self.isOwned))

		for i = 1, #self.productions do
			local production = self.productions[i]

			table.insert(text, string.format("  prodId '%s': cyclesPerMinute: %.2f; enabled: %s", production.id, production.cyclesPerMinute, table.hasElement(self.activeProductions, production)))

			for n = 1, #production.inputs do
				local input = production.inputs[n]

				table.insert(text, string.format("    i: %s: %.2f", g_fillTypeManager:getFillTypeNameByIndex(input.type), input.amount))
			end

			for n = 1, #production.outputs do
				local output = production.outputs[n]

				table.insert(text, string.format("    o: %s: %.2f; directSell:%s; autoDeliver:%s", g_fillTypeManager:getFillTypeNameByIndex(output.type), output.amount, tostring(self.outputFillTypeIdsDirectSell[output.type] == true), tostring(self.outputFillTypeIdsAutoDeliver[output.type] == true)))
			end
		end

		table.insert(text, string.format("productionCostsToClaim : %.1f", self.productionCostsToClaim))
		table.insert(text, string.format("avg updateDuration (%i ms Buffer): %.4f ms", self.valueBuffer.duration, self.valueBuffer:getAverage()))
		table.insert(text, string.format("waitingForPalletToSpawn: %s", self.waitingForPalletToSpawn))

		if g_time < self.palletSpawnCooldown then
			table.insert(text, string.format("palletSpawnCooldown: %.1f s", (self.palletSpawnCooldown - g_time) / 1000))
		end

		self.debugTextElem.text = table.concat(text, "\n")

		self.debugTextElem:update()
		g_debugManager:addFrameElement(self.debugTextElem)
		self.storage:renderDebugInformation()
	end
end

function ProductionPoint:onHourChanged()
	if self.isOwned and self.isServer then
		self:claimProductionCosts()
		self:directlySellOutputs()
		self:updateBalaceDirectlySoldOutputs()
	end
end

function ProductionPoint:onTimescaleChanged()
	self.minuteFactorTimescaled = self.mission:getEffectiveTimeScale() / 1000 / 60
end

function ProductionPoint:claimProductionCosts()
	if self.isOwned and self.isServer and self.productionCostsToClaim > 0 then
		self.mission:addMoney(-self.productionCostsToClaim, self.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
	end

	self.productionCostsToClaim = 0
end

function ProductionPoint:updateBalaceDirectlySoldOutputs()
	if self.isOwned and self.isServer then
		for fillTypeId, amount in pairs(self.soldFillTypesToPayOut) do
			self.mission:addMoney(amount * g_currentMission.economyManager:getPricePerLiter(fillTypeId), self.ownerFarmId, MoneyType.HARVEST_INCOME, true)

			self.soldFillTypesToPayOut[fillTypeId] = 0
		end
	end
end

function ProductionPoint:directlySellOutputs()
	for outputFillTypeId in pairs(self.outputFillTypeIdsDirectSell) do
		local amount = self.storage:getFillLevel(outputFillTypeId)

		if amount > 0 then
			local revenue = ProductionPoint.DIRECT_SELL_PRICE_FACTOR * amount * g_currentMission.economyManager:getPricePerLiter(outputFillTypeId)

			self.mission:addMoney(revenue, self.ownerFarmId, MoneyType.SOLD_PRODUCTS, true)
			self.storage:setFillLevel(0, outputFillTypeId)
		end
	end
end

function ProductionPoint:loadFromXMLFile(xmlFile, key)
	local palletSpawnCooldown = xmlFile:getValue(key .. "#palletSpawnCooldown")

	if palletSpawnCooldown then
		self.palletSpawnCooldown = g_time + palletSpawnCooldown
	end

	self.productionCostsToClaim = xmlFile:getValue(key .. "#productionCostsToClaim") or self.productionCostsToClaim

	if self.owningPlaceable.ownerFarmId == AccessHandler.EVERYONE then
		for n = 1, #self.productions do
			self:setProductionState(self.productions[n].id, true)
		end
	end

	xmlFile:iterate(key .. ".production", function (index, productionKey)
		local prodId = xmlFile:getValue(productionKey .. "#id")
		local isEnabled = xmlFile:getValue(productionKey .. "#isEnabled")

		if self.productionsIdToObj[prodId] == nil then
			Logging.xmlWarning(xmlFile, "Unknown production id '%s'", prodId)
		else
			self:setProductionState(prodId, isEnabled)
		end
	end)
	xmlFile:iterate(key .. ".directSellFillType", function (index, directSellKey)
		local fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(directSellKey))

		if fillType then
			self:setOutputDistributionMode(fillType, ProductionPoint.OUTPUT_MODE.DIRECT_SELL)
		end
	end)
	xmlFile:iterate(key .. ".autoDeliverFillType", function (index, autoDeliverKey)
		local fillType = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(autoDeliverKey))

		if fillType then
			self:setOutputDistributionMode(fillType, ProductionPoint.OUTPUT_MODE.AUTO_DELIVER)
		end
	end)

	if not self.storage:loadFromXMLFile(xmlFile, key .. ".storage") then
		return false
	end

	return true
end

function ProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	if g_time < self.palletSpawnCooldown then
		xmlFile:setValue(key .. "#palletSpawnCooldown", self.palletSpawnCooldown - g_time)
	end

	if self.productionCostsToClaim ~= 0 then
		xmlFile:setValue(key .. "#productionCostsToClaim", self.productionCostsToClaim)
	end

	local xmlIndex = 0

	for i = 1, #self.activeProductions do
		local production = self.activeProductions[i]
		local productionKey = string.format("%s.production(%i)", key, xmlIndex)

		xmlFile:setValue(productionKey .. "#id", production.id)
		xmlFile:setValue(productionKey .. "#isEnabled", true)

		xmlIndex = xmlIndex + 1
	end

	xmlFile:setTable(key .. ".directSellFillType", self.outputFillTypeIdsDirectSell, function (fillTypeKey, _, fillTypeId)
		local fillType = g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)

		xmlFile:setValue(fillTypeKey, fillType)
	end)
	xmlFile:setTable(key .. ".autoDeliverFillType", self.outputFillTypeIdsAutoDeliver, function (fillTypeKey, _, fillTypeId)
		local fillType = g_fillTypeManager:getFillTypeNameByIndex(fillTypeId)

		xmlFile:setValue(fillTypeKey, fillType)
	end)
	self.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
end

function ProductionPoint:getName()
	return self.name or self.owningPlaceable:getName()
end

function ProductionPoint:setProductionState(productionId, state, noEventSend)
	local production = self.productionsIdToObj[productionId]

	if production ~= nil then
		if state then
			if not table.hasElement(self.activeProductions, production) then
				production.status = ProductionPoint.PROD_STATUS.RUNNING

				table.insert(self.activeProductions, production)
			end

			if self.isClient then
				g_soundManager:playSamples(production.samples)
				g_animationManager:startAnimations(production.animationNodes)
				g_effectManager:startEffects(production.effects)
			end
		else
			table.removeElement(self.activeProductions, production)

			production.status = ProductionPoint.PROD_STATUS.INACTIVE

			if self.isClient then
				g_soundManager:stopSamples(production.samples)
				g_animationManager:stopAnimations(production.animationNodes)
				g_effectManager:stopEffects(production.effects)
			end
		end

		self.owningPlaceable:outputsChanged(production.outputs, state)
		ProductionPointProductionStateEvent.sendEvent(self, productionId, state, noEventSend)
	else
		log(string.format("Error: setProductionState(): unknown productionId '%s'", productionId))
	end

	if self.isClient then
		self:updateFxState()
	end
end

function ProductionPoint:getIsProductionEnabled(productionId)
	return table.hasElement(self.activeProductions, self.productionsIdToObj[productionId])
end

function ProductionPoint:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local owningFarm = g_farmManager:getFarmById(self:getOwnerFarmId())

	table.insert(infoTable, {
		title = g_i18n:getText("fieldInfo_ownedBy"),
		text = owningFarm.name
	})

	if #self.activeProductions > 0 then
		table.insert(infoTable, self.infoTables.activeProds)

		local activeProduction = nil

		for i = 1, #self.activeProductions do
			activeProduction = self.activeProductions[i]
			local productionName = activeProduction.name or g_fillTypeManager:getFillTypeByIndex(activeProduction.primaryProductFillType).title

			table.insert(infoTable, {
				title = productionName,
				text = g_i18n:getText(ProductionPoint.PROD_STATUS_TO_L10N[self:getProductionStatus(activeProduction.id)])
			})
		end
	else
		table.insert(infoTable, self.infoTables.noActiveProd)
	end

	local fillType, fillLevel = nil
	local fillTypesDisplayed = false

	table.insert(infoTable, self.infoTables.storage)

	for i = 1, #self.inputFillTypeIdsArray do
		fillType = self.inputFillTypeIdsArray[i]
		fillLevel = self.storage:getFillLevel(fillType)

		if fillLevel > 1 then
			fillTypesDisplayed = true

			table.insert(infoTable, {
				title = g_fillTypeManager:getFillTypeByIndex(fillType).title,
				text = g_i18n:formatVolume(fillLevel, 0)
			})
		end
	end

	for i = 1, #self.outputFillTypeIdsArray do
		fillType = self.outputFillTypeIdsArray[i]
		fillLevel = self.storage:getFillLevel(fillType)

		if fillLevel > 1 then
			fillTypesDisplayed = true

			table.insert(infoTable, {
				title = g_fillTypeManager:getFillTypeByIndex(fillType).title,
				text = g_i18n:formatVolume(fillLevel, 0)
			})
		end
	end

	if not fillTypesDisplayed then
		table.insert(infoTable, self.infoTables.storageEmpty)
	end
end

function ProductionPoint:getProductionStatus(productionId)
	return self.productionsIdToObj[productionId].status
end

function ProductionPoint:setOutputDistributionMode(outputFillTypeId, mode, noEventSend)
	if self.outputFillTypeIds[outputFillTypeId] == nil then
		printf("Error: setOutputDistribution(): fillType '%s' is not an output fillType", g_fillTypeManager:getFillTypeNameByIndex(outputFillTypeId))

		return
	end

	mode = tonumber(mode)
	self.outputFillTypeIdsDirectSell[outputFillTypeId] = nil
	self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = nil

	if mode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
		self.outputFillTypeIdsDirectSell[outputFillTypeId] = true
	elseif mode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
		self.outputFillTypeIdsAutoDeliver[outputFillTypeId] = true
	elseif mode ~= ProductionPoint.OUTPUT_MODE.KEEP then
		printf("Error: setOutputDistribution(): Undefined mode '%s'", mode)

		return
	end

	ProductionPointOutputModeEvent.sendEvent(self, outputFillTypeId, mode, noEventSend)
end

function ProductionPoint:setProductionStatus(productionId, status, noEventSend)
	status = tonumber(status)
	self.productionsIdToObj[productionId].status = status

	ProductionPointProductionStatusEvent.sendEvent(self, productionId, status, noEventSend)
end

function ProductionPoint:getOutputDistributionMode(outputFillTypeId)
	if self.outputFillTypeIdsDirectSell[outputFillTypeId] ~= nil then
		return ProductionPoint.OUTPUT_MODE.DIRECT_SELL
	elseif self.outputFillTypeIdsAutoDeliver[outputFillTypeId] ~= nil then
		return ProductionPoint.OUTPUT_MODE.AUTO_DELIVER
	end

	return ProductionPoint.OUTPUT_MODE.KEEP
end

function ProductionPoint:toggleOutputDistributionMode(outputFillTypeId)
	if self.outputFillTypeIds[outputFillTypeId] ~= nil then
		local curMode = self:getOutputDistributionMode(outputFillTypeId)

		if table.hasElement(ProductionPoint.OUTPUT_MODE, curMode + 1) then
			self:setOutputDistributionMode(outputFillTypeId, curMode + 1)
		else
			self:setOutputDistributionMode(outputFillTypeId, 0)
		end
	end
end

function ProductionPoint:tableId()
	return tostring(self):sub(10)
end

function ProductionPoint:toString()
	local paddedName = self:getName() .. string.rep(" ", 25 - string.len(self:getName()))

	return string.format("PP %s (%s): productions:(%i/%i) - owner: %i", paddedName, self:tableId(), #self.activeProductions, #self.productions, self.ownerFarmId)
end

function ProductionPoint.loadSpecValueInputFillTypes(xmlFile, customEnvironment)
	local fillTypeNames = nil

	xmlFile:iterate("placeable.productionPoint.productions.production", function (_, productionKey)
		xmlFile:iterate(productionKey .. ".inputs.input", function (_, inputKey)
			local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
			fillTypeNames = fillTypeNames or {}
			fillTypeNames[fillTypeName] = true
		end)
	end)

	return fillTypeNames
end

function ProductionPoint.getSpecValueInputFillTypes(storeItem, realItem)
	if storeItem.specs.prodPointInputFillTypes == nil then
		return nil
	end

	return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointInputFillTypes, " "))
end

function ProductionPoint.loadSpecValueOutputFillTypes(xmlFile, customEnvironment)
	local fillTypeNames = nil

	xmlFile:iterate("placeable.productionPoint.productions.production", function (_, productionKey)
		xmlFile:iterate(productionKey .. ".outputs.output", function (_, inputKey)
			local fillTypeName = xmlFile:getValue(inputKey .. "#fillType")
			fillTypeNames = fillTypeNames or {}
			fillTypeNames[fillTypeName] = true
		end)
	end)

	return fillTypeNames
end

function ProductionPoint.getSpecValueOutputFillTypes(storeItem, realItem)
	if storeItem.specs.prodPointOutputFillTypes == nil then
		return nil
	end

	return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.prodPointOutputFillTypes, " "))
end

function ProductionPoint:interactionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and self.mission.player and self.mission.player.rootNode == otherId then
		if onEnter then
			self.activatable:updateText()
			self.mission.activatableObjectsSystem:addActivatable(self.activatable)
		end

		if onLeave then
			self.mission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function ProductionPoint:openMenu()
	g_gui:showGui("InGameMenu")
	g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN, self)
end

function ProductionPoint:buyRequest()
	local storeItem = g_storeManager:getItemByXMLFilename(self.owningPlaceable.configFileName)
	local price = g_currentMission.economyManager:getBuyPrice(storeItem) or self.owningPlaceable:getPrice()

	if self.owningPlaceable.buysFarmland and self.owningPlaceable.farmlandId ~= nil then
		local farmland = g_farmlandManager:getFarmlandById(self.owningPlaceable.farmlandId)

		if farmland ~= nil and g_farmlandManager:getFarmlandOwner(self.owningPlaceable.farmlandId) ~= self.mission:getFarmId() then
			price = price + farmland.price
		end
	end

	local activatable = self.activatable
	local productionPoint = self

	local function buyingEventCallback(statusCode)
		if statusCode ~= nil then
			local dialogArgs = BuyExistingPlaceableEvent.DIALOG_MESSAGES[statusCode]

			if dialogArgs ~= nil then
				g_gui:showInfoDialog({
					text = g_i18n:getText(dialogArgs.text),
					dialogType = dialogArgs.dialogType
				})
			end
		end

		g_messageCenter:unsubscribe(BuyExistingPlaceableEvent, productionPoint)
		activatable:updateText()
	end

	local text = string.format(g_i18n:getText("dialog_buyBuildingFor"), self:getName(), g_i18n:formatMoney(price, 0, true))

	local function dialogCallback(yes)
		if yes then
			g_messageCenter:subscribe(BuyExistingPlaceableEvent, buyingEventCallback)
			g_client:getServerConnection():sendEvent(BuyExistingPlaceableEvent.new(self.owningPlaceable, self.mission:getFarmId()))
		end
	end

	g_gui:showYesNoDialog({
		text = text,
		callback = dialogCallback
	})
end

ProductionPointActivatable = {}
local ProductionPointActivatable_mt = Class(ProductionPointActivatable)

function ProductionPointActivatable.new(productionPoint)
	local self = setmetatable({}, ProductionPointActivatable_mt)
	self.productionPoint = productionPoint
	self.mission = productionPoint.mission

	self:updateText()

	return self
end

function ProductionPointActivatable:updateText()
	if not self.productionPoint.isOwned then
		self.activateText = g_i18n:getText("action_buyProductionPoint")
	else
		self.activateText = g_i18n:getText("action_manageProductionPoint")
	end
end

function ProductionPointActivatable:getIsActivatable()
	return self.mission.accessHandler:canFarmAccess(self.mission:getFarmId(), self.productionPoint)
end

function ProductionPointActivatable:run()
	local ownerFarmId = self.productionPoint:getOwnerFarmId()

	if ownerFarmId == self.mission:getFarmId() then
		self.productionPoint:openMenu()
	elseif ownerFarmId == AccessHandler.EVERYONE then
		self.productionPoint:buyRequest()
	end
end
