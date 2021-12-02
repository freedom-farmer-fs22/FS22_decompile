BaseMaterial = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function BaseMaterial.initSpecialization()
	g_configurationManager:addConfigurationType("baseMaterial", g_i18n:getText("configuration_baseColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("designMaterial", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("designMaterial2", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("designMaterial3", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("BaseMaterial")
	MaterialUtil.registerBaseMaterialXMLPaths(schema, "vehicle.baseMaterial.material")
	BaseMaterial.registerBaseMaterialConfigurationsXMLPaths(schema, "baseMaterial")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "baseMaterial")
	BaseMaterial.registerBaseMaterialConfigurationsXMLPaths(schema, "designMaterial")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "designMaterial")
	BaseMaterial.registerBaseMaterialConfigurationsXMLPaths(schema, "designMaterial2")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "designMaterial2")
	BaseMaterial.registerBaseMaterialConfigurationsXMLPaths(schema, "designMaterial3")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "designMaterial3")
	schema:setXMLSpecializationType()
end

function BaseMaterial.registerBaseMaterialConfigurationsXMLPaths(schema, configurationName)
	local baseKey = string.format("vehicle.%sConfigurations", configurationName)

	schema:register(XMLValueType.STRING, baseKey .. ".material(?)#name", "Material name")
	schema:register(XMLValueType.STRING, baseKey .. ".material(?)#shaderParameter", "Material shader parameter")
	schema:register(XMLValueType.COLOR, baseKey .. ".material(?)#color", "Material color if it shouldn't be used from configuration")
	schema:register(XMLValueType.INT, baseKey .. ".material(?)#material", "Material id if it shouldn't be used from configuration")
	schema:register(XMLValueType.BOOL, baseKey .. ".material(?)#useContrastColor", "Use contrast color from configuration", false)
	schema:register(XMLValueType.FLOAT, baseKey .. ".material(?)#contrastThreshold", "Contrast color brightness threshold", 0.5)
end

function BaseMaterial.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "applyBaseMaterialConfiguration", BaseMaterial.applyBaseMaterialConfiguration)
	SpecializationUtil.registerFunction(vehicleType, "applyBaseMaterial", BaseMaterial.applyBaseMaterial)
	SpecializationUtil.registerFunction(vehicleType, "setBaseMaterialColor", BaseMaterial.setBaseMaterialColor)
end

function BaseMaterial.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaseMaterial)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaseMaterial)
end

function BaseMaterial:onLoad(savegame)
	local spec = self.spec_baseMaterial
	spec.baseMaterials = {}
	spec.nameToMaterial = {}

	MaterialUtil.loadBaseMaterialsFromXML(spec.baseMaterials, self.xmlFile, "vehicle.baseMaterial.material", self.components, self.i3dMappings)

	for i = 1, #spec.baseMaterials do
		local baseMaterial = spec.baseMaterials[i]
		spec.nameToMaterial[baseMaterial.name] = baseMaterial
	end

	if self.configurations.baseMaterial ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "baseMaterial", self.configurations.baseMaterial)
	end

	if self.configurations.designMaterial ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "designMaterial", self.configurations.designMaterial)
	end

	if self.configurations.designMaterial2 ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "designMaterial2", self.configurations.designMaterial2)
	end

	if self.configurations.designMaterial3 ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "designMaterial3", self.configurations.designMaterial3)
	end
end

function BaseMaterial:onLoadFinished(savegame)
	self:applyBaseMaterial()
end

function BaseMaterial:applyBaseMaterial()
	local spec = self.spec_baseMaterial

	for _, material in ipairs(spec.baseMaterials) do
		for _, component in ipairs(self.components) do
			MaterialUtil.applyBaseMaterial(component.node, material)
		end
	end
end

function BaseMaterial:applyBaseMaterialConfiguration(xmlFile, configName, configId)
	local spec = self.spec_baseMaterial
	local baseKey = string.format("vehicle.%sConfigurations", configName)
	local i = 0

	while true do
		local key = string.format("%s.material(%d)", baseKey, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local name = xmlFile:getValue(key .. "#name")

		if not ClassUtil.getIsValidIndexName(name) then
			Logging.xmlWarning(xmlFile, "Given material name '%s' is not valid for material '%s'", name, key)

			return false
		end

		local shaderParameterName = xmlFile:getValue(key .. "#shaderParameter")

		if not ClassUtil.getIsValidIndexName(shaderParameterName) then
			Logging.xmlWarning(xmlFile, "Given shader parameter '%s' is not valid for material '%s'", name, key)

			return false
		end

		local material = spec.nameToMaterial[name]

		if material == nil then
			Logging.xmlWarning(xmlFile, "Given material name '%s' not found for material configuration '%s'", name, key)

			return false
		end

		local shaderParameter = material.nameToShaderParameter[shaderParameterName]

		if shaderParameter == nil then
			Logging.xmlWarning(xmlFile, "Given shader parameter '%s' not found for material configuration '%s'", shaderParameterName, key)

			return false
		end

		local color = xmlFile:getValue(key .. "#color", nil, true)

		if color == nil then
			color = ConfigurationUtil.getColorByConfigId(self, configName, configId)

			if color == nil then
				Logging.xmlWarning(xmlFile, "Color not found for configId '%d' for material configuration '%s'", configId, key)

				return false
			end
		end

		local materialId = xmlFile:getValue(key .. "#material")
		materialId = materialId or ConfigurationUtil.getMaterialByConfigId(self, configName, configId)
		shaderParameter.value[1] = color[1]
		shaderParameter.value[2] = color[2]
		shaderParameter.value[3] = color[3]
		shaderParameter.value[4] = materialId or shaderParameter.value[4]

		if xmlFile:getValue(key .. "#useContrastColor", false) then
			local brightness = MathUtil.getBrightnessFromColor(color[1], color[2], color[3])
			local threshold = xmlFile:getValue(key .. "#contrastThreshold", 0.5)
			brightness = threshold < brightness and 1 or 0
			shaderParameter.value[1] = 1 - brightness
			shaderParameter.value[2] = 1 - brightness
			shaderParameter.value[3] = 1 - brightness
		end

		i = i + 1
	end
end

function BaseMaterial:setBaseMaterialColor(materialName, shaderParameterName, color, materialId)
	local spec = self.spec_baseMaterial
	local material = spec.nameToMaterial[materialName]

	if material ~= nil then
		local shaderParameter = material.nameToShaderParameter[shaderParameterName]

		if shaderParameter ~= nil then
			shaderParameter.value[1] = color[1]
			shaderParameter.value[2] = color[2]
			shaderParameter.value[3] = color[3]
			shaderParameter.value[4] = materialId or shaderParameter.value[4]
		end
	end

	self:applyBaseMaterial()
end
