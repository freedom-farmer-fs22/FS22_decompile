ConfigurationUtil = {
	SEND_NUM_BITS = 6,
	SELECTOR_MULTIOPTION = 0,
	SELECTOR_COLOR = 1,
	addBoughtConfiguration = function (object, name, id)
		if g_configurationManager:getConfigurationIndexByName(name) ~= nil then
			if object.boughtConfigurations[name] == nil then
				object.boughtConfigurations[name] = {}
			end

			object.boughtConfigurations[name][id] = true
		end
	end,
	hasBoughtConfiguration = function (object, name, id)
		if object.boughtConfigurations[name] ~= nil and object.boughtConfigurations[name][id] then
			return true
		end

		return false
	end,
	setConfiguration = function (object, name, id)
		object.configurations[name] = id
	end,
	getColorByConfigId = function (object, configName, configId)
		if configId ~= nil then
			local item = g_storeManager:getItemByXMLFilename(object.configFileName)

			if item.configurations ~= nil then
				local config = item.configurations[configName][configId]

				if config ~= nil then
					local r, g, b = unpack(config.color)

					return {
						r,
						g,
						b,
						config.material
					}
				end
			end
		end

		return nil
	end,
	getSaveIdByConfigId = function (configFileName, configName, configId)
		local item = g_storeManager:getItemByXMLFilename(configFileName)

		if item.configurations ~= nil then
			local configs = item.configurations[configName]

			if configs ~= nil then
				local config = configs[configId]

				if config ~= nil then
					return config.saveId
				end
			end
		end

		return nil
	end,
	getConfigIdBySaveId = function (configFileName, configName, configId)
		local item = g_storeManager:getItemByXMLFilename(configFileName)

		if item.configurations ~= nil then
			local configs = item.configurations[configName]

			if configs ~= nil then
				for j = 1, #configs do
					if configs[j].saveId == configId then
						return configs[j].index
					end
				end
			end
		end

		return 1
	end,
	getMaterialByConfigId = function (object, configName, configId)
		if configId ~= nil then
			local item = g_storeManager:getItemByXMLFilename(object.configFileName)

			if item.configurations ~= nil then
				local config = item.configurations[configName][configId]

				if config ~= nil then
					return config.material
				end
			end
		end

		return nil
	end
}

function ConfigurationUtil.applyConfigMaterials(object, xmlFile, configName, configId)
	local configuration = g_configurationManager:getConfigurationDescByName(configName)
	local xmlKey = configuration.xmlKey

	if xmlKey ~= nil then
		xmlKey = "." .. xmlKey
	else
		xmlKey = ""
	end

	local configKey = string.format("vehicle%s.%sConfigurations.%sConfiguration(%d)", xmlKey, configName, configName, configId - 1)

	if xmlFile:hasProperty(configKey) then
		xmlFile:iterate(configKey .. ".material", function (_, key)
			local baseMaterialNode = xmlFile:getValue(key .. "#node", nil, object.components, object.i3dMappings)
			local refMaterialNode = xmlFile:getValue(key .. "#refNode", nil, object.components, object.i3dMappings)

			if baseMaterialNode ~= nil and refMaterialNode ~= nil then
				local oldMaterial = getMaterial(baseMaterialNode, 0)
				local newMaterial = getMaterial(refMaterialNode, 0)

				for _, component in pairs(object.components) do
					ConfigurationUtil.replaceMaterialRec(object, component.node, oldMaterial, newMaterial)
				end
			end

			local materialName = xmlFile:getValue(key .. "#name")

			if materialName ~= nil then
				local shaderParameterName = xmlFile:getValue(key .. "#shaderParameter")

				if shaderParameterName ~= nil then
					local color = xmlFile:getValue(key .. "#color", nil, true)

					if color ~= nil then
						local materialId = xmlFile:getValue(key .. "#materialId")

						if object.setBaseMaterialColor ~= nil then
							object:setBaseMaterialColor(materialName, shaderParameterName, color, materialId)
						end
					end
				end
			end
		end)
	end
end

