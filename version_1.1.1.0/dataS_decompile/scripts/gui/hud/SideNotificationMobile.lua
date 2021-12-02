SideNotificationMobile = {}
local SideNotificationMobile_mt = Class(SideNotificationMobile, SideNotification)

function SideNotificationMobile.new(hudAtlasPath)
	return SideNotificationMobile:superClass().new(SideNotificationMobile_mt, hudAtlasPath)
end

function SideNotificationMobile:storeScaledValues()
	SideNotificationMobile:superClass().storeScaledValues(self)

	self.textSize = self:scalePixelToScreenHeight(SideNotificationMobile.TEXT_SIZE.DEFAULT_NOTIFICATION)
end

function SideNotificationMobile:createBackground(hudAtlasPath)
	local overlay = SideNotificationMobile:superClass().createBackground(self, hudAtlasPath)

	overlay:setUVs(GuiUtils.getUVs(SideNotificationMobile.UV.DEFAULT_BACKGROUND))
	overlay:setColor(unpack(SideNotificationMobile.COLOR.DEFAULT_BACKGROUND))

	return overlay
end

SideNotificationMobile.UV = {
	DEFAULT_BACKGROUND = {
		779,
		5.5,
		-70,
		0
	}
}
SideNotificationMobile.COLOR = {
	DEFAULT_BACKGROUND = {
		0,
		0,
		0,
		1
	}
}
SideNotificationMobile.TEXT_SIZE = {
	DEFAULT_NOTIFICATION = 31
}
