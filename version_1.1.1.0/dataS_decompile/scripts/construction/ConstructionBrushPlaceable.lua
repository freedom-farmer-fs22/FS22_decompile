ConstructionBrushPlaceable = {}
local ConstructionBrushPlaceable_mt = Class(ConstructionBrushPlaceable, ConstructionBrush)
ConstructionBrushPlaceable.ERROR = {
	NOT_ENOUGH_SLOTS = 201,
	NOT_ENOUGH_MONEY = 200,
	CANNOT_BE_BOUGHT = 202,
	DEFORM_FAILED = 206,
	OBJECT_OVERLAP = 205,
	CANNOT_BE_PLACED_HERE = 203,
	PLAYER_COLLISION = 204,
	BLOCKED = 207
}
ConstructionBrushPlaceable.ERROR_MESSAGES = {
	[ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS] = "ui_construction_notEnoughSlots",
	[ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT] = "ui_construction_cannotBeBought",
	[ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE] = "ui_construction_cannotBePlacedHere",
	[ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION] = "ui_construction_collidesWithPlayer",
	[ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP] = "ui_construction_overlapsWithObject",
	[ConstructionBrushPlaceable.ERROR.DEFORM_FAILED] = "ui_construction_deformationFailed",
	[ConstructionBrushPlaceable.ERROR.BLOCKED] = "ui_construction_deformationBlocked"
}
ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3 = 5
ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS = 2

function ConstructionBrushPlaceable.new(subclass_mt, cursor)
	local self = ConstructionBrushPlaceable:superClass().new(subclass_mt or ConstructionBrushPlaceable_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryAxis = true
	self.primaryAxisIsContinuous = false
	self.supportsSecondaryAxis = false
	self.secondaryAxisIsContinuous = false
	self.placeable = nil
	self.isLoading = false
	self.isPlacing = false
	self.offsetY = 0
	self.inputHeight = 0
	self.displacementCosts = 0
	self.colorIndex = 1
	self.placingText = g_i18n:getText("ui_construction_placingItem")
	self.loadingText = g_i18n:getText("ui_construction_loadingItem")
	self.errorText = nil
	self.errorEndTime = 0
	self.activeValidationCount = 0
	self.requiredPermission = Farm.PERMISSION.BUY_PLACEABLE

	return self
end

function ConstructionBrushPlaceable:delete()
	ConstructionBrushPlaceable:superClass().delete(self)
end

function ConstructionBrushPlaceable:activate()
	ConstructionBrushPlaceable:superClass().activate(self)
	self.cursor:setRotationEnabled(true)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)

	self.offsetY = 0

	self:loadPlaceable()
end

function ConstructionBrushPlaceable:deactivate()
	self:unloadPlaceable()
	ConstructionBrushPlaceable:superClass().deactivate(self)
end

function ConstructionBrushPlaceable:setPlaceableFilename(xmlFilename)
	if not self.isActive then
		self.placeableXMLFilename = xmlFilename
		self.storeItem = g_storeManager:getItemByXMLFilename(xmlFilename)
	end
end

function ConstructionBrushPlaceable:setParameters(filename)
	self:setPlaceableFilename(filename)
end

function ConstructionBrushPlaceable:update(dt)
	ConstructionBrushPlaceable:superClass().update(self, dt)
	self:updateHeightFromInput(dt)

	if self.errorText ~= nil and self.errorEndTime < g_time then
		self.errorText = nil
	end

	self:updatePlaceablePosition()
end

function ConstructionBrushPlaceable:updateHeightFromInput(dt)
	self.offsetY = self.offsetY + self.inputHeight * dt * 0.005
	self.inputHeight = 0
end

function ConstructionBrushPlaceable:getSnappedRotation(rotY)
	if self.placeable ~= nil and self.placeable.getPlacementRotation ~= nil then
		local _ = nil
		_, rotY, _ = self.placeable:getPlacementRotation(0, rotY, 0)
	end

	return rotY
end

function ConstructionBrushPlaceable:getSnappedPosition(x, y, z)
	if x == nil then
		return nil
	end

	if self.placeable ~= nil and self.placeable.getPlacementPosition ~= nil then
		x, y, z = self.placeable:getPlacementPosition(x, y, z)
	end

	return x, y + self.offsetY, z
end

function ConstructionBrushPlaceable:getDisplacementCost()
	return self.displacementCosts
end

function ConstructionBrushPlaceable:getPrice()
	return g_currentMission.economyManager:getBuyPrice(self.storeItem) + self:getDisplacementCost()
end

