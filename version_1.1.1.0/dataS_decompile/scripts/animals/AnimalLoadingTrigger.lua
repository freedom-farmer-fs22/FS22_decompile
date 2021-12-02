AnimalLoadingTrigger = {}
local AnimalLoadingTrigger_mt = Class(AnimalLoadingTrigger)

InitStaticObjectClass(AnimalLoadingTrigger, "AnimalLoadingTrigger", ObjectIds.OBJECT_ANIMAL_LOADING_TRIGGER)

function AnimalLoadingTrigger:onCreate(id)
	local trigger = AnimalLoadingTrigger.new(g_server ~= nil, g_client ~= nil)

	if trigger ~= nil then
		if trigger:load(id) then
			g_currentMission:addNonUpdateable(trigger)
		else
			trigger:delete()
		end
	end
end

function AnimalLoadingTrigger.new(isServer, isClient)
	local self = Object.new(isServer, isClient, AnimalLoadingTrigger_mt)
	self.customEnvironment = g_currentMission.loadingMapModName
	self.isDealer = false
	self.triggerNode = nil
	self.title = g_i18n:getText("ui_farm")
	self.animals = nil
	self.activatable = AnimalLoadingTriggerActivatable.new(self)
	self.isPlayerInRange = false
	self.isEnabled = false
	self.loadingVehicle = nil
	self.activatedTarget = nil

	return self
end

function AnimalLoadingTrigger:load(node, husbandry)
	self.husbandry = husbandry
	self.isDealer = Utils.getNoNil(getUserAttribute(node, "isDealer"), false)

	if self.isDealer then
		local animalTypesString = getUserAttribute(node, "animalTypes")

		if animalTypesString ~= nil then
			local animalTypes = animalTypesString:split(" ")

			for _, animalTypeStr in pairs(animalTypes) do
				local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(animalTypeStr)

				if animalTypeIndex ~= nil then
					if self.animalTypes == nil then
						self.animalTypes = {}
					end

					table.insert(self.animalTypes, animalTypeIndex)
				else
					Logging.warning("Invalid animal type '%s' for animalLoadingTrigger '%s'!", animalTypeStr, getName(node))
				end
			end
		end
	end

	self.triggerNode = node

	addTrigger(self.triggerNode, "triggerCallback", self)

	self.title = g_i18n:getText(Utils.getNoNil(getUserAttribute(node, "title"), "ui_farm"), self.customEnvironment)
	self.isEnabled = not g_isPresentationVersion or g_isPresentationVersionShopEnabled

	return true
end

function AnimalLoadingTrigger:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)

		self.triggerNode = nil
	end

	self.husbandry = nil
end

function AnimalLoadingTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local vehicle = g_currentMission.nodeToObject[otherId]

		if vehicle ~= nil and vehicle.getSupportsAnimalType ~= nil then
			if onEnter then
				self:setLoadingTrailer(vehicle)
			elseif onLeave then
				if vehicle == self.loadingVehicle then
					self:setLoadingTrailer(nil)
				end

				if vehicle == self.activatedTarget then
					g_animalScreen:onVehicleLeftTrigger()
				end
			end

			if GS_IS_MOBILE_VERSION and onEnter and self.activatable:getIsActivatable() then
				self:openAnimalMenu()

				local rootVehicle = vehicle.rootVehicle

				if rootVehicle.brakeToStop ~= nil then
					rootVehicle:brakeToStop()
				end
			end
		elseif g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.isPlayerInRange = true

				if GS_IS_MOBILE_VERSION then
					self:openAnimalMenu()
				end
			else
				self.isPlayerInRange = false
			end

			self:updateActivatableObject()
		end
	end
end

function AnimalLoadingTrigger:updateActivatableObject()
	if self.loadingVehicle ~= nil or self.isPlayerInRange then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	elseif self.loadingVehicle == nil and not self.isPlayerInRange then
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

function AnimalLoadingTrigger:setLoadingTrailer(loadingVehicle)
	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(nil)
	end

	self.loadingVehicle = loadingVehicle

	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(self)
	end

	self:updateActivatableObject()
end

function AnimalLoadingTrigger:showAnimalScreen(husbandry)
	if husbandry == nil and self.loadingVehicle == nil then
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageNoHusbandries")
		})

		return
	end

	local controller = nil

	if husbandry ~= nil and self.loadingVehicle == nil then
		controller = AnimalScreenDealerFarm.new(husbandry)
	elseif husbandry == nil and self.loadingVehicle ~= nil then
		controller = AnimalScreenDealerTrailer.new(self.loadingVehicle)
	else
		controller = AnimalScreenTrailerFarm.new(husbandry, self.loadingVehicle)
	end

	if controller ~= nil then
		controller:init()
		g_animalScreen:setController(controller)
		g_gui:showGui("AnimalScreen")
	end
end

function AnimalLoadingTrigger:onSelectedHusbandry(husbandry)
	if husbandry ~= nil then
		self:showAnimalScreen(husbandry)
	else
		self:updateActivatableObject()
	end
end

function AnimalLoadingTrigger:getAnimals()
	return self.animalTypes
end

function AnimalLoadingTrigger:openAnimalMenu()
	local husbandry = self.husbandry

	if self.isDealer and self.loadingVehicle == nil then
		local husbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm()

		if #husbandries > 1 then
			g_gui:showAnimalDialog({
				title = g_i18n:getText("category_animalpens"),
				husbandries = husbandries,
				callback = self.onSelectedHusbandry,
				target = self
			})

			return
		elseif #husbandries == 1 then
			husbandry = husbandries[1]
		end
	end

	self:showAnimalScreen(husbandry)

	self.activatedTarget = self.loadingVehicle
end

AnimalLoadingTriggerActivatable = {}
local AnimalLoadingTriggerActivatable_mt = Class(AnimalLoadingTriggerActivatable)

function AnimalLoadingTriggerActivatable.new(animalLoadingTrigger)
	local self = setmetatable({}, AnimalLoadingTriggerActivatable_mt)
	self.owner = animalLoadingTrigger
	self.activateText = g_i18n:getText("animals_openAnimalScreen", animalLoadingTrigger.customEnvironment)

	return self
end

function AnimalLoadingTriggerActivatable:getIsActivatable()
	local owner = self.owner

	if not owner.isEnabled then
		return false
	end

	if g_gui.currentGui ~= nil then
		return false
	end

	if not g_currentMission:getHasPlayerPermission("tradeAnimals") then
		return false
	end

	local canAccess = owner.husbandry == nil or owner.husbandry:getOwnerFarmId() == g_currentMission:getFarmId()

	if not canAccess then
		return false
	end

	local rootAttacherVehicle = nil

	if owner.loadingVehicle ~= nil then
		rootAttacherVehicle = owner.loadingVehicle.rootVehicle
	end

	return owner.isPlayerInRange or rootAttacherVehicle == g_currentMission.controlledVehicle
end

function AnimalLoadingTriggerActivatable:run()
	self.owner:openAnimalMenu()
end

function AnimalLoadingTriggerActivatable:getDistance(x, y, z)
	if self.owner.triggerNode ~= nil then
		local tx, ty, tz = getWorldTranslation(self.owner.triggerNode)

		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	end

	return math.huge
end
