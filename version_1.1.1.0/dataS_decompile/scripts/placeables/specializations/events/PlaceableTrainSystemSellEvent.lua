PlaceableTrainSystemSellEvent = {}
local PlaceableTrainSystemSellEvent_mt = Class(PlaceableTrainSystemSellEvent, Event)

InitStaticEventClass(PlaceableTrainSystemSellEvent, "PlaceableTrainSystemSellEvent", EventIds.EVENT_SELL_TRAIN_GOODS)

function PlaceableTrainSystemSellEvent.emptyNew()
	return Event.new(PlaceableTrainSystemSellEvent_mt)
end

function PlaceableTrainSystemSellEvent.new(object, isBlocked)
	local self = PlaceableTrainSystemSellEvent.emptyNew()
	self.object = object

	return self
end

function PlaceableTrainSystemSellEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function PlaceableTrainSystemSellEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function PlaceableTrainSystemSellEvent:run(connection)
	if not connection:getIsServer() and self.object ~= nil and self.object:getIsSynchronized() then
		self.object:sellGoods()
	end
end
