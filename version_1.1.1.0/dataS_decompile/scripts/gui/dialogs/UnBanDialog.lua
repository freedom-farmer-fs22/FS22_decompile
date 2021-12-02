UnBanDialog = {}
local UnBanDialog_mt = Class(UnBanDialog, DialogElement)
UnBanDialog.CONTROLS = {
	"dialogElement",
	"dialogTitleElement",
	"banList",
	"buttonLayout",
	"backButton",
	"unblockButton",
	"noBansText",
	"loadingText"
}

local function NO_CALLBACK()
end

function UnBanDialog.new(target, custom_mt, l10n)
	local self = DialogElement.new(target, custom_mt or UnBanDialog_mt)

	self:registerControls(UnBanDialog.CONTROLS)

	self.l10n = l10n
	self.blockedPlayers = {}
	self.callbackFunc = NO_CALLBACK
	self.target = nil

	return self
end

function UnBanDialog:updateButtons()
	self.unblockButton:setVisible(#self.blockedPlayers > 0)
	self.buttonLayout:invalidateLayout()
end

function UnBanDialog:setUseLocalList(useLocal)
	self.useLocal = useLocal

	self:reloadData()
end

function UnBanDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc or NO_CALLBACK
	self.target = target
end

function UnBanDialog:closeAndCallback()
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target)
			else
				self.callbackFunc()
			end
		end
	end
end

function UnBanDialog:onCreate()
	self.banList:setDataSource(self)
end

function UnBanDialog:onOpen()
	UnBanDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250

	self:updateButtons()
end

function UnBanDialog:onClose()
	UnBanDialog:superClass().onClose(self)
	g_messageCenter:unsubscribeAll(self)
end

function UnBanDialog:onClickBack(_, _)
	self:closeAndCallback()

	return false
end

function UnBanDialog:onClickUnblock()
	if #self.blockedPlayers > 0 then
		local ban = self.blockedPlayers[self.banList.selectedIndex]

		if ban.isLocal then
			setIsUserBlocked(ban.uniqueUserId, ban.platformUserId, ban.platformId, false, "")
			self:reloadData()
		else
			g_client:getServerConnection():sendEvent(UnbanEvent.new(ban.uniqueUserId))
			g_client:getServerConnection():sendEvent(GetBansEvent.new())
			self.loadingText:setVisible(true)
		end
	end

	self:updateButtons()
end

function UnBanDialog:onServerBansUpdated(bans)
	log("BANS")
	print_r(bans)

	self.blockedPlayers = bans

	self.loadingText:setVisible(false)
	self.noBansText:setVisible(#self.blockedPlayers == 0)
	self.banList:reloadData()
	self:updateButtons()
end

function UnBanDialog:reloadData()
	self.blockedPlayers = {}

	log("RELOAD", self.useLocal)

	if self.useLocal or g_currentMission ~= nil and g_currentMission:getIsServer() then
		for i = 0, getNumOfBlockedUsers() - 1 do
			local uniqueUserId, platformUserId, platformId, displayName = getBlockedUser(i)

			table.insert(self.blockedPlayers, {
				isLocal = true,
				uniqueUserId = uniqueUserId,
				platformUserId = platformUserId,
				platformId = platformId,
				displayName = displayName
			})
		end

		self.noBansText:setVisible(#self.blockedPlayers == 0)
		self.loadingText:setVisible(false)
		self.banList:reloadData()
		self:updateButtons()
	else
		g_messageCenter:subscribe(GetBansEvent, self.onServerBansUpdated, self)
		g_client:getServerConnection():sendEvent(GetBansEvent.new())
		self.loadingText:setVisible(true)
		self.noBansText:setVisible(false)
		self:updateButtons()
	end
end

function UnBanDialog:getNumberOfItemsInSection(list, section)
	return #self.blockedPlayers
end

function UnBanDialog:populateCellForItemInSection(list, section, index, cell)
	local ban = self.blockedPlayers[index]

	cell:getAttribute("name"):setText(ban.displayName)
end
