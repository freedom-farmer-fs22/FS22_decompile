BaleManager = {
	baleXMLSchema = nil,
	mapBalesXMLSchema = nil
}
local BaleManager_mt = Class(BaleManager, AbstractManager)

function BaleManager.new(customMt)
	local self = AbstractManager.new(customMt or BaleManager_mt)
	BaleManager.baleXMLSchema = XMLSchema.new("bale")

	BaleManager.registerBaleXMLPaths(BaleManager.baleXMLSchema)

	BaleManager.mapBalesXMLSchema = XMLSchema.new("mapBales")

	BaleManager.registerMapBalesXMLPaths(BaleManager.mapBalesXMLSchema)

	return self
end

function BaleManager:initDataStructures()
	self.bales = {}
	self.modBalesToLoad = {}
	self.fermentations = {}
end

function BaleManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	BaleManager:superClass().loadMapData(self)

	local filename = getXMLString(xmlFile, "map.bales#filename")
	local xmlFilename = Utils.getFilename(filename, baseDirectory)
	local balesXMLFile = XMLFile.load("TempBales", xmlFilename, BaleManager.mapBalesXMLSchema)

	if balesXMLFile ~= nil then
		self:loadBales(balesXMLFile, baseDirectory)
		balesXMLFile:delete()
	end

	for i = #self.modBalesToLoad, 1, -1 do
		local bale = self.modBalesToLoad[i]
		local baleXmlFile = XMLFile.load("TempBale", bale.xmlFilename, BaleManager.baleXMLSchema)

		if baleXmlFile ~= nil then
			if self:loadBaleDataFromXML(bale, baleXmlFile, bale.baseDirectory) then
				table.insert(self.bales, bale)
			end

			baleXmlFile:delete()
		end

		table.remove(self.modBalesToLoad, i)
	end

	for _, bale in ipairs(self.bales) do
		bale.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(bale.i3dFilename, false, true, self.baleLoaded, self, bale)
	end

	if g_addCheatCommands then
		addConsoleCommand("gsBaleAdd", "Adds a bale", "consoleCommandAddBale", self)
		addConsoleCommand("gsBaleList", "List available bale types", "consoleCommandListBales", self)
	end

	return true
end

function BaleManager:baleLoaded(i3dNode, failedReason, bale)
	if i3dNode ~= 0 then
		bale.sharedRoot = i3dNode

		removeFromPhysics(i3dNode)
	end
end

function BaleManager:unloadMapData()
	for _, bale in ipairs(self.bales) do
		if bale.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(bale.sharedLoadRequestId)

			bale.sharedLoadRequestId = nil
		end

		if bale.sharedRoot ~= nil then
			delete(bale.sharedRoot)

			bale.sharedRoot = nil
		end
	end

	if g_addCheatCommands then
		removeConsoleCommand("gsBaleAdd")
		removeConsoleCommand("gsBaleList")
	end

	BaleManager:superClass().unloadMapData(self)
end

function BaleManager:loadBales(xmlFile, baseDirectory)
	xmlFile:iterate("map.bales.bale", function (index, key)
		self:loadBaleFromXML(xmlFile, key, baseDirectory)
	end)

	return true
end

function BaleManager:loadBaleFromXML(xmlFile, key, baseDirectory)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end

	local xmlFilename = xmlFile:getString(key .. "#filename")

	if xmlFilename ~= nil then
		local bale = {
			xmlFilename = Utils.getFilename(xmlFilename, baseDirectory),
			isAvailable = xmlFile:getBool(key .. "#isAvailable", true)
		}
		local baleXmlFile = XMLFile.load("TempBale", bale.xmlFilename, BaleManager.baleXMLSchema)

		if baleXmlFile ~= nil then
			local success = self:loadBaleDataFromXML(bale, baleXmlFile, baseDirectory)

			baleXmlFile:delete()

			if success then
				table.insert(self.bales, bale)

				return true
			end
		end
	end

	Logging.xmlError(xmlFile, "Failed to load bale from xml '%s'", key)

	return false
