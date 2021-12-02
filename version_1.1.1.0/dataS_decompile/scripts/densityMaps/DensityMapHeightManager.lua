DensityMapHeightManager = {
	GENERATED_TIP_COLLISION_FILENAME = "infoLayer_tipCollisionGenerated.grle",
	GENERATED_PLACEMENT_COLLISION_FILENAME = "infoLayer_placementCollisionGenerated.grle",
	DEBUG_ENABLED = false
}
local DensityMapHeightManager_mt = Class(DensityMapHeightManager, AbstractManager)

function DensityMapHeightManager.new(customMt)
	local self = AbstractManager.new(customMt or DensityMapHeightManager_mt)

	return self
end

function DensityMapHeightManager:initDataStructures()
	self.numHeightTypes = 0
	self.heightTypes = {}
	self.fillTypeNameToHeightType = {}
	self.fillTypeIndexToHeightType = {}
	self.heightTypeIndexToFillTypeIndex = {}
	self.fixedFillTypesAreas = {}
	self.convertingFillTypesAreas = {}
	self.tipTypeMappings = {}

	if self.terrainDetailHeightUpdater ~= nil then
		delete(self.terrainDetailHeightUpdater)

		self.terrainDetailHeightUpdater = nil
	end

	if self.tipCollisionMap ~= nil then
		if self.tipCollisionMapCreated then
			delete(self.tipCollisionMap)

			self.tipCollisionMapCreated = false
		end

		self.tipCollisionMap = nil
	end

	if self.placementCollisionMap ~= nil then
		if self.placementCollisionMapCreated then
			delete(self.placementCollisionMap)

			self.placementCollisionMapCreated = false
		end

		self.placementCollisionMap = nil
	end

	self.tipCollisionMask = CollisionFlag.GROUND_TIP_BLOCKING
	self.placementCollisionMask = 1048543
end

function DensityMapHeightManager:loadDefaultTypes(missionInfo, baseDirectory)
	self:initDataStructures()

	local xmlFile = loadXMLFile("heightTypes", "data/maps/maps_densityMapHeightTypes.xml")

	self:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end

function DensityMapHeightManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	DensityMapHeightManager:superClass().loadMapData(self)
	addConsoleCommand("gsTipAnywhereAdd", "Tips a fillType", "consoleCommandTipAnywhereAdd", self)
	addConsoleCommand("gsTipAnywhereClear", "Clears tip area", "consoleCommandTipAnywhereClear", self)
	addConsoleCommand("gsDensityMapToggleDebug", "Toggles debug mode", "consoleCommandToggleDebug", self)
	self:loadDefaultTypes(missionInfo, baseDirectory)

	return XMLUtil.loadDataFromMapXML(xmlFile, "densityMapHeightTypes", baseDirectory, self, self.loadDensityMapHeightTypes, missionInfo, baseDirectory)
end

function DensityMapHeightManager:unloadMapData()
	DensityMapHeightManager:superClass().unloadMapData(self)
	removeConsoleCommand("gsTipAnywhereAdd")
	removeConsoleCommand("gsTipAnywhereClear")
	removeConsoleCommand("gsDensityMapToggleDebug")
end

