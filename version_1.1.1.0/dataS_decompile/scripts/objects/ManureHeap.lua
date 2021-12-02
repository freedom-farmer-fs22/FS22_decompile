ManureHeap = {}
local ManureHeap_mt = Class(ManureHeap, Object)

InitStaticObjectClass(ManureHeap, "ManureHeap", ObjectIds.OBJECT_MANURE_HEAP)

function ManureHeap.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or ManureHeap_mt)
	self.unloadingStations = {}
	self.loadingStations = {}
	self.fillLevelChangedListeners = {}
	self.rootNode = 0

	return self
end

function ManureHeap:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = xmlFile:getValue(key .. "#node", components[1].node, components, i3dMappings)

	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing root node for manure heap")

		return false
	end

	local areaStart = xmlFile:getValue(key .. ".area#startNode", nil, components, i3dMappings)
	local areaWidth = xmlFile:getValue(key .. ".area#widthNode", nil, components, i3dMappings)
	local areaHeight = xmlFile:getValue(key .. ".area#heightNode", nil, components, i3dMappings)

	if areaStart == nil then
		Logging.xmlError(xmlFile, "Missing start node for manure heap")

		return false
	end

	if areaWidth == nil then
		Logging.xmlError(xmlFile, "Missing width node for manure heap")

		return false
	end

	if areaHeight == nil then
		Logging.xmlError(xmlFile, "Missing height node for manure heap")

		return false
	end

	local activationTriggerNode = xmlFile:getValue(key .. ".area#activationTriggerNode", nil, components, i3dMappings)

	if activationTriggerNode == nil then
		Logging.xmlError(xmlFile, "Missing activation trigger node for manure heap")

		return false
	end

	self.activationTriggerNode = activationTriggerNode

	if self.isServer then
		addTrigger(self.activationTriggerNode, "onVehicleCallback", self)
	end

	local clearAreaStart = xmlFile:getValue(key .. ".clearArea#startNode", nil, components, i3dMappings)
	local clearAreaWidth = xmlFile:getValue(key .. ".clearArea#widthNode", nil, components, i3dMappings)
	local clearAreaHeight = xmlFile:getValue(key .. ".clearArea#heightNode", nil, components, i3dMappings)

	if clearAreaStart == nil then
		Logging.xmlError(xmlFile, "Missing clear area start node for manure heap")

		return false
	end

	if clearAreaWidth == nil then
		Logging.xmlError(xmlFile, "Missing clear area width node for manure heap")

		return false
	end

	if clearAreaHeight == nil then
		Logging.xmlError(xmlFile, "Missing clear area height node for manure heap")

		return false
	end

	local capacity = xmlFile:getValue(key .. "#capacity", 20000)

	if capacity <= 0 then
		Logging.xmlError(xmlFile, "Invalid capacity")

		return false
	end

	self.fillTypeIndex = FillType.MANURE
	self.capacity = capacity
	self.fillTypes = {
		[self.fillTypeIndex] = true
	}
	self.fillLevels = {
		[self.fillTypeIndex] = 0
	}
	self.minValidLiterValue = g_densityMapHeightManager:getMinValidLiterValue(self.fillTypeIndex)
	self.manureToDrop = 0
	self.manureToPick = 0
	self.visibleFillLevel = 0
	self.lastVisibleFillLevel = 0
	self.area = {
		start = areaStart,
		width = areaWidth,
		height = areaHeight
	}
	self.clearArea = {
		start = clearAreaStart,
		width = clearAreaWidth,
		height = clearAreaHeight
	}
	self.splitAreas = DensityMapHeightUtil.getAreaPartitions(areaStart, areaWidth, areaHeight)
	self.dirtyFlag = self:getNextDirtyFlag()

	return true
end

function ManureHeap:delete()
	if self.isServer then
		local xs, _, zs = getWorldTranslation(self.clearArea.start)
		local xw, _, zw = getWorldTranslation(self.clearArea.width)
		local xh, _, zh = getWorldTranslation(self.clearArea.height)

		DensityMapHeightUtil.clearArea(xs, zs, xw, zw, xh, zh)
	end

	if self.activationTriggerNode ~= nil then
		removeTrigger(self.activationTriggerNode)

		self.activationTriggerNode = nil
	end

	if self.area ~= nil then
		g_densityMapHeightManager:removeFixedFillTypesArea(self.area)
	end

	ManureHeap:superClass().delete(self)
end

function ManureHeap:finalize()
	g_densityMapHeightManager:setFixedFillTypesArea(self.area, self.fillTypes)
end

function ManureHeap:loadFromXMLFile(xmlFile, key)
	self.manureToDrop = xmlFile:getValue(key .. "#manureToDrop", self.manureToDrop)
	self.manureToPick = xmlFile:getValue(key .. "#manureToPick", self.manureToPick)

	return true
end

function ManureHeap:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#manureToDrop", self.manureToDrop)
	xmlFile:setValue(key .. "#manureToPick", self.manureToPick)
end

function ManureHeap:readStream(streamId, connection)
	ManureHeap:superClass().readStream(self, streamId, connection)

	self.fillLevels[self.fillTypeIndex] = streamReadFloat32(streamId)
end

function ManureHeap:writeStream(streamId, connection)
	ManureHeap:superClass().writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.fillLevels[self.fillTypeIndex])
end

function ManureHeap:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		self.fillLevels[self.fillTypeIndex] = streamReadInt32(streamId)
	end
end

function ManureHeap:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteInt32(streamId, self.fillLevels[self.fillTypeIndex])
	end
