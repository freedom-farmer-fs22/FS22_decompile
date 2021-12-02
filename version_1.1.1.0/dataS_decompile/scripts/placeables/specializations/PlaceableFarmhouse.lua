PlaceableFarmhouse = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableFarmhouse.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "farmhouseSleepingTriggerCallback", PlaceableFarmhouse.farmhouseSleepingTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "getSleepCamera", PlaceableFarmhouse.getSleepCamera)
	SpecializationUtil.registerFunction(placeableType, "getSpawnWorldPosition", PlaceableFarmhouse.getSpawnWorldPosition)
	SpecializationUtil.registerFunction(placeableType, "getSpawnPoint", PlaceableFarmhouse.getSpawnPoint)
end

function PlaceableFarmhouse.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableFarmhouse.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableFarmhouse.canBuy)
end

function PlaceableFarmhouse.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFarmhouse)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFarmhouse)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFarmhouse)
end

function PlaceableFarmhouse.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Farmhouse")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse#spawnNode", "Player spawn node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#triggerNode", "Sleeping trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#cameraNode", "Camera while sleeping")
	schema:setXMLSpecializationType()
end

function PlaceableFarmhouse:onLoad(savegame)
	local spec = self.spec_farmhouse
	spec.activatable = PlaceableFarmhouseActivatable.new(self)
	spec.spawnNode = self.xmlFile:getValue("placeable.farmhouse#spawnNode", nil, self.components, self.i3dMappings)

	if spec.spawnNode == nil then
		Logging.xmlError(self.xmlFile, "No spawn node defined for farmhouse")

		spec.spawnNode = self.rootNode
	end

	local sleepingTriggerKey = "placeable.farmhouse.sleeping#triggerNode"
	spec.sleepingTrigger = self.xmlFile:getValue(sleepingTriggerKey, nil, self.components, self.i3dMappings)

	if spec.sleepingTrigger ~= nil then
		if not CollisionFlag.getHasFlagSet(spec.sleepingTrigger, CollisionFlag.TRIGGER_PLAYER) then
			Logging.warning("%s sleep trigger '%s' does not have 'TRIGGER_PLAYER' bit (%s) set", self.configFileName, sleepingTriggerKey, CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER))
		end

		addTrigger(spec.sleepingTrigger, "farmhouseSleepingTriggerCallback", self)
	end

	local cameraKey = "placeable.farmhouse.sleeping#cameraNode"
	local camera = self.xmlFile:getValue(cameraKey, nil, self.components, self.i3dMappings)

	if camera then
		if getHasClassId(camera, ClassIds.CAMERA) then
			spec.sleepingCamera = camera
		else
			Logging.xmlError(self.xmlFile, "Sleeping camera node '%s' (%s) is not a camera!", getName(camera), cameraKey)
		end
	end
end

function PlaceableFarmhouse:onFinalizePlacement()
	g_currentMission.placeableSystem:addFarmhouse(self)
end

function PlaceableFarmhouse:onDelete()
	local spec = self.spec_farmhouse

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
	g_currentMission.placeableSystem:removeFarmhouse(self)

	if spec.sleepingTrigger ~= nil then
		removeTrigger(spec.sleepingTrigger)
	end
end

function PlaceableFarmhouse:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if g_farmManager:getFarmById(g_currentMission.player.farmId):getFarmhouse() ~= nil then
		return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
	end

	return superFunc(self, x, y, z, farmId)
end

function PlaceableFarmhouse:canBuy(superFunc)
	if g_farmManager:getFarmById(g_currentMission.player.farmId):getFarmhouse() ~= nil then
		return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
	end

	return superFunc(self)
end

function PlaceableFarmhouse:getSpawnPoint()
	return self.spec_farmhouse.spawnNode
end

function PlaceableFarmhouse:getSpawnWorldPosition()
	return getWorldTranslation(self.spec_farmhouse.spawnNode)
end

function PlaceableFarmhouse:getSleepCamera()
	return self.spec_farmhouse.sleepingCamera
end

function PlaceableFarmhouse:farmhouseSleepingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.player:onEnterFarmhouse()
		end

		if self:getOwnerFarmId() == g_currentMission.player.farmId then
			local spec = self.spec_farmhouse

			if onEnter then
				g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
			else
				g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
			end
		end
	end
end

PlaceableFarmhouseActivatable = {}
local PlaceableFarmhouseActivatable_mt = Class(PlaceableFarmhouseActivatable)

function PlaceableFarmhouseActivatable.new(placeable)
	local self = setmetatable({}, PlaceableFarmhouseActivatable_mt)
	self.placeable = placeable
	self.activateText = g_i18n:getText("ui_inGameSleep")

	return self
end

function PlaceableFarmhouseActivatable:getIsActivatable()
	return g_currentMission:getFarmId() == self.placeable:getOwnerFarmId() and not g_sleepManager.isSleeping
end

function PlaceableFarmhouseActivatable:run()
	g_sleepManager:showDialog()
end