function ConfigurationUtil.getOverwrittenMaterialColors(object, xmlFile, targetTable)
	for configName, configId in pairs(object.configurations) do
		local configuration = g_configurationManager:getConfigurationDescByName(configName)
		local xmlKey = configuration.xmlKey

		if xmlKey ~= nil then
			xmlKey = "." .. xmlKey
		else
			xmlKey = ""
		end

		local configKey = string.format("vehicle%s.%sConfigurations.%sConfiguration(%d)", xmlKey, configName, configName, configId - 1)

		if xmlFile:hasProperty(configKey) then
			xmlFile:iterate(configKey .. ".material", function (_, key)
				local materialName = xmlFile:getValue(key .. "#name")

				if materialName ~= nil then
					for name, _ in pairs(targetTable) do
						if materialName == name then
							local color = xmlFile:getValue(key .. "#color", nil, true)

							if color ~= nil and #color > 0 then
								local materialId = xmlFile:getValue(key .. "#materialId")
								targetTable[name][1] = color[1]
								targetTable[name][2] = color[2]
								targetTable[name][3] = color[3]
								targetTable[name][4] = materialId
							end
						end
					end
				end
			end)
		end
	end
end

function ConfigurationUtil.replaceMaterialRec(object, node, oldMaterial, newMaterial)
	if getHasClassId(node, ClassIds.SHAPE) then
		local nodeMaterial = getMaterial(node, 0)

		if nodeMaterial == oldMaterial then
			setMaterial(node, newMaterial, 0)
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			ConfigurationUtil.replaceMaterialRec(object, getChildAt(node, i), oldMaterial, newMaterial)
		end
	end
end

function ConfigurationUtil.setColor(object, xmlFile, configName, configColorId)
	local color = ConfigurationUtil.getColorByConfigId(object, configName, configColorId)

	if color ~= nil then
		local r, g, b, mat = unpack(color)
		local i = 0

		while true do
			local colorKey = string.format("vehicle.%sConfigurations.colorNode(%d)", configName, i)

			if not xmlFile:hasProperty(colorKey) then
				break
			end

			local node = xmlFile:getValue(colorKey .. "#node", nil, object.components, object.i3dMappings)

			if node ~= nil then
				if getHasClassId(node, ClassIds.SHAPE) then
					if mat == nil then
						_, _, _, mat = getShaderParameter(node, "colorScale")
					end

					if xmlFile:getValue(colorKey .. "#recursive", false) then
						I3DUtil.setShaderParameterRec(node, "colorScale", r, g, b, mat)
					else
						setShaderParameter(node, "colorScale", r, g, b, mat, false)
					end
				else
					print("Warning: Could not set vehicle color to '" .. getName(node) .. "' because node is not a shape!")
				end
			end

			i = i + 1
		end
	end
end

function ConfigurationUtil.getConfigurationValue(xmlFile, key, subKey, param, defaultValue, fallbackConfigKey, fallbackOldKey)
	if type(subKey) == "table" then
		printCallstack()
	end

	local value = nil

	if key ~= nil then
		value = xmlFile:getValue(key .. subKey .. param)
	end

	if value == nil and fallbackConfigKey ~= nil then
		value = xmlFile:getValue(fallbackConfigKey .. subKey .. param)
	end

	if value == nil and fallbackOldKey ~= nil then
		value = xmlFile:getValue(fallbackOldKey .. subKey .. param)
	end

	return Utils.getNoNil(value, defaultValue)
end

function ConfigurationUtil.getXMLConfigurationKey(xmlFile, index, key, defaultKey, configurationKey)
	local configIndex = Utils.getNoNil(index, 1)
	local configKey = string.format(key .. "(%d)", configIndex - 1)

	if index ~= nil and not xmlFile:hasProperty(configKey) then
		print("Warning: Invalid " .. configurationKey .. " index '" .. tostring(index) .. "' in '" .. key .. "'. Using default " .. configurationKey .. " settings instead!")
	end

	if not xmlFile:hasProperty(configKey) then
		configKey = key .. "(0)"
	end

	if not xmlFile:hasProperty(configKey) then
		configKey = defaultKey
	end

	return configKey, configIndex
end

