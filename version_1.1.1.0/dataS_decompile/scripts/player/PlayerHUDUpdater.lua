PlayerHUDUpdater = {}
local PlayerHUDUpdater_mt = Class(PlayerHUDUpdater)

function PlayerHUDUpdater.new()
	local self = setmetatable({}, PlayerHUDUpdater_mt)
	self.object = nil
	self.isBale = false
	self.isVehicle = false
	self.isPallet = false
	self.isSplitShape = false
	self.isAnimal = false
	self.fieldBox = g_currentMission.hud.infoDisplay:createBox(KeyValueInfoHUDBox)
	self.objectBox = g_currentMission.hud.infoDisplay:createBox(KeyValueInfoHUDBox)

	return self
end

function PlayerHUDUpdater:delete()
	g_currentMission.hud.infoDisplay:destroyBox(self.fieldBox)
	g_currentMission.hud.infoDisplay:destroyBox(self.objectBox)
end

function PlayerHUDUpdater:update(dt, x, y, z, rotY)
	self:updateFieldInfo(x, z, rotY)

	if self.fieldData ~= nil then
		self:showFieldInfo()
	end

	if self.isVehicle then
		self:showVehicleInfo(self.object)
	elseif self.isBale then
		self:showBaleInfo(self.object)
	elseif self.isPallet then
		self:showPalletInfo(self.object)
	elseif self.isSplitShape then
		self:showSplitShapeInfo(self.object)
	elseif self.isAnimal then
		self:showAnimalInfo(self.object)
	end
end

function PlayerHUDUpdater:setCurrentRaycastTarget(node)
	if self.currentRaycastTarget ~= node then
		self.currentRaycastTarget = node

		self:updateRaycastObject()
	end
end

function PlayerHUDUpdater:updateRaycastObject()
	self.isBale = false
	self.isVehicle = false
	self.isPallet = false
	self.isSplitShape = false
	self.isAnimal = false
	self.object = nil

	if self.currentRaycastTarget == nil then
		return
	end

	local object = g_currentMission:getNodeObject(self.currentRaycastTarget)

	if object == nil then
		local splitType = getSplitType(self.currentRaycastTarget)

		if splitType ~= 0 then
			self.isSplitShape = true
			self.object = self.currentRaycastTarget

			return
		end

		local husbandryId, animalId = getAnimalFromCollisionNode(self.currentRaycastTarget)

		if husbandryId ~= nil and husbandryId ~= 0 then
			local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandyById(husbandryId)

			if clusterHusbandry ~= nil then
				local cluster = clusterHusbandry:getClusterByAnimalId(animalId)

				if cluster ~= nil then
					self.isAnimal = true
					self.object = cluster
				end
			end
		end

		return
	end

	self.object = object

	if object:isa(Vehicle) then
		if object.typeName == "pallet" or object.typeName == "treeSaplingPallet" or object.typeName == "bigBag" then
			self.isPallet = true
		else
			self.isVehicle = true
		end
	elseif object:isa(Bale) then
		self.isBale = true
	end
end

function PlayerHUDUpdater:showVehicleInfo(vehicle)
	local name = vehicle:getFullName()
	local farmId = vehicle:getOwnerFarmId()

	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		local farm = g_farmManager:getFarmById(farmId)
		local box = self.objectBox

		box:clear()
		box:setTitle(name)

		local propertyState = vehicle:getPropertyState()

		if propertyState == Vehicle.PROPERTY_STATE_OWNED then
			box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farm.name)
		else
			box:addLine(g_i18n:getText("infohud_rentedBy"), farm.name)
		end

		vehicle:showInfo(box)
		box:showNextFrame()
	end
end

function PlayerHUDUpdater:showBaleInfo(bale)
	local farm = g_farmManager:getFarmById(bale:getOwnerFarmId())
	local box = self.objectBox

	box:clear()
	box:setTitle(g_i18n:getText("infohud_bale"))

	if farm ~= nil then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farm.name)
	end

	bale:showInfo(box)
	box:showNextFrame()
end

function PlayerHUDUpdater:showPalletInfo(pallet)
	local mass = pallet:getTotalMass()
	local farm = g_farmManager:getFarmById(pallet:getOwnerFarmId())
	local box = self.objectBox

	box:clear()
	box:setTitle(g_i18n:getText("infohud_pallet"))

	if farm ~= nil then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farm.name)
	end

	box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
	pallet:showInfo(box)
	box:showNextFrame()
end

function PlayerHUDUpdater:showSplitShapeInfo(splitShape)
	if not entityExists(splitShape) then
		return
	end

	local splitTypeId = getSplitType(splitShape)

	if splitTypeId == 0 then
		return
	end

	local mass = getMass(splitShape)
	local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(splitShape)
	local splitType = g_splitTypeManager:getSplitTypeByIndex(splitTypeId)
	local splitTypeName = splitType and splitType.title
	local length = math.max(sizeX, sizeY, sizeZ)
	local box = self.objectBox

	box:clear()
	box:setTitle(g_i18n:getText("infohud_wood"))

	if splitTypeName ~= nil then
		box:addLine(g_i18n:getText("infohud_type"), splitTypeName)
	end

	box:addLine(g_i18n:getText("infohud_length"), g_i18n:formatNumber(length, 1) .. " m")
	box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
	box:showNextFrame()
end

function PlayerHUDUpdater:showAnimalInfo(cluster)
	local box = self.objectBox

	box:clear()
	box:setTitle(g_i18n:getText("infohud_animal"))
	cluster:showInfo(box)
	box:showNextFrame()
end

PlayerHUDUpdater.LIME_REQUIRED_THRESHOLD = 0.25
PlayerHUDUpdater.PLOWING_REQUIRED_THRESHOLD = 0.25

