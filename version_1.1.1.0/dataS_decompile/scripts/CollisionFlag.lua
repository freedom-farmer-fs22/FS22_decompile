CollisionFlag = {}
local USED_BITS = {}
local DATA = {}
local DATA_MAPPING = {}
local FULL_MASK = 255
local ACTIVE_MASK = 0

local function registerFlag(bit, name, description, isActive)
	if USED_BITS[bit] ~= nil then
		Logging.error("CollisionFlag.registerFlag: Given bit '%d' is already in use.", bit)

		return nil
	end

	name = name:upper()

	if CollisionFlag[name] ~= nil then
		Logging.error("CollisionFlag.registerFlag: Given  name '%s' is already in use", name)

		return nil
	end

	local data = {
		name = name,
		description = description or "",
		bit = bit,
		flag = 2^bit,
		isActive = isActive or bit < 8,
		isDeprecated = not isActive
	}

	if data.isActive then
		ACTIVE_MASK = bitOR(ACTIVE_MASK, data.flag)
	end

	FULL_MASK = bitOR(FULL_MASK, data.flag)
	USED_BITS[bit] = true
	CollisionFlag[name] = data.flag
	DATA_MAPPING[data.flag] = data

	table.insert(DATA, data)

	return data.flag
end

function CollisionFlag.getHasFlagSet(node, flag)
	local collisionMask = getCollisionMask(node)

	return bitAND(collisionMask, flag) ~= 0
end

function CollisionFlag.getBit(flag)
	local data = DATA_MAPPING[flag]

	if data == nil then
		printCallstack()
	end

	return data.bit
end

function CollisionFlag.checkCollisionMask(node)
	local matches = false

	if getHasClassId(node, ClassIds.SHAPE) then
		local mask = getCollisionMask(node)

		if mask > 0 and mask ~= 255 then
			local undefinedMask = bitAND(mask, bitNOT(FULL_MASK))

			if undefinedMask ~= 0 then
				local bitStr = MathUtil.numberToSetBitsStr(undefinedMask)

				print(string.format("    CollisionFlag-Check: Node '%s' uses undefined bits '%s'!", I3DUtil.getNodePath(node), bitStr))

				matches = true
			end

			local deprecatedMask = bitAND(mask, bitNOT(ACTIVE_MASK))

			if deprecatedMask ~= 0 then
				local bitStr = MathUtil.numberToSetBitsStr(deprecatedMask)

				print(string.format("    CollisionFlag-Check: Node '%s' uses deprecated bits '%s'!", I3DUtil.getNodePath(node), bitStr))

				matches = true
			end
		end
	end

	return matches
end

function CollisionFlag.checkCollisionMaskRec(node)
	local matches = false

	if node ~= nil and node ~= 0 then
		matches = matches or CollisionFlag.checkCollisionMask(node)

		for i = 0, getNumOfChildren(node) - 1 do
			matches = matches or CollisionFlag.checkCollisionMaskRec(getChildAt(node, i))
		end
	end

	return matches
end

addConsoleCommand("gsCollisionFlagShowAll", "Shows all available collision flags", "consoleCommandShowAll", CollisionFlag)

function CollisionFlag.consoleCommandShowAll()
	table.sort(DATA, function (a, b)
		if a.isDeprecated and b.isDeprecated or not a.isDeprecated and not b.isDeprecated then
			return a.bit < b.bit
		elseif a.isDeprecated then
			return false
		end

		return true
	end)
	print("Defined collision flags:")

	local showedDeprecated = false

	for _, data in ipairs(DATA) do
		if data.isDeprecated and not showedDeprecated then
			print("\nDeprecated:")

			showedDeprecated = true
		end

		print(string.format("Bit %02d: %s - %s", data.bit, data.name, data.description))
	end

	print("\n\nPredefined collision masks:")

	for identifier, mask in pairs(CollisionMask) do
		print(string.format("Mask %010d: %s", mask, identifier))
	end
end

