PlaceableColorable = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableColorable.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getAvailableColors", PlaceableColorable.getAvailableColors)
	SpecializationUtil.registerFunction(placeableType, "setColor", PlaceableColorable.setColor)
	SpecializationUtil.registerFunction(placeableType, "getColor", PlaceableColorable.getColor)
	SpecializationUtil.registerFunction(placeableType, "getHasColors", PlaceableColorable.getHasColors)
end

function PlaceableColorable.registerOverwrittenFunctions(placeableType)
end

function PlaceableColorable.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableColorable)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableColorable)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableColorable)
end

function PlaceableColorable.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Colorable")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".colorable.nodes.node(?)#node", "Bees action radius")
	schema:register(XMLValueType.COLOR, basePath .. ".colorable.colors.color(?)#value", "Color")
	schema:setXMLSpecializationType()
end

function PlaceableColorable.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Colorable")
	schema:register(XMLValueType.INT, basePath .. ".color", "Active color index")
	schema:setXMLSpecializationType()
end

function PlaceableColorable:onLoad(savegame)
	local spec = self.spec_colorable
	local xmlFile = self.xmlFile
	spec.nodes = {}
	spec.colors = {}
	spec.currentColorIndex = 0

	xmlFile:iterate("placeable.colorable.nodes.node", function (_, nodeKey)
		local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			if not getHasShaderParameter(node, "colorScale0") then
				Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter 'colorScale0' for key '%s'!", getName(node), nodeKey)
			else
				table.insert(spec.nodes, node)
			end
		end
	end)
	xmlFile:iterate("placeable.colorable.colors.color", function (_, colorKey)
		local color = xmlFile:getValue(colorKey .. "#value", nil, true)

		if color ~= nil then
			table.insert(spec.colors, color)
		end

		if #spec.colors == 255 then
			return false
		end
	end)

	if #spec.colors > 0 then
		self:setColor(1)
	end

	if not self:getHasColors() then
		SpecializationUtil.removeEventListener(self, "onWriteStream", PlaceableColorable)
		SpecializationUtil.removeEventListener(self, "onReadStream", PlaceableColorable)
	end
end

function PlaceableColorable:onReadStream(streamId, connection)
	local spec = self.spec_colorable
	spec.currentColorIndex = streamReadUInt8(streamId)

	self:setColor(spec.currentColorIndex)
end

function PlaceableColorable:onWriteStream(streamId, connection)
	local spec = self.spec_colorable

	streamWriteUInt8(streamId, spec.currentColorIndex)
end

function PlaceableColorable:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_colorable
	spec.currentColorIndex = xmlFile:getValue(key .. ".color", math.min(#spec.colors, 1))

	self:setColor(spec.currentColorIndex)
end

function PlaceableColorable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_colorable

	if self:getHasColors() then
		xmlFile:setValue(key .. ".color", spec.currentColorIndex)
	end
end

function PlaceableColorable:getAvailableColors()
	return self.spec_colorable.colors
end

function PlaceableColorable:setColor(index)
	local spec = self.spec_colorable
	index = math.min(index, #spec.colors)
	spec.currentColorIndex = index

	if index == 0 then
		return
	end

	local r, g, b = unpack(spec.colors[index])

	for _, node in ipairs(spec.nodes) do
		setShaderParameter(node, "colorScale0", r, g, b, 1, false)
	end
end

function PlaceableColorable:getColor()
	return self.spec_colorable.currentColorIndex
end

function PlaceableColorable:getHasColors()
	return #self.spec_colorable.colors > 0 and #self.spec_colorable.nodes > 0
end
