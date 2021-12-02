VariableWorkWidthHUDExtension = {}
local VariableWorkWidthHUDExtension_mt = Class(VariableWorkWidthHUDExtension, VehicleHUDExtension)

VehicleHUDExtension.registerHUDExtension(VariableWorkWidth, VariableWorkWidthHUDExtension)

function VariableWorkWidthHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
	local self = VehicleHUDExtension.new(VariableWorkWidthHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)
	self.variableWorkWidth = vehicle.spec_variableWorkWidth
	local _, sectionHeight = getNormalizedScreenValues(0, 15 * uiScale)
	self.sectionOverlays = {}
	local numSections = #self.variableWorkWidth.sections

	for i = 1, numSections do
		local section = self.variableWorkWidth.sections[i]
		local sectionOverlay = {}
		local overlay = Overlay.new(g_baseHUDFilename, 0, 0, 0, sectionHeight)

		overlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
		overlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
		overlay:setColor(unpack(uiTextColor))
		self:addComponentForCleanup(overlay)

		sectionOverlay.overlay = overlay
		sectionOverlay.section = section

		if i < numSections and self.variableWorkWidth.sections[i + 1].isCenter or section.isCenter or not self.variableWorkWidth.hasCenter and i == numSections / 2 then
			local separatorWidth, separatorHeight = getNormalizedScreenValues(1, 35 * uiScale)
			separatorWidth = math.max(separatorWidth, 1 / g_screenWidth)
			local separator = Overlay.new(g_baseHUDFilename, 0, 0, separatorWidth, separatorHeight)

			separator:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
			separator:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
			separator:setColor(unpack(VariableWorkWidthHUDExtension.COLOR.SEPARATOR))
			self:addComponentForCleanup(separator)

			sectionOverlay.separator = separator
		end

		table.insert(self.sectionOverlays, sectionOverlay)
	end

	local _, helpHeight = getNormalizedScreenValues(0, 75 * uiScale)
	self.displayHeight = helpHeight

	return self
end

function VariableWorkWidthHUDExtension:canDraw()
	return self.vehicle:getIsActiveForInput(true) and self.variableWorkWidth.drawInputHelp
end

function VariableWorkWidthHUDExtension:getDisplayHeight()
	return self:canDraw() and self.displayHeight or 0
end

function VariableWorkWidthHUDExtension:draw(leftPosX, rightPosX, posY)
	setTextColor(unpack(self.uiTextColor))
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(leftPosX, posY + self.displayHeight - self.uiTextSize * 1.7, self.uiTextSize, g_i18n:getText("info_partialWorkingWidth"))
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)

	local usage = self.vehicle:getVariableWorkWidthUsage()

	if usage ~= nil then
		usage = MathUtil.round(usage)

		renderText(rightPosX, posY + self.displayHeight - self.uiTextSize * 1.7, self.uiTextSize, string.format(g_i18n:getText("info_workWidthAndUsage"), usage, self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea)))
	else
		renderText(rightPosX, posY + self.displayHeight - self.uiTextSize * 1.7, self.uiTextSize, string.format(g_i18n:getText("info_workWidth"), self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea)))
	end

	local numSections = #self.sectionOverlays
	local _, yOffset = getNormalizedScreenValues(0, 25 * self.uiScale)
	local fullWidth = rightPosX - leftPosX
	local sectionWidth = fullWidth / numSections
	local sideOffset = sectionWidth * 0.1

	for i = 1, numSections do
		local overlay = self.sectionOverlays[i].overlay
		local color = VariableWorkWidthHUDExtension.COLOR.SECTION_ACTIVE

		if not self.sectionOverlays[i].section.isActive then
			color = VariableWorkWidthHUDExtension.COLOR.SECTION_INACTIVE
		end

		local posX = leftPosX + sectionWidth * (i - 1) * (1 + sectionWidth * 0.2 / fullWidth)
		local width = sectionWidth * 0.8

		overlay:setPosition(posX, posY + yOffset)
		overlay:setDimension(width)
		overlay:setColor(unpack(color))
		overlay:render()

		local separator = self.sectionOverlays[i].separator

		if separator ~= nil then
			separator:setPosition(posX + width + sideOffset - separator.width * 0.5, posY + yOffset)
			separator:render()
		end
	end

	return posY
end

VariableWorkWidthHUDExtension.COLOR = {
	SECTION_ACTIVE = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	SECTION_INACTIVE = {
		0.0003,
		0.5647,
		0.9822,
		0.25
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.3
	}
}
VariableWorkWidthHUDExtension.UV = {}
