PlayerStyle = {}
local PlayerStyle_mt = Class(PlayerStyle)
PlayerStyle.ATLAS_COLUMNS = 16
PlayerStyle.ATLAS_ROWS = 16
PlayerStyle.SEND_NUM_BITS = 7

function PlayerStyle.newRandomHelper()
	local style = PlayerStyle.new()

	style:loadConfigurationXML(g_helperManager:getRandomHelperModel())

	return style
end

function PlayerStyle.newHelper(helper)
	local style = PlayerStyle.new()

	style:loadConfigurationXML(helper.modelFilename)

	return style
end

function PlayerStyle.defaultStyle()
	local style = PlayerStyle.new()
	style.xmlFilename = "dataS/character/humans/player/player01.xml"
	style.bottomConfig.selection = 1
	style.topConfig.selection = 4
	style.footwearConfig.selection = 1
	style.hairStyleConfig.selection = 2
	style.hairStyleConfig.color = 6
	style.faceConfig.selection = 1

	return style
end

function PlayerStyle.new(customMt)
	local self = setmetatable({}, customMt or PlayerStyle_mt)

	local function createConfig(name, setter, listMappingGetter, colorSetter)
		self[name] = {
			color = 1,
			selection = 0,
			items = {},
			setter = setter,
			listMappingGetter = listMappingGetter,
			colorSetter = colorSetter
		}
	end

	createConfig("beardConfig", self.setBeard, self.getPossibleBeards, self.setHairItemColor)
	createConfig("bottomConfig", self.setBottom, self.getPossibleBottoms, self.setItemColor)
	createConfig("faceConfig", self.setFace, self.getPossibleFaces, self.setItemColor)
	createConfig("footwearConfig", self.setFootwear, self.getPossibleFootwear, self.setItemColor)
	createConfig("glassesConfig", self.setGlasses, self.getPossibleGlasses, self.setItemColor)
	createConfig("glovesConfig", self.setGloves, self.getPossibleGloves, self.setItemColor)
	createConfig("hairStyleConfig", self.setHairStyle, self.getPossibleHairStyles, self.setHairItemColor)
	createConfig("headgearConfig", self.setHeadgear, self.getPossibleHeadgear, self.setItemColor)
	createConfig("mustacheConfig", self.setMustache, self.getPossibleMustaches, self.setHairItemColor)
	createConfig("onepieceConfig", self.setOnepiece, self.getPossibleOnepieces, self.setItemColor)
	createConfig("topConfig", self.setTop, self.getPossibleTops, self.setItemColor)
	createConfig("facegearConfig", self.setFacegear)

	self.beardConfig.color = self.hairStyleConfig.color
	self.mustacheConfig.color = self.hairStyleConfig.color
	self.faceConfig.selection = 1
	self.hairStyleConfig.selection = 2
	self.disabledOptionsForSelection = {}
	self.playerName = ""
	self.presets = {}
	self.isConfigurationLoaded = false

	return self
end

function PlayerStyle:delete()
end

function PlayerStyle:copyFrom(other)
	if other == self then
		return
	end

	self.xmlFilename = other.xmlFilename
	self.filename = other.filename
	self.atlasFilename = other.atlasFilename
	self.playerName = other.playerName
	self.attachPoints = other.attachPoints

	local function copyConfig(name)
		if other[name] ~= nil then
			self[name] = table.copy(other[name])
		end
	end

	copyConfig("beardConfig")
	copyConfig("bottomConfig")
	copyConfig("faceConfig")
	copyConfig("footwearConfig")
	copyConfig("glassesConfig")
	copyConfig("glovesConfig")
	copyConfig("hairStyleConfig")
	copyConfig("headgearConfig")
	copyConfig("mustacheConfig")
	copyConfig("onepieceConfig")
	copyConfig("topConfig")
	copyConfig("facegearConfig")

	self.beardConfig.color = self.hairStyleConfig.color
	self.mustacheConfig.color = self.hairStyleConfig.color

	if other.isConfigurationLoaded then
		self.faceNeutralDiffuseColor = other.faceNeutralDiffuseColor
		self.bodyParts = other.bodyParts
		self.bodyPartIndexByName = other.bodyPartIndexByName
		self.hatHairstyleIndex = other.hatHairstyleIndex
		self.presets = other.presets
		self.isConfigurationLoaded = true

		self:updateDisabledOptions()
	else
		self.isConfigurationLoaded = false
	end
end

function PlayerStyle:copyMinimalFrom(other)
	if other == self then
		return
	end

	self.xmlFilename = other.xmlFilename
	self.playerName = other.playerName
	self.isConfigurationLoaded = false

	local function copyConfig(name)
		if other[name] ~= nil then
			self[name].selection = other[name].selection
			self[name].color = other[name].color
		end
	end

	copyConfig("beardConfig")
	copyConfig("bottomConfig")
	copyConfig("faceConfig")
	copyConfig("footwearConfig")
	copyConfig("glassesConfig")
	copyConfig("glovesConfig")
	copyConfig("hairStyleConfig")
	copyConfig("headgearConfig")
	copyConfig("mustacheConfig")
	copyConfig("onepieceConfig")
	copyConfig("topConfig")
	copyConfig("facegearConfig")

	self.beardConfig.color = self.hairStyleConfig.color
	self.mustacheConfig.color = self.hairStyleConfig.color
end

