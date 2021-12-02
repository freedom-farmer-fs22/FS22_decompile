PlaceableHusbandryPallets = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableHusbandryPallets.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onPalletTriggerCallback", PlaceableHusbandryPallets.onPalletTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "getAllPalletsCallback", PlaceableHusbandryPallets.getAllPalletsCallback)
	SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableHusbandryPallets.updatePallets)
	SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableHusbandryPallets.getPalletCallback)
	SpecializationUtil.registerFunction(placeableType, "showSpawnerBlockedWarning", PlaceableHusbandryPallets.showSpawnerBlockedWarning)
	SpecializationUtil.registerFunction(placeableType, "showPalletBlockedWarning", PlaceableHusbandryPallets.showPalletBlockedWarning)
	SpecializationUtil.registerFunction(placeableType, "updatePalletInfo", PlaceableHusbandryPallets.updatePalletInfo)
end

function PlaceableHusbandryPallets.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryPallets.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryPallets.updateOutput)
end

function PlaceableHusbandryPallets.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryPallets)
end

function PlaceableHusbandryPallets.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.pallets"

	schema:register(XMLValueType.NODE_INDEX, basePath .. ".palletTrigger(?)#node", "A pallet trigger")
	schema:register(XMLValueType.STRING, basePath .. "#fillType", "Pallet fill type")
	schema:register(XMLValueType.STRING, basePath .. "#unitText", "Pallet fill type unit")
	schema:register(XMLValueType.INT, basePath .. "#maxNumPallets", "Maximum number of pallets")
	PalletSpawner.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryPallets.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.FLOAT, basePath .. "#pendingLiters", "Pending liters")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Fill Level")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryPallets:onLoad(savegame)
	local spec = self.spec_husbandryPallets
	spec.palletSpawner = PalletSpawner.new()

	spec.palletSpawner:load(self.components, self.xmlFile, "placeable.husbandry.pallets", self.customEnvironment, self.i3dMappings)

	local fillTypeName = self.xmlFile:getValue("placeable.husbandry.pallets#fillType")
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	if fillTypeIndex == nil then
		Logging.xmlError(self.xmlFile, "Pallet filltype '%s' not defined", fillTypeName)
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	spec.fillTypeIndex = fillTypeIndex
	spec.fillUnitIndex = 1
	spec.fillTypeUnit = g_i18n:convertText(self.xmlFile:getValue("placeable.husbandry.pallets#unitText") or "$l10n_unit_literShort", self.customEnvironment)
	spec.maxNumPallets = self.xmlFile:getValue("placeable.husbandry.pallets#maxNumPallets", 1)

	if self.isServer then
		spec.palletTriggers = {}

		self.xmlFile:iterate("placeable.husbandry.pallets.palletTrigger", function (_, key)
			local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

			if node ~= nil then
				table.insert(spec.palletTriggers, {
					added = false,
					node = node
				})
			end
		end)
	end

	spec.isPalletInfoUpdateRunning = false
	spec.animalTypeName = nil
	spec.currentPallet = nil
	spec.pendingLiters = 0
	spec.fillLevel = 0
	spec.fillLevelSent = 0
	spec.capacity = 0
	spec.capacitySent = 0
	spec.litersPerHour = 0
	spec.fillType = nil
	spec.pallets = {}
	spec.spawnPending = false
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function PlaceableHusbandryPallets:onDelete()
	local spec = self.spec_husbandryPallets

	if self.isServer and spec.palletTriggers ~= nil then
		for _, trigger in ipairs(spec.palletTriggers) do
			if trigger.added then
				removeTrigger(trigger.node)
			end
		end
	end
end

function PlaceableHusbandryPallets:onFinalizePlacement()
	local spec = self.spec_husbandryPallets

	if self.isServer then
		for _, trigger in ipairs(spec.palletTriggers) do
			addTrigger(trigger.node, "onPalletTriggerCallback", self)

			trigger.added = true
		end
	end
end

function PlaceableHusbandryPallets:onReadStream(streamId, connection)
	local spec = self.spec_husbandryPallets
	spec.fillLevel = streamReadFloat32(streamId)
	spec.capacity = streamReadFloat32(streamId)
end

function PlaceableHusbandryPallets:onWriteStream(streamId, connection)
	local spec = self.spec_husbandryPallets

	streamWriteFloat32(streamId, spec.fillLevelSent)
	streamWriteFloat32(streamId, spec.capacitySent)
end

function PlaceableHusbandryPallets:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_husbandryPallets
		spec.fillLevel = streamReadFloat32(streamId)
		spec.capacity = streamReadFloat32(streamId)
	end
end

function PlaceableHusbandryPallets:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_husbandryPallets

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, spec.fillLevelSent)
			streamWriteFloat32(streamId, spec.capacitySent)
		end
	end
end

function PlaceableHusbandryPallets:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_husbandryPallets
	self.pendingLiters = xmlFile:getValue(key .. "#pendingLiters", spec.pendingLiters)

	self:updatePalletInfo()
end

function PlaceableHusbandryPallets:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_husbandryPallets

	xmlFile:setValue(key .. "#pendingLiters", spec.pendingLiters)
end

