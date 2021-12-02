LicensePlate = {}
local LicensePlate_mt = Class(LicensePlate)

function LicensePlate.new(customMt)
	local self = {}

	setmetatable(self, customMt or LicensePlate_mt)

	self.variationIndex = 1
	self.characters = ""
	self.manager = g_licensePlateManager

	return self
end

function LicensePlate:loadFromXML(node, filename, customEnvironment, xmlFile, key)
	local typeStr = xmlFile:getValue(key .. "#type", "ELONGATED")

	if typeStr ~= nil then
		self.type = LicensePlateManager.PLATE_TYPE[typeStr]

		if self.type ~= nil then
			self.node = node
			self.filename = filename
			self.width = xmlFile:getValue(key .. "#width", 1)
			self.height = xmlFile:getValue(key .. "#height", 0.3)
			self.fontSize = xmlFile:getValue(key .. ".font#size", 0.1)
			self.fontScaleX = xmlFile:getValue(key .. ".font#scaleX", 1)
			self.fontScaleY = xmlFile:getValue(key .. ".font#scaleY", 1)
			self.widthOffsetLeft = 0
			self.widthOffsetRight = 0
			self.heightOffsetTop = 0
			self.heightOffsetBot = 0
			self.font = g_licensePlateManager:getFont()

			if self.font == nil then
				Logging.error("LicensePlate: Unable to get font from LicensePlateManager, possibly not initialized/loaded yet")
				printCallstack()

				return false
			end

			self.fontMaxWidthRatio = self.font:getFontMaxWidthRatio()
			self.variations = {}

			xmlFile:iterate(key .. ".variations.variation", function (_, variationKey)
				local variation = {
					values = {}
				}
				local realIndex = 0

				xmlFile:iterate(variationKey .. ".value", function (index, valueKey)
					local value = {
						index = index,
						realIndex = realIndex + 1,
						nodePath = xmlFile:getValue(valueKey .. "#node")
					}
					value.node = I3DUtil.indexToObject(self.node, value.nodePath)
					value.nextSection = xmlFile:getValue(valueKey .. "#nextSection", false)

					if value.nodePath ~= nil and value.node ~= nil then
						local x, y, z = getTranslation(value.node)
						value.posX = xmlFile:getValue(valueKey .. "#posX", x)
						value.posY = xmlFile:getValue(valueKey .. "#posY", y)
						value.posZ = xmlFile:getValue(valueKey .. "#posZ", z)
						value.character = xmlFile:getValue(valueKey .. "#character")
						value.numerical = xmlFile:getValue(valueKey .. "#numerical", false)
						value.alphabetical = xmlFile:getValue(valueKey .. "#alphabetical", false)
						value.special = xmlFile:getValue(valueKey .. "#special", false)
						value.isStatic = xmlFile:getValue(valueKey .. "#isStatic", not value.numerical and not value.alphabetical and not value.special and value.character == nil)
						value.locked = xmlFile:getValue(valueKey .. "#locked", value.character ~= nil)
						value.maxWidthRatio = self.font:getFontMaxWidthRatio(value.alphabetical, value.numerical, value.special)
						local positionStr = xmlFile:getValue(valueKey .. "#position", "ANY")
						local position = LicensePlateManager.PLATE_POSITION[positionStr:upper()]

						if position == nil then
							Logging.xmlError(xmlFile, "Unknown position '%s' in '%s'", positionStr, valueKey)
						end

						value.position = position or LicensePlateManager.PLATE_POSITION.ANY

						if not value.isStatic then
							realIndex = realIndex + 1
						end

						table.insert(variation.values, value)
					end
				end)

				variation.colors = {}

				xmlFile:iterate(variationKey .. ".color", function (_, colorKey)
					local color = {
						shaderParameter = xmlFile:getValue(colorKey .. "#shaderParameter"),
						color = xmlFile:getValue(colorKey .. "#color", nil, true)
					}

					if color.shaderParameter ~= nil and color.color ~= nil then
						table.insert(variation.colors, color)
					end
				end)

				if #variation.values > 0 then
					table.insert(self.variations, variation)
				end
			end)

			self.frame = {
				node = xmlFile:getValue(key .. ".frame#node"),
				widthOffset = xmlFile:getValue(key .. ".frame#widthOffset", 0),
				heightOffsetTop = xmlFile:getValue(key .. ".frame#heightOffsetTop", 0),
				heightOffsetBot = xmlFile:getValue(key .. ".frame#heightOffsetBot", 0)
			}

			if self.frame.node == nil or I3DUtil.indexToObject(self.node, self.frame.node) == nil then
				self.frame = nil
			end
		else
			return false
		end
	end

	return true
