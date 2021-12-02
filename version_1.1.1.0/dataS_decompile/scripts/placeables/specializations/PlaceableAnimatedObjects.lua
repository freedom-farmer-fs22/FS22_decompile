PlaceableAnimatedObjects = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableAnimatedObjects.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableAnimatedObjects.setOwnerFarmId)
end

function PlaceableAnimatedObjects.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableAnimatedObjects)
end

function PlaceableAnimatedObjects.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("AnimatedObjects")
	AnimatedObject.registerXMLPaths(schema, basePath .. ".animatedObjects")
	schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#animatedObjectIndex", "Animated object index")
	schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#minTime", "Min Time")
	schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#maxTime", "Max Time")
	schema:setXMLSpecializationType()
end

function PlaceableAnimatedObjects.registerSavegameXMLPaths(schema, basePath)
	AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end

function PlaceableAnimatedObjects:onLoad(savegame)
	local spec = self.spec_animatedObjects
	local xmlFile = self.xmlFile
	spec.animatedObjects = {}

	xmlFile:iterate("placeable.animatedObjects.animatedObject", function (index, animationKey)
		local animatedObject = AnimatedObject.new(self.isServer, self.isClient)
		animatedObject.dependencies = {}

		xmlFile:iterate(animationKey .. ".dependency", function (_, dependencyKey)
			local dependendIndex = xmlFile:getInt(dependencyKey .. "#animatedObjectIndex")

			if dependendIndex ~= nil then
				local minTime = xmlFile:getValue(dependencyKey .. "#minTime", 0)
				local maxTime = xmlFile:getValue(dependencyKey .. "#maxTime", 0)
				local dependency = {
					objectIndex = dependendIndex,
					minTime = minTime,
					maxTime = maxTime
				}

				table.insert(animatedObject.dependencies, dependency)
			else
				Logging.xmlError(xmlFile, "Missing animatedObjectIndex for '%s'", dependencyKey)
			end
		end)

		if animatedObject:load(self.components, xmlFile, animationKey, self.configFileName, self.i3dMappings) then
			table.insert(spec.animatedObjects, animatedObject)
		else
			Logging.xmlError(xmlFile, "Failed to load animated object %i", index)
		end
	end)

	for _, animatedObject in ipairs(spec.animatedObjects) do
		if #animatedObject.dependencies > 0 then
			animatedObject.getCanBeTriggered = Utils.overwrittenFunction(animatedObject.getCanBeTriggered, function (_, superFunc)
				if not superFunc(animatedObject) then
					return false
				end

				for _, dependency in ipairs(animatedObject.dependencies) do
					local dependendObject = spec.animatedObjects[dependency.objectIndex]

					if dependendObject ~= nil then
						local t = dependendObject.animation.time

						if t < dependency.minTime or dependency.maxTime < t then
							return false
						end
					else
						Logging.xmlWarning(xmlFile, "Invalid dependency animated object index '%d'", dependency.objectIndex)
					end
				end

				return true
			end)
		end
	end
end

function PlaceableAnimatedObjects:onDelete()
	local spec = self.spec_animatedObjects

	if spec.animatedObjects ~= nil then
		for _, animatedObject in ipairs(spec.animatedObjects) do
			animatedObject:delete()
			animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)
		end

		spec.animatedObjects = nil
	end
end

function PlaceableAnimatedObjects:onPostFinalizePlacement()
	local spec = self.spec_animatedObjects

	for _, animatedObject in ipairs(spec.animatedObjects) do
		animatedObject:register(true)
	end
end

function PlaceableAnimatedObjects:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_animatedObjects

		for _, animatedObject in ipairs(spec.animatedObjects) do
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end
	end
end

function PlaceableAnimatedObjects:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_animatedObjects

		for _, animatedObject in ipairs(spec.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end
	end
end

function PlaceableAnimatedObjects:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_animatedObjects

	for i, animatedObject in ipairs(spec.animatedObjects) do
		animatedObject:loadFromXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1))
	end
end

function PlaceableAnimatedObjects:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_animatedObjects

	for i, animatedObject in ipairs(spec.animatedObjects) do
		animatedObject:saveToXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1), usedModNames)
	end
end

function PlaceableAnimatedObjects:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	superFunc(self, ownerFarmId, noEventSend)

	local spec = self.spec_animatedObjects

	if spec.animatedObjects ~= nil then
		for _, animatedObject in ipairs(spec.animatedObjects) do
			animatedObject:setOwnerFarmId(ownerFarmId, true)
		end
	end
end
