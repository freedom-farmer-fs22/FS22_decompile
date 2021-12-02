InlineBale = {
	xmlSchema = nil
}

source("dataS/scripts/events/InlineBaleOpenEvent.lua")
InitStaticObjectClass(InlineBale, "InlineBale", ObjectIds.OBJECT_INLINE_BALE)

local InlineBale_mt = Class(InlineBale, Object)

g_xmlManager:addCreateSchemaFunction(function ()
	InlineBale.xmlSchema = XMLSchema.new("inlineBale")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = InlineBale.xmlSchema

	schema:register(XMLValueType.FLOAT, "inlineBale#maxOpenDistance", "Max. distance to player to allow opening of bale", 3)
	schema:register(XMLValueType.STRING, "inlineBale.replacementBale#filename", "Filename of bale replacement")
	schema:register(XMLValueType.STRING, "inlineBale.textures#diffuse", "Wrapping diffuse file to apply on bale")
	schema:register(XMLValueType.STRING, "inlineBale.textures#normal", "Wrapping normal file to apply on bale")
	schema:register(XMLValueType.FLOAT, "inlineBale.wrapping.key(?)#time", "Wrapping time")
	schema:register(XMLValueType.FLOAT, "inlineBale.wrapping.key(?)#wrappingState", "Wrapping shader state")
	schema:register(XMLValueType.VECTOR_ROT, "inlineBale.joint#startRotLimit", "Start rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, "inlineBale.joint#endRotLimit", "End rotation limit")
	schema:register(XMLValueType.VECTOR_TRANS, "inlineBale.joint#startTransLimit", "Start translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, "inlineBale.joint#endTransLimit", "End translation limit")
	schema:register(XMLValueType.INT, "inlineBale.joint#wrappingAxis", "Wrapping axis of bale", 1)
	schema:register(XMLValueType.TIME, "inlineBale.joint#lockTime", "Time until joint is fully locked (sec)", 5)
	schema:register(XMLValueType.STRING, "inlineBale.connector#filename", "Path to connector file")
	schema:register(XMLValueType.INT, "inlineBale.connector#axis", "Connector axis index", 1)
	schema:register(XMLValueType.FLOAT, "inlineBale.connector#offset", "Connection placement offset", 0.5)

	local savegameSchema = ItemSystem.xmlSchemaSavegame

	savegameSchema:register(XMLValueType.STRING, "items.item(?)#filename", "Filename")
	savegameSchema:register(XMLValueType.INT, "items.item(?).bales.bale(?)#saveId", "Save id of inline bale")
end)

function InlineBale.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or InlineBale_mt)
	self.bales = {}
	self.baleJoints = {}
	self.pendingBale = nil
	self.wrappingColor = {
		1,
		1,
		1,
		1
	}
	self.wrappingState = 0
	self.configFileName = nil
	self.maxOpenDistance = 3
	self.connector = nil
	self.connectorAxis = 1
	self.connectorOffset = 0.5
	self.wrappingStateCurve = nil
	self.startRotLimit = {
		0,
		0,
		0
	}
	self.endRotLimit = {
		0,
		0,
		0
	}
	self.startTransLimit = {
		0,
		0,
		0
	}
	self.endTransLimit = {
		0,
		0,
		0
	}
	self.wrappingAxis = 1
	self.wrappingAxisScale = {
		1,
		0,
		0
	}
	self.lockTime = 5000
	self.balesToLoad = {}

	registerObjectClassName(self, "InlineBale")
	g_currentMission.itemSystem:addItemToSave(self)

	self.activatable = InlineBaleActivatable.new(self)
	self.balesDirtyFlag = self:getNextDirtyFlag()
	self.wrapperDirtyFlag = self:getNextDirtyFlag()
	self.wakeUpDelay = 0

	return self
end

function InlineBale:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	g_currentMission.itemSystem:removeItemToSave(self)
	unregisterObjectClassName(self)
	InlineBale:superClass().delete(self)
end

function InlineBale:loadFromConfigXML(configFileName)
	self.configFileName = configFileName
	local _, baseDirectory = Utils.getModNameAndBaseDirectory(configFileName)
	self.baseDirectory = baseDirectory
	local xmlFile = XMLFile.load("inlineBaleXml", configFileName, InlineBale.xmlSchema)

	if xmlFile ~= nil then
		self.maxOpenDistance = xmlFile:getValue("inlineBale#maxOpenDistance", self.maxOpenDistance)
		self.connectorFilename = Utils.getFilename(xmlFile:getValue("inlineBale.connector#filename"), self.baseDirectory)
		self.connectorAxis = xmlFile:getValue("inlineBale.connector#axis", self.connectorAxis)
		self.connectorOffset = xmlFile:getValue("inlineBale.connector#offset", self.connectorOffset)
		local replacementBaleFilename = xmlFile:getValue("inlineBale.replacementBale#filename")

		if replacementBaleFilename ~= nil then
			self.replacementBaleFilename = Utils.getFilename(replacementBaleFilename, self.baseDirectory)

			if not fileExists(self.replacementBaleFilename) then
				Logging.xmlWarning(xmlFile, "Unknown wrapper bale file '%s'", tostring(self.replacementBaleFilename))

				return false
			end
		end

		self.wrapDiffuse = Utils.getFilename(xmlFile:getValue("inlineBale.textures#diffuse"), self.baseDirectory)

		if self.wrapDiffuse == nil or not fileExists(self.wrapDiffuse) then
			Logging.xmlWarning(xmlFile, "Missing wrap diffuse '%s'", tostring(self.wrapDiffuse))

			return false
		end

		self.wrapNormal = Utils.getFilename(xmlFile:getValue("inlineBale.textures#normal"), self.baseDirectory)

		if self.wrapNormal == nil or not fileExists(self.wrapNormal) then
			Logging.xmlWarning(xmlFile, "Missing wrap normal '%s'", tostring(self.wrapNormal))

			return false
		end

		self.wrappingStateCurve = AnimCurve.new(linearInterpolator1)
		local j = 0

		while true do
			local key2 = string.format("inlineBale.wrapping.key(%d)", j)

			if not xmlFile:hasProperty(key2) then
				break
			end

			local t = xmlFile:getValue(key2 .. "#time")
			local wrappingState = xmlFile:getValue(key2 .. "#wrappingState")

			self.wrappingStateCurve:addKeyframe({
				wrappingState,
				time = t
			})

			j = j + 1
		end

		self.startRotLimit = xmlFile:getValue("inlineBale.joint#startRotLimit", self.startRotLimit, true)
		self.endRotLimit = xmlFile:getValue("inlineBale.joint#endRotLimit", self.endRotLimit, true)
		self.startTransLimit = xmlFile:getValue("inlineBale.joint#startTransLimit", self.startTransLimit, true)
		self.endTransLimit = xmlFile:getValue("inlineBale.joint#endTransLimit", self.endTransLimit, true)
		self.wrappingAxis = xmlFile:getValue("inlineBale.joint#wrappingAxis", self.wrappingAxis)
		self.wrappingAxisScale = {
			0,
			0,
			0,
			[math.abs(self.wrappingAxis)] = MathUtil.clamp(self.wrappingAxis, -1, 1)
		}
		self.lockTime = xmlFile:getValue("inlineBale.joint#lockTime", self.lockTime / 1000)

		xmlFile:delete()
	else
		Logging.error("Unable to create InlineBale from config file '%s'", configFileName)

		return false
	end

	return true
end

function InlineBale:loadFromXMLFile(xmlFile, key)
	self.configFileName = xmlFile:getValue(key .. "#filename")

	if self.configFileName == nil then
		Logging.error("Unable to load InlineBale from savegame. No filename given.")

		return false
	end

	if not self:loadFromConfigXML(self.configFileName) then
		Logging.error("Unable to load InlineBale from savegame.")

		return false
	end

	local i = 0

	while true do
		local baseKey = string.format("%s.bales.bale(%d)", key, i)

		if not xmlFile:hasProperty(baseKey) then
			break
		end

		local entry = {
			saveId = xmlFile:getValue(baseKey .. "#saveId")
		}

		if entry.saveId ~= nil then
			table.insert(self.balesToLoad, entry)
		end

		i = i + 1
	end

	if #self.balesToLoad > 0 then
		self:raiseActive()
	else
		self.removeEmptyInlineBale = true

		self:raiseActive()
	end

	self.numBalesSent = 0

	return true
end

function InlineBale:saveToXMLFile(xmlFile, key)
	if #self.bales == 1 and self.pendingBale ~= nil then
		return
	end

	xmlFile:setValue(key .. "#filename", self.configFileName)

	for i, bale in ipairs(self.bales) do
		xmlFile:setValue(string.format("%s.bales.bale(%d)#saveId", key, i - 1), bale.currentSavegameItemId)
	end
end

function InlineBale:readStream(streamId, connection)
	self.configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	self:loadFromConfigXML(self.configFileName)
	InlineBale:superClass().readStream(self, streamId, connection)
	g_currentMission.itemSystem:addItemToSave(self)
	self:readBales(streamId, nil, connection)
end

function InlineBale:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	InlineBale:superClass().writeStream(self, streamId, connection)
	self:writeBales(streamId, connection)
end

function InlineBale:readUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		if streamReadBool(streamId) then
			self:readBales(streamId, timestamp, connection)
		end

		if streamReadBool(streamId) then
			self.currentWrapper = NetworkUtil.readNodeObject(streamId)
		end
	end
end

function InlineBale:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.balesDirtyFlag) ~= 0) then
			self:writeBales(streamId, connection, dirtyMask)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapperDirtyFlag) ~= 0) then
			NetworkUtil.writeNodeObject(streamId, self.currentWrapper)
		end
	end
