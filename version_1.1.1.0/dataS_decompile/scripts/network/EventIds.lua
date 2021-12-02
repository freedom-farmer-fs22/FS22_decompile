EventIds = {
	eventClasses = {},
	eventIdNext = 0,
	eventIdsUsed = {},
	eventIdToClass = {}
}

function InitEventClass(classObject, className)
	if g_currentMission ~= nil then
		print("Error: Event initialization only allowed at compile time")
		printCallstack()

		return
	end

	if EventIds.eventClasses[className] ~= nil then
		print("Error: Same class name used multiple times " .. className)
		printCallstack()

		return
	end

	EventIds.eventClasses[className] = classObject
end

function InitStaticEventClass(classObject, className, id)
	if g_server ~= nil or g_client ~= nil then
		print("Error: Event initialization only allowed at compile time")
		printCallstack()

		return
	end

	EventIds.assignEventObjectId(classObject, className, id)
end

function EventIds.getEventClassByName(className)
	return EventIds.eventClasses[className]
end

function EventIds.getEventClassById(id)
	return EventIds.eventIdToClass[id]
end

function EventIds.assignEventIds()
	for className, classObject in pairs(EventIds.eventClasses) do
		Logging.devInfo("(Server) Assign event id '%d' to class '%s'", EventIds.eventIdNext, className)
		EventIds.assignEventObjectId(classObject, className, EventIds.eventIdNext)
	end
end

function EventIds.assignEventId(className, id)
	local classObject = EventIds.eventClasses[className]

	if classObject ~= nil then
		EventIds.assignEventObjectId(classObject, className, id)
		Logging.devInfo("(Client) Assign event id '%d' to class '%s'", id, className)
	end
end

function EventIds.assignEventObjectId(classObject, className, id)
	if id == nil then
		print("Error: Invalid event id, it is nil")
		printCallstack()

		return
	end

	if EventIds.MAX_EVENT_ID < id then
		print("Error: Invalid object id, maximum is " .. EventIds.MAX_EVENT_ID)
		printCallstack()

		return
	end

	if rawget(classObject, "eventId") == nil then
		if EventIds.eventIdsUsed[id] ~= nil then
			print("Error: Same event id used multiple times " .. id)
			printCallstack()

			return
		end

		EventIds.eventIdsUsed[id] = true
		EventIds.eventIdNext = math.max(EventIds.eventIdNext, id + 1)
		classObject.eventId = id
		EventIds.eventIdToClass[id] = classObject
	end
end

local eventId = 0

local function nextEventId()
	eventId = eventId + 1

	return eventId
end

