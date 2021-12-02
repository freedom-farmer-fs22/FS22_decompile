PlaceableBeehivePalletSpawner = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableBeehivePalletSpawner.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "addFillLevel", PlaceableBeehivePalletSpawner.addFillLevel)
	SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableBeehivePalletSpawner.updatePallets)
	SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableBeehivePalletSpawner.getPalletCallback)
end

function PlaceableBeehivePalletSpawner.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableBeehivePalletSpawner.canBuy)
end

function PlaceableBeehivePalletSpawner.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehivePalletSpawner)
end

function PlaceableBeehivePalletSpawner.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BeehivePalletSpawner")
	PalletSpawner.registerXMLPaths(schema, basePath .. ".beehivePalletSpawner")
	schema:setXMLSpecializationType()
end

function PlaceableBeehivePalletSpawner:onLoad(savegame)
	local spec = self.spec_beehivePalletSpawner
	local xmlFile = self.xmlFile
	local palletSpawnerKey = "placeable.beehivePalletSpawner"
	spec.palletSpawner = PalletSpawner.new()

	if not spec.palletSpawner:load(self.components, xmlFile, palletSpawnerKey, self.customEnvironment, self.i3dMappings) then
		Logging.xmlError(xmlFile, "Unable to load pallet spawner %s", palletSpawnerKey)

		return false
	end

	spec.pendingLiters = 0
	spec.spawnPending = false
	spec.fillType = g_fillTypeManager:getFillTypeIndexByName("HONEY")
end

function PlaceableBeehivePalletSpawner:onDelete()
	local spec = self.spec_beehivePalletSpawner

	if spec.palletSpawner ~= nil then
		spec.palletSpawner:delete()
	end

	g_currentMission.beehiveSystem:removeBeehivePalletSpawner(self)
end

function PlaceableBeehivePalletSpawner:onFinalizePlacement()
	g_currentMission.beehiveSystem:addBeehivePalletSpawner(self)
end

function PlaceableBeehivePalletSpawner:addFillLevel(fillLevel)
	if self.isServer then
		local spec = self.spec_beehivePalletSpawner

		if fillLevel ~= nil then
			spec.pendingLiters = spec.pendingLiters + fillLevel
		end
	end
end

function PlaceableBeehivePalletSpawner:updatePallets()
	if self.isServer then
		local spec = self.spec_beehivePalletSpawner

		if spec.pendingLiters > 5 then
			spec.spawnPending = true

			spec.palletSpawner:getOrSpawnPallet(self:getOwnerFarmId(), spec.fillType, self.getPalletCallback, self)
		end
	end
end

function PlaceableBeehivePalletSpawner:getPalletCallback(pallet, result, fillTypeIndex)
	local spec = self.spec_beehivePalletSpawner
	spec.spawnPending = false

	if pallet ~= nil then
		if result == PalletSpawner.RESULT_SUCCESS then
			pallet:emptyAllFillUnits(true)
		end

		local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), 1, spec.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)
		spec.pendingLiters = math.max(spec.pendingLiters - delta, 0)

		if spec.pendingLiters > 5 then
			self:updatePallets()
		end
	end
end

function PlaceableBeehivePalletSpawner:canBuy(superFunc)
	local canBuy, warning = superFunc(self)

	if not canBuy then
		return false, warning
	end

	if g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(g_currentMission.player.farmId) ~= nil then
		return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
	end

	return true, nil
end
