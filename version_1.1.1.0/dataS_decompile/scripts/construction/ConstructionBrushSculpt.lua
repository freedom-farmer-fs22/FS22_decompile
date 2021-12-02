ConstructionBrushSculpt = {}
local ConstructionBrushSculpt_mt = Class(ConstructionBrushSculpt, ConstructionBrush)
ConstructionBrushSculpt.MODE = {
	LEVEL = 2,
	SHIFT = 1,
	SOFTEN = 3,
	SLOPE = 4
}
ConstructionBrushSculpt.CURSOR_SIZES = {
	2,
	4,
	8,
	16,
	32
}

function ConstructionBrushSculpt.new(subclass_mt, cursor)
	local self = ConstructionBrushSculpt:superClass().new(subclass_mt or ConstructionBrushSculpt_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.supportsSecondaryButton = true
	self.supportsSecondaryDragging = true
	self.supportsTertiaryButton = true
	self.supportsPrimaryAxis = true
	self.requiredPermission = Farm.PERMISSION.LANDSCAPING

	return self
end

function ConstructionBrushSculpt:delete()
	ConstructionBrushSculpt:superClass().delete(self)
end

function ConstructionBrushSculpt:activate()
	ConstructionBrushSculpt:superClass().activate(self)

	self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE

	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setTerrainOnly(true)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SCULPTING)
	self.cursor:setCursorTerrainOffset(true)
	self:setBrushSize(1)
end

function ConstructionBrushSculpt:deactivate()
	self.cursor:setTerrainOnly(false)
	ConstructionBrushSculpt:superClass().deactivate(self)
end

function ConstructionBrushSculpt:copyState(from)
	self:setBrushSize(from.cursorSizeIndex)

	self.brushShape = from.brushShape

	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	else
		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	end
end

function ConstructionBrushSculpt:setParameters(mode)
	self.mode = mode
end

function ConstructionBrushSculpt:setBrushSize(index)
	self.cursorSizeIndex = MathUtil.clamp(index, 2, #ConstructionBrushSculpt.CURSOR_SIZES)
	local size = ConstructionBrushSculpt.CURSOR_SIZES[self.cursorSizeIndex]
	self.brushRadius = size / 2

	self.cursor:setShapeSize(size)
end

function ConstructionBrushSculpt:toggleBrushShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE

		self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	end
end

function ConstructionBrushSculpt:update(dt)
	ConstructionBrushSculpt:superClass().update(self, dt)

	if self.showNoTargetHeightError then
		self.cursor:setErrorMessage(g_i18n:getText("ui_construction_noTargetHeightSet"))
	elseif self.slopeAngle ~= nil then
		self.cursor:setMessage(string.format("%d%%", self.slopeAngle * 100))
	else
		local x, y, z = self.cursor:getHitTerrainPosition()

		if x ~= nil then
			local err = self:verifyAccess(x, y, z)

			if err ~= nil then
				local message = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[err])

				self.cursor:setErrorMessage(message)
			end
		end
	end
end

function ConstructionBrushSculpt:shift(x, y, z, direction)
	local currentRadius = self.brushRadius
	local validateOnly = false
	local strength = 0.5
	local operation = direction > 0 and Landscaping.OPERATION.RAISE or Landscaping.OPERATION.LOWER
	local requestLandscaping = LandscapingSculptEvent.new(validateOnly, operation, x, y, z, nil, , , , , , currentRadius, strength, self.brushShape, Landscaping.TERRAIN_UNIT)

	g_client:getServerConnection():sendEvent(requestLandscaping)
end

function ConstructionBrushSculpt:flatten(x, y, z)
	local validateOnly = false
	local strength = 0.5
	local operation = Landscaping.OPERATION.FLATTEN

	if self.flattenHeight == nil then
		self.flattenHeight = y
	end

	local request = LandscapingSculptEvent.new(validateOnly, operation, x, self.flattenHeight, z, nil, , , , , , self.brushRadius, strength, self.brushShape, Landscaping.TERRAIN_UNIT)

	g_client:getServerConnection():sendEvent(request)
end