end

function InlineBale:readBales(streamId, timestamp, connection)
	local sum = streamReadUIntN(streamId, 6)

	for _, bale in ipairs(self.bales) do
		if entityExists(bale.nodeId) then
			self:removeBaleConnector(bale)
		end
	end

	self.bales = {}

	for i = 1, sum do
		table.insert(self.balesToLoad, NetworkUtil.readNodeObjectId(streamId))
	end

	if sum > 0 then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	end

	if #self.balesToLoad > 0 then
		self:raiseActive()
	end
end

function InlineBale:writeBales(streamId, connection, dirtyMask)
	local numToSend = #self.bales

	if self.pendingBale ~= nil then
		numToSend = numToSend - 1
	end

	streamWriteUIntN(streamId, numToSend, 6)

	for i = 1, numToSend do
		NetworkUtil.writeNodeObject(streamId, self.bales[i])
	end

	self.numBalesSent = numToSend
end

function InlineBale:update(dt)
end

function InlineBale:updateTick(dt)
	if self.isServer then
		if #self.balesToLoad > 0 then
			local allBalesAvailable = true

			for _, bale in ipairs(self.balesToLoad) do
				if g_currentMission.itemSystem:getItemBySaveId(bale.saveId) == nil then
					allBalesAvailable = false
				end
			end

			if allBalesAvailable then
				for _, bale in ipairs(self.balesToLoad) do
					local baleObject = g_currentMission.itemSystem:getItemBySaveId(bale.saveId)

					self:addBale(baleObject)
					self:connectPendingBale(self.connectorFilename)
					self:updateBaleJoints(9999)
				end

				self.balesToLoad = {}
			end

			self:raiseActive()
		end

		self:updateBaleJoints(dt)

		if self.wrappingNode ~= nil and self.wrappingState < 1 then
			local wx, _, wz = getWorldTranslation(self.wrappingNode)
			local globalWrappingState = 0

			for i, bale in ipairs(self.bales) do
				if bale ~= self.pendingBale then
					local halfWidth = bale.width / 2
					local sx, sy, sz = localToWorld(bale.nodeId, self.wrappingAxisScale[1] * halfWidth, self.wrappingAxisScale[2] * halfWidth, self.wrappingAxisScale[3] * halfWidth)
					local ex, ey, ez = localToWorld(bale.nodeId, self.wrappingAxisScale[1] * -halfWidth, self.wrappingAxisScale[2] * -halfWidth, self.wrappingAxisScale[3] * -halfWidth)
					local dirX, dirZ = MathUtil.vector2Normalize(sx - ex, sz - ez)
					local x, z = MathUtil.projectOnLine(wx, wz, sx, sz, dirX, dirZ)
					local dot = MathUtil.clamp(MathUtil.getProjectOnLineParameter(wx, wz, sx, sz, dirX, dirZ), 0, 1)
					local y = sy * dot + ey * (1 - dot)
					local length1 = MathUtil.vector3Length(sx - x, sy - y, sz - z)
					local pos = MathUtil.clamp(length1 / bale.width, 0, 1)
					local s2x, s2y, s2z = localToWorld(bale.nodeId, self.wrappingAxisScale[1] * (halfWidth + 0.1), self.wrappingAxisScale[2] * (halfWidth + 0.1), self.wrappingAxisScale[3] * (halfWidth + 0.1))
					local length2 = MathUtil.vector3Length(s2x - x, s2y - y, s2z - z)

					if length2 < length1 then
						pos = 0
					end

					if self.wrappingStateCurve ~= nil then
						local wrappingState = math.max(self.wrappingStateCurve:get(pos), bale.wrappingState)

						bale:setWrappingState(wrappingState)

						globalWrappingState = globalWrappingState + wrappingState
					end
				end
			end

			self.wrappingState = globalWrappingState / #self.bales

			self:raiseActive()
		end

		if self.pendingBale == nil and #self.bales ~= self.numBalesSent then
			self:raiseDirtyFlags(self.balesDirtyFlag)
		end

		if self.removeEmptyInlineBale then
			self:delete()
		end

		if self.wakeUpDelay > 0 then
			self.wakeUpDelay = self.wakeUpDelay - dt

			if self.wakeUpDelay <= 0 then
				self:wakeUp()
			end

			self:raiseActive()
		end
	elseif #self.balesToLoad > 0 then
		local readyToAdd = true

		for i, baleObjectId in ipairs(self.balesToLoad) do
			if NetworkUtil.getObject(baleObjectId) == nil then
				readyToAdd = false
			end
		end

		if readyToAdd then
			for i, baleObjectId in ipairs(self.balesToLoad) do
				local baleObject = NetworkUtil.getObject(baleObjectId)

				if baleObject ~= nil then
					self:addBale(baleObject)
				end
			end

			self.balesToLoad = {}

			for i = 1, #self.bales - 1 do
				if self.bales[i] ~= nil and self.bales[i + 1] ~= nil then
					self:loadBaleConnector(self.bales[i], self.bales[i + 1], self.connectorFilename)
				end
			end
		end

		self:raiseActive()
	end
