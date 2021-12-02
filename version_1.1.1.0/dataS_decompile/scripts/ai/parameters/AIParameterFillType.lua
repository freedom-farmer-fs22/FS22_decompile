AIParameterFillType = {}
local AIParameterFillType_mt = Class(AIParameterFillType, AIParameter)

function AIParameterFillType.new(customMt)
	local self = AIParameter.new(customMt or AIParameterFillType_mt)
	self.type = AIParameterType.FILLTYPE
	self.fillTypes = {}
	self.fillTypeIndex = nil

	return self
end

function AIParameterFillType:saveToXMLFile(xmlFile, key, usedModNames)
	if self.fillTypeIndex ~= nil then
		local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex)

		xmlFile:setString(key .. "#fillType", fillTypeName)
	end
end

function AIParameterFillType:loadFromXMLFile(xmlFile, key)
	local fillTypeName = xmlFile:getString(key .. "#fillType")

	if fillTypeName ~= nil then
		self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	end
end

function AIParameterFillType:readStream(streamId, connection)
	if streamReadBool(streamId) then
		local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

		self:setFillTypeIndex(fillTypeIndex)
	end
end

function AIParameterFillType:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.fillTypeIndex ~= nil) then
		streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
	end
end

function AIParameterFillType:setValidFillTypes(fillTypes)
	self.fillTypes = {}
	local maxFillLevel = 0
	local maxFillLevelFillTypeIndex = nil

	for fillTypeIndex, fillLevel in pairs(fillTypes) do
		if maxFillLevel < fillLevel then
			maxFillLevelFillTypeIndex = fillTypeIndex
		end

		local title = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex).title
		title = string.format("%s (%d l)", title, fillLevel)

		table.insert(self.fillTypes, {
			index = #self.fillTypes + 1,
			fillTypeIndex = fillTypeIndex,
			title = title,
			fillLevel = fillLevel
		})
	end

	table.sort(self.fillTypes, function (a, b)
		return a.title < b.title
	end)

	if self.fillTypeIndex == nil then
		if maxFillLevelFillTypeIndex ~= nil then
			self.fillTypeIndex = maxFillLevelFillTypeIndex
		else
			self:setFillTypeByIndex(1)
		end
	end
end

function AIParameterFillType:setNextItem()
	local nextIndex = 0

	for k, data in ipairs(self.fillTypes) do
		if self.fillTypeIndex == data.fillTypeIndex then
			nextIndex = k + 1
		end
	end

	if nextIndex > #self.fillTypes then
		nextIndex = 1
	end

	self:setFillTypeByIndex(nextIndex)
end

function AIParameterFillType:setPreviousItem()
	local previousIndex = 0

	for k, data in ipairs(self.fillTypes) do
		if self.fillTypeIndex == data.fillTypeIndex then
			previousIndex = k - 1
		end
	end

	if previousIndex < 1 then
		previousIndex = #self.fillTypes
	end

	self:setFillTypeByIndex(previousIndex)
end

function AIParameterFillType:setFillTypeByIndex(index)
	local data = self.fillTypes[index]

	if data ~= nil then
		self.fillTypeIndex = data.fillTypeIndex
	else
		self.fillTypeIndex = nil
	end
end

function AIParameterFillType:setFillTypeIndex(fillTypeIndex)
	self.fillTypeIndex = fillTypeIndex
end

function AIParameterFillType:getFillTypeIndex()
	return self.fillTypeIndex
end

function AIParameterFillType:getString()
	for _, data in ipairs(self.fillTypes) do
		if data.fillTypeIndex == self.fillTypeIndex then
			return data.title
		end
	end

	return ""
end

function AIParameterFillType:validate()
	if self.fillTypeIndex == nil then
		return false, g_i18n:getText("ai_validationErrorNoFillType")
	end

	return true, nil
end