function DensityMapHeightManager:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	self.heightTypeFirstChannel = getXMLInt(xmlFile, "map.densityMapHeightTypes#firstChannel") or self.heightTypeFirstChannel or 0
	self.heightTypeNumChannels = getXMLInt(xmlFile, "map.densityMapHeightTypes#numChannels") or self.heightTypeNumChannels or 6
	local i = 0

	while true do
		local key = string.format("map.densityMapHeightTypes.densityMapHeightType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local fillTypeName = getXMLString(xmlFile, key .. "#fillTypeName")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			print("Error loading density map height. '" .. tostring(key) .. "' has no valid 'fillTypeName'!")

			return
		end

		local heightType = self.fillTypeNameToHeightType[fillTypeName] or {}
		local maxAngle = getXMLFloat(xmlFile, key .. "#maxSurfaceAngle")
		local maxSurfaceAngle = heightType.maxSurfaceAngle or math.rad(26)

		if maxAngle ~= nil then
			maxSurfaceAngle = math.rad(maxAngle)
		end

		local fillToGroundScale = getXMLFloat(xmlFile, key .. "#fillToGroundScale") or heightType.fillToGroundScale or 1
		local allowsSmoothing = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsSmoothing"), heightType.allowsSmoothing), false)
		local collisionScale = getXMLFloat(xmlFile, key .. ".collision#scale") or heightType.collisionScale or 1
		local collisionBaseOffset = getXMLFloat(xmlFile, key .. ".collision#baseOffset") or heightType.collisionBaseOffset or 0
		local minCollisionOffset = getXMLFloat(xmlFile, key .. ".collision#minOffset") or heightType.minCollisionOffset or 0
		local maxCollisionOffset = getXMLFloat(xmlFile, key .. ".collision#maxOffset") or heightType.maxCollisionOffset or 1

		self:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, isBaseType)

		i = i + 1
	end

	self:sortHeightTypes()

	return true
end

function DensityMapHeightManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end

	local xmlFile = XMLFile.load("densitymapHeightXML", xmlFilename)

	if xmlFile == nil then
		return false
	end

	self.tipTypeMappings = {}

	xmlFile:iterate("tipTypeMappings.tipTypeMapping", function (_, key)
		local name = xmlFile:getString(key .. "#fillType")
		local index = xmlFile:getInt(key .. "#index")

		if name ~= nil and index ~= nil then
			self.tipTypeMappings[name:lower()] = index
		end
	end)
	xmlFile:delete()
end

function DensityMapHeightManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("densityMapHeightXML", xmlFilename, "tipTypeMappings")

	if xmlFile ~= nil then
		for k, heightType in ipairs(self.heightTypes) do
			local mappingKey = string.format("tipTypeMappings.tipTypeMapping(%d)", k - 1)

			xmlFile:setString(mappingKey .. "#fillType", heightType.fillTypeName)
			xmlFile:setInt(mappingKey .. "#index", heightType.index)
		end

		xmlFile:save()
		xmlFile:delete()

		return true
	end

	return false
end

local function sortHeightTypes(a, b)
	return a.fillTypeIndex < b.fillTypeIndex
end

function DensityMapHeightManager:sortHeightTypes()
	table.sort(self.heightTypes, sortHeightTypes)

	for i = 1, #self.heightTypes do
		local heightType = self.heightTypes[i]
		heightType.index = i
		self.heightTypeIndexToFillTypeIndex[heightType.index] = heightType.fillTypeIndex
	end
end

function DensityMapHeightManager:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, isBaseType)
	if isBaseType and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
		print("Warning: density height map for '" .. tostring(fillTypeName) .. "' already exists!")

		return nil
	end

	local heightType = self.fillTypeNameToHeightType[fillTypeName]

	if heightType == nil then
		if self.numHeightTypes >= 2^g_densityMapHeightManager.heightTypeNumChannels - 1 then
			Logging.error("addDensityMapHeightType: maximum number of height types already registered.")

			return nil
		end

		self.numHeightTypes = self.numHeightTypes + 1
		heightType = {
			index = self.numHeightTypes,
			fillTypeName = fillTypeName
		}
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		heightType.fillTypeIndex = fillTypeIndex

		table.insert(self.heightTypes, heightType)

		self.fillTypeNameToHeightType[fillTypeName] = heightType
		self.fillTypeIndexToHeightType[fillTypeIndex] = heightType
		self.heightTypeIndexToFillTypeIndex[heightType.index] = fillTypeIndex
	end

	heightType.maxSurfaceAngle = maxSurfaceAngle
	heightType.collisionScale = collisionScale
	heightType.collisionBaseOffset = collisionBaseOffset
	heightType.minCollisionOffset = minCollisionOffset
	heightType.maxCollisionOffset = maxCollisionOffset
	heightType.fillToGroundScale = fillToGroundScale
	heightType.allowsSmoothing = allowsSmoothing

	return heightType