end

function InlineBale:addBale(bale, baleType)
	local success = false

	if self.isServer then
		if self.pendingBale == nil and self:getIsBaleAllowed(bale, baleType) then
			table.insert(self.bales, bale)

			self.pendingBale = bale
			self.wrappingState = self.wrappingState / #self.bales * (#self.bales - 1)

			if bale:isa(InlineBaleSingle) then
				bale:setConnectedInlineBale(self)
			end

			self:raiseActive()

			success = true
		end
	else
		table.insert(self.bales, bale)

		if bale:isa(InlineBaleSingle) then
			bale:setConnectedInlineBale(self)
		end

		success = true
	end

	if success and bale.inlineWrapperToAdd ~= nil then
		self:setCurrentWrapperInfo(bale.inlineWrapperToAdd.wrapper, bale.inlineWrapperToAdd.wrappingNode)

		bale.inlineWrapperToAdd = nil
	end

	return success
end

function InlineBale:getIsBaleAllowed(bale, baleType)
	if #self.bales == 0 then
		return true
	end

	if baleType ~= nil and self.configFileName ~= baleType.inlineBaleFilename then
		return false
	end

	return true
end

function InlineBale:replacePendingBale(spawnNode, color)
	local replaced = false
	local baleId = nil

	if self.pendingBale ~= nil then
		local attributes = self.pendingBale:getBaleAttributes()
		local bale = InlineBaleSingle.new(self.isServer, self.isClient)
		local x, y, z = getWorldTranslation(spawnNode)
		local rx, ry, rz = getWorldRotation(spawnNode)

		if bale:loadFromConfigXML(self.replacementBaleFilename or attributes.xmlFilename, x, y, z, rx, ry, rz) then
			attributes.wrapDiffuse = self.wrapDiffuse
			attributes.wrapNormal = self.wrapNormal

			bale:applyBaleAttributes(attributes)
			bale:register()
			self.pendingBale:delete()

			if color ~= nil then
				local r, g, b, a = unpack(color)

				bale:setColor(r, g, b, a)
			end

			baleId = NetworkUtil.getObjectId(bale)
			self.bales[#self.bales] = bale
			self.pendingBale = bale

			bale:setConnectedInlineBale(self)
			bale:addDeleteListener(self, "onBaleDeleted")

			replaced = true
		end
	end

	return replaced, baleId
end

function InlineBale:getPendingBale()
	return self.pendingBale
end

function InlineBale:connectPendingBale()
	g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)

	if self.pendingBale ~= nil then
		if #self.bales >= 2 then
			self:connectBale(self.pendingBale)
		end

		self.pendingBale = nil

		return true
	end

	return false
