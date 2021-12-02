AchievementsScreen = {
	CONTROLS = {
		ACHIEVEMENT_LIST = "achievementList",
		STATS_VALUE = "statsValue"
	}
}
local AchievementsScreen_mt = Class(AchievementsScreen, ScreenElement)

function AchievementsScreen.new(target, custom_mt, achievementManager)
	local self = ScreenElement.new(target, custom_mt or AchievementsScreen_mt)

	self:registerControls(AchievementsScreen.CONTROLS)

	self.achievementManager = achievementManager
	self.achievements = {}
	self.needAchievementSync = false
	self.returnScreenName = "MainScreen"

	return self
end

function AchievementsScreen:onOpen()
	AchievementsScreen:superClass().onOpen(self)

	if self:checkAchievementSynchronization() then
		self:getAchievements()
	else
		self:assignAchievementsStatsValue(false)
		self.achievementList:reloadData()
	end
end

function AchievementsScreen:getAchievements()
	self.achievements = self.achievementManager.achievementList

	self:assignAchievementsStatsValue(true)
	self.achievementList:reloadData()
end

function AchievementsScreen:assignAchievementsStatsValue(achievementsAvailable)
	local numUnlocked = achievementsAvailable and self.achievementManager.numberOfUnlockedAchievements or 0

	self.statsValue:setText(string.format(g_i18n:getText("ui_achievementStatsValue"), numUnlocked, self.achievementManager.numberOfAchievements), true)
	self.statsValue.parent:invalidateLayout()
end

function AchievementsScreen:onCancelAchievementsSync()
	self.needAchievementSync = false

	self:changeScreen(MainScreen)
end

function AchievementsScreen:checkAchievementSynchronization()
	local achievementsAvailable = areAchievementsAvailable()

	if not achievementsAvailable and not self.needAchievementSync then
		self.needAchievementSync = true

		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_achievementsSynchronizing"),
			dialogType = DialogElement.TYPE_LOADING,
			callback = self.onCancelAchievementsSync,
			target = self,
			okText = g_i18n:getText("button_cancel"),
			buttonAction = InputAction.MENU_BACK
		})
	elseif achievementsAvailable and self.needAchievementSync then
		self.needAchievementSync = false

		self:getAchievements()
		g_gui:closeAllDialogs()
	end

	return achievementsAvailable
end

function AchievementsScreen:update(dt)
	AchievementsScreen:superClass().update(self, dt)
	self:checkAchievementSynchronization()
end

function AchievementsScreen:onCareerClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.careerButton)
	g_mainScreen:onCareerClick(element)
end

function AchievementsScreen:onCreditsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.creditsButton)
	g_mainScreen:onCreditsClick(element)
end

function AchievementsScreen:getNumberOfItemsInSection(list, section)
	return #self.achievements
end

function AchievementsScreen:populateCellForItemInSection(list, section, index, cell)
	local achievement = self.achievements[index]

	cell:setDisabled(not achievement.unlocked)
	cell:getAttribute("title"):setText(achievement.name)
	cell:getAttribute("description"):setText(achievement.description)

	local icon = cell:getAttribute("icon")

	if achievement.unlocked then
		cell:applyProfile("achievementItem")
		icon:setImageFilename(achievement.imageFilename)

		local v0, u0, v1, u1, v2, u2, v3, u3 = unpack(achievement.imageUVs)

		icon:setImageUVs(nil, v0, u0, v1, u1, v2, u2, v3, u3)
	else
		cell:applyProfile("achievementItemLocked")
		icon:applyProfile("achievementItemIcon")
	end
end

function AchievementsScreen:onListSelectionChanged(list, section, index)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
