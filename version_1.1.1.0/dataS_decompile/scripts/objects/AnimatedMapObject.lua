AnimatedMapObject = {}
local AnimatedMapObject_mt = Class(AnimatedMapObject, AnimatedObject)

InitStaticObjectClass(AnimatedMapObject, "AnimatedMapObject", ObjectIds.OBJECT_ANIMATED_MAP_OBJECT)

function AnimatedMapObject:onCreate(id)
	local object = AnimatedMapObject.new(g_server ~= nil, g_client ~= nil)

	if object:load(id) then
		g_currentMission:addOnCreateLoadedObject(object)
		g_currentMission:addOnCreateLoadedObjectToSave(object)
		object:register(true)
	else
		object:delete()
	end
end

function AnimatedMapObject.new(isServer, isClient, customMt)
	local self = AnimatedObject.new(isServer, isClient, customMt or AnimatedMapObject_mt)

	return self
end

function AnimatedMapObject:delete()
	g_currentMission:removeOnCreateLoadedObjectToSave(self)
	AnimatedMapObject:superClass().delete(self)
end

function AnimatedMapObject:load(nodeId)
	local xmlFilename = getUserAttribute(nodeId, "xmlFilename")

	if xmlFilename == nil then
		print("Error: Missing 'xmlFilename' user attribute for AnimatedMapObject node '" .. getName(nodeId) .. "'!")

		return false
	end

	local baseDir = g_currentMission.loadingMapBaseDirectory

	if baseDir == "" then
		baseDir = Utils.getNoNil(self.baseDirectory, baseDir)
	end

	xmlFilename = Utils.getFilename(xmlFilename, baseDir)
	local index = getUserAttribute(nodeId, "index")

	if index == nil then
		print("Error: Missing 'index' user attribute for AnimatedMapObject node '" .. getName(nodeId) .. "'!")

		return false
	end

	local xmlFile = loadXMLFile("AnimatedObject", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local key = nil
	local i = 0

	while true do
		local objectKey = string.format("animatedObjects.animatedObject(%d)", i)

		if not hasXMLProperty(xmlFile, objectKey) then
			break
		end

		local configIndex = getXMLString(xmlFile, objectKey .. "#index")

		if configIndex == index then
			key = objectKey

			break
		end

		i = i + 1
	end

	if key == nil then
		print("Error: index '" .. index .. "' not found in AnimatedObject xml '" .. xmlFilename .. "'!")

		return false
	end

	local result = AnimatedMapObject:superClass().load(self, nodeId, xmlFile, key, xmlFilename)

	delete(xmlFile)

	return result
end