EventIds.EVENT_FINISHED_LOADING = nextEventId()
EventIds.EVENT_READY_EVENT = nextEventId()
EventIds.EVENT_CHAT = nextEventId()
EventIds.EVENT_CONNECTION_REQUEST_ANSWER = nextEventId()
EventIds.EVENT_CONNECTION_REQUEST = nextEventId()
EventIds.EVENT_SAVEGAME_SETTTINGS = nextEventId()
EventIds.EVENT_ENVIRONMENT_TIME = nextEventId()
EventIds.EVENT_WEATHER_ADD_OBJECT = nextEventId()
EventIds.EVENT_WEATHER_STATE = nextEventId()
EventIds.EVENT_FOG_STATE_EVENT = nextEventId()
EventIds.EVENT_PLAYER_TELEPORT = nextEventId()
EventIds.EVENT_PLAYER_SET_HANDTOOL = nextEventId()
EventIds.EVENT_PLAYER_SET_FARM = nextEventId()
EventIds.EVENT_PLAYER_SET_FARM_ANSWER = nextEventId()
EventIds.EVENT_PLAYER_SET_NICKNAME = nextEventId()
EventIds.EVENT_PLAYER_REQUEST_STYLE = nextEventId()
EventIds.EVENT_PLAYER_SET_STYLE = nextEventId()
EventIds.EVENT_PLAYER_PICKUP_OBJECT = nextEventId()
EventIds.EVENT_PLAYER_THROW_OBJECT = nextEventId()
EventIds.EVENT_PLAYER_TOGGLE_LIGHT = nextEventId()
EventIds.EVENT_PLAYER_SWITCHED_FARM = nextEventId()
EventIds.EVENT_SET_SPLIT_SHAPES = nextEventId()
EventIds.EVENT_UPDATE_SPLIT_SHAPES = nextEventId()
EventIds.EVENT_SHUTDOWN = nextEventId()
EventIds.EVENT_ON_CREATE_LOADED_OBJECT = nextEventId()
EventIds.EVENT_GAME_PAUSE = nextEventId()
EventIds.EVENT_GAME_PAUSE_REQUEST = nextEventId()
EventIds.EVENT_USER = nextEventId()
EventIds.EVENT_USER_DATA = nextEventId()
EventIds.EVENT_USER_BLOCK = nextEventId()
EventIds.EVENT_PLAYER_PERMISSIONS = nextEventId()
EventIds.EVENT_CLIENT_START_MISSION = nextEventId()
EventIds.EVENT_SLEEP_START = nextEventId()
EventIds.EVENT_SLEEP_STOP = nextEventId()
EventIds.EVENT_SLEEP_REQUEST = nextEventId()
EventIds.EVENT_SLEEP_RESPONSE = nextEventId()
EventIds.EVENT_SELL_WOOD = nextEventId()
EventIds.EVENT_SELL_TRAIN_GOODS = nextEventId()
EventIds.EVENT_VEHICLE_REMOVE = nextEventId()
EventIds.EVENT_VEHICLE_ENTER_REQUEST = nextEventId()
EventIds.EVENT_VEHICLE_ENTER_RESPONSE = nextEventId()
EventIds.EVENT_VEHICLE_LEAVE = nextEventId()
EventIds.EVENT_VEHICLE_BROKEN = nextEventId()
EventIds.EVENT_OBJECT_ASYNC_REQUEST = nextEventId()
EventIds.EVENT_OBJECT_ASYNC_STREAM = nextEventId()
EventIds.EVENT_OPEN_BALE = nextEventId()
EventIds.EVENT_OPEN_INLINE_BALE = nextEventId()
EventIds.EVENT_UNPACK_BALE = nextEventId()
EventIds.EVENT_SELL_VEHICLE = nextEventId()
EventIds.EVENT_BUY_VEHICLE = nextEventId()
EventIds.EVENT_PLACEABLE_NAME = nextEventId()
EventIds.EVENT_BUY_PLACEABLE = nextEventId()
EventIds.EVENT_BUY_EXISTING_PLACEABLE = nextEventId()
EventIds.EVENT_BUY_OBJECT = nextEventId()
EventIds.EVENT_BUY_HANDTOOL = nextEventId()
EventIds.EVENT_SELL_HANDTOOL = nextEventId()
EventIds.EVENT_SELL_PLACEABLE = nextEventId()
EventIds.EVENT_RESET_VEHICLE = nextEventId()
EventIds.EVENT_CHANGE_VEHICLE_CONFIG = nextEventId()
EventIds.EVENT_VEHICLE_SALE_ADD = nextEventId()
EventIds.EVENT_VEHICLE_SALE_REMOVE = nextEventId()
EventIds.EVENT_VEHICLE_SALE_SET = nextEventId()
EventIds.EVENT_VEHICLE_ATTACH = nextEventId()
EventIds.EVENT_VEHICLE_ATTACH_REQUEST = nextEventId()
EventIds.EVENT_VEHICLE_BUNDLE_ATTACH = nextEventId()
EventIds.EVENT_VEHICLE_DETACH = nextEventId()
EventIds.EVENT_VEHICLE_LOWER_IMPLEMENT = nextEventId()
EventIds.EVENT_VEHICLE_SET_BEACON_LIGHT = nextEventId()
EventIds.EVENT_VEHICLE_SET_TURNLIGHT = nextEventId()
EventIds.EVENT_VEHICLE_SET_LIGHT = nextEventId()
EventIds.EVENT_VEHICLE_SETTING_CHANGED = nextEventId()
EventIds.EVENT_VEHICLE_SET_IS_RECONFIGURATING = nextEventId()
EventIds.EVENT_CRUISECONTROL_SET_STATE = nextEventId()
EventIds.EVENT_CRUISECONTROL_SET_SPEED = nextEventId()
EventIds.EVENT_SET_MOTOR_TURNED_ON = nextEventId()
EventIds.EVENT_SET_FILLUNIT_IS_FILLING = nextEventId()
EventIds.EVENT_SET_FILLUNIT_CAPACITY = nextEventId()
EventIds.EVENT_ANIMATED_VEHICLE_START = nextEventId()
EventIds.EVENT_ANIMATED_VEHICLE_STOP = nextEventId()
EventIds.EVENT_FOLDABLE_SET_FOLD_DIRECTION = nextEventId()
EventIds.EVENT_SET_TURNED_ON = nextEventId()
EventIds.EVENT_SET_PICKUP_STATE = nextEventId()
EventIds.EVENT_TRAILER_TOGGLE_TIP_SIDE = nextEventId()
EventIds.EVENT_TRAILER_TOGGLE_MANUAL_TIP = nextEventId()
EventIds.EVENT_TRAILER_TOGGLE_MANUAL_DOOR = nextEventId()
EventIds.EVENT_HONK = nextEventId()
EventIds.EVENT_JUMP = nextEventId()
EventIds.EVENT_RECEIVINGHOPPER_SET_CREATE_BOXES = nextEventId()
EventIds.EVENT_TENSION_BELT = nextEventId()
EventIds.EVENT_TENSION_BELT_REFRESH = nextEventId()
EventIds.EVENT_FILLUNIT_UNLOAD = nextEventId()
EventIds.EVENT_VEHICLE_PLAYER_STYLE_CHANGED = nextEventId()
EventIds.EVENT_TRAIN_PLACEABLE_RENT = nextEventId()
EventIds.EVENT_TRAIN_LOCOMOTIVE_STATE = nextEventId()
EventIds.EVENT_SILO_REFILL = nextEventId()
EventIds.EVENT_AIVEHICLE_IS_BLOCKED = nextEventId()
EventIds.EVENT_AIVEHICLE_SET_CONVEYORBELT_ANGLE = nextEventId()
EventIds.EVENT_BALER_CREATE_BALE = nextEventId()
EventIds.EVENT_BALER_SET_BALE_TIME = nextEventId()
EventIds.EVENT_SET_PIPE_STATE = nextEventId()
EventIds.EVENT_SET_PIPE_DISCHARGE_TO_GROUND = nextEventId()
EventIds.EVENT_COMBINE_ENABLE_STRAW = nextEventId()
EventIds.EVENT_CYLINDERED_EASY_CONTROL_CHANGE = nextEventId()
EventIds.EVENT_SET_DISCHARGE_STATE = nextEventId()
EventIds.EVENT_INLINE_WRAPPER_PUSH_OFF = nextEventId()
EventIds.EVENT_PLOW_ROTATION = nextEventId()
EventIds.EVENT_PLOW_LIMIT_TO_FIELD = nextEventId()
EventIds.EVENT_PLOW_PACKER_STATE = nextEventId()
EventIds.EVENT_PLANT_LIMIT_TO_FIELD = nextEventId()
EventIds.EVENT_ANIMATED_OBJECT = nextEventId()
EventIds.EVENT_BALE_LOADER_STATE = nextEventId()
EventIds.EVENT_BALE_WRAPPER_STATE = nextEventId()
EventIds.EVENT_RIDGE_MARKER_SET_STATE = nextEventId()
EventIds.EVENT_MOWER_TOGGLE_WINDROW_DROP = nextEventId()
EventIds.EVENT_SET_COVER_STATE = nextEventId()
EventIds.EVENT_REVERSE_DRIVING_SET_STATE = nextEventId()
EventIds.EVENT_SET_WORK_MODE = nextEventId()
EventIds.EVENT_SPRAYER_DOUBLED_AMOUNT = nextEventId()
EventIds.EVENT_VARIABLE_WORK_WIDTH_STATE = nextEventId()
EventIds.EVENT_SET_CRABSTEERING = nextEventId()
EventIds.EVENT_BALER_SET_IS_UNLOADING_BALE = nextEventId()
EventIds.EVENT_WATER_TRAILER_SET_IS_FILLING = nextEventId()
EventIds.EVENT_SOWING_MACHINE_SET_SEED_INDEX = nextEventId()
EventIds.EVENT_TREE_PLANTER_LOAD_PALLET = nextEventId()
EventIds.EVENT_BUNKER_SILO_CLOSE = nextEventId()
EventIds.EVENT_BUNKER_SILO_OPEN = nextEventId()
EventIds.EVENT_PRODUCTION_CHANGED_OUTPUT_MODE = nextEventId()
EventIds.EVENT_PRODUCTION_CHANGED_STATE = nextEventId()
EventIds.EVENT_PRODUCTION_CHANGED_STATUS = nextEventId()
EventIds.EVENT_MIXERWAGON_BALE_NOT_ACCEPTED = nextEventId()
EventIds.EVENT_MOTOR_GEAR_SHIFT = nextEventId()
EventIds.EVENT_GREAT_DEMANDS = nextEventId()
EventIds.EVENT_CHANGE_LOAN = nextEventId()
EventIds.EVENT_FINANCE_STATS = nextEventId()
EventIds.EVENT_FARMLAND_STATE = nextEventId()
EventIds.EVENT_FARMLAND_INITIAL_STATE = nextEventId()
EventIds.EVENT_HIGHPRESSURE_WASHER_TURN_ON = nextEventId()
EventIds.EVENT_HIGHPRESSURE_WASHER_LANCE_STATE = nextEventId()
EventIds.EVENT_PLACEABLE_LIGHTS_STATE = nextEventId()
EventIds.EVENT_PLACEABLE_FENCE_SEGMENT_ADD = nextEventId()
EventIds.EVENT_PLACEABLE_FENCE_GATE_ADD = nextEventId()
EventIds.EVENT_PLACEABLE_FENCE_SEGMENT_REMOVE = nextEventId()
EventIds.EVENT_FEEDING_ROBOT_STATE = nextEventId()
EventIds.EVENT_ANIMAL_HUSBANDRY_NO_MORE_PALLET_SPACE = nextEventId()
EventIds.EVENT_ANIMAL_BUY = nextEventId()
EventIds.EVENT_ANIMAL_MOVE = nextEventId()
EventIds.EVENT_ANIMAL_SELL = nextEventId()
EventIds.EVENT_ANIMAL_UNLOAD = nextEventId()
EventIds.EVENT_ANIMAL_LOAD = nextEventId()
EventIds.EVENT_ANIMAL_CLUSTER_UPDATE = nextEventId()
EventIds.EVENT_RIDEABLE_STABLE_NOTIFICATION = nextEventId()
EventIds.EVENT_ANIMAL_RIDING = nextEventId()
EventIds.EVENT_ANIMAL_CLEAN = nextEventId()
EventIds.EVENT_ANIMAL_NAME = nextEventId()
EventIds.EVENT_DOGHOUSE_FOOD_BOWL_STATE = nextEventId()
EventIds.EVENT_DOG_PET = nextEventId()
EventIds.EVENT_DOG_FOLLOW = nextEventId()
EventIds.EVENT_DOG_FETCH_ITEM = nextEventId()
EventIds.EVENT_CHAINSAW_STATE = nextEventId()
EventIds.EVENT_CHAINSAW_CUT = nextEventId()
EventIds.EVENT_CHAINSAW_DELIMB = nextEventId()
EventIds.EVENT_WEARABLE_REPAIR = nextEventId()
EventIds.EVENT_WEARABLE_REPAINT = nextEventId()
EventIds.EVENT_WOODHARVESTER_CUT_TREE = nextEventId()
EventIds.EVENT_WOODHARVESTER_ON_CUT_TREE = nextEventId()
EventIds.EVENT_WOODHARVESTER_ON_DELIMB_TREE = nextEventId()
EventIds.EVENT_TREE_PLANT = nextEventId()
EventIds.EVENT_TREE_GROW = nextEventId()
EventIds.EVENT_LOADTRIGGER_SET_IS_LOADING = nextEventId()
EventIds.EVENT_MISSION_START = nextEventId()
EventIds.EVENT_MISSION_STARTED = nextEventId()
EventIds.EVENT_MISSION_CANCEL = nextEventId()
EventIds.EVENT_MISSION_FINISHED = nextEventId()
EventIds.EVENT_MISSION_DISMISS = nextEventId()
EventIds.EVENT_GET_ADMIN = nextEventId()
EventIds.EVENT_GET_ADMIN_ANSWER = nextEventId()
EventIds.EVENT_MISSION_INFO_DYNAMIC = nextEventId()
EventIds.EVENT_KICK_BAN = nextEventId()
EventIds.EVENT_KICK_BAN_NOTIFICATION = nextEventId()
EventIds.EVENT_SAVE = nextEventId()
EventIds.EVENT_CHEAT_MONEY = nextEventId()
EventIds.EVENT_OBJECT_OWNER_CHANGE = nextEventId()
EventIds.EVENT_FARM_CREATE_UPDATE = nextEventId()
EventIds.EVENT_FARM_DESTROY = nextEventId()
EventIds.EVENT_FARM_INITIAL_STATE = nextEventId()
EventIds.EVENT_TRANSFER_MONEY = nextEventId()
EventIds.EVENT_CONTRACTING_STATE = nextEventId()
EventIds.EVENT_REMOVE_PLAYER_FROM_FARM = nextEventId()
EventIds.EVENT_MONEY_CHANGE = nextEventId()
EventIds.EVENT_REQUEST_MONEY_CHANGE = nextEventId()
EventIds.EVENT_LANDSCAPING_SCULPT = nextEventId()
EventIds.EVENT_GET_BANS = nextEventId()
EventIds.EVENT_UNBAN = nextEventId()
EventIds.EVENT_COLLECTIBLE_TRIGGER = nextEventId()
EventIds.EVENT_COLLECTIBLE_STATE = nextEventId()
EventIds.EVENT_AI_JOB_START_REQUEST = nextEventId()
EventIds.EVENT_AI_JOB_START = nextEventId()
EventIds.EVENT_AI_JOB_STOP = nextEventId()
EventIds.EVENT_AI_JOB_SKIP_TASK = nextEventId()
EventIds.EVENT_AI_TASK_START = nextEventId()
EventIds.EVENT_AI_TASK_STOP = nextEventId()
EventIds.EVENT_AI_FIELDWORKER_STATE = nextEventId()
EventIds.EVENT_AI_JOBVEHICLE_STATE = nextEventId()
EventIds.EVENT_SLOT_SYSTEM_UPDATE = nextEventId()
EventIds.SEND_NUM_BITS = 16
EventIds.MAX_EVENT_ID = 2^EventIds.SEND_NUM_BITS - 1