function PlayerStyle:loadConfigurationXML(xmlFilename)
	local xmlFile = XMLFile.load("player", xmlFilename)

	if xmlFile == nil then
		Logging.fatal("Player config does not exist at %s", xmlFilename)
	end

	local restoreSelection = nil
	self.xmlFilename = xmlFilename
	local rootKey = "player.character.playerStyle"
	self.filename = xmlFile:getString("player.filename")
	self.atlasFilename = xmlFile:getString("player.character.playerStyle#atlas")
	self.skeletonRootIndex = xmlFile:getInt("player.character.thirdPerson#skeleton") or 0
	self.attachPoints = {}

	xmlFile:iterate(rootKey .. ".attachPoints.attachPoint", function (_, key)
		local name = xmlFile:getString(key .. "#name")
		local node = self:parseIndex(xmlFile:getString(key .. "#node"))
		self.attachPoints[name] = node
	end)

	if self.faceConfig.selection ~= 0 and self.faceConfig.items[self.faceConfig.selection] ~= nil then
		restoreSelection = self.faceConfig.items[self.faceConfig.selection].name
	end

	self.faceConfig.items = {}
	self.facesByName = {}

	xmlFile:iterate(rootKey .. ".faces.face", function (_, key)
		local index = xmlFile:getString(key .. "#node")
		local name = xmlFile:getString(key .. "#name")
		local skinColor = string.getVectorN(xmlFile:getString(key .. "#skinColor"), 3)
		local uvSlot = xmlFile:getInt(key .. "#uvSlot")
		local filename = xmlFile:getString(key .. "#filename")
		local attachPoint = xmlFile:getString(key .. "#attachPoint") or ""
		local attachNode = self.attachPoints[attachPoint]

		if attachNode == nil then
			Logging.xmlError(xmlFile, "Attach point with name '%s' does not exist for %s", attachPoint, name)

			return
		end

		table.insert(self.faceConfig.items, {
			numColors = 0,
			index = index,
			name = name,
			skinColor = skinColor,
			uvSlot = uvSlot,
			filename = filename,
			attachNode = attachNode
		})

		self.facesByName[name] = #self.faceConfig.items

		if name == restoreSelection then
			self.faceConfig.selection = #self.faceConfig.items
		end
	end)

	self.faceNeutralDiffuseColor = string.getVectorN(xmlFile:getString(rootKey .. ".faces#neutralDiffuse"), 3)
	self.bodyParts = {}
	self.bodyPartIndexByName = {}

	xmlFile:iterate(rootKey .. ".bodyParts.bodyPart", function (_, key)
		local index = self:parseIndex(xmlFile:getString(key .. "#node"))
		local name = xmlFile:getString(key .. "#name")

		table.insert(self.bodyParts, {
			index = index,
			name = name
		})

		self.bodyPartIndexByName[name] = #self.bodyParts
	end)
	self:loadColors(xmlFile, rootKey .. ".colors.hair.color", "hairColors")
	self:loadColors(xmlFile, rootKey .. ".colors.clothing.color", "defaultClothingColors")

	local topsByName = self:loadClothing(xmlFile, rootKey .. ".tops", "top", "topConfig", true)
	local bottomsByName = self:loadClothing(xmlFile, rootKey .. ".bottoms", "bottom", "bottomConfig", true)
	local footwearByName = self:loadClothing(xmlFile, rootKey .. ".footwear", "footwear", "footwearConfig", true)
	local glovesByName = self:loadClothing(xmlFile, rootKey .. ".gloves", "glove", "glovesConfig", true)
	local glassesByName = self:loadClothing(xmlFile, rootKey .. ".glasses", "glasses", "glassesConfig")
	local onepiecesByName = self:loadClothing(xmlFile, rootKey .. ".onepieces", "onepiece", "onepieceConfig", true)
	local facegearByName = self:loadClothing(xmlFile, rootKey .. ".facegear", "facegear", "facegearConfig", true, false, true)
	local headgearByName = self:loadClothing(xmlFile, rootKey .. ".headgear", "headgear", "headgearConfig", true, false, false, true)

	self:loadClothing(xmlFile, rootKey .. ".hairStyles", "hairStyle", "hairStyleConfig", true, true, nil, , true)
	self:loadClothing(xmlFile, rootKey .. ".beards", "beard", "beardConfig", true, true, true)
	self:loadClothing(xmlFile, rootKey .. ".mustaches", "mustache", "mustacheConfig", true, true, true)

	self.presets = {}

	xmlFile:iterate(rootKey .. ".presets.preset", function (index, key)
		local text = xmlFile:getString(key .. "#text")
		local name = xmlFile:getString(key .. "#name")
		local brand = nil

		if g_brandManager ~= nil then
			brand = g_brandManager:getBrandByName(xmlFile:getString(key .. "#brand"))
		end

		local preset = {
			name = name,
			text = text,
			uvSlot = xmlFile:getInt(key .. "#uvSlot"),
			brand = brand,
			extraContentId = xmlFile:getString(key .. "#extraContentId"),
			isSelectable = Utils.getNoNil(xmlFile:getBool(key .. "#isSelectable"), true)
		}

		local function getOrNul(list, itemKey)
			if itemKey == nil then
				return nil
			end

			if list[itemKey] ~= nil then
				return list[itemKey]
			end

			for _, face in ipairs(self.faceConfig.items) do
				local item = list[itemKey .. "_" .. face.name]

				if item ~= nil then
					return item
				end
			end

			return 0
		end

		local faceName = xmlFile:getString(key .. ".face#name")

		if faceName ~= nil then
			preset.face = self.facesByName[faceName]
		end

		preset.top = getOrNul(topsByName, xmlFile:getString(key .. ".top#name"))
		preset.bottom = getOrNul(bottomsByName, xmlFile:getString(key .. ".bottom#name"))
		preset.onepiece = getOrNul(onepiecesByName, xmlFile:getString(key .. ".onepiece#name"))
		preset.glasses = getOrNul(glassesByName, xmlFile:getString(key .. ".glasses#name"))
		preset.gloves = getOrNul(glovesByName, xmlFile:getString(key .. ".gloves#name"))
		preset.headgear = getOrNul(headgearByName, xmlFile:getString(key .. ".headgear#name"))
		preset.footwear = getOrNul(footwearByName, xmlFile:getString(key .. ".footwear#name"))
		preset.facegear = getOrNul(facegearByName, xmlFile:getString(key .. ".facegear#name"))

		table.insert(self.presets, preset)
	end)

	self.isConfigurationLoaded = true

	xmlFile:delete()
