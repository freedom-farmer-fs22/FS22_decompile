VehicleSellingPoint = {}
local VehicleSellingPoint_mt = Class(VehicleSellingPoint)

function VehicleSellingPoint.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#playerTriggerNode", "Player trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#iconNode", "Icon node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#sellTriggerNode", "Sell trigger node")
	schema:register(XMLValueType.BOOL, basePath .. "#ownWorkshop", "Owned by player", false)
	schema:register(XMLValueType.BOOL, basePath .. "#mobileWorkshop", "Workshop is on vehicle", false)
end

function VehicleSellingPoint.new()
	local self = setmetatable({}, VehicleSellingPoint_mt)
	self.vehicleShapesInRange = {}
	self.activateText = ""
	self.isEnabled = true

	return self
end

function VehicleSellingPoint:load(components, xmlFile, key, i3dMappings)
	self.playerTrigger = xmlFile:getValue(key .. "#playerTriggerNode", nil, components, i3dMappings)
	self.sellIcon = xmlFile:getValue(key .. "#iconNode", nil, components, i3dMappings)
	self.sellTriggerNode = xmlFile:getValue(key .. "#sellTriggerNode", nil, components, i3dMappings)
	self.ownWorkshop = xmlFile:getValue(key .. "#ownWorkshop", false)
	self.mobileWorkshop = xmlFile:getValue(key .. "#mobileWorkshop", false)

	if not CollisionFlag.getHasFlagSet(self.playerTrigger, CollisionFlag.TRIGGER_PLAYER) then
		Logging.xmlWarning(xmlFile, "Missing collision mask bit '%d'. Please add this bit to vehicle selling player trigger node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_PLAYER), I3DUtil.getNodePath(self.playerTrigger))
	end

	addTrigger(self.playerTrigger, "triggerCallback", self)

	if not CollisionFlag.getHasFlagSet(self.sellTriggerNode, CollisionFlag.TRIGGER_VEHICLE) then
		Logging.xmlWarning(xmlFile, "Missing collision mask bit '%d'. Please add this bit to vehicle sell area trigger node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_VEHICLE), I3DUtil.getNodePath(self.sellTriggerNode))
	end

	addTrigger(self.sellTriggerNode, "sellAreaTriggerCallback", self)

	self.activatable = VehicleSellingPointActivatable.new(self, self.ownWorkshop)

	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.playerFarmChanged, self)
	self:updateIconVisibility()
end

function VehicleSellingPoint:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.playerTrigger ~= nil then
		removeTrigger(self.playerTrigger)

		self.playerTrigger = nil
	end

	if self.sellTriggerNode ~= nil then
		removeTrigger(self.sellTriggerNode)

		self.sellTriggerNode = nil
	end

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

	self.sellIcon = nil
end

function VehicleSellingPoint:openMenu()
	local vehicles = self:determineCurrentVehicles()

	g_workshopScreen:setSellingPoint(self, not self.ownWorkshop, self.ownWorkshop, self.mobileWorkshop)
	g_workshopScreen:setVehicles(vehicles)
	g_gui:showGui("WorkshopScreen")
end

function VehicleSellingPoint:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
			self:determineCurrentVehicles()
		end
	end
end

function VehicleSellingPoint:sellAreaTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherShapeId ~= nil and (onEnter or onLeave) then
		if onEnter then
			self.vehicleShapesInRange[otherShapeId] = true
		elseif onLeave then
			self.vehicleShapesInRange[otherShapeId] = nil
		end
	end
end

function VehicleSellingPoint:determineCurrentVehicles()
	local vehicles = {}

	for shapeId, inRange in pairs(self.vehicleShapesInRange) do
		if inRange ~= nil and entityExists(shapeId) then
			local vehicle = g_currentMission.nodeToObject[shapeId]

			if vehicle ~= nil then
				local isPallet = vehicle.typeName == "pallet"
				local isRidable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)

				if not isRidable and not isPallet and vehicle.getSellPrice ~= nil and vehicle.price ~= nil then
					local items = vehicle.rootVehicle:getChildVehicles()

					for i = 1, #items do
						local item = items[i]

						if (self:getOwnerFarmId() == AccessHandler.EVERYONE or self:getOwnerFarmId() == item:getOwnerFarmId()) and g_currentMission.accessHandler:canPlayerAccess(item) then
							table.addElement(vehicles, item)
						end
					end
				end
			end
		else
			self.vehicleShapesInRange[shapeId] = nil
		end
	end

	table.sort(vehicles, function (a, b)
		return a.rootNode < b.rootNode
	end)

	return vehicles
end

function VehicleSellingPoint:updateIconVisibility()
	if self.sellIcon ~= nil then
		local hideMission = g_isPresentationVersion and not g_isPresentationVersionShopEnabled or not g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		local farmId = g_currentMission:getFarmId()
		local visibleForFarm = farmId ~= FarmManager.SPECTATOR_FARM_ID and (self:getOwnerFarmId() == AccessHandler.EVERYONE or farmId == self:getOwnerFarmId())

		setVisibility(self.sellIcon, not hideMission and visibleForFarm)
	end
end

function VehicleSellingPoint:playerFarmChanged(player)
	if player == g_currentMission.player then
		self:updateIconVisibility()
	end
end

function VehicleSellingPoint:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId

	self:updateIconVisibility()
end

function VehicleSellingPoint:getOwnerFarmId()
	return self.ownerFarmId
end

VehicleSellingPointActivatable = {}
local VehicleSellingPointActivatable_mt = Class(VehicleSellingPointActivatable)

function VehicleSellingPointActivatable.new(sellingPoint, ownWorkshop)
	local self = setmetatable({}, VehicleSellingPointActivatable_mt)
	self.sellingPoint = sellingPoint

	if ownWorkshop then
		self.activateText = g_i18n:getText("action_openWorkshopOptions")
	else
		self.activateText = g_i18n:getText("action_openDealerOptions")
	end

	return self
end

function VehicleSellingPointActivatable:getIsActivatable()
	if not self.sellingPoint.isEnabled then
		return false
	end

	if not g_currentMission.controlPlayer then
		return false
	end

	local farmId = g_currentMission:getFarmId()
	local isSpectator = farmId == FarmManager.SPECTATOR_FARM_ID

	if isSpectator then
		return false
	end

	return self.sellingPoint:getOwnerFarmId() == AccessHandler.EVERYONE or farmId == self.sellingPoint:getOwnerFarmId()
end

function VehicleSellingPointActivatable:run()
	self.sellingPoint:openMenu()
end

function VehicleSellingPointActivatable:getDistance(x, y, z)
	local tx, _, tz = getWorldTranslation(self.sellingPoint.playerTrigger)

	return MathUtil.getPointPointDistance(tx, tz, x, z)
end
