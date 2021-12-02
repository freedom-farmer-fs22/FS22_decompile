PlaceableCartridgePlayer = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableCartridgePlayer.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "cartridgePlayerTriggerCallback", PlaceableCartridgePlayer.cartridgePlayerTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "activatePlayer", PlaceableCartridgePlayer.activatePlayer)
end

function PlaceableCartridgePlayer.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableCartridgePlayer)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableCartridgePlayer)
end

function PlaceableCartridgePlayer.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("CartridgePlayer")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#itemsNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorLightNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#connectorNode", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#triggerNode", "")
	schema:setXMLSpecializationType()
end

function PlaceableCartridgePlayer:onLoad(savegame)
	local spec = self.spec_cartridgePlayer
	local baseKey = "placeable.cartridgePlayer"
	spec.itemsNode = self.xmlFile:getValue(baseKey .. "#itemsNode", nil, self.components, self.i3dMappings)
	spec.monitorNode = self.xmlFile:getValue(baseKey .. "#monitorNode", nil, self.components, self.i3dMappings)
	spec.monitorLightNode = self.xmlFile:getValue(baseKey .. "#monitorLightNode", nil, self.components, self.i3dMappings)
	spec.connectorNode = self.xmlFile:getValue(baseKey .. "#connectorNode", nil, self.components, self.i3dMappings)
	spec.triggerNode = self.xmlFile:getValue(baseKey .. "#triggerNode", nil, self.components, self.i3dMappings)

	if spec.triggerNode ~= nil then
		if not CollisionFlag.getHasFlagSet(spec.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
			Logging.error("Missing collision mask bit '%d'. Please add this bit to computer trigger node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER), I3DUtil.getNodePath(spec.triggerNode))

			return nil
		else
			addTrigger(spec.triggerNode, "cartridgePlayerTriggerCallback", self)
		end

		spec.activatable = PlaceableCartridgePlayerActivatable.new(self)
	end

	spec.currentItem = 0

	return self
end

function PlaceableCartridgePlayer:onDelete()
	local spec = self.spec_cartridgePlayer

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode)
	end
end

function PlaceableCartridgePlayer:cartridgePlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		local spec = self.spec_cartridgePlayer

		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
		end
	end
end

function PlaceableCartridgePlayer:activatePlayer()
	local spec = self.spec_cartridgePlayer

	if spec.currentItem ~= 0 then
		link(getChildAt(spec.itemsNode, spec.currentItem - 1), getChildAt(spec.connectorNode, 0))
		setVisibility(spec.monitorLightNode, false)
		setVisibility(getChildAt(spec.monitorNode, spec.currentItem - 1), false)
	end

	local firstVisibleIndex = 0
	local nextVisibleIndex = 0

	for i = 1, getNumOfChildren(spec.itemsNode) do
		local isVisible = getVisibility(getChildAt(spec.itemsNode, i - 1))

		if isVisible then
			if firstVisibleIndex == 0 then
				firstVisibleIndex = i
			end

			if nextVisibleIndex == 0 and spec.currentItem < i then
				nextVisibleIndex = i
			end
		end
	end

	if nextVisibleIndex ~= 0 then
		spec.currentItem = nextVisibleIndex
	elseif firstVisibleIndex ~= 0 then
		spec.currentItem = firstVisibleIndex
	elseif spec.currentItem == 0 then
		g_currentMission.hud:showInGameMessage(g_i18n:getText("ui_gameComputer"), g_i18n:getText("ui_gameComputerNoCartridges"), -1)
	else
		spec.currentItem = 0
	end

	if spec.currentItem ~= 0 then
		link(spec.connectorNode, getChildAt(getChildAt(spec.itemsNode, spec.currentItem - 1), 0))
		setVisibility(spec.monitorLightNode, true)
		setVisibility(getChildAt(spec.monitorNode, spec.currentItem - 1), true)
	end
end

PlaceableCartridgePlayerActivatable = {}
local PlaceableCartridgePlayerActivatable_mt = Class(PlaceableCartridgePlayerActivatable)

function PlaceableCartridgePlayerActivatable.new(placeable)
	local self = setmetatable({}, PlaceableCartridgePlayerActivatable_mt)
	self.placeable = placeable
	self.activateText = g_i18n:getText("action_gameComputerChangeCartridge")

	return self
end

function PlaceableCartridgePlayerActivatable:run()
	self.placeable:activatePlayer()
end