end

function PlayerStyle:loadClothing(xmlFile, rootKey, itemKey, configName, isColorable, isHair, isFaceSpecific, isHeadgear, resetToOne)
	local config = self[configName]
	local restoreSelectionName, restoreSelectionIndex = nil

	if config.selection ~= 0 and config.selection ~= nil and config.items[config.selection] ~= nil then
		restoreSelectionName = config.items[config.selection].name
		restoreSelectionIndex = config.selection
	else
		restoreSelectionIndex = config.selection
	end

	config.selection = 0

	if resetToOne then
		config.selection = 1
	end

	local nameToItemList = {}
	config.items = {}

	xmlFile:iterate(rootKey .. "." .. itemKey, function (_, key)
		local index = xmlFile:getString(key .. "#node")
		local index2 = xmlFile:getString(key .. "#node2")
		local itemName = xmlFile:getString(key .. "#name")
		local text = xmlFile:getString(key .. "#text")
		local extent = xmlFile:getString(key .. "#extent")
		local hidden = xmlFile:getBool(key .. "#hidden")
		local uvSlot = xmlFile:getInt(key .. "#uvSlot")
		local extraContentId = xmlFile:getString(key .. "#extraContentId")
		local hideGlasses = xmlFile:getBool(key .. "#hideGlasses", false)
		local isForestryItem = xmlFile:getBool(key .. "#isForestryItem", false)
		local brand = nil

		if g_brandManager ~= nil then
			brand = g_brandManager:getBrandByName(xmlFile:getString(key .. "#brand"))
		end

		local filename = xmlFile:getString(key .. "#filename")
		local attachPoint = xmlFile:getString(key .. "#attachPoint") or ""
		local attachNode = self.attachPoints[attachPoint]

		if attachNode == nil then
			Logging.xmlError(xmlFile, "Attach point with name '%s' does not exist for %s", attachPoint, itemName)

			return
		end

		local item = {
			filename = filename,
			index = index,
			index2 = index2,
			attachNode = attachNode,
			name = itemName,
			text = text,
			extent = extent,
			hidden = hidden or false,
			hiddenBodyParts = {},
			disabledOptions = {},
			uvSlot = uvSlot,
			itemIndex = #config.items + 1,
			hideGlasses = hideGlasses,
			brand = brand,
			extraContentId = extraContentId,
			isForestryItem = isForestryItem
		}

		if isHair then
			item.forHat = xmlFile:getBool(key .. "#forHat")

			if item.forHat then
				self.hatHairstyleIndex = #config.items + 1
			end
		end

		if isFaceSpecific then
			local face = xmlFile:getString(key .. "#face")

			if face ~= nil then
				item.face = self.facesByName[face]
			end

			if xmlFile:hasProperty(key .. ".transform") then
				item.transforms = {}

				xmlFile:iterate(key .. ".transform", function (_, tKey)
					local transform = {
						face = self.facesByName[xmlFile:getString(tKey .. "#face")],
						translation = xmlFile:getVector(tKey .. "#translation"),
						rotation = xmlFile:getVector(tKey .. "#rotation"),
						scale = xmlFile:getVector(tKey .. "#scale")
					}
					item.transforms[transform.face] = transform
				end)
			end
		end

		item.numColors = xmlFile:getInt(key .. "#colorable", 0)

		if item.numColors >= 1 then
			if xmlFile:hasProperty(key .. ".colors") then
				item.colors = {}

				xmlFile:iterate(key .. ".colors.color", function (_, cKey)
					local primary = string.getVectorN(xmlFile:getString(cKey .. "#primary"), 4)
					local secondary = string.getVectorN(xmlFile:getString(cKey .. "#secondary"), 4)

					table.insert(item.colors, {
						primary = primary,
						secondary = secondary
					})
				end)
			else
				item.colors = self.defaultClothingColors
			end

			local defaultPrimary = xmlFile:getVector(key .. "#defaultPrimary", 4)

			if defaultPrimary ~= nil then
				local colorIndex = 0

				for i, color in ipairs(item.colors) do
					if table.equals(color.primary, defaultPrimary) then
						colorIndex = i

						break
					end
				end

				if colorIndex == 0 then
					Logging.xmlWarning(xmlFile, "Item %s has no valid default color. The color must exist in its palette.", itemName)
				else
					item.defaultColor = colorIndex
				end
			end
		end

		if isHair then
			item.numColors = 1
			item.colors = self.hairColors
		end

		xmlFile:iterate(key .. ".hidesBodypart", function (_, bpKey)
			local name = xmlFile:getString(bpKey .. "#name")

			if name ~= nil and self.bodyPartIndexByName[name] ~= nil then
				table.insert(item.hiddenBodyParts, self.bodyPartIndexByName[name])
			end
		end)
		xmlFile:iterate(key .. ".disablesOption", function (_, doKey)
			local name = xmlFile:getString(doKey .. "#name")

			if name ~= nil then
				item.disabledOptions[name] = name
			end
		end)
		xmlFile:iterate(key .. ".extent", function (_, eKey)
			if item.extents == nil then
				item.extents = {}
			end

			local node = xmlFile:getString(eKey .. "#node")
			local typ = xmlFile:getString(eKey .. "#type")
			item.extents[typ] = node
		end)

		item.belt = xmlFile:getString(key .. ".belt#node")
		item.beltHidden = xmlFile:getBool(key .. "#beltHidden")

		table.insert(config.items, item)

		nameToItemList[itemName] = #config.items

		if itemName == restoreSelectionName then
			config.selection = #config.items
		end
	end)

	local emptyUVSlot = xmlFile:getInt(rootKey .. "#nullUVSlot")

	if emptyUVSlot ~= nil then
		config.items[0] = {
			numColors = 0,
			uvSlot = emptyUVSlot
		}
	end

	if (config.selection == 0 or config.selection == 1 and resetToOne) and restoreSelectionName == nil and restoreSelectionIndex ~= 0 then
		local minimum = 1

		if config.items[0] ~= nil then
			minimum = 0
		end

		config.selection = math.min(math.max(restoreSelectionIndex or 0, minimum), #config.items)
	end

	return nameToItemList
end

function PlayerStyle:parseIndex(index)
	if index == nil then
		return nil
	end

	if index:sub(1, 2) == self.skeletonRootIndex .. "|" then
		return {
			isSkeleton = true,
			path = index:sub(3)
		}
	else
		return {
			isSkeleton = false,
			path = index:sub(3)
		}
	end
end

function PlayerStyle:loadColors(xmlFile, rootKey, listName)
	self[listName] = {}

	xmlFile:iterate(rootKey, function (index, key)
		local primary = string.getVectorN(xmlFile:getString(key .. "#primary"), 4)
		local secondary = string.getVectorN(xmlFile:getString(key .. "#secondary"), 4)

		if primary ~= nil then
			table.insert(self[listName], {
				primary = primary,
				secondary = secondary
			})

			if xmlFile:getBool(key .. "#default") then
				self[listName].default = #self[listName]
			end
		end
	end)
end

function PlayerStyle:saveToXMLFile(xmlFile, key)
	xmlFile:setString(key .. "#filename", self.xmlFilename)

	local function saveConfig(configName)
		local selection = self[configName].selection

		xmlFile:setInt(key .. "#" .. configName, selection)

		if selection ~= 0 and self[configName].color ~= nil then
			xmlFile:setInt(key .. "#" .. configName .. "Color", self[configName].color)
		end
	end

	saveConfig("beardConfig")
	saveConfig("bottomConfig")
	saveConfig("faceConfig")
	saveConfig("footwearConfig")
	saveConfig("glassesConfig")
	saveConfig("glovesConfig")
	saveConfig("hairStyleConfig")
	saveConfig("headgearConfig")
	saveConfig("mustacheConfig")
	saveConfig("onepieceConfig")
	saveConfig("topConfig")
	saveConfig("facegearConfig")
end

function PlayerStyle:loadFromXMLFile(xmlFile, key)
	self.xmlFilename = xmlFile:getString(key .. "#filename")

	local function loadConfig(configName)
		local selection = xmlFile:getInt(key .. "#" .. configName, self[configName].selection)
		self[configName].selection = selection

		if selection ~= 0 then
			self[configName].color = xmlFile:getInt(key .. "#" .. configName .. "Color", self[configName].color)
		end
	end

	loadConfig("beardConfig")
	loadConfig("bottomConfig")
	loadConfig("faceConfig")
	loadConfig("footwearConfig")
	loadConfig("glassesConfig")
	loadConfig("glovesConfig")
	loadConfig("hairStyleConfig")
	loadConfig("headgearConfig")
	loadConfig("mustacheConfig")
	loadConfig("onepieceConfig")
	loadConfig("topConfig")
	loadConfig("facegearConfig")

	self.beardConfig.color = self.hairStyleConfig.color
	self.mustacheConfig.color = self.hairStyleConfig.color
end

function PlayerStyle:readStream(streamId, connection)
	self.xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	local function readConfig(configName)
		local selection = streamReadUIntN(streamId, PlayerStyle.SEND_NUM_BITS)
		self[configName].selection = selection
		self[configName].color = self:readStreamColor(streamId)
	end

	readConfig("beardConfig")
	readConfig("bottomConfig")
	readConfig("faceConfig")
	readConfig("footwearConfig")
	readConfig("glassesConfig")
	readConfig("glovesConfig")
	readConfig("hairStyleConfig")
	readConfig("headgearConfig")
	readConfig("mustacheConfig")
	readConfig("onepieceConfig")
	readConfig("topConfig")
	readConfig("facegearConfig")

	self.playerName = streamReadString(streamId)
end

function PlayerStyle:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))

	local function writeConfig(configName)
		local selection = self[configName].selection

		streamWriteUIntN(streamId, selection, PlayerStyle.SEND_NUM_BITS)
		self:writeStreamColor(streamId, self[configName].color)
	end

	writeConfig("beardConfig")
	writeConfig("bottomConfig")
	writeConfig("faceConfig")
	writeConfig("footwearConfig")
	writeConfig("glassesConfig")
	writeConfig("glovesConfig")
	writeConfig("hairStyleConfig")
	writeConfig("headgearConfig")
	writeConfig("mustacheConfig")
	writeConfig("onepieceConfig")
	writeConfig("topConfig")
	writeConfig("facegearConfig")
	streamWriteString(streamId, self.playerName or "")
