DigitalDisplay = {}
local DigitalDisplay_mt = Class(DigitalDisplay)

function DigitalDisplay.new(customMt)
	return setmetatable({}, customMt or DigitalDisplay_mt)
end

function DigitalDisplay:load(components, xmlFile, key, i3dMappings)
	self.baseNode = xmlFile:getValue(key .. "#baseNode", nil, components, i3dMappings)

	if self.baseNode ~= nil then
		self.precision = xmlFile:getValue(key .. "#precision", 0)
		self.showZero = xmlFile:getValue(key .. "#showZero", true)

		return true
	end

	return false
end

function DigitalDisplay:setValue(value)
	if self.baseNode ~= nil then
		I3DUtil.setNumberShaderByValue(self.baseNode, math.max(0, value), self.precision, self.showZero)
	end
end

function DigitalDisplay.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#baseNode", "Base node", false)
	schema:register(XMLValueType.INT, basePath .. "#precision", "Precision", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#showZero", "Show zeros or hide them", true)
end