end

function LicensePlate:delete()
	delete(self.node)
end

function LicensePlate:clone(includeFrame)
	local licensePlateClone = LicensePlate.new()
	licensePlateClone.node = clone(self.node, false, false, false)
	licensePlateClone.type = self.type
	licensePlateClone.filename = self.filename
	licensePlateClone.width = self.width
	licensePlateClone.height = self.height
	licensePlateClone.fontSize = self.fontSize
	licensePlateClone.fontScaleX = self.fontScaleX
	licensePlateClone.fontScaleY = self.fontScaleY
	licensePlateClone.rawWidth = self.width
	licensePlateClone.rawHeight = self.height
	licensePlateClone.widthOffsetLeft = 0
	licensePlateClone.widthOffsetRight = 0
	licensePlateClone.heightOffsetTop = 0
	licensePlateClone.heightOffsetBot = 0
	licensePlateClone.font = self.font
	licensePlateClone.fontMaxWidthRatio = self.fontMaxWidthRatio
	licensePlateClone.variations = table.copy(self.variations, math.huge)

	for i = 1, #licensePlateClone.variations do
		local variation = licensePlateClone.variations[i]

		for j = 1, #variation.values do
			local value = variation.values[j]
			value.node = I3DUtil.indexToObject(licensePlateClone.node, value.nodePath)
		end
	end

	licensePlateClone.frame = table.copy(self.frame, math.huge)

	if licensePlateClone.frame ~= nil then
		includeFrame = includeFrame == true
		local frameNode = I3DUtil.indexToObject(licensePlateClone.node, licensePlateClone.frame.node)

		if frameNode ~= nil then
			setVisibility(frameNode, includeFrame)

			if includeFrame then
				licensePlateClone.width = licensePlateClone.width + 2 * licensePlateClone.frame.widthOffset
				licensePlateClone.height = licensePlateClone.height + licensePlateClone.frame.heightOffsetTop + licensePlateClone.frame.heightOffsetBot
				licensePlateClone.widthOffsetLeft = licensePlateClone.frame.widthOffset
				licensePlateClone.widthOffsetRight = licensePlateClone.frame.widthOffset
				licensePlateClone.heightOffsetTop = licensePlateClone.frame.heightOffsetTop
				licensePlateClone.heightOffsetBot = licensePlateClone.frame.heightOffsetBot
			end
		end
	end

	licensePlateClone:setVariation(self.variationIndex)

	return licensePlateClone
end

function LicensePlate:updateData(variationIndex, position, characters, validate)
	if variationIndex ~= self.variationIndex then
		self:setVariation(variationIndex)
	end

	if validate == true then
		characters = self:validateLicensePlateCharacters(characters)
	end

	self.characters = characters
	local variation = self.variations[self.variationIndex]

	if variation ~= nil then
		local stringPos = 1

		for i = 1, #variation.values do
			local value = variation.values[i]

			if value.node ~= nil then
				setTranslation(value.node, value.posX, value.posY, value.posZ)

				local samePosition = (value.position == LicensePlateManager.PLATE_POSITION.ANY or value.position == position) and value.position ~= LicensePlateManager.PLATE_POSITION.NONE
				local targetChar = value.character or characters:sub(stringPos, stringPos)

				if not value.isStatic and targetChar ~= "" and targetChar ~= "_" and samePosition then
					self.font:updateSingleCharacter(value.singleCharacter, targetChar)
					setVisibility(value.node, true)
				elseif value.isStatic and samePosition then
					setVisibility(value.node, true)
				else
					setVisibility(value.node, false)
				end

				if not value.isStatic then
					stringPos = stringPos + 1
				end
			end
		end
	end