end

function PlayerStyle:readStreamColor(streamId)
	return streamReadUIntN(streamId, PlayerStyle.SEND_NUM_BITS)
end

function PlayerStyle:writeStreamColor(streamId, color)
	streamWriteUIntN(streamId, color or 1, PlayerStyle.SEND_NUM_BITS)
end

function PlayerStyle:loadConfigurationIfRequired()
	if not self.isConfigurationLoaded then
		self:loadConfigurationXML(self.xmlFilename)
	end
end

function PlayerStyle:getRequiredNodeFiles()
	local list = {}

	if self.xmlFilename == nil then
		return list
	end

	self:loadConfigurationIfRequired()

	local function add(configName)
		local config = self[configName]
		local item = config.items[config.selection]

		if item ~= nil and item.filename ~= nil then
			table.insert(list, item.filename)
		end
	end

	add("beardConfig")
	add("bottomConfig")
	add("faceConfig")
	add("footwearConfig")
	add("glassesConfig")
	add("glovesConfig")
	add("hairStyleConfig")
	add("headgearConfig")
	add("mustacheConfig")
	add("onepieceConfig")
	add("topConfig")
	add("facegearConfig")

	if (self.headgearConfig.selection ~= 0 or self.onepieceConfig.selection ~= 0 and self.onepieceConfig.items[self.onepieceConfig.selection].disabledOptions.headgear) and self.hatHairstyleIndex ~= nil then
		table.insert(list, self.hairStyleConfig.items[self.hatHairstyleIndex].filename)
	end

	return list
