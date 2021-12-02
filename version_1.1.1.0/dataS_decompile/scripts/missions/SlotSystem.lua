SlotSystem = {
	TOTAL_VRAM_MEGABYTES = {
		[PlatformId.WIN] = math.huge,
		[PlatformId.MAC] = math.huge,
		[PlatformId.PS4] = 2749,
		[PlatformId.PS5] = 5155,
		[PlatformId.XBOX_ONE] = 2749,
		[PlatformId.XBOX_SERIES] = 5155,
		[PlatformId.IOS] = 2598,
		[PlatformId.ANDROID] = 2598,
		[PlatformId.SWITCH] = 2598,
		[PlatformId.GGP] = 2598
	},
	VRAM_MEGABYTES_PER_SLOT = 1048576,
	VISIBILITY_THRESHOLD = 10000,
	CRITICAL_FACTOR = 0.9,
	TOTAL_NUM_GARAGE_SLOTS = {}
}

for platformId, vram in pairs(SlotSystem.TOTAL_VRAM_MEGABYTES) do
	vram = vram * 1024 * 1024
	SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId] = math.floor(vram / SlotSystem.VRAM_MEGABYTES_PER_SLOT)
end

local SlotSystem_mt = Class(SlotSystem)

function SlotSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or SlotSystem_mt)
	self.mission = mission
	self.slotUsage = 0
	self.slotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]

	return self
end

function SlotSystem:delete()
end

function SlotSystem:loadMapData(xmlFile, missionInfo)
	self:updateSlotLimit()

	return true
end

function SlotSystem:saveToXMLFile(xmlFile, key)
	setXMLInt(xmlFile, key .. "#slotUsage", self.slotUsage)
end

function SlotSystem:getIsCountableObject(object)
	return object:isa(Vehicle) or object:isa(Placeable)
end

function SlotSystem:updateSlotUsage()
	local mapVRAMUsage = self.mission.vertexBufferMemoryUsage + self.mission.indexBufferMemoryUsage + self.mission.textureMemoryUsage
	self.slotUsage = mapVRAMUsage / SlotSystem.VRAM_MEGABYTES_PER_SLOT

	for storeItem, item in pairs(self.mission.ownedItems) do
		if item.numItems > 0 and not storeItem.ignoreVramUsage then
			local baseSlots = self:getStoreItemSlotUsage(storeItem, true)
			local sharedSlots = self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
			self.slotUsage = self.slotUsage + baseSlots + sharedSlots
		end
	end

	for storeItem, item in pairs(self.mission.leasedVehicles) do
		if item.numItems > 0 and not storeItem.ignoreVramUsage then
			self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(storeItem, true) + self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
		end
	end

	self.mission.shopMenu:onSlotUsageChanged(self.slotUsage, self.slotLimit)
end

function SlotSystem:updateSlotLimit()
	local slots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]

	for _, user in ipairs(self.mission.userManager:getUsers()) do
		local userSlotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[user:getPlatformId()]

		if userSlotLimit ~= nil then
			slots = math.min(slots, userSlotLimit)
		end
	end

	self:setSlotLimit(slots)
end

function SlotSystem:setSlotLimit(slotLimit)
	self.mission.shopMenu:onSlotUsageChanged(self.slotUsage, slotLimit)

	if slotLimit ~= self.slotLimit then
		local text = g_i18n:getText("ingameNotification_crossPlaySlotLimitInactive")
		local notificationType = FSBaseMission.INGAME_NOTIFICATION_OK

		if slotLimit < math.huge then
			text = string.format(g_i18n:getText("ingameNotification_crossPlayNewSlotLimit"), slotLimit)
			notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
		end

		self.mission:addIngameNotification(notificationType, text)

		self.slotLimit = slotLimit

		if g_server ~= nil then
			g_server:broadcastEvent(SlotSystemUpdateEvent.new(slotLimit))
		end

		return true
	end

	return false
end

function SlotSystem:hasEnoughSlots(storeItem)
	if storeItem.ignoreVramUsage then
		return true
	end

	local slotUsage = self:getStoreItemSlotUsage(storeItem, self.mission:getNumOfItems(storeItem) == 0)

	return self.slotLimit >= self.slotUsage + slotUsage
end

function SlotSystem:getAreSlotsVisible()
	if self.slotLimit < SlotSystem.VISIBILITY_THRESHOLD then
		return true
	end

	if self.slotUsage >= self.slotLimit * SlotSystem.CRITICAL_FACTOR then
		return true
	end

	return false
end

function SlotSystem:getStoreItemSlotUsage(storeItem, includeShared)
	if storeItem == nil or StoreItemUtil.getIsAnimal(storeItem) or StoreItemUtil.getIsObject(storeItem) then
		return 0
	end

	local vramUsage = nil

	if includeShared then
		vramUsage = storeItem.perInstanceVramUsage + storeItem.sharedVramUsage
	else
		vramUsage = math.max(storeItem.perInstanceVramUsage, storeItem.sharedVramUsage * 0.05)
	end

	return math.max(math.ceil(vramUsage / SlotSystem.VRAM_MEGABYTES_PER_SLOT), 1)
end

function SlotSystem:getCanConnect(uniqueUserId, platformId)
	local platformSlots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId]

	return platformSlots == nil or self.slotUsage < platformSlots
end