end

function BaleManager:loadModBaleFromXML(xmlFile, key, baseDirectory, customEnvironment)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end

	local xmlFilename = xmlFile:getString(key .. "#filename")

	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
		local bale = {
			xmlFilename = xmlFilename,
			baseDirectory = baseDirectory,
			customEnvironment = customEnvironment,
			isAvailable = xmlFile:getBool(key .. "#isAvailable", true)
		}

		table.insert(self.modBalesToLoad, bale)

		return true
	end

	Logging.xmlError(xmlFile, "Failed to load bale from xml '%s'", key)

	return false
end

function BaleManager:loadBaleDataFromXML(bale, xmlFile, baseDirectory)
	local i3dFilename = xmlFile:getValue("bale.filename")

	if i3dFilename ~= nil then
		bale.i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)

		if not fileExists(bale.i3dFilename) then
			Logging.xmlError(xmlFile, "Bale i3d file could not be found '%s'", bale.i3dFilename)

			return false
		end

		bale.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
		bale.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
		bale.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
		bale.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
		bale.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)

		if bale.isRoundbale and (bale.diameter == 0 or bale.width == 0) then
			Logging.xmlError(xmlFile, "Missing size attributes for round bale. Requires width and diameter.")

			return false
		elseif not bale.isRoundbale and (bale.width == 0 or bale.height == 0 or bale.length == 0) then
			Logging.xmlError(xmlFile, "Missing size attributes for square bale. Requires width, height and length.")

			return false
		end

		bale.fillTypes = {}

		xmlFile:iterate("bale.fillTypes.fillType", function (index, key)
			local fillTypeName = xmlFile:getValue(key .. "#name")
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

			if fillTypeIndex ~= nil then
				local fillTypeData = {
					fillTypeIndex = fillTypeIndex,
					capacity = xmlFile:getValue(key .. "#capacity", 0)
				}

				table.insert(bale.fillTypes, fillTypeData)
			else
				Logging.xmlWarning(xmlFile, "Unknown fill type '%s' for bale in '%s'", fillTypeName, key)
			end
		end)
	else
		Logging.xmlError(xmlFile, "No i3D file defined in bale xml.")

		return false
	end

	return true
end

function BaleManager:update(dt)
	if g_server ~= nil then
		local numFermentations = #self.fermentations

		if numFermentations > 0 then
			local timeScale = g_currentMission:getEffectiveTimeScale()

			for i = numFermentations, 1, -1 do
				local fermentation = self.fermentations[i]
				fermentation.time = fermentation.time + dt * timeScale

				if fermentation.maxTime <= fermentation.time then
					fermentation.bale:onFermentationEnd()
					table.remove(self.fermentations, i)
				end

				local percentage = fermentation.time / fermentation.maxTime

				if math.floor(percentage * 100) ~= math.floor(fermentation.percentageSend * 100) then
					fermentation.bale:onFermentationUpdate(percentage)

					fermentation.percentageSend = percentage
				end
			end
		end
	end
end

function BaleManager:registerFermentation(bale, currentTime, maxTime)
	maxTime = maxTime * g_currentMission.missionInfo.economicDifficulty
	local fermentation = {
		bale = bale,
		time = currentTime,
		percentageSend = 0,
		maxTime = maxTime
	}

	table.insert(self.fermentations, fermentation)
end

function BaleManager:getFermentationTime(bale)
	for i = 1, #self.fermentations do
		if self.fermentations[i].bale == bale then
			return self.fermentations[i].time
		end
	end

	return 0
end

function BaleManager:removeFermentation(bale)
	for i = #self.fermentations, 1, -1 do
		if self.fermentations[i].bale == bale then
			table.remove(self.fermentations, i)
		end
	end
end

