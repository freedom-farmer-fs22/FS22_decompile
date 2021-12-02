ConfigurationManager = {}
local ConfigurationManager_mt = Class(ConfigurationManager, AbstractManager)

function ConfigurationManager.new(customMt)
	local self = AbstractManager.new(customMt or ConfigurationManager_mt)

	self:initDataStructures()

	return self
end

function ConfigurationManager:initDataStructures()
	self.configurations = {}
	self.intToConfigurationName = {}
	self.configurationNameToInt = {}
end

function ConfigurationManager:addConfigurationType(name, title, xmlKey, preLoadFunc, singleItemLoadFunc, postLoadFunc, selectorType, subConfigurationTitle, getSubConfigurationValuesFunc, getItemsBySubConfigurationIdentifierFunc)
	if self.configurations[name] ~= nil then
		print("Error: configuration name '" .. name .. "' is already in use!")

		return
	end

	if self:getNumOfConfigurationTypes() >= 2^ConfigurationUtil.SEND_NUM_BITS then
		print("Error: ConfigurationManager.addConfigurationType too many configuration types. Only " .. 2^ConfigurationUtil.SEND_NUM_BITS .. " configuration types are supported")

		return
	end

	local entry = {
		name = name,
		xmlKey = xmlKey,
		title = title,
		preLoadFunc = preLoadFunc,
		singleItemLoadFunc = singleItemLoadFunc,
		postLoadFunc = postLoadFunc,
		selectorType = Utils.getNoNil(selectorType, ConfigurationUtil.SELECTOR_MULTIOPTION),
		subConfigurationTitle = subConfigurationTitle,
		getSubConfigurationValuesFunc = getSubConfigurationValuesFunc,
		getItemsBySubConfigurationIdentifierFunc = getItemsBySubConfigurationIdentifierFunc,
		hasSubselection = getSubConfigurationValuesFunc ~= nil
	}
	self.configurations[name] = entry

	table.insert(self.intToConfigurationName, name)

	self.configurationNameToInt[name] = self:getNumOfConfigurationTypes()

	print("  Register configuration '" .. name .. "'")
end

function ConfigurationManager:getNumOfConfigurationTypes()
	return #self.intToConfigurationName
end

function ConfigurationManager:getConfigurationTypes()
	return self.intToConfigurationName
end

function ConfigurationManager:getConfigurationNameByIndex(index)
	return self.intToConfigurationName[index]
end

function ConfigurationManager:getConfigurationIndexByName(name)
	return self.configurationNameToInt[name]
end

function ConfigurationManager:getConfigurations()
	return self.configurations
end

function ConfigurationManager:getConfigurationDescByName(name)
	return self.configurations[name]
end

function ConfigurationManager:getConfigurationAttribute(configurationName, attribute)
	local config = self:getConfigurationDescByName(configurationName)

	return config[attribute]
end

g_configurationManager = ConfigurationManager.new()
