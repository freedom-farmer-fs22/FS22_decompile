ConstructionBrushFoliage = {}
local ConstructionBrushFoliage_mt = Class(ConstructionBrushFoliage, ConstructionBrush)

function ConstructionBrushFoliage.new(subclass_mt, cursor)
	local self = ConstructionBrushFoliage:superClass().new(subclass_mt or ConstructionBrushFoliage_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.supportsSecondaryButton = true
	self.supportsSecondaryDragging = true
	self.requiredPermission = Farm.PERMISSION.LANDSCAPING
	self.supportsPrimaryAxis = true
	self.primaryAxisIsContinuous = false
	self.supportsTertiaryButton = true

	return self
end

function ConstructionBrushFoliage:delete()
	ConstructionBrushFoliage:superClass().delete(self)
end

function ConstructionBrushFoliage:activate()
	ConstructionBrushFoliage:superClass().activate(self)

	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE

	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	self:setBrushSize(1)
	g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptingFinished, self)
end

function ConstructionBrushFoliage:deactivate()
	self.cursor:setTerrainOnly(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushFoliage:superClass().deactivate(self)
end

function ConstructionBrushFoliage:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)

	self.brushShape = from.brushShape

	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
end

function ConstructionBrushFoliage:setFoliageType(foliageName, foliageState)
	if not self.isActive then
		self.foliagePaint = g_currentMission.foliageSystem:getFoliagePaintByName(foliageName)
		self.foliageState = foliageState
	end
end

function ConstructionBrushFoliage:setParameters(foliageName, foliageState)
	self:setFoliageType(foliageName, tonumber(foliageState))
end

function ConstructionBrushFoliage:setBrushSize(index)
	self.cursorSizeIndex = MathUtil.clamp(index, 1, #ConstructionBrush.CURSOR_SIZES)
	local size = ConstructionBrush.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = size / 2

	self.cursor:setShapeSize(size)
end

function ConstructionBrushFoliage:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

function ConstructionBrushFoliage:update(dt)
	ConstructionBrushFoliage:superClass().update(self, dt)

	if self.foliagePaint == nil then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_plantNotSupported"))

		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	local err = self:verifyAccess(x, y, z)

	if err ~= nil then
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[err]))
	elseif g_currentMission:getMoney() < self:getPrice() then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
	end
end

function ConstructionBrushFoliage:getPrice()
	return Landscaping.FOLIAGE_BASE_COST_PER_M2 * 5
end

function ConstructionBrushFoliage:onSculptingFinished(isValidation, errorCode, displacedVolumeOrArea)
	local success = errorCode == TerrainDeformation.STATE_SUCCESS
end

function ConstructionBrushFoliage:performBrush(isDown, isDrag, isUp, direction)
	if isUp then
		self.lastX = nil

		return
	end

	if self.foliagePaint == nil then
		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	local radius = self.brushRadius
	local validateOnly = false

	if self.lastX ~= nil then
		local dx = x - self.lastX
		local dz = z - self.lastZ
		local dist = math.sqrt(dx * dx + dz * dz)

		if dist < 0.25 then
			return
		end
	end

	self.lastZ = z
	self.lastX = x
	local err = self:verifyAccess(x, y, z)

	if err ~= nil then
		return
	end

	local requestLandscaping = nil

	if direction > 0 then
		requestLandscaping = LandscapingSculptEvent.new(validateOnly, Landscaping.OPERATION.FOLIAGE, x, y, z, nil, , , , , , radius, 1, self.brushShape, Landscaping.TERRAIN_UNIT, nil, self.foliagePaint.id, self.foliageState)
	else
		requestLandscaping = LandscapingSculptEvent.new(validateOnly, Landscaping.OPERATION.PAINT, x, y, z, nil, , , , , , radius, 1, self.brushShape, Landscaping.TERRAIN_UNIT, TerrainDeformation.NO_TERRAIN_BRUSH)
	end

	g_client:getServerConnection():sendEvent(requestLandscaping)
end

function ConstructionBrushFoliage:onButtonPrimary(isDown, isDrag, isUp)
	self:performBrush(isDown, isDrag, isUp, 1)
end

function ConstructionBrushFoliage:onButtonSecondary(isDown, isDrag, isUp)
	self:performBrush(isDown, isDrag, isUp, -1)
end

function ConstructionBrushFoliage:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushFoliage:onButtonTertiary()
	self:toggleBrushShape()
end

function ConstructionBrushFoliage:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushFoliage:getButtonSecondaryText()
	return "$l10n_input_CONSTRUCTION_REMOVE"
end

function ConstructionBrushFoliage:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushFoliage:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end
