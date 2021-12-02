AnimalHusbandryNoMorePalletSpaceEvent = {}
local AnimalHusbandryNoMorePalletSpaceEvent_mt = Class(AnimalHusbandryNoMorePalletSpaceEvent, Event)

InitStaticEventClass(AnimalHusbandryNoMorePalletSpaceEvent, "AnimalHusbandryNoMorePalletSpaceEvent", EventIds.EVENT_ANIMAL_HUSBANDRY_NO_MORE_PALLET_SPACE)

function AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
	local self = Event.new(AnimalHusbandryNoMorePalletSpaceEvent_mt)

	return self
end

function AnimalHusbandryNoMorePalletSpaceEvent.new(animalHusbandry)
	local self = AnimalHusbandryNoMorePalletSpaceEvent.emptyNew()
	self.animalHusbandry = animalHusbandry

	return self
end

function AnimalHusbandryNoMorePalletSpaceEvent:readStream(streamId, connection)
	self.animalHusbandry = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function AnimalHusbandryNoMorePalletSpaceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.animalHusbandry)
end

function AnimalHusbandryNoMorePalletSpaceEvent:run(connection)
	if connection:getIsServer() and self.animalHusbandry ~= nil then
		self.animalHusbandry:showPalletBlockedWarning()
	end
end
