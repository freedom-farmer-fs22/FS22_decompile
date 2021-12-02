InGameIcon = {}
local InGameIcon_mt = Class(InGameIcon)

function InGameIcon.new()
	local instance = {}

	setmetatable(instance, InGameIcon_mt)

	instance.width, instance.height = getNormalizedScreenValues(50, 50)
	instance.posX, instance.posY = getNormalizedScreenValues(25, 360)
	instance.textPosX = instance.posX + instance.width * 0.6
	instance.textPosY = instance.posY + 0.005
	instance.fadeTime = 1000
	instance.visibleTime = 2000
	instance.visible = false
	instance.time = 0
	instance.alpha = 0
	instance.fileName = "dataS/menu/blank.png"
	instance.text = "+1"
	instance.iconOverlay = Overlay.new(instance.fileName, instance.posX, instance.posY, instance.width, instance.height)

	return instance
end

function InGameIcon:delete()
	self.iconOverlay:delete()
end

function InGameIcon:setIcon(fileName)
	self.iconOverlay:delete()

	self.fileName = fileName
	self.iconOverlay = Overlay.new(self.fileName, self.posX, self.posY, self.width, self.height)
end

function InGameIcon:setText(text)
	self.text = text
end

function InGameIcon:mouseEvent(posX, posY, isDown, isUp, button)
	if self.visible and isDown and button == 1 and self.time <= self.fadeTime + self.visibleTime then
		self:hideIcon()
	end
end

function InGameIcon:update(dt)
	if self.visible then
		self.time = self.time + dt
		self.alpha = math.min(1, self.time / self.fadeTime)

		if self.time > self.fadeTime + self.visibleTime then
			self.alpha = math.max(0, (self.fadeTime - (self.time - self.fadeTime - self.visibleTime)) / self.fadeTime)
		end

		if self.time > self.fadeTime * 2 + self.visibleTime then
			self.time = 0
			self.visible = false
		end
	end
end

function InGameIcon:showIcon(duration)
	self.visibleTime = duration
	self.time = 0
	self.alpha = 0
	self.visible = true
end

function InGameIcon:hideIcon()
	self.time = self.fadeTime + self.visibleTime
end

function InGameIcon:setPosition(x, y)
	self.iconOverlay:setPosition(x, y)

	self.posX = Utils.getNoNil(x, self.posX)
	self.posY = Utils.getNoNil(y, self.posY)
	self.textPosX = self.posX + self.width * 0.6
	self.textPosY = self.posY + 0.005
end

function InGameIcon:draw()
	if self.visible then
		self.iconOverlay:setColor(1, 1, 1, self.alpha)
		self.iconOverlay:render()
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(0, 0, 0, self.alpha)
		renderText(self.textPosX, self.textPosY - 0.003, 0.025, self.text)
		setTextColor(1, 1, 1, self.alpha)
		renderText(self.textPosX, self.textPosY, 0.025, self.text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
	end
end
