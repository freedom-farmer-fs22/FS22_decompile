LicensePlateManager = {
	PLATE_TYPE = {}
}
LicensePlateManager.PLATE_TYPE.SQUARISH = 0
LicensePlateManager.PLATE_TYPE.ELONGATED = 1
LicensePlateManager.PLATE_POSITION = {
	NONE = 0,
	FRONT = 1,
	BACK = 2,
	ANY = 3
}
LicensePlateManager.CHARACTER_TYPE = {
	NUMERICAL = 0,
	ALPHABETICAL = 1,
	SPECIAL = 2
}
LicensePlateManager.PLACEMENT_OPTION = {
	NONE = 0,
	BOTH = 1,
	BACK_ONLY = 2
}
LicensePlateManager.PLACEMENT_OPTION_TEXT = {
	[LicensePlateManager.PLACEMENT_OPTION.NONE] = "ui_licensePlatePlacementNone",
	[LicensePlateManager.PLACEMENT_OPTION.BOTH] = "ui_licensePlatePlacementBoth",
	[LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY] = "ui_licensePlatePlacementBackOnly"
}
LicensePlateManager.SEND_NUM_BITS_VARIATION = 4
LicensePlateManager.SEND_NUM_BITS_COLOR = 6
LicensePlateManager.SEND_NUM_BITS_CHARACTER = 8
LicensePlateManager.SEND_NUM_BITS_PLACEMENT = 2
LicensePlateManager.xmlSchema = nil
local LicensePlateManager_mt = Class(LicensePlateManager, AbstractManager)

function LicensePlateManager.new(customMt)
	return AbstractManager.new(customMt or LicensePlateManager_mt)
end

function LicensePlateManager:initDataStructures()
	self.licensePlates = {}
	self.colorConfigurations = {}
	self.licensePlatesAvailable = false
	self.sharedLoadRequestIds = {}
end

function LicensePlateManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	LicensePlateManager:superClass().loadMapData(self)

	self.baseDirectory = baseDirectory

	LicensePlateManager.createLicensePlateXMLSchema()

	local filename = getXMLString(xmlFile, "map.licensePlates#filename")

	if filename ~= nil then
		local xmlFilename = Utils.getFilename(filename, baseDirectory)
		self.licensePlateXML = XMLFile.load("mapLicensePlates", xmlFilename, LicensePlateManager.xmlSchema)

		if self.licensePlateXML ~= nil then
			self.xmlReferences = 0

			self:loadLicensePlatesFromXML(self.licensePlateXML, baseDirectory)

			if self.licensePlateXML ~= nil and self.xmlReferences == 0 then
				self.licensePlateXML:delete()

				self.licensePlateXML = nil
			end
		end
	end

	return true
end

