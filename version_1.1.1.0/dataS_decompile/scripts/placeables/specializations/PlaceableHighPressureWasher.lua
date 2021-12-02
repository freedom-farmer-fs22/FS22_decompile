PlaceableHighPressureWasher = {}

source("dataS/scripts/placeables/specializations/events/PlaceableHighPressureWasherStateEvent.lua")

function PlaceableHighPressureWasher.prerequisitesPresent(specializations)
	return true
end

function PlaceableHighPressureWasher.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "deactivateHighPressureWasher", PlaceableHighPressureWasher.deactivateHighPressureWasher)
	SpecializationUtil.registerFunction(placeableType, "onHighPressureWasherLanceDeleted", PlaceableHighPressureWasher.onHighPressureWasherLanceDeleted)
	SpecializationUtil.registerFunction(placeableType, "onHighPressureWasherLanceEquipped", PlaceableHighPressureWasher.onHighPressureWasherLanceEquipped)
	SpecializationUtil.registerFunction(placeableType, "onHighPressureWasherPlayerDeleted", PlaceableHighPressureWasher.onHighPressureWasherPlayerDeleted)
	SpecializationUtil.registerFunction(placeableType, "setIsHighPressureWasherTurnedOn", PlaceableHighPressureWasher.setIsHighPressureWasherTurnedOn)
	SpecializationUtil.registerFunction(placeableType, "getHighPressureWasherLoad", PlaceableHighPressureWasher.getHighPressureWasherLoad)
	SpecializationUtil.registerFunction(placeableType, "getHighPressureWasherIsPlayerInRange", PlaceableHighPressureWasher.getHighPressureWasherIsPlayerInRange)
end

function PlaceableHighPressureWasher.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableHighPressureWasher.canBeSold)
end

function PlaceableHighPressureWasher.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onUpdateTick", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableHighPressureWasher)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableHighPressureWasher)
end

function PlaceableHighPressureWasher.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("highPressureWasher")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".highPressureWasher.lance#node", "Lance node")
	schema:register(XMLValueType.STRING, basePath .. ".highPressureWasher.handtool#filename", "Hand tool xml filename")
	schema:register(XMLValueType.FLOAT, basePath .. ".highPressureWasher.playerInRangeDistance", "Player in range distance", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".highPressureWasher.actionRadius#distance", "Action radius distance", 15)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".highPressureWasher.sounds", "compressor")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".highPressureWasher.sounds", "switch")
	schema:register(XMLValueType.STRING, basePath .. ".highPressureWasher.exhaust#filename", "Exhaust effect i3d filename")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".highPressureWasher.exhaust#index", "Exhaust effect link node")
	schema:setXMLSpecializationType()
end

