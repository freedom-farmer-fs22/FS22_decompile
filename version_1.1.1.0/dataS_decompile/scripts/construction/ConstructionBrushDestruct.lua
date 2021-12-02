ConstructionBrushDestruct = {}
local ConstructionBrushDestruct_mt = Class(ConstructionBrushDestruct, ConstructionBrush)
ConstructionBrushDestruct.OVERLAY_COLOR = {
	1,
	0.1,
	0.1
}

function ConstructionBrushDestruct.new(subclass_mt, cursor)
	local self = ConstructionBrushDestruct:superClass().new(subclass_mt or ConstructionBrushDestruct_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.requiredPermission = Farm.PERMISSION.SELL_PLACEABLE

	return self
end

function ConstructionBrushDestruct:delete()
	ConstructionBrushDestruct:superClass().delete(self)
end

function ConstructionBrushDestruct:activate()
	ConstructionBrushDestruct:superClass().activate(self)
	self.cursor:setRotationEnabled(false)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
	self.cursor:setSelectionMode(true)
end

function ConstructionBrushDestruct:deactivate()
	self.cursor:setSelectionMode(false)
	ConstructionBrushDestruct:superClass().deactivate(self)
end

function ConstructionBrushDestruct:update(dt)
	ConstructionBrushDestruct:superClass().update(self, dt)
	self:visualizeMouseOver()

	if not self:hasPlayerPermission() then
		self.cursor:setErrorMessage(g_i18n:getText("shop_messageNoPermissionGeneral"))
	end
end

function ConstructionBrushDestruct:visualizeMouseOver()
	local placeable = self.cursor:getHitPlaceable()

	if placeable ~= self.lastPlaceable or self.perNodeMode then
		if self.lastPlaceable ~= nil then
			if self.lastPlaceable.rootNode ~= nil then
				self.lastPlaceable:setOverlayColor(1, 1, 1, 0)
			end

			self.lastPlaceable = nil
		end

		if placeable ~= nil and g_currentMission.player.farmId == placeable.ownerFarmId then
			self.lastPlaceable = placeable
			local color = ConstructionBrushDestruct.OVERLAY_COLOR
			local r = color[1]
			local g = color[2]
			local b = color[3]
			local a = 0.8

			if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
				local nodes = placeable:previewNodeDestructionNodes(self.cursor:getHitNode())

				if nodes ~= nil then
					for _, node in ipairs(nodes) do
						if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
							setShaderParameter(node, "placeableColorScale", r, g, b, a, false)
						end
					end
				end

				self.perNodeMode = true
			else
				placeable:setOverlayColor(r, g, b, a)

				self.perNodeMode = false
			end
		end
	end
end

function ConstructionBrushDestruct:onButtonPrimary(isDown, isDrag, isUp)
	if isUp then
		self.lastDragPlaceable = nil

		return
	end

	local placeable = self.cursor:getHitPlaceable()

	if placeable ~= nil and g_currentMission.player.farmId == placeable.ownerFarmId and (self.lastDragPlaceable == nil or placeable == self.lastDragPlaceable) then
		if not self:hasPlayerPermission() then
			return
		end

		if placeable:getDestructionMethod() == Placeable.DESTRUCTION.PER_NODE then
			if isDown then
				self.lastDragPlaceable = placeable
			end

			placeable:performNodeDestruction(self.cursor:getHitNode())
		elseif isDown then
			local canBeSold, warning = placeable:canBeSold()
			local price = g_currentMission.economyManager:getSellPrice(placeable)

			local function callbackFunc(yes)
				if yes then
					g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable))
				end
			end

			if warning ~= nil then
				if canBeSold then
					g_gui:showYesNoDialog({
						text = warning,
						callback = callbackFunc,
						yesText = g_i18n:getText("button_ok"),
						noText = g_i18n:getText("button_cancel")
					})
				else
					g_gui:showInfoDialog({
						text = warning,
						buttonAction = InputAction.MENU_BACK,
						okText = g_i18n:getText("button_back")
					})
				end
			else
				g_gui:showYesNoDialog({
					text = string.format(g_i18n:getText("ui_constructionSellConfirmation"), placeable:getName(), g_i18n:formatMoney(price, 0, true, true)),
					callback = callbackFunc
				})
			end
		end
	end
end

function ConstructionBrushDestruct:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_REMOVE"
end