end

function LicensePlate:setVariation(variationIndex)
	local variation = self.variations[variationIndex]

	if variation ~= nil then
		local oldVariation = self.variations[self.variationIndex]

		for i = 1, #oldVariation.values do
			local value = oldVariation.values[i]

			if not value.isStatic then
				for j = 1, getNumOfChildren(value.node) do
					delete(getChildAt(value.node, j - 1))
				end
			end
		end

		self.variationIndex = variationIndex

		for i = 1, #variation.values do
			local value = variation.values[i]

			if not value.isStatic then
				value.singleCharacter = self.font:createSingleCharacter(value.node, self.fontSize, {
					0,
					0,
					0,
					1
				}, nil, 0, self.fontScaleX, self.fontScaleY, 0)
			end
		end

		for i = 1, #variation.colors do
			local color = variation.colors[i]

			I3DUtil.setShaderParameterRec(self.node, color.shaderParameter, color.color[1], color.color[2], color.color[3])
		end
	end
end

function LicensePlate:getFontSize()
	return self.fontSize * self.fontMaxWidthRatio, self.fontSize
end

function LicensePlate:setColorIndex(colorIndex)
	local colors, _ = self.manager:getAvailableColors()
	local colorData = colors[colorIndex]

	if colorData ~= nil then
		self:setColor(colorData.color[1], colorData.color[2], colorData.color[3])
	end
end

function LicensePlate:getColor(colorIndex)
	local colors, _ = self.manager:getAvailableColors()
	local colorData = colors[colorIndex]

	if colorData ~= nil then
		return colorData.color
	end
end

function LicensePlate:setColor(r, g, b)
	I3DUtil.setShaderParameterRec(self.node, g_licensePlateManager.shaderParameterPlate, r, g, b)

	for j = 1, #self.variations do
		for i = 1, #self.variations[j].values do
			local value = self.variations[j].values[i]

			if value.node ~= nil then
				I3DUtil.setShaderParameterRec(value.node, g_licensePlateManager.shaderParameterCharacters, r, g, b)
			end
		end
	end
end

function LicensePlate:getRandomCharacters(variationIndex)
	local characters = {}
	local firstNumericCharacter = true
	local variation = self.variations[variationIndex]

	if variation ~= nil then
		for i = 1, #variation.values do
			local value = variation.values[i]

			if not value.isStatic then
				if value.character == nil then
					local random = math.random()
					local sourceCharacters = self.font.characters

					if value.alphabetical then
						sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
					elseif value.numerical then
						sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
					elseif value.special then
						sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
					end

					if sourceCharacters ~= nil and #sourceCharacters > 0 then
						local index = math.max(math.floor(random * #sourceCharacters), 1)

						if value.numerical and firstNumericCharacter then
							if index == 1 and #sourceCharacters > 1 then
								index = 2
							end

							firstNumericCharacter = false
						end

						table.insert(characters, sourceCharacters[index].value)
					else
						table.insert(characters, "0")
					end
				else
					table.insert(characters, value.character)
				end
			end
		end
	end

	return characters
end

function LicensePlate:validateLicensePlateCharacters(characters)
	local str = characters
	local isTbl = type(characters) == "table"
	local length = nil

	if isTbl then
		str = table.concat(characters, "")
		length = #characters
	else
		length = characters:len()
	end

	local variation = self.variations[self.variationIndex]
	str = filterText(str, false, false)

	for i = 1, length do
		local replacement = str:sub(i, i)
		local old = nil

		if isTbl then
			old = characters[i]
		else
			old = characters:sub(i, i)
		end

		if replacement ~= old then
			local value = variation.values[i]

			if value ~= nil then
				local sourceCharacters = self.font.characters

				if value.alphabetical then
					sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL]
				elseif value.numerical then
					sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL]
				elseif value.special then
					sourceCharacters = self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL]
				end

				if isTbl then
					characters[i] = sourceCharacters[1].value
				else
					characters = str:sub(1, i - 1) .. sourceCharacters[1].value .. str:sub(i + 1)
				end
			end
		end
	end

	return characters
end