end

function ManureHeap:update(dt)
	if self.isServer then
		if self.minValidLiterValue < self.manureToDrop then
			local litersToDrop = self.manureToDrop

			for _, area in ipairs(self.splitAreas) do
				local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(area.start, area.width, area.height, false)
				local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, litersToDrop, self.fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, radius, area.lineOffset, false, nil)
				area.lineOffset = lineOffset
				litersToDrop = math.max(litersToDrop - dropped, 0)

				if litersToDrop <= 0 then
					break
				end
			end

			self.manureToDrop = litersToDrop
		end

		if self.minValidLiterValue < self.manureToPick then
			local litersToPick = self.manureToPick

			for i = #self.splitAreas, 1, -1 do
				local area = self.splitAreas[i]
				local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(area.start, area.width, area.height, false)
				local picked, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, -litersToPick, self.fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, radius, area.lineOffset, false, nil)
				area.lineOffset = lineOffset
				litersToPick = math.max(litersToPick + picked, 0)

				if litersToPick <= 0 then
					break
				end
			end

			self.manureToPick = litersToPick
		end

		self:updateTotalFillLevel()
	end
end

function ManureHeap:updateTotalFillLevel()
	local xs, _, zs = getWorldTranslation(self.area.start)
	local xw, _, zw = getWorldTranslation(self.area.width)
	local xh, _, zh = getWorldTranslation(self.area.height)
	local visibleFillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fillTypeIndex, xs, zs, xw, zw, xh, zh)

	if visibleFillLevel ~= self.lastVisibleFillLevel then
		self.fillLevels[self.fillTypeIndex] = visibleFillLevel + self.manureToDrop - self.manureToPick
		self.lastVisibleFillLevel = visibleFillLevel

		self:raiseDirtyFlags(self.dirtyFlag)
	end
end

function ManureHeap:getIsFillTypeSupported(fillTypeIndex)
	return fillTypeIndex == self.fillTypeIndex
end

function ManureHeap:getFillLevel(fillTypeIndex)
	if fillTypeIndex == self.fillTypeIndex then
		return self.fillLevels[fillTypeIndex]
	end

	return 0
end

function ManureHeap:getFillLevels()
	return self.fillLevels
end

function ManureHeap:getCapacity(fillTypeIndex)
	if fillTypeIndex == self.fillTypeIndex then
		return self.capacity
	end

	return 0
end

function ManureHeap:setFillLevel(fillLevel, fillTypeIndex)
	if fillTypeIndex ~= self.fillTypeIndex then
		return
	end

	local oldFillLevel = self.fillLevels[fillTypeIndex]
	fillLevel = MathUtil.clamp(fillLevel, 0, self.capacity)
	local delta = fillLevel - oldFillLevel
	local absDelta = math.abs(delta)

	if absDelta > 0.1 then
		self.fillLevels[fillTypeIndex] = fillLevel

		if self.isServer then
			if delta > 0 then
				self.manureToDrop = self.manureToDrop + absDelta
			else
				self.manureToPick = self.manureToPick + absDelta
			end

			if self.manureToDrop < self.manureToPick then
				self.manureToPick = self.manureToPick - self.manureToDrop
				self.manureToDrop = 0
			else
				self.manureToDrop = self.manureToDrop - self.manureToPick
				self.manureToPick = 0
			end

			self:raiseActive()
			self:raiseDirtyFlags(self.dirtyFlag)
		end

		for _, func in ipairs(self.fillLevelChangedListeners) do
			func(self.fillTypeIndex, delta)
		end
	end
end

function ManureHeap:removeManure(absDelta)
	if self.isServer then
		local newFillLevel = math.max(self.fillLevels[self.fillTypeIndex] - absDelta, 0)

		self:setFillLevel(newFillLevel, self.fillTypeIndex)
	end
end

function ManureHeap:getFreeCapacity(fillTypeIndex)
	if fillTypeIndex == self.fillTypeIndex then
		return math.max(self.capacity - self.fillLevels[self.fillTypeIndex], 0)
	end

	return 0
end

function ManureHeap:getSupportedFillTypes()
	return self.fillTypes
end

function ManureHeap:onVehicleCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onLeave then
		local node = g_currentMission:getNodeObject(otherId)

		if node ~= nil then
			self:raiseActive()
		end
	elseif onEnter and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		self:raiseActive()
	end
end

function ManureHeap:addUnloadingStation(station)
	self.unloadingStations[station] = station
end

function ManureHeap:removeUnloadingStation(station)
	self.unloadingStations[station] = nil
end

function ManureHeap:addLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = loadingStation
end

function ManureHeap:removeLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = nil
end

function ManureHeap:addFillLevelChangedListeners(func)
	table.addElement(self.fillLevelChangedListeners, func)
end

function ManureHeap:removeFillLevelChangedListeners(func)
	table.removeElement(self.fillLevelChangedListeners, func)
end

function ManureHeap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Manure heap rootnode")
	schema:register(XMLValueType.INT, basePath .. "#capacity", "Capacity", 20000)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Manure area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Manure area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Manure area height node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#activationTriggerNode", "Activation trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#startNode", "Manure clear area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#widthNode", "Manure clear area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearArea#heightNode", "Manure clear area height node")
end

function ManureHeap.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#manureToDrop", "Manure that should be drop the visible heap", 0)
	schema:register(XMLValueType.INT, basePath .. "#manureToPick", "Manure that need to be picked from visible heap", 0)
end