end

function DensityMapHeightManager:getDensityMapHeightTypeByIndex(index)
	if index ~= nil then
		return self.heightTypes[index]
	end

	return nil
end

function DensityMapHeightManager:getFillTypeNameByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeName
	end

	return nil
end

function DensityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeIndex
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeName(fillTypeName)
	if fillTypeName ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName]
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex]
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeName(fillTypeName)
	if fillTypeName ~= nil and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName].index
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil and self.fillTypeIndexToHeightType[fillTypeIndex] ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex].index
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypes()
	return self.heightTypes
end

function DensityMapHeightManager:getFillTypeToDensityMapHeightTypes()
	return self.fillTypeIndexToHeightType
end

function DensityMapHeightManager:setFixedFillTypesArea(area, fillTypes)
	self.fixedFillTypesAreas[area] = {
		fillTypes = fillTypes
	}
end

function DensityMapHeightManager:removeFixedFillTypesArea(area)
	self.fixedFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getFixedFillTypesAreas()
	return self.fixedFillTypesAreas
end

function DensityMapHeightManager:setConvertingFillTypeAreas(area, fillTypes, fillTypeTarget)
	self.convertingFillTypesAreas[area] = {
		fillTypes = fillTypes,
		fillTypeTarget = fillTypeTarget
	}
end

function DensityMapHeightManager:removeConvertingFillTypeAreas(area)
	self.convertingFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getConvertingFillTypesAreas()
	return self.convertingFillTypesAreas
end

function DensityMapHeightManager:checkTypeMappings()
	local typeMappings = self.tipTypeMappings

	if typeMappings ~= nil and next(typeMappings) ~= nil then
		local numUsedMappings = 0

		for _, entry in ipairs(self.heightTypes) do
			local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
			local oldTypeIndex = typeMappings[name]

			if oldTypeIndex == nil or oldTypeIndex ~= entry.index then
				return false
			end

			numUsedMappings = numUsedMappings + 1
		end

		local numMappings = 0

		for _, _ in pairs(typeMappings) do
			numMappings = numMappings + 1
		end

		if numMappings ~= numUsedMappings then
			return false
		end
	end

	return true
end

