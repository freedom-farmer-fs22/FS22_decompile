ShopTrigger = {}
local ShopTrigger_mt = Class(ShopTrigger)

function ShopTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(ShopTrigger.new(id))
end

function ShopTrigger.new(node)
	local self = {}

	setmetatable(self, ShopTrigger_mt)

	if g_currentMission:getIsClient() then
		self.triggerId = node

		if not CollisionFlag.getHasFlagSet(node, CollisionFlag.TRIGGER_PLAYER) then
			Logging.warning("Missing collision mask bit '%d'. Please add this bit to shop trigger node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER), I3DUtil.getNodePath(node))
		end

		addTrigger(node, "triggerCallback", self)
	end

	self.shopSymbol = getChildAt(node, 0)
	self.shopPlayerSpawn = getChildAt(node, 1)
	self.isEnabled = true

	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	self:updateIconVisibility()

	self.activatable = ShopTriggerActivatable.new(self)

	return self
end

function ShopTrigger:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end

	self.shopSymbol = nil

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

function ShopTrigger:openShop()
	g_gui:changeScreen(nil, ShopMenu)

	local x, y, z = getWorldTranslation(self.shopPlayerSpawn)
	local dx, _, dz = localDirectionToWorld(self.shopPlayerSpawn, 0, 0, -1)

	g_currentMission.player:moveToAbsolute(x, y, z)

	g_currentMission.player.rotY = MathUtil.getYRotationFromDirection(dx, dz)
end

function ShopTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function ShopTrigger:updateIconVisibility()
	if self.shopSymbol ~= nil then
		local hideMission = g_isPresentationVersion and not g_isPresentationVersionShopEnabled or not g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		local farmId = g_currentMission:getFarmId()
		local visibleForFarm = farmId ~= FarmManager.SPECTATOR_FARM_ID

		setVisibility(self.shopSymbol, not hideMission and visibleForFarm)
	end
end

function ShopTrigger:playerFarmChanged(player)
	if player == g_currentMission.player then
		self:updateIconVisibility()
	end
end

ShopTriggerActivatable = {}
local ShopTriggerActivatable_mt = Class(ShopTriggerActivatable)

function ShopTriggerActivatable.new(shopTrigger)
	local self = setmetatable({}, ShopTriggerActivatable_mt)
	self.shopTrigger = shopTrigger
	self.activateText = g_i18n:getText("action_activateShop")

	return self
end

function ShopTriggerActivatable:getIsActivatable()
	return self.shopTrigger.isEnabled and g_currentMission.controlPlayer and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end

function ShopTriggerActivatable:run()
	self.shopTrigger:openShop()
end
