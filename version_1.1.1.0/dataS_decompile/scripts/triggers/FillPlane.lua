FillPlane = {}
local FillPlane_mt = Class(FillPlane)

function FillPlane.new(customMt)
	local self = setmetatable({}, customMt or FillPlane_mt)
	self.node = nil
	self.maxCapacity = 0
	self.moveMinY = 0
	self.moveMaxY = 0
	self.loaded = false
	self.colorChange = false

	return self
end

function FillPlane:delete()
end

function FillPlane:load(components, xmlFile, xmlNode, i3dMappings)
	local fillPlaneNode = xmlFile:getValue(xmlNode .. "#node", nil, components, i3dMappings)

	if fillPlaneNode ~= nil then
		self.node = fillPlaneNode
		local x, y, z = getTranslation(self.node)
		self.moveMinY = xmlFile:getValue(xmlNode .. "#minY", y)
		self.moveMaxY = xmlFile:getValue(xmlNode .. "#maxY", y)
		self.colorChange = xmlFile:getValue(xmlNode .. "#colorChange", false)

		if self.colorChange and not getHasShaderParameter(self.node, "colorScale") then
			Logging.warning("Fillplane '%s' has no shader parameter 'colorScale'. Disabled color change!", getName(self.node))

			self.colorChange = false
		end

		if self.moveMaxY < self.moveMinY then
			self.moveMaxY = self.moveMinY
			self.moveMinY = self.moveMaxY

			Logging.warning("Fillplane '%s' has inverted moveMinY and moveMaxY values. Switched values!", getName(self.node))
		end

		self.loaded = true

		setTranslation(self.node, x, self.moveMinY, z)

		local rotX, _, _ = getRotation(self.node)
		self.rotMinX = xmlFile:getValue(xmlNode .. "#minRotX", rotX)
		self.rotMaxX = xmlFile:getValue(xmlNode .. "#maxRotX", rotX)
		self.changeVisibility = xmlFile:getValue(xmlNode .. "#changeVisibility", false)

		return true
	end

	return false
end

function FillPlane:setState(state)
	if self.loaded then
		local y = MathUtil.lerp(self.moveMinY, self.moveMaxY, state)
		local x, oldY, z = getTranslation(self.node)

		setTranslation(self.node, x, y, z)

		local rotX = MathUtil.lerp(self.rotMinX, self.rotMaxX, state)

		setRotation(self.node, rotX, 0, 0)
		setVisibility(self.node, not self.changeVisibility or state > 0)

		return oldY ~= y
	end

	return false
end

function FillPlane:setColorScale(colorScale)
	if self.loaded then
		setShaderParameter(self.node, "colorScale", colorScale[1], colorScale[2], colorScale[3], 0, false)
	end
end

function FillPlane.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Fill plane node")
	schema:register(XMLValueType.FLOAT, basePath .. "#minY", "Fill plane min y")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxY", "Fill plane max y")
	schema:register(XMLValueType.ANGLE, basePath .. "#minRotX", "Fill plane min rotation x")
	schema:register(XMLValueType.ANGLE, basePath .. "#maxRotX", "Fill plane max rotation x")
	schema:register(XMLValueType.BOOL, basePath .. "#changeVisibility", "Hide node if state is zero")
	schema:register(XMLValueType.BOOL, basePath .. "#colorChange", "Fill plane color change", false)
end