end

function PlayerStyle:apply(skeleton, mesh, hideBody, models)
	self:loadConfigurationIfRequired()

	if #self.faceConfig.items == 0 then
		return
	end

	local function indexToObject(index)
		if index == nil then
			return nil
		end

		if index.isSkeleton then
			return I3DUtil.indexToObject(skeleton, index.path)
		else
			return I3DUtil.indexToObject(mesh, index.path)
		end
	end

	local function getNodeClone(filename)
		if models[filename] == nil then
			return nil
		end

		local cloneId = clone(models[filename], false, false, false)

		return cloneId
	end

	for _, nodeIndex in pairs(self.attachPoints) do
		local node = indexToObject(nodeIndex)

		for i = getNumOfChildren(node) - 1, 0, -1 do
			delete(getChildAt(node, i))
		end
	end

	if self.faceConfig.selection ~= 0 then
		local skinColorR, skinColorG, skinColorB = unpack(self.faceConfig.items[self.faceConfig.selection].skinColor)

		for _, part in ipairs(self.bodyParts) do
			local node = indexToObject(part.index)

			setVisibility(node, not hideBody)
			setShaderParameter(node, "colorScaleR", skinColorR, skinColorG, skinColorB, 1, false)
		end

		local selectedFace = self.faceConfig.items[math.max(self.faceConfig.selection, 1)]
		local modelNode = getNodeClone(selectedFace.filename)

		if modelNode == nil then
			print_r(models)
			printCallstack()

			return
		end

		local faceSourceNode = I3DUtil.indexToObject(modelNode, selectedFace.index)
		local oldFaceSkeleton = getChildAt(modelNode, 0)

		link(indexToObject(selectedFace.attachNode), faceSourceNode)

		for i = 0, getNumOfChildren(faceSourceNode) - 1 do
			local node = getChildAt(faceSourceNode, i)

			setShapeBones(node, skeleton, oldFaceSkeleton, true)

			if getHasShaderParameter(node, "sssColor") then
				setShaderParameter(node, "colorScaleR", skinColorR, skinColorG, skinColorB, 1, false)
			end
		end

		delete(modelNode)
	end

	local function enable(item, extentToCompare, extentToCompare2)
		if item == nil then
			return nil
		end

		local modelNode = getNodeClone(item.filename)

		if modelNode == nil then
			return nil
		end

		local node = I3DUtil.indexToObject(modelNode, item.index)
		local attachNode = indexToObject(item.attachNode)

		link(attachNode, node)

		local node2 = nil

		if item.index2 ~= nil then
			node2 = I3DUtil.indexToObject(modelNode, item.index2)

			link(attachNode, node2)
		end

		if not item.attachNode.isSkeleton then
			local oldSkeleton = getChildAt(modelNode, 0)

			I3DUtil.setShapeBonesRec(node, skeleton, oldSkeleton, true)

			if node2 ~= nil then
				I3DUtil.setShapeBonesRec(node2, skeleton, oldSkeleton, true)
			end
		end

		for _, partIndex in ipairs(item.hiddenBodyParts) do
			local partNode = indexToObject(self.bodyParts[partIndex].index)

			setVisibility(partNode, false)
		end

		if extentToCompare ~= nil and item.extents ~= nil then
			if item.extents[extentToCompare] == nil then
				extentToCompare = "hands"
			end

			local extentsSeen = {}

			for typ, nodeIndex in pairs(item.extents) do
				local show = false

				if typ == extentToCompare or typ == extentToCompare2 then
					show = true
				end

				local extentNode = I3DUtil.indexToObject(node, nodeIndex)

				if extentsSeen[extentNode] == nil then
					setVisibility(extentNode, show)

					if show then
						extentsSeen[extentNode] = true
					end
				end
			end
		end

		if item.transforms ~= nil then
			local transform = item.transforms[self.faceConfig.selection]

			setTranslation(node, unpack(transform.translation))
			setRotation(node, math.rad(transform.rotation[1]), math.rad(transform.rotation[2]), math.rad(transform.rotation[3]))
			setScale(node, unpack(transform.scale))
		end

		delete(modelNode)

		return node, node2
	end

	local function updateColors(node, item, selectedColorIndex)
		if node == nil then
			return
		end

		local numColors = item.numColors

		if numColors == 0 then
			return
		end

		if selectedColorIndex == nil then
			printCallstack()

			return
		end

		local color = item.colors[selectedColorIndex]

		if color ~= nil and numColors >= 1 then
			local primaryColor = color.primary

			I3DUtil.setShaderParameterRec(node, "colorScaleR", primaryColor[1], primaryColor[2], primaryColor[3], primaryColor[4], false)
		end

		if color ~= nil and numColors >= 2 then
			local secondaryColor = color.secondary

			if secondaryColor ~= nil then
				I3DUtil.setShaderParameterRec(node, "colorScaleG", secondaryColor[1], secondaryColor[2], secondaryColor[3], secondaryColor[4], false)
			end
		end
	end

	local function updateHairColors(node, item)
		if item == nil or node == nil then
			return
		end

		local selectedColorItem = item.colors[self.hairStyleConfig.color]
		local hairColorR, hairColorG, hairColorB = unpack(selectedColorItem.primary)
		local hairColorR2, hairColorG2, hairColorB2 = unpack(selectedColorItem.secondary)

		I3DUtil.setShaderParameterRec(node, "colorScaleG", hairColorR, hairColorG, hairColorB, 1, false)
		I3DUtil.setShaderParameterRec(node, "colorScaleR", hairColorR2, hairColorG2, hairColorB2, 1, false)
	end

	if self.topConfig.selection ~= 0 then
		local itemAttachNode = enable(self.topConfig.items[self.topConfig.selection], self.glovesConfig.selection ~= 0 and self.glovesConfig.items[self.glovesConfig.selection].extent or "hands")

		updateColors(itemAttachNode, self.topConfig.items[self.topConfig.selection], self.topConfig.color)
	end

	local bottomNode = nil

	if self.bottomConfig.selection ~= 0 then
		bottomNode = enable(self.bottomConfig.items[self.bottomConfig.selection], self.footwearConfig.selection ~= 0 and self.footwearConfig.items[self.footwearConfig.selection].extent or "low")

		updateColors(bottomNode, self.bottomConfig.items[self.bottomConfig.selection], self.bottomConfig.color)
	end

	if self.footwearConfig.selection ~= 0 then
		local extent = "high"

		if self.bottomConfig.selection ~= 0 then
			extent = self.bottomConfig.items[self.bottomConfig.selection].extent
		end

		if self.onepieceConfig.selection ~= 0 then
			extent = self.onepieceConfig.items[self.onepieceConfig.selection].extent
		end

		local item = self.footwearConfig.items[self.footwearConfig.selection]
		local itemAttachNode = enable(item, extent)

		updateColors(itemAttachNode, item, self.footwearConfig.color)
	end

	if self.glovesConfig.selection ~= 0 then
		local item = self.glovesConfig.items[self.glovesConfig.selection]
		local itemAttachNode = enable(item)

		updateColors(itemAttachNode, item, self.glovesConfig.color)
	end

	local hideGlasses = false

	if self.headgearConfig.selection ~= 0 then
		local item = self.headgearConfig.items[self.headgearConfig.selection]
		local itemAttachNode = enable(item)

		updateColors(itemAttachNode, item, self.headgearConfig.color)

		if item.hideGlasses then
			hideGlasses = true
		end
	end

	if self.glassesConfig.selection ~= 0 and not hideGlasses then
		enable(self.glassesConfig.items[self.glassesConfig.selection])
	end

	if self.hairStyleConfig.selection ~= 0 then
		if (self.headgearConfig.selection ~= 0 or self.onepieceConfig.selection ~= 0 and self.onepieceConfig.items[self.onepieceConfig.selection].disabledOptions.headgear) and self.hatHairstyleIndex ~= nil then
			local item = self.hairStyleConfig.items[self.hatHairstyleIndex]
			local itemNode, itemNode2 = enable(item)

			updateHairColors(itemNode, item)
			updateHairColors(itemNode2, item)
		else
			local item = self.hairStyleConfig.items[self.hairStyleConfig.selection]
			local itemNode, itemNode2 = enable(item)

			updateHairColors(itemNode, item)
			updateHairColors(itemNode2, item)
		end
	end

	if self.facegearConfig.selection ~= 0 then
		enable(self.facegearConfig.items[self.facegearConfig.selection])
	else
		if self.mustacheConfig.selection ~= 0 then
			for i = self.mustacheConfig.selection, #self.mustacheConfig.items do
				local item = self.mustacheConfig.items[i]

				if item.face == nil or item.face == self.faceConfig.selection or self.faceConfig.selection == 0 and item.face == 1 then
					local itemNode, itemNode2 = enable(item)

					updateHairColors(itemNode, item)
					updateHairColors(itemNode2, item)

					break
				end
			end
		end

		if self.beardConfig.selection ~= 0 then
			for i = self.beardConfig.selection, #self.beardConfig.items do
				local item = self.beardConfig.items[i]

				if item.face == nil or item.face == self.faceConfig.selection or self.faceConfig.selection == 0 and item.face == 1 then
					local itemNode, itemNode2 = enable(item)

					updateHairColors(itemNode, item)
					updateHairColors(itemNode2, item)

					break
				end
			end
		end
	end

	if self.onepieceConfig.selection ~= 0 then
		local itemAttachNode = enable(self.onepieceConfig.items[self.onepieceConfig.selection], self.glovesConfig.selection ~= 0 and self.glovesConfig.items[self.glovesConfig.selection].extent or "hands", self.footwearConfig.selection ~= 0 and self.footwearConfig.items[self.footwearConfig.selection].extent or "low")

		updateColors(itemAttachNode, self.onepieceConfig.items[self.onepieceConfig.selection], self.onepieceConfig.color)
	end

	if (self.topConfig.selection ~= 0 or self.topConfig.selection == 0 and self.onepieceConfig.selection == 0) and self.bottomConfig.selection ~= 0 then
		local bottom = self.bottomConfig.items[self.bottomConfig.selection]
		local beltHidden = false

		if self.topConfig.selection ~= 0 then
			beltHidden = self.topConfig.items[self.topConfig.selection].beltHidden
		end

		if bottom.belt ~= nil then
			local node = I3DUtil.indexToObject(bottomNode, bottom.belt)

			setVisibility(node, not beltHidden)
		end
	end
