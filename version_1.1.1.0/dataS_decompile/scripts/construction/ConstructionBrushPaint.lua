ConstructionBrushPaint = {}
local ConstructionBrushPaint_mt = Class(ConstructionBrushPaint, ConstructionBrush)

function ConstructionBrushPaint.new(subclass_mt, cursor)
	local self = ConstructionBrushPaint:superClass().new(subclass_mt or ConstructionBrushPaint_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.requiredPermission = Farm.PERMISSION.LANDSCAPING
	self.supportsPrimaryAxis = true
	self.primaryAxisIsContinuous = false
	self.supportsTertiaryButton = true

	return self
end

function ConstructionBrushPaint:delete()
	ConstructionBrushPaint:superClass().delete(self)
end

function ConstructionBrushPaint:activate()
	ConstructionBrushPaint:superClass().activate(self)

	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE

	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.PAINTING)
	self.cursor:setTerrainOnly(true)
	self:setBrushSize(1)
	g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptingFinished, self)
end

function ConstructionBrushPaint:deactivate()
	self.cursor:setTerrainOnly(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushPaint:superClass().deactivate(self)
end

function ConstructionBrushPaint:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)

	self.brushShape = from.brushShape

	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
end

function ConstructionBrushPaint:setGroundType(groundTypeName)
	if not self.isActive then
		local layer = g_groundTypeManager:getTerrainLayerByType(groundTypeName)
		self.terrainLayer = layer
	end
end

function ConstructionBrushPaint:setParameters(groundTypeName)
	self:setGroundType(groundTypeName)
end

function ConstructionBrushPaint:setBrushSize(index)
	self.cursorSizeIndex = MathUtil.clamp(index, 1, #ConstructionBrush.CURSOR_SIZES)
	local size = ConstructionBrush.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = size / 2

	self.cursor:setShapeSize(size)
end

function ConstructionBrushPaint:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

function ConstructionBrushPaint:update(dt)
	ConstructionBrushPaint:superClass().update(self, dt)

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	local err = self:verifyAccess(x, y, z)

	if err ~= nil then
		self.cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[err]))
	elseif g_currentMission:getMoney() < Landscaping.PAINT_BASE_COST_PER_M2 * 5 then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
	end
end

function ConstructionBrushPaint:onSculptingFinished(isValidation, errorCode, displacedVolumeOrArea)
	local success = errorCode == TerrainDeformation.STATE_SUCCESS
end

function ConstructionBrushPaint:onButtonPrimary(isDown, isDrag, isUp)
	if isUp then
		self.lastX = nil

		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	local currentRadius = self.brushRadius
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

	local requestLandscaping = LandscapingSculptEvent.new(validateOnly, Landscaping.OPERATION.PAINT, x, y, z, nil, , , , , , currentRadius, 1, self.brushShape, Landscaping.TERRAIN_UNIT, self.terrainLayer)

	g_client:getServerConnection():sendEvent(requestLandscaping)
end

function ConstructionBrushPaint:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushPaint:onButtonTertiary()
	self:toggleBrushShape()
end

function ConstructionBrushPaint:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PAINT"
end

function ConstructionBrushPaint:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushPaint:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end