function LicensePlateManager:unloadMapData()
	for i = 1, #self.licensePlates do
		self.licensePlates[i]:delete()
	end

	if self.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(self.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end

		self.sharedLoadRequestIds = nil
	end

	if self.licensePlateXML ~= nil then
		self.licensePlateXML:delete()

		self.licensePlateXML = nil
	end

	LicensePlateManager:superClass().unloadMapData(self)
end

function LicensePlateManager:loadLicensePlatesFromXML(xmlFile, baseDirectory)
	local customEnvironment, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
	self.fontName = xmlFile:getValue("licensePlates.font#name", "GENERIC")
	self.customEnvironment = customEnvironment

	xmlFile:iterate("licensePlates.licensePlate", function (_, plateKey)
		local filename = xmlFile:getValue(plateKey .. "#filename")

		if filename ~= nil then
			self.xmlReferences = self.xmlReferences + 1
			filename = Utils.getFilename(filename, baseDirectory)
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.licensePlateI3DFileLoaded, self, {
				filename,
				xmlFile,
				plateKey,
				customEnvironment
			})

			table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
		else
			Logging.xmlError(xmlFile, "Missing filename for license plate '%s'", plateKey)
		end
	end)

	self.shaderParameterPlate = xmlFile:getValue("licensePlates.colorConfigurations#shaderParameter", "colorMat0")
	self.shaderParameterCharacters = xmlFile:getValue("licensePlates.colorConfigurations#shaderParameterCharacters", "colorScale")
	self.useDefaultColors = xmlFile:getValue("licensePlates.colorConfigurations#useDefaultColors", false)
	self.defaultColorIndex = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorIndex")
	self.defaultColorMaxBrightness = xmlFile:getValue("licensePlates.colorConfigurations#defaultColorMaxBrightness", 0.55)
	local defaultConfiguration = 1

	xmlFile:iterate("licensePlates.colorConfigurations.colorConfiguration", function (index, baseKey)
		local name = xmlFile:getValue(baseKey .. "#name", "", self.customEnvironment, false)
		local color = xmlFile:getValue(baseKey .. "#color", nil, true)
		local isDefault = xmlFile:getValue(baseKey .. "#isDefault", false)

		if color ~= nil then
			if isDefault then
				defaultConfiguration = index
			end

			table.insert(self.colorConfigurations, {
				name = name,
				color = color,
				isDefault = isDefault
			})
		end
	end)

	if self.defaultColorIndex ~= nil then
		self.defaultColorIndex = self.defaultColorIndex + #self.colorConfigurations
	else
		self.defaultColorIndex = defaultConfiguration
	end

	self.colors = {}

	for j = 1, #self.colorConfigurations do
		table.insert(self.colors, self.colorConfigurations[j])
	end

	if self.useDefaultColors then
		for j = 1, #g_vehicleColors do
			local color = g_vehicleColors[j]
			local colorData = {
				name = g_i18n:convertText(color.name),
				color = {
					1,
					1,
					1,
					1
				}
			}

			if color.r ~= nil and color.g ~= nil and color.b ~= nil then
				colorData.color = {
					color.r,
					color.g,
					color.b,
					1
				}
			elseif color.brandColor ~= nil then
				colorData.color = g_brandColorManager:getBrandColorByName(color.brandColor)
			end

			local brightness = MathUtil.getBrightnessFromColor(colorData.color[1], colorData.color[2], colorData.color[3])

			if brightness < self.defaultColorMaxBrightness then
				table.insert(self.colors, colorData)
			end
		end
	end

	self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BOTH
	local placementStr = xmlFile:getValue("licensePlates.placement#defaultType")

	if placementStr ~= nil then
		self.defaultPlacementIndex = LicensePlateManager.PLACEMENT_OPTION[placementStr:upper()] or self.defaultPlacementIndex
	end
end

function LicensePlateManager:licensePlateI3DFileLoaded(i3dNode, failedReason, args)
	local filename, xmlFile, plateKey, customEnvironment = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local node = xmlFile:getValue(plateKey .. "#node", nil, i3dNode)

		if node ~= nil then
			unlink(node)

			local licensePlate = LicensePlate.new()

			if licensePlate:loadFromXML(node, filename, customEnvironment, xmlFile, plateKey) then
				table.insert(self.licensePlates, licensePlate)
			end
		end

		delete(i3dNode)
	end

	self.xmlReferences = self.xmlReferences - 1

	if self.xmlReferences == 0 then
		xmlFile:delete()

		self.licensePlatesAvailable = #self.licensePlates > 0

		if xmlFile == self.licensePlateXML then
			self.licensePlateXML = nil
		end
	end
end

function LicensePlateManager:getAreLicensePlatesAvailable()
	return self.licensePlatesAvailable and g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end

function LicensePlateManager:getLicensePlate(preferedType, includeFrame)
	local licensePlate = self.licensePlates[1]

	for i = 1, #self.licensePlates do
		if self.licensePlates[i].type == preferedType then
			licensePlate = self.licensePlates[i]
		end
	end

	if licensePlate ~= nil then
		return licensePlate:clone(includeFrame)
	end
end

function LicensePlateManager:getLicensePlateValues(licensePlate, variationIndex)
	local variation = licensePlate.variations[variationIndex]

	if variation ~= nil then
		return variation.values
	end
end

