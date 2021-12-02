Collectible = {}
local Collectible_mt = Class(Collectible)

function Collectible:onCreate(node)
	g_currentMission:addNonUpdateable(Collectible.new(node))
end

function Collectible.new(node)
	local self = setmetatable({}, Collectible_mt)
	self.node = node
	self.name = getUserAttribute(node, "name")

	if self.name == nil then
		Logging.error("Collectible has no 'name' defined")

		return nil
	end

	local triggerIndex = getUserAttribute(node, "triggerIndex")

	if triggerIndex ~= nil then
		self.triggerNode = getChildAt(node, triggerIndex)

		if self.triggerNode == 0 then
			Logging.error("Collectible has wrong 'triggerIndex' defined, node does not exist.")

			return nil
		end
	else
		self.triggerNode = node
	end

	if not CollisionFlag.getHasFlagSet(self.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
		Logging.warning("Missing collision mask bit '%d'. Please add this bit to collectible trigger node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER), I3DUtil.getNodePath(self.triggerNode))
	end

	self.activatable = CollectibleActivatable.new(self)
	self.isActive = false

	g_currentMission.collectiblesSystem:addCollectible(self)

	return self
end

function Collectible:delete()
	self:deactivate()
	g_currentMission.collectiblesSystem:removeCollectible(self)
end

function Collectible:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode and g_currentMission.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function Collectible:activate()
	if not self.isActive then
		setVisibility(self.node, true)
		addTrigger(self.triggerNode, "triggerCallback", self)

		self.isActive = true
	end
end

function Collectible:deactivate()
	if self.isActive then
		setVisibility(self.node, false)
		removeTrigger(self.triggerNode)
		delete(self.node)
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

		self.isActive = false
	end
end

CollectibleActivatable = {}
local CollectibleActivatable_mt = Class(CollectibleActivatable)

function CollectibleActivatable.new(collectible)
	local self = setmetatable({}, CollectibleActivatable_mt)
	self.collectible = collectible
	self.activateText = g_i18n:getText("action_collectibleCollect")

	return self
end

function CollectibleActivatable:run()
	if g_currentMission.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		g_currentMission.collectiblesSystem:onTriggerCollectible(self.collectible)
	end
end
