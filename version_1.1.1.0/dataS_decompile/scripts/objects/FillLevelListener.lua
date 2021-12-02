FillLevelListener = {}
local FillLevelListener_mt = Class(FillLevelListener, Object)

InitStaticObjectClass(FillLevelListener, "FillLevelListener", ObjectIds.OBJECT_FILLLEVEL_LISTENER)

function FillLevelListener.new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = FillLevelListener_mt
	end

	local self = Object.new(isServer, isClient, customMt)

	return self
end

function FillLevelListener:load(id)
	self.node = id
	self.fillTypes = {}
	local fillTypeCategories = getUserAttribute(id, "fillTypeCategories")
	local fillTypeNames = getUserAttribute(id, "fillTypes")
	local fillTypes = nil

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: UnloadTrigger has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: UnloadTrigger has invalid fillType '%s'.")
	end

	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			self.fillTypes[fillType] = true
		end
	else
		self.fillTypes = nil
	end

	if self.fillTypes ~= nil then
		local avoidFillTypes = nil
		local avoidFillTypeNames = getUserAttribute(id, "avoidFillTypes")

		if avoidFillTypeNames ~= nil then
			avoidFillTypes = g_fillTypeManager:getFillTypesByNames(avoidFillTypeNames, "Warning: UnloadTrigger has invalid avoidFillType '%s'.")
		end

		if avoidFillTypes ~= nil then
			for _, avoidFillType in pairs(avoidFillTypes) do
				if self.fillTypes[avoidFillType] ~= nil then
					self.fillTypes[avoidFillType] = nil
				end
			end
		end
	end

	self.fillLevelMaxY = getUserAttribute(id, "fillLevelMaxY")
	local minMaxY = getUserAttribute(id, "minMaxY")
	self.minMaxY = string.getVectorN(minMaxY, 2)
	self.baseTranslation = {
		getTranslation(self.node)
	}
	self.currentY = self.baseTranslation[2]

	if self.fillTypes ~= nil and self.fillLevelMaxY ~= nil and self.minMaxY ~= nil then
		self.dirtyFlag = self:getNextDirtyFlag()

		return true
	else
		return false
	end
end

function FillLevelListener:delete()
end

function FillLevelListener:readStream(streamId, connection)
	FillLevelListener:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local newY = streamWriteFloat32(streamId)

		setTranslation(self.node, self.baseTranslation[1], newY, self.baseTranslation[3])
	end
end

function FillLevelListener:writeStream(streamId, connection)
	FillLevelListener:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteFloat32(streamId, self.currentY)
	end
end

function FillLevelListener:readUpdateStream(streamId, timestamp, connection)
	FillLevelListener:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		local newY = streamWriteFloat32(streamId)

		setTranslation(self.node, self.baseTranslation[1], newY, self.baseTranslation[3])
	end
end

function FillLevelListener:writeUpdateStream(streamId, connection, dirtyMask)
	FillLevelListener:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.currentY)
	end
end

function FillLevelListener:setSource(source)
	assert(source.getFillLevel ~= nil)
	assert(source.getSupportedFillTypes ~= nil)

	self.source = source
	local supportedFillTypes = self.source:getSupportedFillTypes()

	for fillType, _ in pairs(self.fillTypes) do
		if supportedFillTypes[fillType] ~= true then
			self.fillTypes[fillType] = nil
		end
	end

	self.fillLevels = {}

	for fillType, _ in pairs(self.fillTypes) do
		self.fillLevels[fillType] = 0
	end
end

function FillLevelListener:fillLevelsChanged()
	local fillLevelSum = 0

	for fillType, fillLevel in pairs(self.fillLevels) do
		fillLevelSum = fillLevelSum + fillLevel
	end

	local p = math.min(1, fillLevelSum / self.fillLevelMaxY)
	local newY = self.minMaxY[1] + p * (self.minMaxY[2] - self.minMaxY[1])

	if newY ~= self.currentY then
		self:raiseDirtyFlags(self.dirtyFlag)
	end

	self.currentY = newY

	setTranslation(self.node, self.baseTranslation[1], newY, self.baseTranslation[3])
end
