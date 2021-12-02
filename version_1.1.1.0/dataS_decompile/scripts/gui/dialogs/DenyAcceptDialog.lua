DenyAcceptDialog = {
	CONTROLS = {
		"platformIcon",
		"dialogWarning"
	}
}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog, YesNoDialog)

function DenyAcceptDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or DenyAcceptDialog_mt)

	self:registerControls(DenyAcceptDialog.CONTROLS)

	return self
end

function DenyAcceptDialog:sendCallback(isDenied, isAlwaysDenied)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, self.connection, isDenied, isAlwaysDenied)
			else
				self.callbackFunc(self.connection, isDenied, isAlwaysDenied)
			end
		end
	end
end

function DenyAcceptDialog:onClickAccept()
	self:sendCallback(false, false)

	return false
end

function DenyAcceptDialog:onClickBack(forceBack)
	self:onClickRefuse()
end

function DenyAcceptDialog:onClickRefuse(forceBack)
	self:sendCallback(true, false)

	return false
end

function DenyAcceptDialog:onClickDenyAlways()
	self:sendCallback(true, true)

	return false
end

function DenyAcceptDialog:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
	if connection ~= nil then
		self.connection = connection
	end

	self:setTitle(nickname)
	self.platformIcon:setPlatformId(platformId)
	self.platformIcon.parent:invalidateLayout()
	self.dialogWarning:setVisible(not splitShapesWithinLimits)
end