function DensityMapHeightManager:initialize(isServer, tipCollisionMap, placementCollisionMap)
	local id = g_currentMission.terrainDetailHeightId
	self.tipToGroundIsAllowed = true
	local densitySize = getDensityMapSize(id)
	local deform = TerrainDeformation.new(g_currentMission.terrainRootNode)
	local placementMapSize = deform:getBlockedAreaMapSize()

	deform:cancel()
	deform:delete()

	self.worldToDensityMap = densitySize / g_currentMission.terrainSize
	self.densityToWorldMap = g_currentMission.terrainSize / densitySize
	self.worldToPlacementMap = placementMapSize / g_currentMission.terrainSize
	self.placementToWorldMap = g_currentMission.terrainSize / placementMapSize
	self.pendingCollisionRecalculateAreas = {}
	self.collisionRecalculateAreaSize = 16
	self.collisionRecalculateAreaWorldSize = self.collisionRecalculateAreaSize * self.densityToWorldMap
	self.numCollisionRecalculateAreasPerSide = math.floor((densitySize + self.collisionRecalculateAreaSize - 1) / self.collisionRecalculateAreaSize)
	local litersPerMeter = 250
	local maxHeight = getDensityMapMaxHeight(id)
	local unitLength = g_currentMission.terrainSize / densitySize
	self.volumePerPixel = maxHeight * unitLength * unitLength
	self.literPerPixel = litersPerMeter * maxHeight * self.volumePerPixel
	self.fillToGroundScale = self.worldToDensityMap^2 / (litersPerMeter * maxHeight)
	local maxHeightDensityValue = 2^getDensityMapHeightNumChannels(id) - 1
	self.minValidLiterValue = self.literPerPixel / maxHeightDensityValue
	self.minValidVolumeValue = self.volumePerPixel / maxHeightDensityValue
	self.heightToDensityValue = maxHeightDensityValue / maxHeight
	local heightFirstChannel = getDensityMapHeightFirstChannel(id)
	local heightNumChannels = getDensityMapHeightNumChannels(id)
	local typeFirstChannel = self.heightTypeFirstChannel
	local typeNumChannels = self.heightTypeNumChannels

	if heightFirstChannel < typeFirstChannel + typeNumChannels and typeFirstChannel < heightFirstChannel + heightNumChannels then
		print(string.format("Warning: Density map height type channels [%d-%d] are overlapping with the density map height channels [%d-%d]. This will lead to unexpected results.", typeFirstChannel, typeFirstChannel + typeNumChannels - 1, heightFirstChannel, heightFirstChannel + heightNumChannels - 1))
	end

	local densityMapHeightCollisionMask = CollisionMask.TERRAIN_DETAIL_HEIGHT
	self.terrainDetailHeightUpdater = createDensityMapHeightUpdater("TerrainDetailHeightUpdater", id, typeFirstChannel, typeNumChannels, densityMapHeightCollisionMask)
	local numUsedMappings = 0
	local heightTypes = self:getDensityMapHeightTypes()

	if heightTypes ~= nil then
		for _, entry in ipairs(heightTypes) do
			local oldTypeIndex = entry.index

			if self.tipTypeMappings ~= nil and next(self.tipTypeMappings) ~= nil then
				local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
				local fillTypeName = name:lower()
				oldTypeIndex = Utils.getNoNil(self.tipTypeMappings[fillTypeName], -1)

				if oldTypeIndex >= 0 then
					numUsedMappings = numUsedMappings + 1
				end
			end

			setDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, entry.index, oldTypeIndex, entry.maxSurfaceAngle, entry.collisionScale, entry.collisionBaseOffset, entry.minCollisionOffset, entry.maxCollisionOffset)
		end
	end

	g_fillTypeManager:constructFillTypeDistanceTextureArray(g_currentMission.terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)

	local forceTypeConversion = false

	if self.tipTypeMappings ~= nil then
		local numMappings = 0

		for _, _ in pairs(self.tipTypeMappings) do
			numMappings = numMappings + 1
		end

		if numMappings ~= numUsedMappings then
			forceTypeConversion = true
		end
	end

	initDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, forceTypeConversion)

	local missionInfo = g_currentMission.missionInfo

	if isServer then
		self.tipCollisionMap = tipCollisionMap
		self.tipCollisionMapCreated = false

		if tipCollisionMap == 0 then
			self.tipCollisionMap = createBitVectorMap("CollisionMap")
			self.tipCollisionMapCreated = true
		end

		local collisionMapValid = false

		if not GS_IS_MOBILE_VERSION and missionInfo:getIsTipCollisionValid(g_currentMission) then
			local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME

			if loadBitVectorMapFromFile(self.tipCollisionMap, savegameFilename, 2) and setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, false) then
				collisionMapValid = true
			else
				Logging.warning("Failed to load savegame tip collision map '" .. savegameFilename .. "'. Loading default tip collision map and recreating from placeables.")
			end
		end

		if not collisionMapValid then
			local cleanupHeights = false

			if missionInfo.isValid then
				cleanupHeights = true
			end

			if self.tipCollisionMapCreated or not setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, cleanupHeights) then
				Logging.warning("No tip collision map defined. Creating empty tip placement collision map.")
				loadBitVectorMapNew(self.tipCollisionMap, densitySize, densitySize, 2, false)
				setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, cleanupHeights)
			end
		end
	end

	self.placementCollisionMap = placementCollisionMap
	self.placementCollisionMapCreated = false

	if placementCollisionMap == 0 then
		self.placementCollisionMap = createBitVectorMap("PlacementCollisionMap")
		self.placementCollisionMapCreated = true
	end

	local placementCollisionMapValid = false

	if not GS_IS_MOBILE_VERSION and missionInfo:getIsPlacementCollisionValid(g_currentMission) then
		local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME

		if loadBitVectorMapFromFile(self.placementCollisionMap, savegameFilename, 1) then
			placementCollisionMapValid = true
		else
			Logging.warning("Failed to load savegame placement collision map '" .. savegameFilename .. "'. Loading default placement collision map and recreating from placeables.")
		end
	end

	if not placementCollisionMapValid and self.placementCollisionMapCreated then
		Logging.warning("No placement collision map defined. Creating empty placement collision map.")
		loadBitVectorMapNew(self.placementCollisionMap, placementMapSize, placementMapSize, 1, false)
	end

	g_fillTypeManager:constructDensityMapHeightTextureArrays(heightTypes)

	local numShapes = getNumOfChildren(g_currentMission.terrainDetailHeightTGId)

	for i = 0, numShapes - 1 do
		local detailShape = getChildAt(g_currentMission.terrainDetailHeightTGId, i)

		if getHasClassId(detailShape, ClassIds.SHAPE) then
			g_fillTypeManager:assignDensityMapHeightTextureArrays(detailShape)
		end
	end