function LicensePlate:changeCharacter(variationIndex, currentCharacters, valueIndex, direction)
	local variation = self.variations[variationIndex]

	if variation ~= nil then
		local value = variation.values[valueIndex]
		local currentCharacter = currentCharacters[value.realIndex]
		local sourceCharactersSources = {}

		if value.alphabetical then
			table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL])
		end

		if value.numerical then
			table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL])
		end

		if value.special then
			table.insert(sourceCharactersSources, self.font.charactersByType[MaterialManager.FONT_CHARACTER_TYPE.SPECIAL])
		end

		local newSource = nil
		local newIndex = 1

		for j = 1, #sourceCharactersSources do
			local source = sourceCharactersSources[j]

			for i = 1, #source do
				local sourceCharacter = source[i]

				if sourceCharacter.value == currentCharacter then
					newIndex = i + direction

					if newIndex > #source then
						local nextSource = sourceCharactersSources[j + 1]

						if nextSource ~= nil then
							newIndex = 1
							newSource = nextSource
						else
							newIndex = #source
							newSource = source
						end
					elseif newIndex < 1 then
						local prevSource = sourceCharactersSources[j - 1]

						if prevSource ~= nil then
							newIndex = #prevSource
							newSource = prevSource
						else
							newIndex = 1
							newSource = source
						end
					else
						newSource = source
					end
				end
			end
		end

		if newSource ~= nil and newSource[newIndex] ~= nil then
			currentCharacters[value.realIndex] = newSource[newIndex].value
		end
	end

	return currentCharacters
end

function LicensePlate:getFormattedString()
	if self.characters == "" then
		return nil
	end

	local str = ""
	local variation = self.variations[self.variationIndex]

	if variation ~= nil then
		for i = 1, #variation.values do
			local value = variation.values[i]

			if not value.isStatic then
				local char = self.characters:sub(i, i) or ""

				if char ~= "_" then
					if value.nextSection then
						str = str .. " " .. char
					else
						str = str .. char
					end
				end
			end
		end
	end

	return str
end

function LicensePlate.registerXMLPaths(schema, baseName)
	schema:register(XMLValueType.STRING, baseName .. "#filename", "License plate i3d filename")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "License plate node")
	schema:register(XMLValueType.STRING, baseName .. "#type", "License plate type 'SQUARISH' or 'ELONGATED'", "ELONGATED")
	schema:register(XMLValueType.FLOAT, baseName .. "#width", "Width of license plate", 1)
	schema:register(XMLValueType.FLOAT, baseName .. "#height", "Height of license plate", 0.2)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#size", "Size of font", 0.1)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleX", "Additional scaling of font X", 1)
	schema:register(XMLValueType.FLOAT, baseName .. ".font#scaleY", "Additional scaling of font Y", 1)
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#node", "Value mesh index")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posX", "X translation of value node")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posY", "Y translation of value node")
	schema:register(XMLValueType.FLOAT, baseName .. ".variations.variation(?).value(?)#posZ", "Z translation of value node")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#nextSection", "Is start character for next section", false)
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#character", "Pre defined character of node")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#numerical", "Node supports numeric characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#alphabetical", "Node supports alphabetical characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#special", "Node supports special characters", false)
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#isStatic", "Node is only static without applying of characters", "is static if 'numerical' and 'alphabetical' are both on false and no fixed character is given")
	schema:register(XMLValueType.BOOL, baseName .. ".variations.variation(?).value(?)#locked", "Character value can not be changed", "locked when character is defined")
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).value(?)#position", "Value will be hidden of position differs from placement position", "ANY")
	schema:register(XMLValueType.STRING, baseName .. ".variations.variation(?).color(?)#shaderParameter", "Shader parameter to set")
	schema:register(XMLValueType.COLOR, baseName .. ".variations.variation(?).color(?)#color", "Color to apply on shader parameter")
	schema:register(XMLValueType.STRING, baseName .. ".frame#node", "Frame node that can be toggled")
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#widthOffset", "Width of frame on each side", 0)
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetTop", "Height of frame on top", 0)
	schema:register(XMLValueType.FLOAT, baseName .. ".frame#heightOffsetBot", "Height of frame at bottom", 0)
end
