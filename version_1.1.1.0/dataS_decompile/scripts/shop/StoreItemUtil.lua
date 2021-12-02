StoreItemUtil = {
	getIsVehicle = function (storeItem)
		return storeItem ~= nil and (storeItem.species == nil or storeItem.species == "" or storeItem.species == "vehicle")
	end,
	getIsAnimal = function (storeItem)
		return storeItem ~= nil and storeItem.species ~= nil and storeItem.species ~= "" and storeItem.species ~= "placeable" and storeItem.species ~= "object" and storeItem.species ~= "handTool" and storeItem.species ~= "vehicle"
	end,
	getIsPlaceable = function (storeItem)
		return storeItem ~= nil and storeItem.species == "placeable"
	end,
	getIsObject = function (storeItem)
		return storeItem ~= nil and storeItem.species == "object"
	end,
	getIsHandTool = function (storeItem)
		return storeItem ~= nil and storeItem.species == "handTool"
	end,
	getIsConfigurable = function (storeItem)
		local hasConfigurations = storeItem ~= nil and storeItem.configurations ~= nil
		local hasMoreThanOneOption = false

		if hasConfigurations then
			for _, configItems in pairs(storeItem.configurations) do
				local selectableItems = 0

				for i = 1, #configItems do
					if configItems[i].isSelectable ~= false then
						selectableItems = selectableItems + 1

						if selectableItems > 1 then
							hasMoreThanOneOption = true

							break
						end
					end
				end

				if hasMoreThanOneOption then
					break
				end
			end
		end

		return hasConfigurations and hasMoreThanOneOption
	end
}

function StoreItemUtil.getIsLeasable(storeItem)
	return storeItem ~= nil and storeItem.runningLeasingFactor ~= nil and not StoreItemUtil.getIsPlaceable(storeItem)
end

function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
	return StoreItemUtil.getDefaultConfigIdFromItems(storeItem.configurations[configurationName])
end

function StoreItemUtil.getDefaultConfigIdFromItems(configItems)
	if configItems ~= nil then
		for k, item in pairs(configItems) do
			if item.isDefault and item.isSelectable ~= false then
				return k
			end
		end

		for k, item in pairs(configItems) do
			if item.isSelectable ~= false then
				return k
			end
		end
	end

	return 1
end

function StoreItemUtil.getDefaultPrice(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "price")
end

function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end

function StoreItemUtil.getCosts(storeItem, configurations, costType)
	if storeItem ~= nil then
		local costs = storeItem[costType]

		if costs == nil then
			costs = 0
		end

		if storeItem.configurations ~= nil then
			for name, value in pairs(configurations) do
				local nameConfig = storeItem.configurations[name]

				if nameConfig ~= nil then
					local valueConfig = nameConfig[value]

					if valueConfig ~= nil then
						local costTypeConfig = valueConfig[costType]

						if costTypeConfig ~= nil then
							costs = costs + tonumber(costTypeConfig)
						end
					end
				end
			end
		end

		return costs
	end

	return 0
end

function StoreItemUtil.renameDuplicatedConfigurationNames(configurationItems, configItem)
	local name = configItem.name

	if name ~= nil then
		local duplicateFound = true
		local nameIndex = 2

		while duplicateFound do
			duplicateFound = false

			for i = 1, #configurationItems do
				if configurationItems[i] ~= configItem and configurationItems[i].name == name then
					local ignore = false

					for j = 1, #configItem.nameCompareParams do
						if configurationItems[i][configItem.nameCompareParams[j]] ~= configItem[configItem.nameCompareParams[j]] then
							ignore = true
						end
					end

					if not ignore then
						duplicateFound = true
					end
				end
			end

			if duplicateFound then
				name = string.format("%s (%d)", configItem.name, nameIndex)
				nameIndex = nameIndex + 1
			end
		end

		configItem.name = name
	end
end