end

function PlayerStyle:setFace(faceIndex)
	if faceIndex ~= self.faceConfig.selection then
		self.faceConfig.selection = faceIndex
	end
end

function PlayerStyle:setHairStyle(hairStyleIndex)
	self.hairStyleConfig.selection = hairStyleIndex
end

function PlayerStyle:setBeard(beardIndex)
	self.beardConfig.selection = beardIndex
end

function PlayerStyle:setMustache(mustacheIndex)
	self.mustacheConfig.selection = mustacheIndex
end

function PlayerStyle:setHeadgear(headgearIndex, force)
	if self.headgearConfig.selection ~= headgearIndex or force == true then
		self.headgearConfig.selection = headgearIndex
		local headgear = self.headgearConfig.items[headgearIndex]

		if headgear ~= nil and headgear.numColors >= 1 and headgear.defaultColor ~= nil then
			self.headgearConfig.color = headgear.defaultColor
		end
	end
end

function PlayerStyle:setTop(topIndex, force)
	if topIndex ~= self.topConfig.selection or force == true then
		self.topConfig.selection = topIndex
		local top = self.topConfig.items[topIndex]

		if top ~= nil and top.numColors >= 1 and top.defaultColor ~= nil then
			self.topConfig.color = top.defaultColor
		end
	end