end

function DensityMapHeightManager:getIsValid()
	return self.terrainDetailHeightUpdater ~= nil
end

function DensityMapHeightManager:getTerrainDetailHeightUpdater()
	return self.terrainDetailHeightUpdater
end

function DensityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
	local heightType = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0
	end

	return self.minValidLiterValue / heightType.fillToGroundScale
end

function DensityMapHeightManager:update(dt)
	if not self:getIsValid() then
		return
	end

	local num = 0

	for areaIndex in pairs(self.pendingCollisionRecalculateAreas) do
		self.pendingCollisionRecalculateAreas[areaIndex] = nil
		local zi = math.floor(areaIndex / self.numCollisionRecalculateAreasPerSide)
		local xi = areaIndex - zi * self.numCollisionRecalculateAreasPerSide
		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local minX = xi * self.collisionRecalculateAreaWorldSize - terrainHalfSize
		local minZ = zi * self.collisionRecalculateAreaWorldSize - terrainHalfSize

		self:updateCollisionMap(minX, minZ, minX + self.collisionRecalculateAreaWorldSize, minZ + self.collisionRecalculateAreaWorldSize)

		num = num + 1

		if num > 6 then
			break
		end
	end
end

function DensityMapHeightManager:visualizeCollisionMap()
	if self.tipCollisionMap ~= nil then
		local densitySize = getDensityMapSize(g_currentMission.terrainDetailHeightId)
		local x, _, z = getWorldTranslation(getCamera(0))

		if g_currentMission.controlledVehicle ~= nil then
			local object = g_currentMission.controlledVehicle

			if g_currentMission.controlledVehicle.selectedImplement ~= nil then
				object = g_currentMission.controlledVehicle.selectedImplement.object
			end

			x, _, z = getWorldTranslation(object.components[1].node)
		end

		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local xi = math.floor((x + terrainHalfSize) * self.worldToDensityMap)
		local zi = math.floor((z + terrainHalfSize) * self.worldToDensityMap)
		local minXi = math.max(xi - 25, 0)
		local minZi = math.max(zi - 25, 0)
		local maxXi = math.min(xi + 25, densitySize - 1)
		local maxZi = math.min(zi + 25, densitySize - 1)

		for stepZi = minZi, maxZi do
			for stepXi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.tipCollisionMap, stepXi, stepZi, 0, 2)
				local r = 0
				local g = 1
				local b = 0

				if v > 1 then
					b = 0.1
					g = 0
					r = 1
				elseif v > 0 then
					b = 1
					g = 0
					r = 0
				end

				local wx = stepXi * self.densityToWorldMap - terrainHalfSize
				local wz = stepZi * self.densityToWorldMap - terrainHalfSize
				local wy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, 0, wz) + 0.05

				Utils.renderTextAtWorldPosition(wx, wy, wz, tostring(v), getCorrectTextSize(0.016), 0, {
					r,
					g,
					b,
					1
				})
			end
		end
	end
