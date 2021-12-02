PlaceableWardrobe = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableWardrobe.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "wardrobeTriggerCallback", PlaceableWardrobe.wardrobeTriggerCallback)
end

function PlaceableWardrobe.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWardrobe)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWardrobe)
end

function PlaceableWardrobe.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Wardrobe")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wardrobe#triggerNode", "Wardrobe trigger node for player")
	schema:register(XMLValueType.BOOL, basePath .. ".wardrobe#allowAllFarms", "Allow any farm not just the owner to access the wardrobe", "false if owned by a specific farm, true otherwise")
	schema:setXMLSpecializationType()
end

function PlaceableWardrobe:onLoad(savegame)
	local spec = self.spec_wardrobe
	spec.activatable = PlaceableWardrobeActivatable.new(self)
	local wardrobeTriggerKey = "placeable.wardrobe#triggerNode"
	spec.wardrobeTrigger = self.xmlFile:getValue(wardrobeTriggerKey, nil, self.components, self.i3dMappings)

	if spec.wardrobeTrigger ~= nil then
		if not CollisionFlag.getHasFlagSet(spec.wardrobeTrigger, CollisionFlag.TRIGGER_PLAYER) then
			Logging.warning("%s wardrobe trigger '%s' does not have 'TRIGGER_PLAYER' bit (%s) set", self.configFileName, wardrobeTriggerKey, CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER))
		end

		addTrigger(spec.wardrobeTrigger, "wardrobeTriggerCallback", self)
	end

	spec.allowAllFarms = self.xmlFile:getValue("placeable.wardrobe#allowAllFarms", self:getOwnerFarmId() == AccessHandler.EVERYONE)
end

function PlaceableWardrobe:onDelete()
	local spec = self.spec_wardrobe

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

	if spec.wardrobeTrigger ~= nil then
		removeTrigger(spec.wardrobeTrigger)
	end
end

function PlaceableWardrobe:wardrobeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		local spec = self.spec_wardrobe

		if spec.allowAllFarms or self:getOwnerFarmId() == g_currentMission.player.farmId then
			if onEnter then
				g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
			else
				g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
			end
		end
	end
end

PlaceableWardrobeActivatable = {}
local PlaceableWardrobeActivatable_mt = Class(PlaceableWardrobeActivatable)

function PlaceableWardrobeActivatable.new(placeable)
	local self = setmetatable({}, PlaceableWardrobeActivatable_mt)
	self.placeable = placeable
	self.activateText = g_i18n:getText("action_openWardrobe")

	return self
end

function PlaceableWardrobeActivatable:getIsActivatable()
	return self.placeable.spec_wardrobe.allowAllFarms or g_currentMission:getFarmId() == self.placeable:getOwnerFarmId()
end

function PlaceableWardrobeActivatable:run()
	if not g_isPresentationVersion or g_isPresentationVersionWardrobeEnabled then
		g_currentMission:onToggleCharacterCreation()
	else
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_featureDisabled")
		})
	end
end
