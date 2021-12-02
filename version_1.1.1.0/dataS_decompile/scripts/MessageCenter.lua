MessageCenter = {}
local MessageCenter_mt = Class(MessageCenter)

function MessageCenter.new(customMt)
	local self = setmetatable({}, MessageCenter_mt)
	self.subscribers = {}
	self.queue = {}

	return self
end

function MessageCenter:delete()
end

function MessageCenter:update(dt)
	if #self.queue > 0 then
		for _, message in ipairs(self.queue) do
			self:publish(message[1], unpack(message[2]))
		end

		self.queue = {}
	end
end

function MessageCenter:subscribe(messageType, callback, callbackTarget, argument, isOneShot)
	if messageType == nil then
		Logging.warning("Tried subscribing to a message with a nil-value message type. Check subscribe() function call arguments at:")
		printCallstack()

		return
	end

	if callback == nil then
		Logging.warning("Tried subscribing to a message with a nil-value callback. Check subscribe() function call arguments at:")
		printCallstack()

		return
	end

	assertWithCallstack(type(callback) == "function", "Error: MessageCenter:subscribe(): given argument 'callback' is not a function")

	local subscribers = self.subscribers[messageType]

	if subscribers == nil then
		subscribers = {}
		self.subscribers[messageType] = subscribers
	end

	table.insert(subscribers, {
		callback = callback,
		callbackTarget = callbackTarget,
		argument = argument,
		isOneShot = Utils.getNoNil(isOneShot, false)
	})
end

function MessageCenter:subscribeOneshot(messageType, callback, callbackTarget, argument)
	self:subscribe(messageType, callback, callbackTarget, argument, true)
end

function MessageCenter:unsubscribe(messageType, callbackTarget)
	local subscribers = self.subscribers[messageType]

	if subscribers ~= nil then
		for i = #subscribers, 1, -1 do
			local info = subscribers[i]

			if info.callbackTarget == callbackTarget then
				table.remove(subscribers, i)
			end
		end

		if #subscribers == 0 then
			self.subscribers[messageType] = nil
		end
	end
end

function MessageCenter:unsubscribeAll(callbackTarget)
	for k, subscribers in pairs(self.subscribers) do
		for i = #subscribers, 1, -1 do
			local info = subscribers[i]

			if info.callbackTarget == callbackTarget then
				table.remove(subscribers, i)
			end
		end

		if #subscribers == 0 then
			self.subscribers[k] = nil
		end
	end
end

