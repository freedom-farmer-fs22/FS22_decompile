MixerWagonHUDExtension = {}
local MixerWagonHUDExtension_mt = Class(MixerWagonHUDExtension, VehicleHUDExtension)

VehicleHUDExtension.registerHUDExtension(MixerWagon, MixerWagonHUDExtension)

function MixerWagonHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
	local self = VehicleHUDExtension.new(MixerWagonHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)
	self.mixerWagon = vehicle.spec_mixerWagon
	self.fillTypeStatus = {}

	for _, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
		local fillType = g_fillTypeManager:getFillTypeByIndex(next(mixerWagonFillType.fillTypes))

		if fillType ~= nil then
			local entry = {
				minPercentage = 0,
				maxPercentage = 0,
				fillLevel = 0,
				fillType = fillType,
				minPercentage = mixerWagonFillType.minPercentage,
				maxPercentage = mixerWagonFillType.maxPercentage
			}
			local width, height = getNormalizedScreenValues(30 * uiScale, 30 * uiScale)
			entry.overlay = Overlay.new(fillType.hudOverlayFilename, 0, 0, width, height)

			entry.overlay:setColor(unpack(uiTextColor))
			self:addComponentForCleanup(entry.overlay)

			entry.statusBarColor = MixerWagonHUDExtension.COLOR.STATUS_BAR_GOOD
			entry.statusBarColor2 = MixerWagonHUDExtension.COLOR.STATUS_BAR_BAD
			width, height = getNormalizedScreenValues(315 * uiScale, 12 * uiScale)
			entry.statusBar = StatusBar.new(g_baseUIFilename, g_colorBgUVs, nil, MixerWagonHUDExtension.COLOR.STATUS_BAR_BG, entry.statusBarColor2, nil, 0, 0, width, height)

			self:addComponentForCleanup(entry.statusBar)
			table.insert(self.fillTypeStatus, entry)
		end
	end

	local _ = nil
	self.fillLevelTextOffsetX, self.fillLevelTextOffsetY = getNormalizedScreenValues(105 * uiScale, 7 * uiScale)
	_, self.helpHeightPerFruit = getNormalizedScreenValues(0, 28 * uiScale)
	_, self.helpHeightOffset = getNormalizedScreenValues(0, 12 * uiScale)
	local width, height = getNormalizedScreenValues(9 * uiScale, 12.5 * uiScale)
	self.fillRangeMarkerOverlay = Overlay.new(g_baseUIFilename, 0, 0, width, height)

	self.fillRangeMarkerOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
	self.fillRangeMarkerOverlay:setUVs(GuiUtils.getUVs(MixerWagonHUDExtension.UV.RANGE_MARKER_ARROW))
	self.fillRangeMarkerOverlay:setColor(unpack(uiTextColor))
	self:addComponentForCleanup(self.fillRangeMarkerOverlay)

	self.displayHeight = (#self.mixerWagon.mixerWagonFillTypes + 1) * self.helpHeightPerFruit + self.helpHeightOffset

	return self
end

function MixerWagonHUDExtension:canDraw()
	return self.vehicle:getIsActiveForInput(true)
end

function MixerWagonHUDExtension:getDisplayHeight()
	return self:canDraw() and self.displayHeight or 0
end

function MixerWagonHUDExtension:draw(leftPosX, rightPosX, posY)
	setTextColor(unpack(self.uiTextColor))
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(leftPosX, posY + self.displayHeight - self.uiTextSize * 1.7, self.uiTextSize, g_i18n:getText("info_mixingRatio"))
	setTextBold(false)

	local totalFillLevel = 0

	if self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) > 0 then
		for i, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
			totalFillLevel = totalFillLevel + mixerWagonFillType.fillLevel
			self.fillTypeStatus[i].fillLevel = mixerWagonFillType.fillLevel
		end
	end

	local barY = posY + #self.fillTypeStatus * self.helpHeightPerFruit + self.helpHeightPerFruit * 0.3

	for _, fillTypeDisplay in ipairs(self.fillTypeStatus) do
		barY = barY - self.helpHeightPerFruit
		local percentage = 0

		if self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) > 0 then
			percentage = fillTypeDisplay.fillLevel / totalFillLevel
		end

		if fillTypeDisplay.fillLevel > 0 then
			if self.vehicle:getFillUnitFillType(self.mixerWagon.fillUnitIndex) ~= FillType.FORAGE_MIXING or fillTypeDisplay.minPercentage <= percentage and percentage <= fillTypeDisplay.maxPercentage then
				fillTypeDisplay.statusBar:setColor(unpack(fillTypeDisplay.statusBarColor))
			else
				fillTypeDisplay.statusBar:setColor(unpack(fillTypeDisplay.statusBarColor2))
			end
		end

		fillTypeDisplay.statusBar:setPosition(rightPosX - fillTypeDisplay.statusBar.width, barY + (self.helpHeightPerFruit - fillTypeDisplay.statusBar.height) * 0.5)
		fillTypeDisplay.statusBar:setValue(percentage)
		fillTypeDisplay.statusBar:render()

		if fillTypeDisplay.overlay ~= nil then
			fillTypeDisplay.overlay:setPosition(leftPosX, barY + (self.helpHeightPerFruit - fillTypeDisplay.overlay.height) * 0.5)
			fillTypeDisplay.overlay:render()
		end

		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(leftPosX + self.fillLevelTextOffsetX, barY + self.fillLevelTextOffsetY, self.uiTextSize, string.format("%1.1f%%", percentage * 100))
		setTextAlignment(RenderText.ALIGN_LEFT)

		local y = fillTypeDisplay.statusBar.y + fillTypeDisplay.statusBar.height * 0.5
		local maxLeft = fillTypeDisplay.statusBar.x + fillTypeDisplay.statusBar.width
		local xLeft = math.min(fillTypeDisplay.statusBar.x + fillTypeDisplay.statusBar.width * fillTypeDisplay.minPercentage, maxLeft)
		local xRight = math.min(fillTypeDisplay.statusBar.x + fillTypeDisplay.statusBar.width * fillTypeDisplay.maxPercentage, maxLeft)

		self.fillRangeMarkerOverlay:setInvertX(false)
		self.fillRangeMarkerOverlay:setPosition(xLeft, y)
		self.fillRangeMarkerOverlay:render()
		self.fillRangeMarkerOverlay:setInvertX(true)
		self.fillRangeMarkerOverlay:setPosition(xRight - self.fillRangeMarkerOverlay.width, y)
		self.fillRangeMarkerOverlay:render()
	end

	return posY
end

MixerWagonHUDExtension.COLOR = {
	STATUS_BAR_BG = {
		0.8,
		0.8,
		0.8,
		0.5
	},
	STATUS_BAR_GOOD = {
		0.3763,
		0.6038,
		0.0782,
		1
	},
	STATUS_BAR_BAD = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
}
MixerWagonHUDExtension.UV = {
	RANGE_MARKER_ARROW = {
		880,
		395,
		18,
		25
	}
}
