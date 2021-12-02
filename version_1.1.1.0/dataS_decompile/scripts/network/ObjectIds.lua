ObjectIds = {
	objectClasses = {},
	objectIdNext = 0,
	objectIdsUsed = {},
	objectIdToClass = {}
}

function InitObjectClass(classObject, className)
	if g_currentMission ~= nil then
		print("Error: Object initialization only allowed at compile time")
		printCallstack()

		return
	end

	if ObjectIds.objectClasses[className] ~= nil then
		print("Error: Same class name used multiple times " .. className)
		printCallstack()

		return
	end

	classObject.className = className
	ObjectIds.objectClasses[className] = classObject
end

function InitStaticObjectClass(classObject, className, id)
	if g_server ~= nil or g_client ~= nil then
		print("Error: Object initialization only allowed at compile time")
		printCallstack()

		return
	end

	classObject.className = className

	ObjectIds.assignObjectClassObjectId(classObject, className, id)
end

function ObjectIds.getObjectClassByName(className)
	return ObjectIds.objectClasses[className]
end

function ObjectIds.getObjectClassById(id)
	return ObjectIds.objectIdToClass[id]
end

function ObjectIds.assignObjectClassIds()
	for className, classObject in pairs(ObjectIds.objectClasses) do
		ObjectIds.assignObjectClassObjectId(classObject, className, ObjectIds.objectIdNext)
	end
end

function ObjectIds.assignObjectClassId(className, id)
	local classObject = ObjectIds.objectClasses[className]

	if classObject ~= nil then
		ObjectIds.assignObjectClassObjectId(classObject, className, id)
	end
end

function ObjectIds.assignObjectClassObjectId(classObject, className, id)
	if id == nil then
		print("Error: Invalid object id, it is nil")
		printCallstack()

		return
	end

	if ObjectIds.MAX_OBJECT_ID < id then
		print("Error: Invalid object id, maximum is " .. ObjectIds.MAX_OBJECT_ID)
		printCallstack()

		return
	end

	if rawget(classObject, "classId") == nil then
		if ObjectIds.objectIdsUsed[id] ~= nil then
			print("Error: Same object id used multiple times " .. id)
			printCallstack()

			return
		end

		ObjectIds.objectIdsUsed[id] = true
		ObjectIds.objectIdNext = math.max(ObjectIds.objectIdNext, id) + 1
		classObject.classId = id
		ObjectIds.objectIdToClass[id] = classObject
	end
end

local objectId = 0

local function nextObjectId()
	objectId = objectId + 1

	return objectId
end

ObjectIds.OBJECT_PLAYER = nextObjectId()
ObjectIds.OBJECT_VEHICLE = nextObjectId()
ObjectIds.OBJECT_OBJECT = nextObjectId()
ObjectIds.OBJECT_PHYSICS_OBJECT = nextObjectId()
ObjectIds.OBJECT_MOUNTABLE_OBJECT = nextObjectId()
ObjectIds.OBJECT_BALE = nextObjectId()
ObjectIds.OBJECT_INLINE_BALE = nextObjectId()
ObjectIds.OBJECT_INLINE_BALE_SINGLE = nextObjectId()
ObjectIds.OBJECT_PACKED_BALE = nextObjectId()
ObjectIds.OBJECT_MISSION_PHYSICS_OBJECT = nextObjectId()
ObjectIds.OBJECT_ANIMAL_LOADING_TRIGGER = nextObjectId()
ObjectIds.OBJECT_DOG = nextObjectId()
ObjectIds.OBJECT_BALE_UNLOAD_TRIGGER = nextObjectId()
ObjectIds.OBJECT_WOOD_UNLOAD_TRIGGER = nextObjectId()
ObjectIds.OBJECT_UNLOAD_TRIGGER = nextObjectId()
ObjectIds.OBJECT_LOAD_TRIGGER = nextObjectId()
ObjectIds.OBJECT_UNLOADING_STATION = nextObjectId()
ObjectIds.OBJECT_PRODUCTION_POINT = nextObjectId()
ObjectIds.OBJECT_SELLING_STATION = nextObjectId()
ObjectIds.OBJECT_SIMPLE_BGA_SELLING_STATION = nextObjectId()
ObjectIds.OBJECT_BGA_SELLING_STATION = nextObjectId()
ObjectIds.OBJECT_BUYING_STATION = nextObjectId()
ObjectIds.OBJECT_LOADING_STATION = nextObjectId()
ObjectIds.OBJECT_FILLLEVEL_LISTENER = nextObjectId()
ObjectIds.OBJECT_ANIMAL_HUSBANDRY_FEEDING_ROBOT = nextObjectId()
ObjectIds.OBJECT_ANIMAL_LIGHT_WILDLIFE = nextObjectId()
ObjectIds.OBJECT_ANIMAL_CROWS_WILDLIFE = nextObjectId()
ObjectIds.OBJECT_BUNKER_SILO = nextObjectId()
ObjectIds.OBJECT_RAILROADVEHICLE = nextObjectId()
ObjectIds.OBJECT_BGA = nextObjectId()
ObjectIds.OBJECT_PLACEABLE = nextObjectId()
ObjectIds.OBJECT_ANIMATED_OBJECT = nextObjectId()
ObjectIds.OBJECT_ANIMATED_MAP_OBJECT = nextObjectId()
ObjectIds.OBJECT_HANDTOOL = nextObjectId()
ObjectIds.OBJECT_CHAINSAW = nextObjectId()
ObjectIds.OBJECT_HIGHPRESSUREWASHERLANCE = nextObjectId()
ObjectIds.OBJECT_BASKETBALL = nextObjectId()
ObjectIds.OBJECT_DOGBALL = nextObjectId()
ObjectIds.OBJECT_STORAGE = nextObjectId()
ObjectIds.OBJECT_MANURE_HEAP = nextObjectId()
ObjectIds.FARM = nextObjectId()
ObjectIds.MISSION = nextObjectId()
ObjectIds.MISSION_FIELD = nextObjectId()
ObjectIds.MISSION_BALE = nextObjectId()
ObjectIds.MISSION_CULTIVATE = nextObjectId()
ObjectIds.MISSION_FERTILIZE = nextObjectId()
ObjectIds.MISSION_HARVEST = nextObjectId()
ObjectIds.MISSION_PLOW = nextObjectId()
ObjectIds.MISSION_SOW = nextObjectId()
ObjectIds.MISSION_SPRAY = nextObjectId()
ObjectIds.MISSION_TRANSPORT = nextObjectId()
ObjectIds.MISSION_WEED = nextObjectId()
ObjectIds.TRAFFIC_SYSTEM = nextObjectId()
ObjectIds.SEND_NUM_BITS = 16
ObjectIds.MAX_OBJECT_ID = 2^ObjectIds.SEND_NUM_BITS - 1
