LoanTrigger = {}
local LoanTrigger_mt = Class(LoanTrigger)

function LoanTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(LoanTrigger.new(id))
end

function LoanTrigger.new(name)
	local self = {}

	setmetatable(self, LoanTrigger_mt)

	if g_currentMission:getIsClient() then
		self.triggerId = name

		addTrigger(name, "triggerCallback", self)
	end

	self.loanSymbol = getChildAt(name, 0)
	self.activatable = LoanTriggerActivatable.new(self)
	self.isEnabled = true

	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	self:updateIconVisibility()

	return self
end

function LoanTrigger:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end

	self.loanSymbol = nil

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

function LoanTrigger:openFinanceMenu()
	g_gui:showGui("InGameMenu")
	g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_FINANCES_SCREEN)
end

function LoanTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function LoanTrigger:updateIconVisibility()
	if self.loanSymbol ~= nil then
		local hideMission = g_isPresentationVersion and not g_isPresentationVersionShopEnabled or not g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		local farmId = g_currentMission:getFarmId()
		local visibleForFarm = farmId ~= FarmManager.SPECTATOR_FARM_ID

		setVisibility(self.loanSymbol, not hideMission and visibleForFarm)
	end
end

function LoanTrigger:playerFarmChanged(player)
	if player == g_currentMission.player then
		self:updateIconVisibility()
	end
end

LoanTriggerActivatable = {}
local LoanTriggerActivatable_mt = Class(LoanTriggerActivatable)

function LoanTriggerActivatable.new(loanTrigger)
	local self = setmetatable({}, LoanTriggerActivatable_mt)
	self.loanTrigger = loanTrigger
	self.activateText = g_i18n:getText("action_checkFinances")

	return self
end

function LoanTriggerActivatable:getIsActivatable()
	return self.loanTrigger.isEnabled and g_currentMission.controlPlayer and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end

function LoanTriggerActivatable:run()
	self.loanTrigger:openFinanceMenu()
end