end

function InlineBale:connectBale(bale)
	local lastBale = self.bales[#self.bales - 1]

	self:createBaleJoint(lastBale, bale)
	self:loadBaleConnector(lastBale, bale, self.connectorFilename)
	self:raiseActive()
end

function InlineBale:createBaleJoint(bale1, bale2)
	local constr = JointConstructor.new()

	constr:setActors(bale1.nodeId, bale2.nodeId)
	constr:setJointTransforms(bale1.nodeId, bale2.nodeId)
	constr:setEnableCollision(true)
	constr:setRotationLimit(0, -self.startRotLimit[1], self.startRotLimit[1])
	constr:setRotationLimit(1, -self.startRotLimit[2], self.startRotLimit[2])
	constr:setRotationLimit(2, -self.startRotLimit[3], self.startRotLimit[3])
	constr:setTranslationLimit(0, true, -self.startTransLimit[1], self.startTransLimit[1])
	constr:setTranslationLimit(1, true, -self.startTransLimit[2], self.startTransLimit[2])
	constr:setTranslationLimit(2, true, -self.startTransLimit[3], self.startTransLimit[3])

	local jointIndex = constr:finalize()
	local entry = {
		jointIndex = jointIndex,
		time = 0
	}
	self.baleJoints[bale1] = entry
end

function InlineBale:updateBaleJoints(dt)
	for _, joint in pairs(self.baleJoints) do
		if joint.time < self.lockTime then
			joint.time = joint.time + dt

			self:setBaleJointLimits(joint.jointIndex, MathUtil.clamp(joint.time / self.lockTime, 0, 1))
			self:raiseActive()
		end
	end
end

function InlineBale:setBaleJointLimits(jointIndex, alpha)
	local x, y, z = MathUtil.lerp3(self.startRotLimit[1], self.startRotLimit[2], self.startRotLimit[3], self.endRotLimit[1], self.endRotLimit[2], self.endRotLimit[3], alpha)

	setJointRotationLimit(jointIndex, 0, true, -x, x)
	setJointRotationLimit(jointIndex, 1, true, -y, y)
	setJointRotationLimit(jointIndex, 2, true, -z, z)

	x, y, z = MathUtil.lerp3(self.startTransLimit[1], self.startTransLimit[2], self.startTransLimit[3], self.endTransLimit[1], self.endTransLimit[2], self.endTransLimit[3], alpha)

	setJointTranslationLimit(jointIndex, 0, true, -x, x)
	setJointTranslationLimit(jointIndex, 1, true, -y, y)
	setJointTranslationLimit(jointIndex, 2, true, -z, z)
end

function InlineBale:loadBaleConnector(bale1, bale2, filename)
	if filename ~= nil and not bale2:getHasConnector() then
		if not bale2:setConnector(bale1, filename, self.connectorAxis, self.connectorOffset) then
			return false
		end

		return true
	end

	return false
end

function InlineBale:removeBaleConnector(bale)
	if bale ~= nil then
		bale:removeConnector()
	end
end

function InlineBale:setCurrentWrapperInfo(wrapper, wrappingNode)
	self.wrappingNode = wrappingNode

	self:raiseActive()

	if wrapper ~= self.currentWrapper then
		self.currentWrapper = wrapper

		self:raiseDirtyFlags(self.wrapperDirtyFlag)
	end
end

function InlineBale:getNumberOfBales()
	return #self.bales
end

function InlineBale:getBales()
	return self.bales
end

function InlineBale:setWrappingState(state)
	for _, bale in ipairs(self:getBales()) do
		bale:setWrappingState(state)
	end

	self.wrappingState = state
end

function InlineBale:wakeUp(delay)
	if delay == nil or delay == 0 then
		for _, bale in ipairs(self:getBales()) do
			I3DUtil.wakeUpObject(bale.nodeId)
		end
	else
		self.wakeUpDelay = delay

		self:raiseActive()
	end
end

function InlineBale:getCanInteract()
	if #self.bales <= 0 then
		return false
	end

	if self.currentWrapper ~= nil then
		return false
	end

	local x1, y1, z1 = self:getInteractionPosition()

	if x1 ~= nil then
		local fristBale = self.bales[1]
		local x2, y2, z2 = getWorldTranslation(fristBale.nodeId)
		local distance = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

		if distance < self.maxOpenDistance then
			return true
		end

		local lastBale = self.bales[#self.bales]
		x2, y2, z2 = getWorldTranslation(lastBale.nodeId)
		distance = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

		if distance < self.maxOpenDistance then
			return true
		end
	end

	return false
end

function InlineBale:getInteractionPosition()
	if not g_currentMission.controlPlayer then
		return
	end

	return getWorldTranslation(g_currentMission.player.rootNode)
end

function InlineBale:getCanBeOpened()
	for _, bale in ipairs(self.bales) do
		if bale.wrappingState < 1 or bale:getIsFermenting() then
			return false
		end
	end

	return true
end

function InlineBale:openBaleAtPosition(x, y, z)
	local distance1 = 0
	local distance2 = 1
	local fristBale = self.bales[1]
	local lastBale = self.bales[#self.bales]

	if #self.bales > 1 then
		local bx, by, bz = getWorldTranslation(fristBale.nodeId)
		distance1 = MathUtil.vector3Length(x - bx, y - by, z - bz)
		bx, by, bz = getWorldTranslation(lastBale.nodeId)
		distance2 = MathUtil.vector3Length(x - bx, y - by, z - bz)
	end

	if distance1 < distance2 then
		self:openBale(fristBale, true)
	else
		self:openBale(lastBale, false)
	end
end

function InlineBale:openBale(bale, isFirst, replaceBale)
	if isFirst then
		local nextBale = self.bales[2]

		self:removeBaleConnector(nextBale)

		local joint = self.baleJoints[bale]

		if joint ~= nil then
			removeJoint(joint.jointIndex)
		end

		for i = 1, #self.bales - 1 do
			self.bales[i] = self.bales[i + 1]
		end
	else
		self:removeBaleConnector(bale)

		local prevBale = self.bales[#self.bales - 1]

		if prevBale ~= nil then
			local joint = self.baleJoints[prevBale]

			if joint ~= nil then
				removeJoint(joint.jointIndex)
			end
		end
	end

	table.remove(self.bales, #self.bales)
	bale:setConnectedInlineBale(nil)

	if replaceBale == nil or replaceBale then
		local attributes = bale:getBaleAttributes()
		local newBale = Bale.new(self.isServer, self.isClient)
		local x, y, z = getWorldTranslation(bale.nodeId)
		local rx, ry, rz = getWorldRotation(bale.nodeId)

		if newBale:loadFromConfigXML(attributes.xmlFilename, x, y, z, rx, ry, rz) then
			attributes.wrapDiffuse = self.wrapDiffuse
			attributes.wrapNormal = self.wrapNormal

			newBale:applyBaleAttributes(attributes)
			newBale:register()
			newBale:open()
			bale:delete()
		end
	end

	if #self.bales == 0 then
		self:delete()
	end

	self:raiseActive()
end

function InlineBale:onBaleDeleted(bale)
	if self.pendingBale == nil then
		if self.bales[1] == bale then
			self:openBale(bale, true, false)
		elseif self.bales[#self.bales] == bale then
			self:openBale(bale, false, false)
		else
			local baleIndex = nil

			for i, bale2 in ipairs(self.bales) do
				if bale2 == bale then
					baleIndex = i
				end
			end

			if baleIndex ~= nil then
				if baleIndex > #self.bales - baleIndex then
					for i = #self.bales, baleIndex + 1, -1 do
						self:openBale(self.bales[i], false)
					end

					self:openBale(bale, false, false)
				else
					for i = 1, baleIndex - 1 do
						self:openBale(self.bales[1], true)
					end

					self:openBale(bale, true, false)
				end
			end
		end
	end
end

InlineBaleActivatable = {}
local InlineBaleActivatable_mt = Class(InlineBaleActivatable)

function InlineBaleActivatable.new(inlineBale)
	local self = {}

	setmetatable(self, InlineBaleActivatable_mt)

	self.inlineBale = inlineBale
	self.activateText = g_i18n:getText("action_cutBale")

	return self
end

function InlineBaleActivatable:getIsActivatable()
	if self.inlineBale:getCanInteract() and self.inlineBale:getCanBeOpened() then
		return true
	end

	return false
end

function InlineBaleActivatable:run()
	local ix, iy, iz = self.inlineBale:getInteractionPosition()

	if ix ~= nil then
		if g_server ~= nil then
			self.inlineBale:openBaleAtPosition(ix, iy, iz)
		else
			g_client:getServerConnection():sendEvent(InlineBaleOpenEvent.new(self.inlineBale, ix, iy, iz))
		end
	end
end