function BaleManager:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	if customEnvironment ~= nil then
		for baleIndex = 1, #self.bales do
			local bale = self.bales[baleIndex]

			if bale.isAvailable and customEnvironment == bale.customEnvironment and self:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter) then
				return baleIndex
			end
		end
	end

	for baleIndex = 1, #self.bales do
		local bale = self.bales[baleIndex]

		if bale.isAvailable and bale.customEnvironment == nil and self:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter) then
			return baleIndex
		end
	end

	return nil
end

function BaleManager:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter)
	if bale.isRoundbale == isRoundbale then
		local fillTypeMatch = false

		for j = 1, #bale.fillTypes do
			if bale.fillTypes[j].fillTypeIndex == fillTypeIndex then
				fillTypeMatch = true

				break
			end
		end

		if fillTypeMatch then
			local sizeMatch = nil

			if isRoundbale then
				sizeMatch = (width == nil or MathUtil.round(width, 2) == bale.width) and (diameter == nil or MathUtil.round(diameter, 2) == bale.diameter)
			else
				sizeMatch = (width == nil or MathUtil.round(width, 2) == bale.width) and (height == nil or MathUtil.round(height, 2) == bale.height) and (length == nil or MathUtil.round(length, 2) == bale.length)
			end

			if sizeMatch then
				return true
			end
		end
	end

	return false
end

function BaleManager:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	local baleIndex = self:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)

	if baleIndex ~= nil then
		return self.bales[baleIndex].xmlFilename, baleIndex
	end

	return nil
end

function BaleManager:getBaleCapacityByBaleIndex(baleIndex, fillTypeIndex)
	if baleIndex ~= nil then
		local bale = self.bales[baleIndex]

		if bale ~= nil then
			for j = 1, #bale.fillTypes do
				if bale.fillTypes[j].fillTypeIndex == fillTypeIndex then
					return bale.fillTypes[j].capacity
				end
			end
		end
	end

	return 0
end

function BaleManager:consoleCommandAddBale(fillTypeName, isRoundbale, width, height, length, wrapState, modName)
	local usage = "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]"

	if g_currentMission:getIsServer() then
		fillTypeName = Utils.getNoNil(fillTypeName, "STRAW")
		isRoundbale = Utils.stringToBoolean(isRoundbale)
		width = width ~= nil and tonumber(width) or nil
		height = height ~= nil and tonumber(height) or nil
		length = length ~= nil and tonumber(length) or nil

		if wrapState ~= nil and tonumber(wrapState) == nil then
			Logging.error("Invalid wrapState '%s'. Number expected", wrapState, usage)

			return
		end

		wrapState = tonumber(wrapState or 0)
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			Logging.error("Invalid fillTypeName '%s' (e.g. STRAW). Use %s", fillTypeName, usage)

			return
		end

		local baleXMLFilename, _ = self:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, height, modName)

		if baleXMLFilename ~= nil then
			local x = 0
			local y = 0
			local z = 0
			local dirX = 1
			local dirZ = 0
			local _ = nil

			if g_currentMission.controlPlayer then
				local player = g_currentMission.player

				if player ~= nil and player.isControlled and player.rootNode ~= nil and player.rootNode ~= 0 then
					x, y, z = getWorldTranslation(player.rootNode)
					dirZ = -math.cos(player.rotY)
					dirX = -math.sin(player.rotY)
				end
			elseif g_currentMission.controlledVehicle ~= nil then
				x, y, z = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
				dirX, _, dirZ = localDirectionToWorld(g_currentMission.controlledVehicle.rootNode, 0, 0, 1)
			else
				x, y, z = getWorldTranslation(getCamera())
				dirX, _, dirZ = localDirectionToWorld(getCamera(), 0, 0, -1)
			end

			z = z + dirZ * 4
			x = x + dirX * 4
			y = y + 5
			local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
			local baleObject = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())

			if baleObject:loadFromConfigXML(baleXMLFilename, x, y, z, 0, ry, 0) then
				baleObject:setFillType(fillTypeIndex)
				baleObject:setFillLevel(99999)
				baleObject:setWrappingState(wrapState)
				baleObject:setOwnerFarmId(g_currentMission:getFarmId(), true)
				baleObject:register()
			end

			return string.format("Created bale at (%.2f, %.2f, %.2f). For specific bales use: %s", x, y, z, usage)
		else
			Logging.error("Could not find bale for given size attributes! (%s)", usage)
			self:consoleCommandListBales()
		end
	else
		Logging.error("Command only allowed on server!")
	end