function StoreItemUtil.addConfigurationItem(configurationItems, name, desc, price, dailyUpkeep, isDefault, overwrittenTitle, saveId, brandIndex, isSelectable, vehicleBrand, vehicleName, vehicleIcon)
	local configItem = {
		name = name,
		desc = desc,
		price = price,
		dailyUpkeep = dailyUpkeep,
		isDefault = isDefault,
		isSelectable = isSelectable,
		overwrittenTitle = overwrittenTitle
	}

	table.insert(configurationItems, configItem)

	configItem.index = #configurationItems
	configItem.saveId = saveId or tostring(configItem.index)
	configItem.brandIndex = brandIndex
	configItem.nameCompareParams = {}
	configItem.vehicleBrand = vehicleBrand
	configItem.vehicleName = vehicleName
	configItem.vehicleIcon = vehicleIcon

	return configItem
end

function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
	local i = 0
	local functions = {}

	while true do
		local functionKey = string.format(storeDataXMLName .. ".functions.function(%d)", i)

		if not xmlFile:hasProperty(functionKey) then
			break
		end

		local functionName = xmlFile:getValue(functionKey, nil, customEnvironment, true)

		if functionName ~= nil then
			table.insert(functions, functionName)
		end

		i = i + 1
	end

	return functions
end

function StoreItemUtil.loadSpecsFromXML(item)
	if item.specs == nil then
		local storeItemXmlFile = XMLFile.load("storeItemXML", item.xmlFilename, item.xmlSchema)
		item.specs = StoreItemUtil.getSpecsFromXML(g_storeManager:getSpecTypes(), item.species, storeItemXmlFile, item.customEnvironment, item.baseDir)

		storeItemXmlFile:delete()
	end

	if item.bundleInfo ~= nil then
		local bundleItems = item.bundleInfo.bundleItems

		for i = 1, #bundleItems do
			StoreItemUtil.loadSpecsFromXML(bundleItems[i].item)
		end
	end
end

function StoreItemUtil.getSpecsFromXML(specTypes, species, xmlFile, customEnvironment, baseDirectory)
	local specs = {}

	for _, specType in pairs(specTypes) do
		if specType.species == species and specType.loadFunc ~= nil then
			specs[specType.name] = specType.loadFunc(xmlFile, customEnvironment, baseDirectory)
		end
	end

	return specs
end

function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
	local brandName = xmlFile:getValue(storeDataXMLKey .. ".brand", "")

	return g_brandManager:getBrandIndexByName(brandName)
end

function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
	local vertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".vertexBufferMemoryUsage", 0)
	local indexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".indexBufferMemoryUsage", 0)
	local textureMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".textureMemoryUsage", 0)
	local instanceVertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceVertexBufferMemoryUsage", 0)
	local instanceIndexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceIndexBufferMemoryUsage", 0)
	local ignoreVramUsage = xmlFile:getValue(storeDataXMLName .. ".ignoreVramUsage", false)
	local perInstanceVramUsage = instanceVertexBufferMemoryUsage + instanceIndexBufferMemoryUsage
	local sharedVramUsage = vertexBufferMemoryUsage + indexBufferMemoryUsage + textureMemoryUsage

	return sharedVramUsage, perInstanceVramUsage, ignoreVramUsage
end