function PlayerHUDUpdater:updateFieldInfo(posX, posZ, rotY)
	if self.requestedFieldData then
		return
	end

	local sizeX = 5
	local sizeZ = 5
	local distance = 2
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
	local sideX, _, sideZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
	local startWorldX = posX - sideX * sizeX * 0.5 - dirX * distance
	local startWorldZ = posZ - sideZ * sizeX * 0.5 - dirZ * distance
	local widthWorldX = posX + sideX * sizeX * 0.5 - dirX * distance
	local widthWorldZ = posZ + sideZ * sizeX * 0.5 - dirZ * distance
	local heightWorldX = posX - sideX * sizeX * 0.5 - dirX * (distance + sizeZ)
	local heightWorldZ = posZ - sideZ * sizeX * 0.5 - dirZ * (distance + sizeZ)
	self.requestedFieldData = true

	FSDensityMapUtil.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.onFieldDataUpdateFinished, self)
end

function PlayerHUDUpdater:onFieldDataUpdateFinished(data)
	if self.requestedFieldData then
		self.fieldData = data
		self.fieldInfoNeedsRebuild = true
	end

	self.requestedFieldData = false
end

function PlayerHUDUpdater:showFieldInfo()
	local data = self.fieldData
	local box = self.fieldBox

	if self.fieldInfoNeedsRebuild then
		box:clear()
		box:setTitle(g_i18n:getText("ui_fieldInfo"))
		self:fieldAddFarmland(data, box)
		self:fieldAddFruit(data, box)
		self:fieldAddFertilization(data, box)
		self:fieldAddWeed(data, box)
		self:fieldAddLime(data, box)
		self:fieldAddPlowing(data, box)

		self.fieldInfoNeedsRebuild = false
	end

	box:showNextFrame()
end

function PlayerHUDUpdater:fieldAddFarmland(data, box)
	local farmName = nil
	local ownerFarmId = data.ownerFarmId

	if ownerFarmId == g_currentMission:getFarmId() and ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
		farmName = g_i18n:getText("fieldInfo_ownerYou")
	elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
		local farmland = g_farmlandManager:getFarmlandById(data.farmlandId)

		if farmland == nil then
			farmName = g_i18n:getText("fieldInfo_ownerNobody")
		else
			local npc = farmland:getNPC()
			farmName = npc.title
		end
	else
		local farm = g_farmManager:getFarmById(ownerFarmId)

		if farm ~= nil then
			farmName = farm.name
		else
			farmName = "Unknown"
		end
	end

	box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farmName)
end

function PlayerHUDUpdater:fieldAddLime(data, box)
	local isRequired = PlayerHUDUpdater.LIME_REQUIRED_THRESHOLD < data.needsLimeFactor

	if isRequired and g_currentMission.missionInfo.limeRequired then
		box:addLine(g_i18n:getText("ui_growthMapNeedsLime"), nil, true)
	end
end

function PlayerHUDUpdater:fieldAddPlowing(data, box)
	local isRequired = PlayerHUDUpdater.PLOWING_REQUIRED_THRESHOLD < data.needsPlowFactor

	if isRequired and g_currentMission.missionInfo.plowingRequiredEnabled then
		box:addLine(g_i18n:getText("ui_growthMapNeedsPlowing"), nil, true)
	end
end

function PlayerHUDUpdater:fieldAddFertilization(data, box)
	local fertilizationFactor = data.fertilizerFactor

	if fertilizationFactor >= 0 then
		box:addLine(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", fertilizationFactor * 100))
	end
end

function PlayerHUDUpdater:fieldAddWeed(data, box)
	local weedFactor = data.weedFactor

	if weedFactor >= 0 and g_currentMission.missionInfo.weedsEnabled then
		box:addLine(g_i18n:getText("fillType_weed"), string.format("%d %%", (1 - weedFactor) * 100))
	end
end

function PlayerHUDUpdater:fieldAddFruit(data, box)
	local fruitTypeIndex = 0
	local fruitGrowthState = 0
	local maxPixels = 0

	for fruitDescIndex, state in pairs(data.fruits) do
		if maxPixels < data.fruitPixels[fruitDescIndex] then
			maxPixels = data.fruitPixels[fruitDescIndex]
			fruitTypeIndex = fruitDescIndex
			fruitGrowthState = state
		end
	end

	if fruitTypeIndex == 0 then
		return
	end

	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

	box:addLine(g_i18n:getText("statistic_fillType"), fruitType.fillType.title)

	local witheredState = fruitType.maxHarvestingGrowthState + 1

	if fruitType.maxPreparingGrowthState >= 0 then
		witheredState = fruitType.maxPreparingGrowthState + 1
	end

	local maxGrowingState = fruitType.minHarvestingGrowthState - 1

	if fruitType.minPreparingGrowthState >= 0 then
		maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
	end

	local text = nil

	if fruitGrowthState == fruitType.cutState then
		text = g_i18n:getText("ui_growthMapCut")
	elseif fruitGrowthState == witheredState then
		text = g_i18n:getText("ui_growthMapWithered")
	elseif fruitGrowthState > 0 and fruitGrowthState <= maxGrowingState then
		text = g_i18n:getText("ui_growthMapGrowing")
	elseif fruitType.minPreparingGrowthState >= 0 and fruitType.minPreparingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxPreparingGrowthState then
		text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
	elseif fruitType.minHarvestingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxHarvestingGrowthState then
		text = g_i18n:getText("ui_growthMapReadyToHarvest")
	end

	if text ~= nil then
		box:addLine(g_i18n:getText("ui_mapOverviewGrowth"), text)
	end
end
