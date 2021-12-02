GuiProfile = {}
local GuiProfile_mt = Class(GuiProfile)

function GuiProfile.new(profiles, traits)
	local self = setmetatable({}, GuiProfile_mt)
	self.values = {}
	self.name = ""
	self.profiles = profiles
	self.traits = traits
	self.parent = nil

	return self
end

function GuiProfile:loadFromXML(xmlFile, key, presets, isTrait, isVariant)
	local name = getXMLString(xmlFile, key .. "#name")

	if name == nil then
		return false
	end

	self.name = name
	self.isTrait = isTrait or false
	self.parent = getXMLString(xmlFile, key .. "#extends")
	self.isVariant = isVariant

	if self.parent == self.name then
		error("Profile " .. name .. " extends itself")
	end

	if not isTrait then
		local traits = getXMLString(xmlFile, key .. "#with")

		if traits ~= nil then
			local traitNames = traits:split(" ")

			for i = #traitNames, 1, -1 do
				local traitName = traitNames[i]
				local trait = self.traits[traitName]

				if trait ~= nil then
					for traitValueName, value in pairs(trait.values) do
						self.values[traitValueName] = value
					end
				else
					print("Warning: Trait-profile '" .. traitName .. "' not found for trait '" .. self.name .. "'")
				end
			end
		end
	end

	local i = 0

	while true do
		local k = key .. ".Value(" .. i .. ")"
		local valueName = getXMLString(xmlFile, k .. "#name")
		local value = getXMLString(xmlFile, k .. "#value")

		if valueName == nil or value == nil then
			break
		end

		if value:startsWith("$preset_") then
			local preset = string.gsub(value, "$preset_", "")

			if presets[preset] ~= nil then
				value = presets[preset]
			else
				print("Warning: Preset '" .. preset .. "' is not defined in GuiProfile!")
			end
		end

		self.values[valueName] = value
		i = i + 1
	end

	return true
end

function GuiProfile:getValue(name, default)
	local ret = default

	if self.values[name .. g_baseUIPostfix] ~= nil and self.values[name .. g_baseUIPostfix] ~= "nil" then
		ret = self.values[name .. g_baseUIPostfix]
	elseif self.values[name] ~= nil and self.values[name] ~= "nil" then
		ret = self.values[name]
	elseif self.parent ~= nil then
		local parentProfile = nil

		if self.isVariant then
			parentProfile = self.profiles[self.parent]
		else
			parentProfile = g_gui:getProfile(self.parent)
		end

		if parentProfile ~= nil and parentProfile ~= "nil" then
			ret = parentProfile:getValue(name, default)
		else
			print("Warning: Parent-profile '" .. self.parent .. "' not found for profile '" .. self.name .. "'")
		end
	end

	return ret
end

function GuiProfile:getBool(name, default)
	local value = self:getValue(name)
	local ret = default

	if value ~= nil and value ~= "nil" then
		ret = value:lower() == "true"
	end

	return ret
end

function GuiProfile:getNumber(name, default)
	local value = self:getValue(name)
	local ret = default

	if value ~= nil and value ~= "nil" then
		ret = tonumber(value)
	end

	return ret
end
