InfoHUDBox = {}
local InfoHUDBox_mt = Class(InfoHUDBox)

function InfoHUDBox.new(classMt, uiScale)
	local self = setmetatable({}, classMt or InfoHUDBox_mt)
	self.uiScale = uiScale

	self:setScale(uiScale)

	return self
end

function InfoHUDBox:delete()
end

function InfoHUDBox:canDraw()
	return true
end

function InfoHUDBox:getDisplayHeight()
	return 0
end

function InfoHUDBox:draw(posX, posY)
end

function InfoHUDBox:setScale(uiScale)
end

function InfoHUDBox:storeScaledValues()
end