end

function BaleManager:consoleCommandListBales()
	print("Available bale types:")

	for _, bale in ipairs(self.bales) do
		local attributes = {
			bale.xmlFilename
		}

		table.insert(attributes, string.format("isRoundbale=%s", bale.isRoundbale))

		for _, sizeProperty in ipairs({
			"width",
			"height",
			"length",
			"diameter"
		}) do
			if bale[sizeProperty] ~= nil and bale[sizeProperty] ~= 0 then
				table.insert(attributes, string.format("%s=%s", sizeProperty, bale[sizeProperty]))
			end
		end

		log(table.concat(attributes, "  "))

		local fillTypeNames = {}

		for _, fillTypeData in ipairs(bale.fillTypes) do
			table.insert(fillTypeNames, g_fillTypeManager:getFillTypeNameByIndex(fillTypeData.fillTypeIndex))
		end

		log("    fillTypes: ", table.concat(fillTypeNames, "  "))
	end
end

function BaleManager.registerBaleXMLPaths(schema)
	schema:register(XMLValueType.STRING, "bale.filename", "Path to i3d file")
	schema:register(XMLValueType.BOOL, "bale.size#isRoundbale", "Bale is a roundbale", true)
	schema:register(XMLValueType.FLOAT, "bale.size#width", "Bale Width", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#height", "Bale Height", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#length", "Bale Length", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#diameter", "Bale Diameter", 0)
	schema:register(XMLValueType.NODE_INDEX, "bale.mountableObject#triggerNode", "Trigger node")
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceAcceleration", "Acceleration force", 4)
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceLimitScale", "Force limit scale", 1)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeY", "Joint is free in Y direction", false)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeX", "Joint is free in X direction", false)
	schema:register(XMLValueType.STRING, "bale.uvId", "Specify that this bale model has a custom UV. This will result in baleWrapper to replace the bale if the UV is different to the defined one in the baleWrapper. So the baleWrapper will always use a bale with a UV that matches the wrapping texture.", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, "bale.baleMeshes.baleMesh(?)#node", "Path to mesh node")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#supportsWrapping", "Defines if the mesh is hidden while wrapping or not")
	schema:register(XMLValueType.STRING, "bale.baleMeshes.baleMesh(?)#fillTypes", "If defined this mesh is only visible if any of this fillTypes is set")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#isTensionBeltMesh", "Defines if this mesh is detected for tension belt calculation", false)
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#name", "Name of fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#capacity", "Fill level of bale with this fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#mass", "Mass of bale with this fill type", 500)
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?)#supportsWrapping", "Wrapping is allowed while this type is used")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).diffuse#filename", "Diffuse texture to apply to all mesh nodes")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).normal#filename", "Normal texture to apply to all mesh nodes")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).specular#filename", "Specular texture to apply to all mesh nodes")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).alpha#filename", "Alpha texture to apply to all mesh nodes")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).fermenting#outputFillType", "Output fill type after fermenting")
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?).fermenting#requiresWrapping", "Wrapping is required to start fermenting", true)
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?).fermenting#time", "Fermenting time in ingame days which represent months", 1)
	schema:register(XMLValueType.STRING, "bale.packedBale#singleBale", "Path to single bale xml filename")
	schema:register(XMLValueType.NODE_INDEX, "bale.packedBale.singleBale(?)#node", "Single bale spawn node")
end

function BaleManager.registerMapBalesXMLPaths(schema)
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#filename", "Path to bale xml")
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#isAvailable", "Bale is available for all balers to spawn")
end

g_baleManager = BaleManager.new()
