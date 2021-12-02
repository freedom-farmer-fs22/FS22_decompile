FieldHotspot = {}
local FieldHotspot_mt = Class(FieldHotspot, MapHotspot)

function FieldHotspot.new(customMt)
	local self = MapHotspot.new(customMt or FieldHotspot_mt)
	local _, textSize = getNormalizedScreenValues(0, 16)
	self.textSize = textSize
	self.name = ""

	return self
end

function FieldHotspot:getCategory()
	return MapHotspot.CATEGORY_FIELD
end

function FieldHotspot:getWidth()
	return getTextWidth(self.textSize * self.scale, self.name)
end

function FieldHotspot:getHeight()
	return self.textSize * self.scale
end

function FieldHotspot:setField(field)
	self.field = field
	self.name = field:getName()
	self.worldX = field.posX
	self.worldZ = field.posZ
end

function FieldHotspot:getField()
	return self.field
end

function FieldHotspot:setOwnerFarmId(farmId)
	FieldHotspot:superClass().setOwnerFarmId(self, farmId)

	if farmId ~= FarmlandManager.NO_OWNER_FARM_ID then
		local farm = g_farmManager:getFarmById(farmId)

		if farm ~= nil then
			local color = farm:getColor()

			if color ~= nil then
				self:setColor(color[1], color[2], color[3], color[4])
			end
		end
	else
		self:setColor(1, 1, 1, 1)
	end
end

function FieldHotspot:render(x, y, rot)
	if self.field ~= nil and self.name ~= "" then
		local shadowOffsetX = 1 / g_screenWidth
		local shadowOffsetY = -1 / g_screenHeight
		local r, g, b, a = unpack(self.color)
		local alpha = 1

		if self.isBlinking then
			alpha = IngameMap.alpha
		end

		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextWrapWidth(0)
		setTextColor(0, 0, 0, alpha)
		renderText(x + shadowOffsetX, y + shadowOffsetY, self.textSize * self.scale, self.name)
		setTextColor(r, g, b, a * alpha)
		renderText(x, y, self.textSize * self.scale, self.name)
	end
end