function MessageCenter:publish(messageType, ...)
	if messageType == nil then
		Logging.warning("Warning: Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()

		return
	end

	local subscribers = self.subscribers[messageType]

	if subscribers ~= nil then
		local i = 1

		while true do
			local info = subscribers[i]

			if info == nil then
				break
			end

			if info.callbackTarget == nil then
				if info.argument == nil then
					info.callback(...)
				else
					info.callback(info.argument, ...)
				end
			elseif info.argument == nil then
				info.callback(info.callbackTarget, ...)
			else
				info.callback(info.callbackTarget, info.argument, ...)
			end

			if info.isOneShot then
				table.remove(subscribers, i)
			else
				i = i + 1
			end
		end
	end
end

function MessageCenter:publishDelayed(messageType, ...)
	if messageType == nil then
		Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()

		return
	end

	table.insert(self.queue, {
		messageType,
		{
			...
		}
	})
end

function MessageCenter:consoleCommandShowActiveSubscribers()
	local messageCount = 0
	local subscriberCount = 0

	for messageType, subscribers in pairs(self.subscribers) do
		local messageName = nil

		if type(messageType) == "number" then
			for k, v in pairs(MessageType) do
				if v == messageType then
					messageName = k

					break
				end
			end

			if messageName == nil then
				for k, v in pairs(MessageType.SETTING_CHANGED) do
					if v == messageType then
						for name, setting in pairs(GameSettings.SETTING) do
							if k == setting then
								messageName = name

								break
							end
						end

						break
					end
				end
			end
		else
			messageName = ClassUtil.getClassName(messageType)
		end

		if messageName == nil then
			messageName = type(messageType) .. " " .. tostring(messageType)
		end

		log("Message Subscribers for '" .. messageName .. "':")

		for _, subscriber in ipairs(subscribers) do
			local target = subscriber.callbackTarget

			if target ~= nil then
				target = ClassUtil.getClassNameByObject(target)
			end

			log("    ", target or "Unknown")

			subscriberCount = subscriberCount + 1
		end

		messageCount = messageCount + 1
	end

	log("\nTotal Messages: " .. messageCount)
	log("\nTotal Subscribers: " .. subscriberCount)
end

local messageTypeId = 0

function nextMessageTypeId()
	messageTypeId = messageTypeId + 1

	return messageTypeId
end

MessageType = {
	MONEY_CHANGED = nextMessageTypeId(),
	PLAYER_FARM_CHANGED = nextMessageTypeId(),
	FARM_CREATED = nextMessageTypeId(),
	FARM_PROPERTY_CHANGED = nextMessageTypeId(),
	FARM_DELETED = nextMessageTypeId(),
	PLAYER_CREATED = nextMessageTypeId(),
	PLAYER_NICKNAME_CHANGED = nextMessageTypeId(),
	OWN_PLAYER_ENTERED = nextMessageTypeId(),
	OWN_PLAYER_LEFT = nextMessageTypeId(),
	ACHIEVEMENT_UNLOCKED = nextMessageTypeId(),
	HUSBANDRY_ANIMALS_CHANGED = nextMessageTypeId(),
	VEHICLE_REPAIRED = nextMessageTypeId(),
	VEHICLE_REPAINTED = nextMessageTypeId(),
	VEHICLE_RESET = nextMessageTypeId(),
	VEHICLE_SALES_CHANGED = nextMessageTypeId(),
	STORE_ITEMS_RELOADED = nextMessageTypeId(),
	GUI_BEFORE_OPEN = nextMessageTypeId(),
	GUI_AFTER_OPEN = nextMessageTypeId(),
	GUI_BEFORE_CLOSE = nextMessageTypeId(),
	GUI_AFTER_CLOSE = nextMessageTypeId(),
	GUI_INGAME_OPEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_FINANCES_SCREEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_FARMS_SCREEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_PRODUCTION_SCREEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_AI_SCREEN = nextMessageTypeId(),
	GUI_CAREER_SCREEN_OPEN = nextMessageTypeId(),
	GUI_MAIN_SCREEN_OPEN = nextMessageTypeId(),
	GUI_CHARACTER_CREATION_SCREEN_OPEN = nextMessageTypeId(),
	GUI_DIALOG_OPENED = nextMessageTypeId(),
	SAVEGAMES_LOADED = nextMessageTypeId(),
	GAME_STATE_CHANGED = nextMessageTypeId(),
	SETTING_CHANGED = {}
}

for _, setting in pairs(GameSettings.SETTING) do
	MessageType.SETTING_CHANGED[setting] = nextMessageTypeId()
end

MessageType.INPUT_BINDINGS_CHANGED = nextMessageTypeId()
MessageType.INPUT_MODE_CHANGED = nextMessageTypeId()
MessageType.INPUT_HELP_MODE_CHANGED = nextMessageTypeId()
MessageType.INPUT_DEVICES_CHANGED = nextMessageTypeId()
MessageType.TIMESCALE_CHANGED = nextMessageTypeId()
MessageType.SAVEGAME_LOADED = nextMessageTypeId()
MessageType.MISSION_GENERATED = nextMessageTypeId()
MessageType.MISSION_DELETED = nextMessageTypeId()
MessageType.MISSION_TOUR_STARTED = nextMessageTypeId()
MessageType.MISSION_TOUR_FINISHED = nextMessageTypeId()
MessageType.USER_PROFILE_CHANGED = nextMessageTypeId()
MessageType.USER_ADDED = nextMessageTypeId()
MessageType.USER_REMOVED = nextMessageTypeId()
MessageType.MASTERUSER_ADDED = nextMessageTypeId()
MessageType.PLAYER_STYLE_CHANGED = nextMessageTypeId()
MessageType.MINUTE_CHANGED = nextMessageTypeId()
MessageType.HOUR_CHANGED = nextMessageTypeId()
MessageType.DAY_CHANGED = nextMessageTypeId()
MessageType.REALHOUR_CHANGED = nextMessageTypeId()
MessageType.PERIOD_CHANGED = nextMessageTypeId()
MessageType.PERIOD_LENGTH_CHANGED = nextMessageTypeId()
MessageType.SEASON_CHANGED = nextMessageTypeId()
MessageType.YEAR_CHANGED = nextMessageTypeId()
MessageType.DAYLIGHT_CHANGED = nextMessageTypeId()
MessageType.WEATHER_CHANGED = nextMessageTypeId()
MessageType.UNLOADING_STATIONS_CHANGED = nextMessageTypeId()
MessageType.AI_VEHICLE_STATE_CHANGE = nextMessageTypeId()
MessageType.RADIO_CHANNEL_CHANGE = nextMessageTypeId()
MessageType.APP_SUSPENDED = nextMessageTypeId()
MessageType.APP_RESUMED = nextMessageTypeId()
MessageType.STORAGE_ADDED_TO_UNLOADING_STATION = nextMessageTypeId()
MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION = nextMessageTypeId()
MessageType.STORAGE_ADDED_TO_LOADING_STATION = nextMessageTypeId()
MessageType.STORAGE_REMOVED_FROM_LOADING_STATION = nextMessageTypeId()
MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE = nextMessageTypeId()
MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE = nextMessageTypeId()
MessageType.LOADED_ALL_SAVEGAME_VEHICLES = nextMessageTypeId()
MessageType.LOADED_ALL_SAVEGAME_PLACEABLES = nextMessageTypeId()
MessageType.FINISHED_GROWTH_PERIOD = nextMessageTypeId()
MessageType.AI_JOB_STARTED = nextMessageTypeId()
MessageType.AI_JOB_REMOVED = nextMessageTypeId()
MessageType.AI_JOB_STOPPED = nextMessageTypeId()
MessageType.TREE_SHAPE_CUT = nextMessageTypeId()
