ConstructionBrushSelect = {}
local ConstructionBrushSelect_mt = Class(ConstructionBrushSelect, ConstructionBrush)
ConstructionBrushSelect.OVERLAY_COLOR = {
	0.2,
	0.4,
	1
}

function ConstructionBrushSelect.new(subclass_mt, cursor)
	local self = ConstructionBrushSelect:superClass().new(subclass_mt or ConstructionBrushSelect_mt, cursor)
	self.isSelector = true
	self.supportsFourthButton = true

	return self
end

function ConstructionBrushSelect:delete()
	ConstructionBrushSelect:superClass().delete(self)
end

function ConstructionBrushSelect:activate()
	ConstructionBrushSelect:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
	self.cursor:setSelectionMode(true)
	g_messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableDestroyed, self)
end

function ConstructionBrushSelect:deactivate()
	if self.lastPlaceable ~= nil then
		if self.lastPlaceable.rootNode ~= nil and entityExists(self.lastPlaceable.rootNode) then
			self.lastPlaceable:setOverlayColor(0.2, 0.4, 1, 0)
		end

		self.lastPlaceable = nil
	end

	self.pauseUpdates = false

	self.cursor:setSelectionMode(false)
	g_messageCenter:unsubscribeAll(self)
	ConstructionBrushSelect:superClass().deactivate(self)
end

function ConstructionBrushSelect:update(dt)
	ConstructionBrushSelect:superClass().update(self, dt)

	if self.lastPlaceable ~= nil and self.lastPlaceable.isDeleted then
		self.lastPlaceable = nil
		self.pauseUpdates = false
	end

	if not self.pauseUpdates then
		self:visualizeMouseOver()
	end
end

function ConstructionBrushSelect:visualizeMouseOver()
	local placeable = self.cursor:getHitPlaceable()

	if placeable ~= self.lastPlaceable then
		if self.lastPlaceable ~= nil then
			if self.lastPlaceable.rootNode ~= nil then
				self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
			end

			self.lastPlaceable = nil
		end

		if placeable ~= nil and placeable:getDestructionMethod() ~= Placeable.DESTRUCTION.PER_NODE then
			local color = ConstructionBrushSelect.OVERLAY_COLOR

			placeable:setOverlayColor(color[1], color[2], color[3], 0.8)

			self.lastPlaceable = placeable
		end
	end
end

function ConstructionBrushSelect:onButtonFourth()
	if self.lastPlaceable == nil or self.lastPlaceable.isDeleted then
		self.lastPlaceable = nil
		self.pauseUpdates = false

		return
	end

	self.pauseUpdates = true

	g_gui:showPlaceableInfoDialog({
		placeable = self.lastPlaceable,
		callback = function (didSell)
			if didSell then
				self.lastPlaceable = nil
			end

			self.pauseUpdates = false
		end
	})
end

function ConstructionBrushSelect:onPlaceableDestroyed()
	if self.lastPlaceable ~= nil and self.lastPlaceable.isDeleted then
		self.lastPlaceable = nil
		self.pauseUpdates = false
	end
end

function ConstructionBrushSelect:getButtonFourthText()
	return "$l10n_button_select"
end