end

function DensityMapHeightManager:visualizePlacementCollisionMap()
	if self.placementCollisionMap ~= nil then
		local densitySize = getDensityMapSize(g_currentMission.terrainDetailHeightId)
		local x, _, z = getWorldTranslation(getCamera(0))

		if g_currentMission.controlledVehicle ~= nil then
			local object = g_currentMission.controlledVehicle

			if g_currentMission.controlledVehicle.selectedImplement ~= nil then
				object = g_currentMission.controlledVehicle.selectedImplement.object
			end

			x, _, z = getWorldTranslation(object.components[1].node)
		end

		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local xi = math.floor((x + terrainHalfSize) * self.worldToPlacementMap)
		local zi = math.floor((z + terrainHalfSize) * self.worldToPlacementMap)
		local minXi = math.max(xi - 20, 0)
		local minZi = math.max(zi - 20, 0)
		local maxXi = math.min(xi + 20, densitySize - 1)
		local maxZi = math.min(zi + 20, densitySize - 1)

		for stepZi = minZi, maxZi do
			for stepXi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.placementCollisionMap, stepXi, stepZi, 0, 1)
				local r = 0
				local g = 1
				local b = 0

				if v > 0 then
					b = 0
					g = 0
					r = 1
				end

				local wx = stepXi * self.placementToWorldMap - terrainHalfSize
				local wz = stepZi * self.placementToWorldMap - terrainHalfSize
				local wy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, 0, wz)

				drawDebugLine(wx, wy, wz, r, g, b, wx, wy + 1, wz, r, g, b, false)
			end
		end
	end
end

function DensityMapHeightManager:saveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		saveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:prepareSaveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:savePreparedCollisionMap(callback, callbackObject)
	if self.tipCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.tipCollisionMap, callback, callbackObject)
	end
end

function DensityMapHeightManager:savePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		saveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:prepareSavePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end

function DensityMapHeightManager:savePreparedPlacementCollisionMap(callback, callbackObject)
	if self.placementCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.placementCollisionMap, callback, callbackObject)
	end
end

function DensityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ)
	local terrainHalfSize = g_currentMission.terrainSize * 0.5
	local minXi = math.floor((minX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local minZi = math.floor((minZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxXi = math.ceil((maxX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxZi = math.ceil((maxZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)

	for zi = minZi, maxZi do
		for xi = minXi, maxXi do
			local areaIndex = zi * self.numCollisionRecalculateAreasPerSide + xi
			self.pendingCollisionRecalculateAreas[areaIndex] = true
		end
	end
end

function DensityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ)
	if self.tipCollisionMap ~= nil or self.placementCollisionMap ~= nil then
		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		minX = MathUtil.clamp(minX, -terrainHalfSize, terrainHalfSize)
		minZ = MathUtil.clamp(minZ, -terrainHalfSize, terrainHalfSize)
		maxX = MathUtil.clamp(maxX, -terrainHalfSize, terrainHalfSize)
		maxZ = MathUtil.clamp(maxZ, -terrainHalfSize, terrainHalfSize)

		if self.tipCollisionMap ~= nil then
			updateTerrainCollisionMap(self.tipCollisionMap, g_currentMission.terrainRootNode, "tipCollision", 0, self.tipCollisionMask, minX, minZ, maxX, maxZ)
		end

		if self.placementCollisionMap ~= nil then
			updatePlacementCollisionMap(self.placementCollisionMap, g_currentMission.terrainRootNode, self.placementCollisionMask, minX, minZ, maxX, maxZ)
		end
	end
end

function DensityMapHeightManager:consoleCommandTipAnywhereAdd(fillTypeName, amount, length, rows, spacing)
	local usage = "gsTipAnywhereAdd fillTypeName amount length rows spacing"

	if fillTypeName == nil then
		return "Error: No filltype given. " .. usage
	end

	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	if fillTypeIndex == nil then
		local availableFillTypes = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)

		return string.format("Error: Invalid fillType '%s'.\nAvailable fillTypes: %s", fillTypeName, table.concat(availableFillTypes, ", "))
	end

	if self.fillTypeIndexToHeightType[fillTypeIndex] == nil then
		local availableFillTypes = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)

		return string.format("Error: fillType '%s' not supported for tip anywhere.\nAvailable fillTypes: %s", fillTypeName, table.concat(availableFillTypes, ", "))
	end

	amount = tonumber(amount)

	if amount == nil then
		return "No amount given. " .. usage
	end

	length = Utils.getNoNil(tonumber(length), 1)
	rows = Utils.getNoNil(tonumber(rows), 1)
	spacing = Utils.getNoNil(tonumber(spacing), 3)
	local mission = g_currentMission
	local player = mission.player
	local controlledVehicle = mission.controlledVehicle
	local x = 0
	local y = 0
	local z = 0
	local dirX = 1
	local _ = 0
	local dirZ = 0

	if mission.controlPlayer then
		if player ~= nil and player.isControlled and player.rootNode ~= nil and player.rootNode ~= 0 then
			x, y, z = getWorldTranslation(player.rootNode)
			dirZ = -math.cos(player.rotY)
			_ = 0
			dirX = -math.sin(player.rotY)
		end
	elseif controlledVehicle ~= nil then
		x, y, z = getWorldTranslation(controlledVehicle.rootNode)
		dirX, _, dirZ = localDirectionToWorld(controlledVehicle.rootNode, 0, 0, 1)
	end

	local initialOffset = (rows - 1) * spacing * -0.5

	for i = 0, rows - 1 do
		local offset = initialOffset + i * spacing
		local lx = x + offset * dirZ
		local ly = y
		local lz = z + offset * -dirX

		DensityMapHeightUtil.tipToGroundAroundLine(controlledVehicle, amount, fillTypeIndex, lx, ly, lz, lx + length * dirX, ly, lz + length * dirZ, 10, 40, nil, , , )
	end

	if mission.controlPlayer and player ~= nil then
		local _, delta = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)

		player:moveTo(x, delta, z, false, false)
	end

	return "Tipped " .. amount .. "l of " .. fillTypeName
end

function DensityMapHeightManager:consoleCommandTipAnywhereClear(size)
	local usage = "gsTipAnywhereClear size"
	size = tonumber(size)

	if size == nil then
		return "Invalid size. " .. usage
	end

	local mission = g_currentMission
	local player = mission.player
	local terrainSizeHalf = mission.terrainSize * 0.5
	local x0 = -terrainSizeHalf
	local z0 = terrainSizeHalf
	local x1 = terrainSizeHalf
	local z1 = terrainSizeHalf
	local x2 = -terrainSizeHalf
	local z2 = -terrainSizeHalf

	if size ~= nil then
		local node = nil

		if mission.controlPlayer then
			if player ~= nil and player.isControlled and player.rootNode ~= nil and player.rootNode ~= 0 then
				node = player.rootNode
			end
		elseif mission.controlledVehicle ~= nil then
			node = mission.controlledVehicle.rootNode
		end

		if node ~= nil then
			local sizeHalf = size * 0.5
			local _ = nil
			x0, _, z0 = localToWorld(node, -sizeHalf, 0, sizeHalf)
			x1, _, z1 = localToWorld(node, sizeHalf, 0, sizeHalf)
			x2, _, z2 = localToWorld(node, -sizeHalf, 0, -sizeHalf)
		end
	end

	DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)

	return "Cleared area (" .. size .. "m)"
end

function DensityMapHeightManager:consoleCommandToggleDebug()
	DensityMapHeightManager.DEBUG_ENABLED = not DensityMapHeightManager.DEBUG_ENABLED

	return string.format("DensityMapHeightManager.DEBUG_ENABLED = %s", tostring(DensityMapHeightManager.DEBUG_ENABLED))
end

g_densityMapHeightManager = DensityMapHeightManager.new()