function ConstructionBrushPlaceable:updatePlaceablePosition()
	if self.errorText ~= nil then
		self.cursor:setErrorMessage(self.errorText)
	elseif self.isPlacing then
		self.cursor:setMessage(self.placingText)
	elseif self.isLoading then
		self.cursor:setMessage(self.loadingText)
	elseif self.placeable ~= nil then
		local x, y, z = self.cursor:getPosition()
		local rotY = self.cursor:getRotation()

		self.placeable:startPlacementCheck(x, y, z, rotY)

		x, y, z = self:getSnappedPosition(x, y, z)
		rotY = self:getSnappedRotation(rotY)

		if x ~= nil then
			self.placeable:setPreviewPosition(x, y, z, 0, rotY, 0)

			local err, message = self:verifyPlacement(x, y, z, rotY)

			if err ~= nil then
				if message == nil then
					message = g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err])
				end

				self.cursor:setErrorMessage(message)
			elseif self.displacementError ~= nil then
				self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrushPlaceable.ERROR_MESSAGES[self.displacementError]))
			else
				self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
			end
		end

		setVisibility(self.placeable.rootNode, self.cursor.isVisible)
	else
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_couldNotLoadItem"))
	end
end

function ConstructionBrushPlaceable:verifyPlacement(x, y, z, rotY)
	local err = self:verifyAccess(x, y, z, self.placeable)

	if err ~= nil then
		return err
	end

	local price = self:getPrice()
	local enoughMoney = price <= g_currentMission:getMoney()
	local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(self.storeItem)

	if not enoughMoney then
		return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_MONEY
	end

	if not enoughSlots then
		return ConstructionBrushPlaceable.ERROR.NOT_ENOUGH_SLOTS
	end

	local canBuy, message = self.placeable:canBuy()

	if not canBuy then
		return ConstructionBrushPlaceable.ERROR.CANNOT_BE_BOUGHT, message
	end

	local canBePlaced, placingFailedMessage = self.placeable:getCanBePlacedAt(x, y, z, g_currentMission:getFarmId())

	if not canBePlaced then
		return ConstructionBrushPlaceable.ERROR.CANNOT_BE_PLACED_HERE, placingFailedMessage
	end

	if self.placeable.getHasOverlap ~= nil then
		local hasOverlap, node = self.placeable:getHasOverlap(x, y, z, rotY)

		if hasOverlap then
			local isPlayer = false

			if node ~= nil then
				isPlayer = g_currentMission.players[node] ~= nil
			end

			if isPlayer then
				return ConstructionBrushPlaceable.ERROR.PLAYER_COLLISION
			else
				return ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
			end
		end
	end

	if self.placeable.getHasOverlapWithZones ~= nil and self.placeable:getHasOverlapWithZones(g_currentMission.restrictedZones, x, y, z, rotY) then
		return ConstructionBrush.ERROR.RESTRICTED_ZONE
	end

	if self.placeable.getHasOverlapWithPlaces ~= nil then
		if self.placeable:getHasOverlapWithPlaces(g_currentMission.storeSpawnPlaces, x, y, z, rotY) then
			return ConstructionBrush.ERROR.STORE_PLACE
		end

		if self.placeable:getHasOverlapWithPlaces(g_currentMission.loadSpawnPlaces, x, y, z, rotY) then
			return ConstructionBrush.ERROR.SPAWN_PLACE
		end
	end

	if self.placeable.getRequiresLeveling ~= nil and self.placeable:getRequiresLeveling() and self.activeValidationCount < ConstructionBrushPlaceable.MAX_ACTIVE_VALIDATIONS then
		self.terrainValidationPending = true
		self.activeValidationCount = self.activeValidationCount + 1

		self.placeable:applyDeformation(true, function (...)
			self:onTerrainValidationFinished(...)
		end)
	end

	return nil
end

function ConstructionBrushPlaceable:onTerrainValidationFinished(errorCode, displacedVolume, blockedObjectName)
	self.activeValidationCount = self.activeValidationCount - 1
	self.terrainValidationPending = false

	if errorCode == TerrainDeformation.STATE_STATE_CANCELLED then
		return
	elseif errorCode == TerrainDeformation.STATE_SUCCESS then
		self.displacementCosts = displacedVolume * ConstructionBrushPlaceable.DISPLACEMENT_COST_PER_M3
		self.displacementError = nil
	else
		self.displacementCosts = 0

		if errorCode == TerrainDeformation.STATE_FAILED_BLOCKED then
			self.displacementError = ConstructionBrushPlaceable.ERROR.BLOCKED
		elseif errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT then
			self.displacementError = ConstructionBrushPlaceable.ERROR.OBJECT_OVERLAP
		elseif errorCode == TerrainDeformation.STATE_FAILED_TO_DEFORM then
			self.displacementError = ConstructionBrushPlaceable.ERROR.DEFORM_FAILED
		end
	end