function PlaceableHusbandryPallets:onHusbandryAnimalsCreated(husbandry)
	if husbandry ~= nil then
		local animalTypeIndex = self:getAnimalTypeIndex()
		local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)

		if animalType ~= nil then
			local spec = self.spec_husbandryPallets
			local l10nText = "ui_statisticView_" .. tostring(animalType.name):lower()
			spec.animalTypeName = g_i18n:getText(l10nText, self.customEnvironment)
		end
	end
end

function PlaceableHusbandryPallets:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryPallets
	spec.litersPerHour = 0

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local pallets = subType.output.pallets

			if pallets ~= nil then
				local age = cluster:getAge()
				local litersPerAnimal = pallets:get(age)
				local litersPerDay = litersPerAnimal * cluster:getNumAnimals()
				spec.litersPerHour = spec.litersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryPallets:onPalletTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onLeave then
		local spec = self.spec_husbandryPallets
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil then
			if object == spec.currentPallet then
				spec.currentPallet = nil
			end

			spec.pallets[object] = nil

			self:updatePalletInfo()
		end
	end
end

function PlaceableHusbandryPallets:updatePalletInfo()
	if self.isServer then
		local spec = self.spec_husbandryPallets

		if not spec.isPalletInfoUpdateRunning then
			spec.isPalletInfoUpdateRunning = true

			spec.palletSpawner:getAllPallets(spec.fillTypeIndex, self.getAllPalletsCallback, self)
		end
	end
end

function PlaceableHusbandryPallets:getAllPalletsCallback(pallets)
	local spec = self.spec_husbandryPallets
	local fillLevel = 0
	local capacity = 0
	local maxCapacity = 0
	spec.isPalletInfoUpdateRunning = false

	for _, pallet in pairs(pallets) do
		local palletCapacity = pallet:getFillUnitCapacity(spec.fillUnitIndex)
		capacity = capacity + palletCapacity
		maxCapacity = math.max(maxCapacity, palletCapacity)
		fillLevel = fillLevel + pallet:getFillUnitFillLevel(spec.fillUnitIndex)
	end

	if #pallets < spec.maxNumPallets then
		capacity = maxCapacity * spec.maxNumPallets
	end

	spec.fillLevel = fillLevel
	spec.capacity = capacity

	if math.abs(fillLevel - spec.fillLevelSent) > 1 or math.abs(capacity - spec.capacitySent) > 1 then
		spec.fillLevelSent = fillLevel
		spec.capacitySent = capacity

		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function PlaceableHusbandryPallets:updatePallets()
	if self.isServer then
		local spec = self.spec_husbandryPallets

		if not spec.spawnPending and spec.pendingLiters > 5 then
			spec.spawnPending = true

			spec.palletSpawner:getOrSpawnPallet(self:getOwnerFarmId(), spec.fillTypeIndex, self.getPalletCallback, self)
		end
	end
end

function PlaceableHusbandryPallets:getPalletCallback(pallet, result, fillTypeIndex)
	local spec = self.spec_husbandryPallets
	spec.spawnPending = false
	spec.currentPallet = pallet

	if pallet ~= nil then
		if result == PalletSpawner.RESULT_SUCCESS then
			pallet:emptyAllFillUnits(true)
		end

		spec.pallets[pallet] = true
		local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)
		spec.pendingLiters = math.max(spec.pendingLiters - delta, 0)

		if spec.pendingLiters > 5 then
			self:updatePallets()
		end
	else
		self:showSpawnerBlockedWarning()
	end

	self:updatePalletInfo()
end

function PlaceableHusbandryPallets:showSpawnerBlockedWarning()
	local spec = self.spec_husbandryPallets

	if not spec.showedWarning then
		if self.isServer then
			g_currentMission:broadcastEventToFarm(AnimalHusbandryNoMorePalletSpaceEvent.new(self), self:getOwnerFarmId(), false)
		end

		self:showPalletBlockedWarning()

		spec.showedWarning = true
	end
end

function PlaceableHusbandryPallets:showPalletBlockedWarning()
	local spec = self.spec_husbandryPallets

	if self.isClient and g_currentMission:getFarmId() == self:getOwnerFarmId() then
		local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

		if fillType ~= nil and spec.animalTypeName ~= nil then
			local text = string.format(g_i18n:getText("ingameNotification_palletSpawnerBlocked"), fillType.title, spec.animalTypeName)

			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
		end
	end
end

function PlaceableHusbandryPallets:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local spec = self.spec_husbandryPallets
	local info = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)
	info.title = fillType.title
	info.value = spec.fillLevel
	local ratio = 0

	if spec.capacity > 0 then
		ratio = spec.fillLevel / spec.capacity
	end

	info.ratio = MathUtil.clamp(ratio, 0, 1)
	info.invertedBar = true
	info.customUnitText = spec.fillTypeUnit

	table.insert(infos, info)

	return infos
end

function PlaceableHusbandryPallets:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)

	local spec = self.spec_husbandryPallets
	spec.showedWarning = false

	if self.isServer and spec.litersPerHour > 0 then
		spec.pendingLiters = spec.pendingLiters + productionFactor * globalProductionFactor * spec.litersPerHour * g_currentMission.environment.timeAdjustment

		self:updatePallets()
	end
end