function ConstructionBrushSculpt:smooth(x, y, z)
	local validateOnly = false
	local strength = 1
	local operation = Landscaping.OPERATION.SMOOTH
	local requestLandscaping = LandscapingSculptEvent.new(validateOnly, operation, x, y, z, nil, , , , , , self.brushRadius, strength, self.brushShape, Landscaping.TERRAIN_UNIT)

	g_client:getServerConnection():sendEvent(requestLandscaping)
end

function ConstructionBrushSculpt:slope(x, y, z)
	if self.slopeTargetX == nil then
		self.showNoTargetHeightError = true

		return
	else
		self.showNoTargetHeightError = false
	end

	if self.slopeSourceX == nil then
		self.slopeSourceZ = z
		self.slopeSourceY = y
		self.slopeSourceX = x
		local x1 = x
		local y1 = y
		local z1 = z
		local x2 = self.slopeTargetX
		local y2 = self.slopeTargetY
		local z2 = self.slopeTargetZ
		local vx1, vy1, vz1 = MathUtil.vector3Normalize(x2 - x1, y2 - y1, z2 - z1)
		self.slopeAngle = MathUtil.clamp((y1 - y2) / math.max(MathUtil.vector2Length(x1 - x2, z1 - z2), 1e-06), 0, 1)
		local vx2, vy2, vz2 = MathUtil.vector3Normalize(-vz1, 0, vx1)
		local nx, ny, nz = MathUtil.crossProduct(vx2, vy2, vz2, vx1, vy1, vz1)
		self.slopeNZ = nz
		self.slopeNY = ny
		self.slopeNX = nx
		self.slopeD = -(nx * x1 + ny * y1 + nz * z1)
		self.slopeMinY = math.min(y1, y2)
		self.slopeMaxY = math.max(y1, y2)
	end

	local validateOnly = false
	local strength = 5
	local operation = Landscaping.OPERATION.SLOPE
	local requestLandscaping = LandscapingSculptEvent.new(validateOnly, operation, x, y, z, self.slopeNX, self.slopeNY, self.slopeNZ, self.slopeD, self.slopeMinY, self.slopeMaxY, self.brushRadius, strength, self.brushShape, Landscaping.TERRAIN_UNIT)

	g_client:getServerConnection():sendEvent(requestLandscaping)
end

function ConstructionBrushSculpt:slopeSetTarget(x, y, z)
	self.slopeTargetZ = z
	self.slopeTargetY = y
	self.slopeTargetX = x
	self.slopeAngle = nil
	self.showNoTargetHeightError = false
end

function ConstructionBrushSculpt:onButtonPrimary(isDown, isDrag, isUp)
	if isUp then
		self.flattenHeight = nil
		self.slopeSourceZ = nil
		self.slopeSourceY = nil
		self.slopeSourceX = nil
		self.showNoTargetHeightError = false
		self.slopeAngle = nil

		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	local err = self:verifyAccess(x, y, z)

	if err ~= nil then
		return
	end

	if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
		self:shift(x, y, z, 1)
	elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
		self:flatten(x, y, z)
	elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
		self:smooth(x, y, z)
	elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
		self:slope(x, y, z)
	end
end

function ConstructionBrushSculpt:onButtonSecondary(isDown, isDrag, isUp)
	if isUp then
		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x == nil then
		return
	end

	if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
		self:shift(x, y, z, -1)
	elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
		self:slopeSetTarget(x, y, z)
	end
end

function ConstructionBrushSculpt:onButtonTertiary()
	self:toggleBrushShape()
end

function ConstructionBrushSculpt:onAxisPrimary(inputValue)
	self:setBrushSize(self.cursorSizeIndex + inputValue)
end

function ConstructionBrushSculpt:getButtonPrimaryText()
	if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
		return "$l10n_input_CONSTRUCTION_SHIFT_UP"
	elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
		return "$l10n_input_CONSTRUCTION_LEVEL"
	elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
		return "$l10n_input_CONSTRUCTION_SOFTEN"
	elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
		return "$l10n_input_CONSTRUCTION_SLOPE"
	end

	return nil
end

function ConstructionBrushSculpt:getButtonSecondaryText()
	if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
		return "$l10n_input_CONSTRUCTION_SHIFT_DOWN"
	elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
		return nil
	elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
		return nil
	elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
		return "$l10n_input_CONSTRUCTION_SLOPE_START"
	end

	return nil
end

function ConstructionBrushSculpt:getAxisPrimaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end

function ConstructionBrushSculpt:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end
