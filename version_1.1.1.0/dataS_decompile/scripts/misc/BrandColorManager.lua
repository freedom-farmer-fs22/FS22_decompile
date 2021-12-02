BrandColorManager = {}
local BrandColorManager_mt = Class(BrandColorManager, AbstractManager)

function BrandColorManager.new(customMt)
	local self = AbstractManager.new(customMt or BrandColorManager_mt)

	return self
end

function BrandColorManager:initDataStructures()
	self.brandColors = {}

	self:loadDefaultTypes()
end

function BrandColorManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("brandColors", "data/shared/brandColors.xml")

	self:loadBrandColors(xmlFile, true)
	delete(xmlFile)
end

function BrandColorManager:loadBrandColors(xmlFile, isBaseType)
	local i = 0

	while true do
		local key = string.format("brandColors.color(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		self:loadBrandColorFromXML(xmlFile, key)

		i = i + 1
	end

	return true
end

function BrandColorManager:loadBrandColorFromXML(xmlFile, key, isBaseType)
	local name = getXMLString(xmlFile, key .. "#name")
	local value = getXMLString(xmlFile, key .. "#value")

	if name ~= nil and value ~= nil then
		return self:addBrandColor(name, value, isBaseType)
	else
		Logging.warning("Failed to load BrandColor '%s' ", key)
	end
end

function BrandColorManager:addBrandColor(name, value, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a brand color. Ignoring brand color!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToBrandColor[name] ~= nil then
		print("Warning: BrandColor '" .. tostring(name) .. "' already exists. Ignoring brandColor!")

		return nil
	end

	local color = value:getVectorN(4)

	if color == nil then
		print("Warning: BrandColor '" .. tostring(name) .. "' has invalid format. Should be '1 1 1 1'. Ignoring brandColor!")

		return nil
	end

	self.brandColors[name] = color

	return color
end

function BrandColorManager:getBrandColorByName(name)
	if name ~= nil and ClassUtil.getIsValidIndexName(name) then
		name = name:upper()
		local color = self.brandColors[name]

		if color ~= nil then
			return {
				color[1],
				color[2],
				color[3],
				color[4]
			}
		end
	end

	return nil
end

function BrandColorManager:loadColorAndMaterialFromXML(xmlFile, node, shaderParam, key, name, required)
	local value = xmlFile:getValue(key .. "#" .. (name or "value"), nil, true)

	if value == nil then
		return nil
	end

	local materialId = nil
	local materialStr = xmlFile:getValue(key .. "#material")

	if materialStr == nil and node ~= nil then
		local _, _, _, w = getShaderParameter(node, shaderParam)
		materialId = w
	else
		materialId = tonumber(materialStr) or 1
	end

	value[4] = materialId or value[4] or 1

	return value
end

g_brandColorManager = BrandColorManager.new()