end

function PlayerStyle:setBottom(bottomIndex, force)
	if self.bottomConfig.selection ~= bottomIndex or force == true then
		self.bottomConfig.selection = bottomIndex
		local bottom = self.bottomConfig.items[bottomIndex]

		if bottom ~= nil and bottom.numColors >= 1 and bottom.defaultColor ~= nil then
			self.bottomConfig.color = bottom.defaultColor
		end
	end
end

function PlayerStyle:setFootwear(footwearIndex, force)
	if self.footwearConfig.selection ~= footwearIndex or force == true then
		self.footwearConfig.selection = footwearIndex
		local footwear = self.footwearConfig.items[footwearIndex]

		if footwear ~= nil and footwear.numColors >= 1 and footwear.defaultColor ~= nil then
			self.footwearConfig.color = footwear.defaultColor
		end
	end
end

function PlayerStyle:setGloves(glovesIndex, force)
	if self.glovesConfig.selection ~= glovesIndex or force == true then
		self.glovesConfig.selection = glovesIndex
		local glove = self.glovesConfig.items[glovesIndex]

		if glove ~= nil and glove.numColors >= 1 and glove.defaultColor ~= nil then
			self.glovesConfig.color = glove.defaultColor
		end
	end
end

function PlayerStyle:setGlasses(glassesIndex, force)
	self.glassesConfig.selection = glassesIndex
end

function PlayerStyle:setFacegear(facegearIndex, force)
	self.facegearConfig.selection = facegearIndex
end

function PlayerStyle:setOnepiece(onepieceIndex, force)
	if self.onepieceConfig.selection ~= onepieceIndex or force == true then
		self.onepieceConfig.selection = onepieceIndex

		if onepieceIndex == 0 then
			if self.topConfig.selection == 0 then
				self:setTop(1)
			end

			if self.bottomConfig.selection == 0 then
				self:setBottom(1)
			end
		else
			local piece = self.onepieceConfig.items[onepieceIndex]
			local disabled = piece.disabledOptions

			for k, _ in pairs(disabled) do
				if k == "tops" then
					self.topConfig.selection = 0
				elseif k == "bottoms" then
					self.bottomConfig.selection = 0
				elseif k == "headgear" then
					self.headgearConfig.selection = 0
				end
			end

			if piece.numColors >= 1 and piece.defaultColor ~= nil then
				self.onepieceConfig.color = piece.defaultColor
			end
		end

		self:updateDisabledOptions()
	end
end

function PlayerStyle:setPreset(preset, force)
	if preset == nil then
		self.disabledOptionsForSelection = {}

		return
	end

	self:setOnepiece(preset.onepiece or 0, force)

	if preset.face ~= nil then
		self:setFace(preset.face)
	end

	if preset.top ~= nil then
		self:setTop(preset.top, force)
	elseif self.disabledOptionsForSelection.tops then
		self:setTop(0)
	end

	if preset.glasses ~= nil then
		self:setGlasses(preset.glasses, force)
	elseif self.disabledOptionsForSelection.glasses then
		self:setGlasses(0)
	end

	if preset.bottom ~= nil then
		self:setBottom(preset.bottom, force)
	elseif self.disabledOptionsForSelection.bottoms then
		self:setBottom(0)
	end

	if preset.footwear ~= nil then
		self:setFootwear(preset.footwear, force)
	elseif self.disabledOptionsForSelection.footwear then
		self:setFootwear(0)
	end

	if preset.headgear ~= nil then
		self:setHeadgear(preset.headgear, force)
	elseif self.disabledOptionsForSelection.headgear then
		self:setHeadgear(0)
	end

	if preset.gloves ~= nil then
		self:setGloves(preset.gloves, force)
	elseif self.disabledOptionsForSelection.gloves then
		self:setGloves(0)
	end

	if preset.facegear ~= nil then
		self:setFacegear(preset.facegear, force)
	elseif self.disabledOptionsForSelection.facegear then
		self:setFacegear(0)
	end

	self:updateDisabledOptions()
end

function PlayerStyle:setHairItemColor(item, colorIndex)
	self.hairStyleConfig.color = colorIndex
	self.beardConfig.color = colorIndex
	self.mustacheConfig.color = colorIndex
end

function PlayerStyle:setItemColor(item, colorIndex)
	item.color = colorIndex
end

function PlayerStyle:getPossibleFaces()
	local possible = {}

	for index, _ in ipairs(self.faceConfig.items) do
		table.insert(possible, index)
	end

	return possible
end

function PlayerStyle:getPossibleHairStyles()
	local possible = {}

	for index, style in ipairs(self.hairStyleConfig.items) do
		if not style.forHat then
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getHeadgearHair()
	if self.hairStyleConfig.selection == 0 then
		return 0
	end

	for index, style in ipairs(self.hairStyleConfig.items) do
		if style.forHat then
			return index
		end
	end
end

function PlayerStyle:getPossibleHeadgear()
	local possible = {}

	if not self.disabledOptionsForSelection.headgear then
		for index, gear in ipairs(self.headgearConfig.items) do
			if not gear.hidden then
				table.insert(possible, index)
			end
		end
	end

	return possible