end

function ConstructionBrushPlaceable:loadPlaceable()
	if self.placeableXMLFilename == nil then
		Logging.warning("Placeable brush has no placeable set")

		return
	end

	self.isLoading = true
	local position = {
		z = 0,
		x = 0,
		y = -500
	}
	local rotation = {
		z = 0,
		x = 0,
		y = 0
	}
	self.loadingPlaceable = PlaceableUtil.loadPlaceable(self.placeableXMLFilename, position, rotation, nil, , ConstructionBrushPlaceable.loadedPlaceable, self, {})
end

function ConstructionBrushPlaceable:loadedPlaceable(placeable, loadingState, args)
	self.isLoading = false
	self.loadingPlaceable = nil

	if loadingState == Placeable.LOADING_STATE_ERROR then
		Logging.warning("Failed to load placeable")

		if placeable ~= nil then
			placeable:delete()
		end

		return
	end

	if placeable == nil then
		Logging.warning("Failed to load placeable")

		return
	end

	if not self.isActive then
		placeable:delete()

		return
	end

	placeable:setOwnerFarmId(g_currentMission.player.farmId)

	if placeable.setColor ~= nil then
		placeable:setColor(self.colorIndex)
	end

	self:setInputTextDirty()

	self.placeable = placeable
end

function ConstructionBrushPlaceable:unloadPlaceable()
	if self.placeable ~= nil then
		self.placeable:delete()

		self.placeable = nil
		self.isLoading = false
		self.isPlacing = false
	end

	if self.loadingPlaceable ~= nil then
		self.loadingPlaceable:delete()
	end
end

function ConstructionBrushPlaceable:onButtonPrimary()
	if self.placeable == nil then
		return
	end

	if self.isLoading or self.isPlacing or self.displacementError ~= nil then
		return false
	end

	local displacementCosts = self:getDisplacementCost()
	local modifyingTerrain = true
	local x, y, z = self.cursor:getPosition()
	local rotY = self.cursor:getRotation()

	self.placeable:startPlacementCheck(x, y, z, rotY)

	x, y, z = self:getSnappedPosition(x, y, z)
	rotY = self:getSnappedRotation(rotY)
	local err = self:verifyPlacement(x, y, z, rotY)

	if err ~= nil then
		return
	end

	self.isPlacing = true

	g_messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableCreated, self)
	g_client:getServerConnection():sendEvent(BuyPlaceableEvent.new(self.placeableXMLFilename, x, y, z, 0, rotY, 0, displacementCosts, g_currentMission:getFarmId(), modifyingTerrain, self.colorIndex))
end

function ConstructionBrushPlaceable:onAxisPrimary(inputValue)
	if self.placeable.getAvailableColors == nil then
		return
	end

	local colors = self.placeable:getAvailableColors()

	if #colors > 0 then
		self.colorIndex = self.colorIndex + inputValue

		if self.colorIndex > #colors then
			self.colorIndex = 1
		elseif self.colorIndex < 1 then
			self.colorIndex = #colors
		end

		self.placeable:setColor(self.colorIndex)
	end
end

function ConstructionBrushPlaceable:onAxisSecondary(inputValue)
	self.inputHeight = inputValue
end

function ConstructionBrushPlaceable:onPlaceableCreated(errorCode, price)
	self.isPlacing = false
	local errorText = nil

	if errorCode == BuyPlaceableEvent.STATE_FAILED_TO_LOAD then
		errorText = g_i18n:getText("ui_construction_couldNotLoadItem")
	elseif errorCode == BuyPlaceableEvent.STATE_NO_SPACE then
		errorText = g_i18n:getText("ui_construction_spaceAlreadyOccupied")
	elseif errorCode == BuyPlaceableEvent.STATE_NO_PERMISSION then
		errorText = g_i18n:getText("ui_construction_noBuildPermission")
	elseif errorCode == BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY then
		errorText = g_i18n:getText("ui_construction_notEnoughMoney")
	elseif errorCode == BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED then
		errorText = g_i18n:getText("ui_construction_deformationFailed")
	end

	if errorText ~= nil then
		self.errorText = errorText
		self.errorEndTime = g_time + 3000
	end

	g_messageCenter:unsubscribe(BuyPlaceableEvent, self)
end

function ConstructionBrushPlaceable:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushPlaceable:getAxisPrimaryText()
	if self.placeable ~= nil and self.placeable.getHasColors ~= nil and self.placeable:getHasColors() then
		return "$l10n_input_CONSTRUCTION_CHANGE_COLOR"
	else
		return nil
	end
end

function ConstructionBrushPlaceable:getAxisSecondaryText()
	return "$l10n_input_CONSTRUCTION_HEIGHT"
end