function StoreItemUtil.getConfigurationsFromXML(xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
	local configurations = {}
	local defaultConfigurationIds = {}
	local numConfigs = 0
	local configurationTypes = g_configurationManager:getConfigurationTypes()

	for _, name in pairs(configurationTypes) do
		local configuration = g_configurationManager:getConfigurationDescByName(name)
		local configurationItems = {}
		local i = 0
		local xmlKey = configuration.xmlKey

		if xmlKey ~= nil then
			xmlKey = "." .. xmlKey
		else
			xmlKey = ""
		end

		local baseKey = key .. xmlKey .. "." .. name .. "Configurations"

		if configuration.preLoadFunc ~= nil then
			configuration.preLoadFunc(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems)
		end

		local overwrittenTitle = xmlFile:getValue(baseKey .. "#title", nil, customEnvironment, false)
		local loadedSaveIds = {}

		while true do
			if i > 2^ConfigurationUtil.SEND_NUM_BITS then
				Logging.xmlWarning(xmlFile, "Maximum number of configurations are reached for %s. Only %d configurations per type are allowed!", name, 2^ConfigurationUtil.SEND_NUM_BITS)
			end

			local configKey = string.format(baseKey .. "." .. name .. "Configuration(%d)", i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local configName = ConfigurationUtil.loadConfigurationNameFromXML(xmlFile, configKey, customEnvironment)
			local desc = xmlFile:getValue(configKey .. "#desc", nil, customEnvironment, false)
			local price = xmlFile:getValue(configKey .. "#price", 0)
			local dailyUpkeep = xmlFile:getValue(configKey .. "#dailyUpkeep", 0)
			local isDefault = xmlFile:getValue(configKey .. "#isDefault", false)
			local isSelectable = xmlFile:getValue(configKey .. "#isSelectable", true)
			local saveId = xmlFile:getValue(configKey .. "#saveId")
			local vehicleBrandName = xmlFile:getValue(configKey .. "#vehicleBrand")
			local vehicleBrand = g_brandManager:getBrandIndexByName(vehicleBrandName)
			local vehicleName = xmlFile:getValue(configKey .. "#vehicleName")
			local vehicleIcon = xmlFile:getValue(configKey .. "#vehicleIcon")

			if vehicleIcon ~= nil then
				vehicleIcon = Utils.getFilename(vehicleIcon, baseDir)
			end

			local brandName = xmlFile:getValue(configKey .. "#displayBrand")
			local brandIndex = g_brandManager:getBrandIndexByName(brandName)
			local configItem = StoreItemUtil.addConfigurationItem(configurationItems, configName, desc, price, dailyUpkeep, isDefault, overwrittenTitle, saveId, brandIndex, isSelectable, vehicleBrand, vehicleName, vehicleIcon)

			if saveId ~= nil then
				if loadedSaveIds[saveId] == true then
					Logging.xmlWarning(xmlFile, "Duplicated saveId '%s' in '%s' configurations", saveId, name)
				else
					loadedSaveIds[saveId] = true
				end
			end

			if configuration.singleItemLoadFunc ~= nil then
				configuration.singleItemLoadFunc(xmlFile, configKey, baseDir, customEnvironment, isMod, configItem)
			end

			StoreItemUtil.renameDuplicatedConfigurationNames(configurationItems, configItem)

			i = i + 1
		end

		if configuration.postLoadFunc ~= nil then
			configuration.postLoadFunc(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
		end

		if #configurationItems > 0 then
			defaultConfigurationIds[name] = StoreItemUtil.getDefaultConfigIdFromItems(configurationItems)
			configurations[name] = configurationItems
			numConfigs = numConfigs + 1
		end
	end

	if numConfigs == 0 then
		configurations, defaultConfigurationIds = nil
	end

	return configurations, defaultConfigurationIds
end

function StoreItemUtil.getConfigurationSetsFromXML(storeItem, xmlFile, key, baseDir, customEnvironment, isMod)
	local configurationSetsKey = string.format("%s.configurationSets", key)
	local overwrittenTitle = xmlFile:getValue(configurationSetsKey .. "#title", nil, customEnvironment, false)
	local configurationsSets = {}
	local i = 0

	while true do
		local key = string.format("%s.configurationSet(%d)", configurationSetsKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local configSet = {
			name = xmlFile:getValue(key .. "#name", nil, customEnvironment, false)
		}
		local params = xmlFile:getValue(key .. "#params")

		if params ~= nil then
			params = params:split("|")
			configSet.name = string.format(configSet.name, unpack(params))
		end

		configSet.isDefault = xmlFile:getValue(key .. "#isDefault", false)
		configSet.overwrittenTitle = overwrittenTitle
		configSet.configurations = {}
		local j = 0

		while true do
			local configKey = string.format("%s.configuration(%d)", key, j)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local name = xmlFile:getValue(configKey .. "#name")

			if name ~= nil then
				if storeItem.configurations[name] ~= nil then
					local index = xmlFile:getValue(configKey .. "#index")

					if index ~= nil then
						if storeItem.configurations[name][index] ~= nil then
							configSet.configurations[name] = index
						else
							Logging.xmlWarning(xmlFile, "Index '" .. index .. "' not defined for configuration '" .. name .. "'!")
						end
					end
				else
					Logging.xmlWarning(xmlFile, "Configuration name '" .. name .. "' is not defined!")
				end
			else
				Logging.xmlWarning(xmlFile, "Missing name for configuration set item '" .. key .. "'!")
			end

			j = j + 1
		end

		table.insert(configurationsSets, configSet)

		i = i + 1
	end

	return configurationsSets
end

function StoreItemUtil.getSubConfigurationsFromXML(configurations)
	local subConfigurations = nil

	if configurations ~= nil then
		subConfigurations = {}

		for name, items in pairs(configurations) do
			local config = g_configurationManager:getConfigurationDescByName(name)

			if config.hasSubselection then
				local subConfigValues = config.getSubConfigurationValuesFunc(items)

				if #subConfigValues > 1 then
					local subConfigItemMapping = {}
					subConfigurations[name] = {
						subConfigValues = subConfigValues,
						subConfigItemMapping = subConfigItemMapping
					}

					for k, value in ipairs(subConfigValues) do
						subConfigItemMapping[value] = config.getItemsBySubConfigurationIdentifierFunc(items, value)
					end
				end
			end
		end
	end

	return subConfigurations
end

function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues

	for k, identifier in ipairs(subConfigValues) do
		local items = subConfigurations.subConfigItemMapping[identifier]

		for _, item in ipairs(items) do
			if item.index == configIndex then
				return k
			end
		end
	end

	return nil
end

function StoreItemUtil.getFilteredConfigurationIndex(storeItem, configName, configIndex)
	local subConfigurations = storeItem.subConfigurations[configName]

	if subConfigurations ~= nil then
		local subConfigValues = subConfigurations.subConfigValues

		for _, identifier in ipairs(subConfigValues) do
			local items = subConfigurations.subConfigItemMapping[identifier]

			for k, item in ipairs(items) do
				if item.index == configIndex then
					return k
				end
			end
		end
	end

	return configIndex
end

function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues
	local identifier = subConfigValues[state]

	return subConfigurations.subConfigItemMapping[identifier]
end

function StoreItemUtil.getConfigurationsMatchConfigSets(configurations, configSets)
	for _, configSet in pairs(configSets) do
		local isMatch = true

		for configName, index in pairs(configSet.configurations) do
			if configurations[configName] ~= index then
				isMatch = false

				break
			end
		end

		if isMatch then
			return true
		end
	end

	return false
end

function StoreItemUtil.getClosestConfigurationSet(configurations, configSets)
	local closestSet = nil
	local closestSetMatches = 0

	for _, configSet in pairs(configSets) do
		local numMatches = 0

		for configName, index in pairs(configSet.configurations) do
			if configurations[configName] == index then
				numMatches = numMatches + 1
			end
		end

		if closestSetMatches < numMatches then
			closestSet = configSet
			closestSetMatches = numMatches
		end
	end

	return closestSet, closestSetMatches
end

function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
	local xmlFile = XMLFile.load("storeItemGetSizeXml", xmlFilename, Vehicle.xmlSchema)
	local size = {
		heightOffset = 0,
		lengthOffset = 0,
		widthOffset = 0,
		width = Vehicle.defaultWidth,
		length = Vehicle.defaultLength,
		height = Vehicle.defaultHeight
	}

	if xmlFile ~= nil then
		size = StoreItemUtil.getSizeValuesFromXML(xmlFile, baseName, rotationOffset, configurations)

		xmlFile:delete()
	end

	return size
end

function StoreItemUtil.getSizeValuesFromXML(xmlFile, baseName, rotationOffset, configurations)
	return StoreItemUtil.getSizeValuesFromXMLByKey(xmlFile, baseName, "base", "size", "size", rotationOffset, configurations, Vehicle.DEFAULT_SIZE)
end

function StoreItemUtil.getSizeValuesFromXMLByKey(xmlFile, baseName, baseKey, elementKey, configKey, rotationOffset, configurations, defaults)
	local baseSizeKey = string.format("%s.%s.%s", baseName, baseKey, elementKey)
	local size = {
		width = xmlFile:getValue(baseSizeKey .. "#width", defaults.width),
		length = xmlFile:getValue(baseSizeKey .. "#length", defaults.length),
		height = xmlFile:getValue(baseSizeKey .. "#height", defaults.height),
		widthOffset = xmlFile:getValue(baseSizeKey .. "#widthOffset", defaults.widthOffset),
		lengthOffset = xmlFile:getValue(baseSizeKey .. "#lengthOffset", defaults.lengthOffset),
		heightOffset = xmlFile:getValue(baseSizeKey .. "#heightOffset", defaults.heightOffset)
	}

	if configurations ~= nil then
		for name, id in pairs(configurations) do
			local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

			if specializationKey ~= nil then
				specializationKey = "." .. specializationKey
			else
				specializationKey = ""
			end

			local key = string.format("%s%s.%sConfigurations.%sConfiguration(%d).%s", baseName, specializationKey, name, name, id - 1, configKey)
			local tempWidth = xmlFile:getValue(key .. "#width")
			local tempLength = xmlFile:getValue(key .. "#length")
			local tempHeight = xmlFile:getValue(key .. "#height")
			local tempWidthOffset = xmlFile:getValue(key .. "#widthOffset")
			local tempLengthOffset = xmlFile:getValue(key .. "#lengthOffset")
			local tempHeightOffset = xmlFile:getValue(key .. "#heightOffset")

			if tempWidth ~= nil then
				size.width = math.max(size.width, tempWidth)
			end

			if tempLength ~= nil then
				size.length = math.max(size.length, tempLength)
			end

			if tempHeight ~= nil then
				size.height = math.max(size.height, tempHeight)
			end

			if tempWidthOffset ~= nil then
				if size.widthOffset < 0 then
					size.widthOffset = math.min(size.widthOffset, tempWidthOffset)
				else
					size.widthOffset = math.max(size.widthOffset, tempWidthOffset)
				end
			end

			if tempLengthOffset ~= nil then
				if size.lengthOffset < 0 then
					size.lengthOffset = math.min(size.lengthOffset, tempLengthOffset)
				else
					size.lengthOffset = math.max(size.lengthOffset, tempLengthOffset)
				end
			end

			if tempHeightOffset ~= nil then
				if size.heightOffset < 0 then
					size.heightOffset = math.min(size.heightOffset, tempHeightOffset)
				else
					size.heightOffset = math.max(size.heightOffset, tempHeightOffset)
				end
			end
		end
	end

	rotationOffset = math.floor(rotationOffset / math.rad(90) + 0.5) * math.rad(90)
	rotationOffset = rotationOffset % (2 * math.pi)

	if rotationOffset < 0 then
		rotationOffset = rotationOffset + 2 * math.pi
	end

	local rotationIndex = math.floor(rotationOffset / math.rad(90) + 0.5)

	if rotationIndex == 1 then
		size.length = size.width
		size.width = size.length
		size.lengthOffset = -size.widthOffset
		size.widthOffset = size.lengthOffset
	elseif rotationIndex == 2 then
		size.lengthOffset = -size.lengthOffset
		size.widthOffset = -size.widthOffset
	elseif rotationIndex == 3 then
		size.length = size.width
		size.width = size.length
		size.lengthOffset = size.widthOffset
		size.widthOffset = -size.lengthOffset
	end

	return size
end

function StoreItemUtil.registerConfigurationSetXMLPaths(schema, baseKey)
	baseKey = baseKey .. ".configurationSets"

	schema:register(XMLValueType.L10N_STRING, baseKey .. "#title", "Title to display in config screen")

	local setKey = baseKey .. ".configurationSet(?)"

	schema:register(XMLValueType.L10N_STRING, setKey .. "#name", "Set name")
	schema:register(XMLValueType.STRING, setKey .. "#params", "Parameters to insert into name")
	schema:register(XMLValueType.BOOL, setKey .. "#isDefault", "Is default set")
	schema:register(XMLValueType.STRING, setKey .. ".configuration(?)#name", "Configuration name")
	schema:register(XMLValueType.INT, setKey .. ".configuration(?)#index", "Selected index")
end