function PlaceableHighPressureWasher:onLoad(savegame)
	local spec = self.spec_highPressureWasher
	local xmlFile = self.xmlFile
	spec.lanceNode = xmlFile:getValue("placeable.highPressureWasher.lance#node", nil, self.components, self.i3dMappings)
	spec.handtoolXML = Utils.getFilename(xmlFile:getValue("placeable.highPressureWasher.handtool#filename"), self.baseDirectory)
	spec.playerInRangeDistance = xmlFile:getValue("placeable.highPressureWasher.playerInRangeDistance", 3)
	spec.actionRadius = xmlFile:getValue("placeable.highPressureWasher.actionRadius#distance", 10)

	if self.isClient then
		spec.samples = {
			compressor = g_soundManager:loadSampleFromXML(xmlFile, "placeable.highPressureWasher.sounds", "compressor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			switch = g_soundManager:loadSampleFromXML(xmlFile, "placeable.highPressureWasher.sounds", "switch", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.isTurnedOn = false
	spec.isTurningOff = false
	spec.turnOffTime = 0
	spec.turnOffDuration = 500
	spec.numPlayersInTrigger = 0
	spec.activatable = HighPressureWasherActivatable.new(self)
end

function PlaceableHighPressureWasher:onDelete()
	local spec = self.spec_highPressureWasher

	if spec.isTurnedOn then
		self:setIsHighPressureWasherTurnedOn(false, nil, false)
	end

	g_soundManager:deleteSamples(spec.samples)
	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
end

function PlaceableHighPressureWasher:onReadStream(streamId, connection)
	local isTurnedOn = streamReadBool(streamId)

	if isTurnedOn then
		local player = NetworkUtil.readNodeObject(streamId)

		if player ~= nil then
			self:setIsHighPressureWasherTurnedOn(isTurnedOn, player, true)
		end
	end
end

function PlaceableHighPressureWasher:onWriteStream(streamId, connection)
	local spec = self.spec_highPressureWasher

	streamWriteBool(streamId, spec.isTurnedOn)

	if spec.isTurnedOn then
		NetworkUtil.writeNodeObject(streamId, spec.currentPlayer)
	end
end

function PlaceableHighPressureWasher:onUpdate(dt)
	local spec = self.spec_highPressureWasher

	if spec.currentPlayer ~= nil then
		local isPlayerInRange, _, distance = self:getHighPressureWasherIsPlayerInRange(spec.actionRadius, spec.currentPlayer)

		if not isPlayerInRange then
			local maxRadius = spec.actionRadius + 5
			local distanceLeft = maxRadius - distance

			if distanceLeft > 0 then
				if spec.currentPlayer == g_currentMission.player then
					g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_hpwRangeRestriction"), distanceLeft), 100)
				end
			elseif self.isServer then
				self:setIsHighPressureWasherTurnedOn(false, nil, false)
			end
		end
	end

	if self.isClient and spec.isTurningOff and spec.turnOffTime < g_currentMission.time then
		spec.isTurningOff = false

		g_soundManager:stopSample(spec.samples.compressor)
	end

	if spec.currentPlayer ~= nil or spec.isTurningOff or spec.isPlayerInTrigger then
		self:raiseActive()
	end
end

function PlaceableHighPressureWasher:onUpdateTick(dt)
	local spec = self.spec_highPressureWasher

	if g_currentMission.accessHandler:canPlayerAccess(self, g_currentMission.player) then
		local isPlayerInRange, _ = self:getHighPressureWasherIsPlayerInRange(spec.playerInRangeDistance, g_currentMission.player)

		if isPlayerInRange then
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
		end
	end
end

function PlaceableHighPressureWasher:onInfoTriggerEnter()
	local spec = self.spec_highPressureWasher
	spec.isPlayerInTrigger = true

	self:raiseActive()
end

function PlaceableHighPressureWasher:onInfoTriggerLeave()
	local spec = self.spec_highPressureWasher
	spec.isPlayerInTrigger = false
end

function PlaceableHighPressureWasher:getHighPressureWasherLoad()
	local spec = self.spec_highPressureWasher

	if spec.isTurningOff then
		if g_currentMission.time < spec.turnOffTime then
			return MathUtil.clamp((spec.turnOffTime - g_currentMission.time) / spec.turnOffDuration, 0, 1)
		end

		return 0
	end

	return 1
end

g_soundManager:registerModifierType("HIGH_PRESSURE_WASHER_LOAD", PlaceableHighPressureWasher.getHighPressureWasherLoad)

function PlaceableHighPressureWasher:setIsHighPressureWasherTurnedOn(isTurnedOn, player, noEventSend)
	local spec = self.spec_highPressureWasher

	if spec.isTurnedOn ~= isTurnedOn then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(PlaceableHighPressureWasherStateEvent.new(self, isTurnedOn, player), nil, , self)
			else
				g_client:getServerConnection():sendEvent(PlaceableHighPressureWasherStateEvent.new(self, isTurnedOn, player))
			end
		end

		if isTurnedOn then
			spec.isTurnedOn = isTurnedOn

			if player ~= nil then
				spec.currentPlayer = player

				spec.currentPlayer:addDeleteListener(self, "onHighPressureWasherPlayerDeleted")

				if noEventSend ~= true then
					spec.currentPlayer:equipHandtool(spec.handtoolXML, true, noEventSend, self.onHighPressureWasherLanceEquipped, self)
				end
			end

			if spec.isClient then
				g_soundManager:playSample(spec.samples.switch)
				g_soundManager:playSample(spec.samples.compressor)

				if spec.isTurningOff then
					spec.isTurningOff = false
				end

				setVisibility(spec.lanceNode, false)
			end
		else
			self:deactivateHighPressureWasher()
		end

		if spec.exhaustNode ~= nil then
			setVisibility(spec.exhaustNode, isTurnedOn)
		end

		self:raiseActive()
	end
end

function PlaceableHighPressureWasher:onHighPressureWasherLanceEquipped(handTool)
	handTool:addDeleteListener(self, "onHighPressureWasherLanceDeleted")
end

function PlaceableHighPressureWasher:onHighPressureWasherPlayerDeleted()
	local spec = self.spec_highPressureWasher
	spec.currentPlayer = nil

	self:setIsHighPressureWasherTurnedOn(false, nil, )
end

function PlaceableHighPressureWasher:onHighPressureWasherLanceDeleted()
	local spec = self.spec_highPressureWasher
	spec.currentPlayer = nil

	self:setIsHighPressureWasherTurnedOn(false, nil, )
end

function PlaceableHighPressureWasher:deactivateHighPressureWasher()
	local spec = self.spec_highPressureWasher

	if self.isClient then
		g_soundManager:playSample(spec.samples.switch)

		spec.isTurningOff = true
		spec.turnOffTime = g_currentMission.time + spec.turnOffDuration
	end

	spec.isTurnedOn = false

	if spec.lanceNode ~= nil then
		setVisibility(spec.lanceNode, true)
	end

	if spec.currentPlayer ~= nil then
		if spec.currentPlayer:hasHandtoolEquipped() then
			spec.currentPlayer.baseInformation.currentHandtool:removeDeleteListener(self, "onHighPressureWasherLanceDeleted")
			spec.currentPlayer:unequipHandtool()
		end

		spec.currentPlayer:removeDeleteListener(self, "onHighPressureWasherPlayerDeleted")

		spec.currentPlayer = nil
	end
end

function PlaceableHighPressureWasher:canBeSold(superFunc)
	local canBeSold, warning = superFunc(self)

	if not canBeSold then
		return canBeSold, warning
	end

	local spec = self.spec_highPressureWasher

	if spec.currentPlayer ~= nil then
		warning = g_i18n:getText("shop_messageReturnVehicleInUse")

		return false, warning
	end

	return true, nil
end

function PlaceableHighPressureWasher:getHighPressureWasherIsPlayerInRange(actionRadius, player)
	if self.rootNode ~= 0 then
		local distance = calcDistanceFrom(player.rootNode, self.rootNode)

		return distance < actionRadius, player, distance
	end

	return false, nil, 0
end

HighPressureWasherActivatable = {}
local HighPressureWasherActivatable_mt = Class(HighPressureWasherActivatable)

function HighPressureWasherActivatable.new(placeable)
	local self = {}

	setmetatable(self, HighPressureWasherActivatable_mt)

	self.placeable = placeable
	self.activateText = "unknown"

	return self
end

function HighPressureWasherActivatable:getIsActivatable()
	local spec = self.placeable.spec_highPressureWasher

	if spec.isTurnedOn and spec.currentPlayer ~= g_currentMission.player then
		return false
	end

	local hasHPWLance = self.currentPlayer ~= nil and self.currentPlayer:hasHandtoolEquipped() and self.currentPlayer.baseInformation.currentHandtool.isHPWLance

	if not spec.isTurnedOn and hasHPWLance then
		return false
	end

	if self.placeable.isDeleted then
		return false
	end

	self:updateActivateText()

	return true
end

function HighPressureWasherActivatable:run()
	local spec = self.placeable.spec_highPressureWasher

	self.placeable:setIsHighPressureWasherTurnedOn(not spec.isTurnedOn, g_currentMission.player)
	self:updateActivateText()
end

function HighPressureWasherActivatable:updateActivateText()
	local spec = self.placeable.spec_highPressureWasher

	if spec.isTurnedOn then
		self.activateText = string.format(g_i18n:getText("action_turnOffOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
	else
		self.activateText = string.format(g_i18n:getText("action_turnOnOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
	end
end