CollisionFlag.DEFAULT = registerFlag(0, "DEFAULT", "The default bit", true)
CollisionFlag.STATIC_WORLD = registerFlag(1, "STATIC_WORLD", "Collision with terrain, terrainHeight and static objects", true)
CollisionFlag.STATIC_OBJECTS = registerFlag(3, "STATIC_OBJECTS", "Collision with static objects", true)
CollisionFlag.STATIC_OBJECT = registerFlag(4, "STATIC_OBJECT", "A static object", true)
CollisionFlag.AI_BLOCKING = registerFlag(5, "AI_BLOCKING", "Blocks the AI", true)
CollisionFlag.TERRAIN = registerFlag(8, "TERRAIN", "Collision with terrain", true)
CollisionFlag.TERRAIN_DELTA = registerFlag(9, "TERRAIN_DELTA", "Collision with terrain delta", true)
CollisionFlag.CAMERA_BLOCKING = registerFlag(10, "CAMERA_BLOCKING", "Blocks outdoor vehicle camera", true)
CollisionFlag.TREE = registerFlag(11, "TREE", "A tree", true)
CollisionFlag.DYNAMIC_OBJECT = registerFlag(12, "DYNAMIC_OBJECT", "A dynamic object", true)
CollisionFlag.VEHICLE = registerFlag(13, "VEHICLE", "A vehicle", true)
CollisionFlag.PLAYER = registerFlag(14, "PLAYER", "A player", true)
CollisionFlag.BLOCKED_BY_PLAYER = registerFlag(15, "BLOCKED_BY_PLAYER", "Object that's blocked by a player", true)
CollisionFlag.ANIMAL = registerFlag(16, "ANIMAL", "An animal", true)
CollisionFlag.ANIMAL_POSITIONING = registerFlag(17, "ANIMAL_POSITIONING", "An object where animals can walk on", true)
CollisionFlag.AI_DRIVABLE = registerFlag(18, "AI_DRIVABLE", "AI can drive over this node", true)
CollisionFlag.GROUND_TIP_BLOCKING = registerFlag(19, "GROUND_TIP_BLOCKING", "Bit to block the ground tipping at this position", true)
CollisionFlag.TRIGGER_PLAYER = registerFlag(20, "TRIGGER_PLAYER", "A trigger for players", true)
CollisionFlag.TRIGGER_VEHICLE = registerFlag(21, "TRIGGER_VEHICLE", "A trigger for vehicles!", true)
CollisionFlag.TRIGGER_DYNAMIC_OBJECT = registerFlag(24, "TRIGGER_DYNAMIC_OBJECT", "A dynamic object", true)
CollisionFlag.TRIGGER_TRAFFIC_VEHICLE_BLOCKING = registerFlag(25, "TRIGGER_TRAFFIC_VEHICLE_BLOCKING", "A trigger that blocks the traffic vehicles", true)
CollisionFlag.TRIGGER_FORK = registerFlag(27, "TRIGGER_FORK", "A trigger for fork object mounting", true)
CollisionFlag.TRIGGER_ANIMAL = registerFlag(28, "TRIGGER_ANIMAL", "A trigger for animals", true)
CollisionFlag.FILLABLE = registerFlag(30, "FILLABLE", "A fillable node. Used in trailers and unload triggers", true)
CollisionFlag.WATER = registerFlag(31, "WATER", "Collision of the water plane", true)

registerFlag(2, "STATIC_WORLD_WITHOUT_DELTA", "Deprecated in FS22: Do not use it anymore!", false)
registerFlag(6, "TRACTOR", "Deprecated in FS22: Do not use it anymore!", false)
registerFlag(7, "COMBINE", "Deprecated in FS22: Do not use it anymore!", false)
registerFlag(22, "TRIGGER_COMBINE", "Deprecated in FS22: Do not use it anymore!", false)
registerFlag(23, "TRIGGER_FILLABLE", "Deprecated in FS22: Do not use it anymore!", false)
registerFlag(26, "TRIGGER_CUTTER", "Deprecated in FS22: Do not use it anymore!", false)
I3DManager.addDebugLoadingCheck("Collision-Flag check", function (filename, node)
	return CollisionFlag.checkCollisionMaskRec(node)
end)
