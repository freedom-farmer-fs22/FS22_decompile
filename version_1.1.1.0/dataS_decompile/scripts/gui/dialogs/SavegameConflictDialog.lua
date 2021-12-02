SavegameConflictDialog = {}
local SavegameConflictDialog_mt = Class(SavegameConflictDialog, MessageDialog)
SavegameConflictDialog.CONTROLS = {
	CLOUD_TIME_PLAYED = "cloud_timePlayed",
	LOCAL_TIME_PLAYED = "local_timePlayed",
	LOCAL_CREATE_DATE = "local_createDate",
	CLOUD_DIFFICULTY = "cloud_difficulty",
	KEEP_BOTH = "keepBoth",
	LOCAL_GAME_NAME = "local_gameName",
	CLOUD_CREATE_DATE = "cloud_createDate",
	CLOUD_GAME_NAME = "cloud_gameName",
	LOCAL_MONEY = "local_money",
	CLOUD_MONEY = "cloud_money",
	LOCAL_DIFFICULTY = "local_difficulty",
	CLOUD_MAP_NAME = "cloud_mapName",
	LOCAL_MAP_NAME = "local_mapName"
}

function SavegameConflictDialog.new(target, custom_mt, l10n, savegameController)
	if custom_mt == nil then
		custom_mt = SavegameConflictDialog_mt
	end

	local self = ColorPickerDialog.new(target, custom_mt)
	self.l10n = l10n
	self.savegameController = savegameController
	self.savegameId = 1

	self:registerControls(SavegameConflictDialog.CONTROLS)

	return self
end

function SavegameConflictDialog:setFinishedCallback(startCallback, savegameScreenCallback)
	self.startCallback = startCallback
	self.savegameScreenCallback = savegameScreenCallback
end

function SavegameConflictDialog:setLocalSavegame(metadata)
	local savegame = self:getSavegameFromMetadata(metadata)

	self:setSavegame(true, savegame)
end

function SavegameConflictDialog:setCloudSavegame(metadata)
	local savegame = self:getSavegameFromMetadata(metadata)

	self:setSavegame(false, savegame)
end

function SavegameConflictDialog:getSavegameFromMetadata(metadata)
	local savegame = FSCareerMissionInfo.new("", nil, 1)

	savegame:loadDefaults()

	if metadata ~= "" then
		local xmlFile = loadXMLFileFromMemory("careerSavegameXML", metadata)

		if xmlFile ~= nil then
			if not savegame:loadFromXML(xmlFile) then
				savegame:loadDefaults()
			end

			delete(xmlFile)
		end
	end

	return savegame
end

function SavegameConflictDialog:setSavegame(isLocal, savegame)
	if savegame ~= nil then
		local playTimeHoursF = savegame.playTime / 60 + 0.0001
		local playTimeHours = math.floor(playTimeHoursF)
		local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
		local timePlayed = string.format("%02d:%02d", playTimeHours, playTimeMinutes)
		local difficulty = g_i18n:getText("ui_difficulty" .. savegame.difficulty)

		if isLocal then
			self.local_gameName:setText(savegame.savegameName)
			self.local_money:setText(savegame.money)
			self.local_difficulty:setText(difficulty)
			self.local_timePlayed:setText(timePlayed)
			self.local_createDate:setText(savegame.saveDateFormatted)
		else
			self.cloud_gameName:setText(savegame.savegameName)
			self.cloud_money:setText(savegame.money)
			self.cloud_difficulty:setText(difficulty)
			self.cloud_timePlayed:setText(timePlayed)
			self.cloud_createDate:setText(savegame.saveDateFormatted)
		end
	end
end

function SavegameConflictDialog:setSavegameId(savegameId)
	self.savegameId = savegameId
end

function SavegameConflictDialog:setShowKeepBoth(showKeepBoth)
	self.keepBoth:setDisabled(showKeepBoth ~= nil and not showKeepBoth)
end

function SavegameConflictDialog:onClickKeepLocal()
	self.savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_LOCAL)
	self:close()

	if self.startCallback ~= nil then
		self.startCallback.callback(self.startCallback.target, unpack(self.startCallback.extraAttributes))
	end
end

function SavegameConflictDialog:onClickKeepRemote()
	self.savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
	self:close()

	if self.startCallback ~= nil then
		self.startCallback.callback(self.startCallback.target, unpack(self.startCallback.extraAttributes))
	end
end

function SavegameConflictDialog:onClickKeepBoth()
	self:close()

	if self.savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_BOTH) and self.savegameScreenCallback ~= nil then
		self.savegameScreenCallback.callback(self.savegameScreenCallback.target, unpack(self.savegameScreenCallback.extraAttributes))
	end
end

SavegameConflictDialog.L10N_SYMBOL = {
	TITLE_EDIT_FARM_TEMPLATE = "ui_editFarm",
	TITLE_CREATE_FARM = "ui_createNewFarm",
	BUTTON_CONFIRM = "button_confirm",
	BUTTON_CREATE = "button_mp_createFarm",
	DEFAULT_FARM_NAME = "ui_defaultFarmName"
}