function ConfigurationUtil.getConfigColorSingleItemLoad(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.color = xmlFile:getValue(baseXMLName .. "#color", "1 1 1", true)
	configItem.uiColor = xmlFile:getValue(baseXMLName .. "#uiColor", configItem.color, true)
	configItem.material = xmlFile:getValue(baseXMLName .. "#material")
	configItem.name = ConfigurationUtil.loadConfigurationNameFromXML(xmlFile, baseXMLName, customEnvironment)
end

function ConfigurationUtil.getConfigColorPostLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	local defaultColorIndex = xmlFile:getValue(baseKey .. "#defaultColorIndex")

	if xmlFile:getValue(baseKey .. "#useDefaultColors", false) then
		local price = xmlFile:getValue(baseKey .. "#price", 1000)

		for i, color in pairs(g_vehicleColors) do
			local configItem = StoreItemUtil.addConfigurationItem(configurationItems, "", "", price, 0, false)

			if color.r ~= nil and color.g ~= nil and color.b ~= nil then
				configItem.color = {
					color.r,
					color.g,
					color.b,
					1
				}
			elseif color.brandColor ~= nil then
				configItem.color = g_brandColorManager:getBrandColorByName(color.brandColor)

				if configItem.color == nil then
					configItem.color = {
						1,
						1,
						1,
						1
					}

					Logging.warning("Unable to find brandColor '%s' in g_vehicleColors", color.brandColor)
				end
			end

			configItem.name = g_i18n:convertText(color.name)

			if i == defaultColorIndex then
				configItem.isDefault = true
				configItem.price = 0
			end
		end
	end

	if defaultColorIndex == nil then
		local defaultIsDefined = false

		for _, item in ipairs(configurationItems) do
			if item.isDefault ~= nil and item.isDefault then
				defaultIsDefined = true
			end
		end

		if not defaultIsDefined and #configurationItems > 0 then
			configurationItems[1].isDefault = true
			configurationItems[1].price = 0
		end
	end
end

function ConfigurationUtil.getConfigMaterialSingleItemLoad(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.color = xmlFile:getValue(baseXMLName .. "#color", "1 1 1", true)
	configItem.material = xmlFile:getValue(baseXMLName .. "#material")
end

function ConfigurationUtil.getStoreAdditionalConfigData(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.vehicleType = xmlFile:getValue(baseXMLName .. "#vehicleType")
end

function ConfigurationUtil.getColorFromString(colorString)
	if colorString ~= nil then
		if not g_brandColorManager:getBrandColorByName(colorString) then
			local colorVector = {
				colorString:getVector()
			}
		end

		if colorVector == nil or #colorVector < 3 or #colorVector > 4 then
			print("Error: Invalid color string '" .. colorString .. "'")

			return nil
		end

		return colorVector
	end

	return nil
end

function ConfigurationUtil.loadConfigurationNameFromXML(xmlFile, configKey, customEnvironment)
	local configName = xmlFile:getValue(configKey .. "#name", nil, customEnvironment, false)
	local params = xmlFile:getValue(configKey .. "#params")

	if params ~= nil then
		params = params:split("|")

		for i = 1, #params do
			params[i] = g_i18n:convertText(params[i])
		end

		configName = string.format(configName, unpack(params))
	end

	return configName
end

function ConfigurationUtil.registerColorConfigurationXMLPaths(schema, configurationName)
	local baseKey = string.format("vehicle.%sConfigurations", configurationName)

	schema:register(XMLValueType.INT, baseKey .. "#defaultColorIndex", "Default color index on start")
	schema:register(XMLValueType.BOOL, baseKey .. "#useDefaultColors", "Use default colors", false)
	schema:register(XMLValueType.INT, baseKey .. "#price", "Default color price", 1000)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. ".colorNode(?)#node", "Color node")
	schema:register(XMLValueType.BOOL, baseKey .. ".colorNode(?)#recursive", "Apply recursively")

	local itemKey = string.format("%s.%sConfiguration(?)", baseKey, configurationName)

	schema:register(XMLValueType.COLOR, itemKey .. "#color", "Configuration color", "1 1 1 1")
	schema:register(XMLValueType.COLOR, itemKey .. "#uiColor", "Configuration UI color", "1 1 1 1")
	schema:register(XMLValueType.INT, itemKey .. "#material", "Configuration material")
	schema:register(XMLValueType.L10N_STRING, itemKey .. "#name", "Color name")
end

function ConfigurationUtil.registerMaterialConfigurationXMLPaths(schema, configurationName)
	schema:register(XMLValueType.NODE_INDEX, configurationName .. ".material(?)#node", "Material node")
	schema:register(XMLValueType.NODE_INDEX, configurationName .. ".material(?)#refNode", "Material reference node")
	schema:register(XMLValueType.STRING, configurationName .. ".material(?)#name", "Material name")
	schema:register(XMLValueType.STRING, configurationName .. ".material(?)#shaderParameter", "Material shader parameter name")
	schema:register(XMLValueType.COLOR, configurationName .. ".material(?)#color", "Color")
	schema:register(XMLValueType.INT, configurationName .. ".material(?)#materialId", "Material id")
end

function ConfigurationUtil.isColorMetallic(materialId)
	return materialId == 2 or materialId == 3 or materialId == 19 or materialId == 30 or materialId == 31 or materialId == 35
end