function LicensePlateManager:getRandomLicensePlateData()
	local licensePlate = self.licensePlates[1]

	if licensePlate ~= nil then
		local variationIndex = 1
		local characters = licensePlate:getRandomCharacters(variationIndex)
		local colorIndex = self.defaultColorIndex

		return {
			variation = variationIndex,
			characters = characters,
			colorIndex = colorIndex,
			placementIndex = self:getDefaultPlacementIndex()
		}
	end

	return {
		variation = 1,
		placementIndex = self:getDefaultPlacementIndex()
	}
end

function LicensePlateManager:getAvailableColors()
	return self.colors, self.defaultColorIndex
end

function LicensePlateManager:getDefaultPlacementIndex()
	return self.defaultPlacementIndex
end

function LicensePlateManager:getFont()
	return g_materialManager:getFontMaterial(self.fontName, self.customEnvironment)
end

function LicensePlateManager.readLicensePlateData(streamId, connection)
	local licensePlateData = {
		variation = 1,
		placementIndex = 1
	}
	local valid = streamReadBool(streamId)

	if valid then
		licensePlateData.variation = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		licensePlateData.colorIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_COLOR)
		licensePlateData.placementIndex = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)
		local font = g_licensePlateManager:getFont()
		licensePlateData.characters = {}
		local numCharacters = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER)

		for i = 1, numCharacters do
			local index = streamReadUIntN(streamId, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
			local character = font:getCharacterByCharacterIndex(index)

			table.insert(licensePlateData.characters, character)
		end
	end

	return licensePlateData
end

function LicensePlateManager.writeLicensePlateData(streamId, connection, licensePlateData)
	if streamWriteBool(streamId, licensePlateData ~= nil and licensePlateData.variation ~= nil and licensePlateData.characters ~= nil and licensePlateData.colorIndex ~= nil and licensePlateData.placementIndex ~= nil) then
		streamWriteUIntN(streamId, licensePlateData.variation, LicensePlateManager.SEND_NUM_BITS_VARIATION)
		streamWriteUIntN(streamId, licensePlateData.colorIndex, LicensePlateManager.SEND_NUM_BITS_COLOR)
		streamWriteUIntN(streamId, licensePlateData.placementIndex, LicensePlateManager.SEND_NUM_BITS_PLACEMENT)

		local font = g_licensePlateManager:getFont()

		streamWriteUIntN(streamId, #licensePlateData.characters, LicensePlateManager.SEND_NUM_BITS_CHARACTER)

		for i = 1, #licensePlateData.characters do
			local index = font:getCharacterIndexByCharacter(licensePlateData.characters[i])

			streamWriteUIntN(streamId, index, LicensePlateManager.SEND_NUM_BITS_CHARACTER)
		end
	end
end

function LicensePlateManager.createLicensePlateXMLSchema()
	if LicensePlateManager.xmlSchema == nil then
		local schema = XMLSchema.new("mapLicensePlates")

		LicensePlate.registerXMLPaths(schema, "licensePlates.licensePlate(?)")
		schema:register(XMLValueType.STRING, "licensePlates.font#name", "License plate font name", "GENERIC")
		schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#shaderParameter", "Color shader parameter", "colorMat0")
		schema:register(XMLValueType.STRING, "licensePlates.colorConfigurations#shaderParameterCharacters", "Color shader parameter of characters", "colorSale")
		schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations#useDefaultColors", "License plate can be colored with all available default colors", false)
		schema:register(XMLValueType.INT, "licensePlates.colorConfigurations#defaultColorIndex", "Default selected color")
		schema:register(XMLValueType.FLOAT, "licensePlates.colorConfigurations#defaultColorMaxBrightness", "Default colors with higher brightness will be skipped", 0.55)
		schema:register(XMLValueType.L10N_STRING, "licensePlates.colorConfigurations.colorConfiguration(?)#name", "Name of color to display")
		schema:register(XMLValueType.COLOR, "licensePlates.colorConfigurations.colorConfiguration(?)#color", "Color values")
		schema:register(XMLValueType.BOOL, "licensePlates.colorConfigurations.colorConfiguration(?)#isDefault", "Color is default selected")
		schema:register(XMLValueType.STRING, "licensePlates.placement#defaultType", "Default type of placement (none/both/back_only)", "both")

		LicensePlateManager.xmlSchema = schema
	end
end

g_licensePlateManager = LicensePlateManager.new()