end

function PlayerStyle:getPossibleTops()
	local possible = {}

	if not self.disabledOptionsForSelection.tops and self.onepieceConfig.selection == 0 then
		for index, _ in ipairs(self.topConfig.items) do
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleBottoms()
	local possible = {}

	if not self.disabledOptionsForSelection.bottoms and self.onepieceConfig.selection == 0 then
		for index, _ in ipairs(self.bottomConfig.items) do
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleGloves()
	local possible = {}

	if not self.disabledOptionsForSelection.gloves then
		for index, gear in ipairs(self.glovesConfig.items) do
			if not gear.hidden then
				table.insert(possible, index)
			end
		end
	end

	return possible
end

function PlayerStyle:getPossibleFootwear()
	local possible = {}

	if not self.disabledOptionsForSelection.footwear then
		for index, _ in ipairs(self.footwearConfig.items) do
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleGlasses()
	local possible = {}

	for index, _ in ipairs(self.glassesConfig.items) do
		if not self.disabledOptionsForSelection.glasses or self.glassesConfig.selection == index then
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleOnepieces()
	local possible = {}

	for index, _ in ipairs(self.onepieceConfig.items) do
		if not self.disabledOptionsForSelection.onepiece or self.onepieceConfig.selection == index then
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleBeards()
	local possible = {}

	for index, beard in ipairs(self.beardConfig.items) do
		if not self.disabledOptionsForSelection.beards and (beard.face == nil or beard.face == self.faceConfig.selection) then
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPossibleMustaches()
	local possible = {}

	for index, mustache in ipairs(self.mustacheConfig.items) do
		if not self.disabledOptionsForSelection.mustaches and (mustache.face == nil or mustache.face == self.faceConfig.selection) then
			table.insert(possible, index)
		end
	end

	return possible
end

function PlayerStyle:getPresets()
	return self.presets
end

function PlayerStyle:getPresetByName(presetName)
	for _, preset in ipairs(self.presets) do
		if preset.name == presetName then
			return preset
		end
	end

	return nil
end

function PlayerStyle:getDisabledOptionsForPreset()
	return self.disabledOptionsForSelection
end

function PlayerStyle:buildPreset()
	local preset = {
		xmlFilename = self.xmlFilename,
		face = self.faceConfig.selection,
		top = self.topConfig.selection,
		bottom = self.bottomConfig.selection,
		footwear = self.footwearConfig.selection,
		gloves = self.glovesConfig.selection,
		glasses = self.glassesConfig.selection,
		headgear = self.headgearConfig.selection,
		hairStyle = self.hairStyleConfig.selection,
		onepiece = self.onepieceConfig.selection,
		facegear = self.facegearConfig.selection,
		mustache = self.mustacheConfig.selection,
		beard = self.beardConfig.selection
	}

	return preset
end

function PlayerStyle:updateDisabledOptions()
	if self.onepieceConfig.selection == 0 then
		self.disabledOptionsForSelection = {}
	else
		self.disabledOptionsForSelection = self.onepieceConfig.items[self.onepieceConfig.selection].disabledOptions
	end
end

function PlayerStyle:convertSkinColorToScreenColor(r, g, b)
	return r * self.faceNeutralDiffuseColor[1], g * self.faceNeutralDiffuseColor[2], b * self.faceNeutralDiffuseColor[3]
end

function PlayerStyle:getIsMale()
	return g_characterModelManager:getIsPlayerModelMaleForFilename(self.xmlFilename)
end

function PlayerStyle:getIsPresetUsed(preset)
	return (preset.face == nil or preset.face == self.faceConfig.selection) and (preset.top == nil or preset.top == self.topConfig.selection) and (preset.bottom == nil or preset.bottom == self.bottomConfig.selection) and (preset.footwear == nil or preset.footwear == self.footwearConfig.selection) and (preset.gloves == nil or preset.gloves == self.glovesConfig.selection) and (preset.glasses == nil or preset.glasses == self.glassesConfig.selection) and (preset.headgear == nil or preset.headgear == self.headgearConfig.selection) and (preset.onepiece == nil or preset.onepiece == self.onepieceConfig.selection) and (preset.facegear == nil or preset.facegear == self.facegearConfig.selection)
end

function PlayerStyle:getSlotUVs(slot)
	if slot == 0 or slot == nil then
		slot = 1
	end

	slot = slot - 1
	local slotU = math.floor(slot / PlayerStyle.ATLAS_ROWS)
	local slotV = slot % PlayerStyle.ATLAS_ROWS
	local u = slotU / PlayerStyle.ATLAS_COLUMNS
	local v = slotV / PlayerStyle.ATLAS_ROWS
	local uvs = GuiUtils.getNormalizedValues(u .. " " .. v .. " " .. " " .. 1 / PlayerStyle.ATLAS_COLUMNS .. " " .. 1 / PlayerStyle.ATLAS_ROWS, {
		PlayerStyle.ATLAS_COLUMNS,
		PlayerStyle.ATLAS_ROWS
	})

	return uvs[1], 1 - uvs[2] - uvs[4], uvs[1], 1 - uvs[2], uvs[1] + uvs[3], 1 - uvs[2] - uvs[4], uvs[1] + uvs[3], 1 - uvs[2]
end

function PlayerStyle:print()
	local function p(configName)
		log(" ", configName, ":", self[configName].selection, "(", #self[configName].items, "items )")
	end

	p("beardConfig")
	p("bottomConfig")
	p("faceConfig")
	p("footwearConfig")
	p("glassesConfig")
	p("glovesConfig")
	p("hairStyleConfig")
	p("headgearConfig")
	p("mustacheConfig")
	p("onepieceConfig")
	p("topConfig")
	p("facegearConfig")
end
