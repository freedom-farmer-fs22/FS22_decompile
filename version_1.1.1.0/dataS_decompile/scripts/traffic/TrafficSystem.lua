TrafficSystem = {}
local TrafficSystem_mt = Class(TrafficSystem, Object)

InitStaticObjectClass(TrafficSystem, "TrafficSystem", ObjectIds.TRAFFIC_SYSTEM)

function TrafficSystem:onCreate(transformId)
	local xmlFilename = getUserAttribute(transformId, "xmlFile")

	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, g_currentMission.loadingMapBaseDirectory)
		local lightsProfile = g_gameSettings:getValue("lightsProfile")
		local useHighProfile = lightsProfile == GS_PROFILE_HIGH or lightsProfile == GS_PROFILE_VERY_HIGH
		local trafficSystem = TrafficSystem.new(g_server ~= nil, g_client ~= nil)

		if trafficSystem:load(xmlFilename, transformId, useHighProfile, g_server ~= nil, g_client ~= nil) then
			trafficSystem:register(true)
			g_currentMission:addOnCreateLoadedObject(trafficSystem)
			trafficSystem:setEnabled(g_currentMission.missionInfo.trafficEnabled)
		else
			trafficSystem:delete()
		end

		g_currentMission.trafficSystem = trafficSystem
	else
		print("Error: Missing xmlFile attribute for traffic system in " .. getName(transformId))
	end
end

function TrafficSystem.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or TrafficSystem_mt)
	self.trafficSystemId = nil
	self.isEnabled = false
	self.trafficSystemDirtyFlag = self:getNextDirtyFlag()

	return self
end

function TrafficSystem:load(xmlFilename, transformId, useHighProfile, isServer, isClient)
	local trafficSystemId = createTrafficSystem(xmlFilename, transformId, useHighProfile, isServer, isClient)

	if trafficSystemId == 0 then
		Logging.error("Unable to create TrafficSystem from '%s' and '%s'", xmlFilename, I3DUtil.getNodePath(transformId))

		return false
	end

	self.trafficSystemId = trafficSystemId
	self.rootNodeId = transformId
	local groundMask = CollisionFlag.TERRAIN + CollisionFlag.STATIC_WORLD
	local stopMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.TRIGGER_VEHICLE
	local playerStopMask = CollisionFlag.TRIGGER_VEHICLE
	local ignoreMask = CollisionFlag.TRIGGER_TRAFFIC_VEHICLE_BLOCKING

	setTrafficSystemCollisionMasks(self.trafficSystemId, groundMask, stopMask, playerStopMask, ignoreMask)

	self.isEnabled = true

	g_soundManager:addIndoorStateChangedListener(self)
	setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not g_soundManager:getIsIndoor())
	self:updateNightTimeRange()
	g_messageCenter:subscribe(MessageType.DAYLIGHT_CHANGED, self.onDaylightChanged, self)

	return true
end

function TrafficSystem:delete()
	if self.trafficSystemId ~= nil then
		delete(self.trafficSystemId)

		g_currentMission.trafficSystem = nil
	end

	g_messageCenter:unsubscribeAll(self)
	g_soundManager:removeIndoorStateChangedListener(self)
end

function TrafficSystem:writeUpdateStream(streamId, connection, dirtyMask)
	TrafficSystem:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		writeTrafficSystemToStream(self.trafficSystemId, streamId)
	end
end

function TrafficSystem:readUpdateStream(streamId, timestamp, connection)
	TrafficSystem:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		readTrafficSystemFromStream(self.trafficSystemId, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
	end
end

function TrafficSystem:update(dt)
	setTrafficSystemDaytime(self.trafficSystemId, g_currentMission.environment.dayTime)

	if self.isEnabled then
		self:raiseActive()
	end
end

function TrafficSystem:updateTick(dt)
	self:raiseDirtyFlags(self.trafficSystemDirtyFlag)
end

function TrafficSystem:setNightTimeRange(nightStart, nightEnd)
	setTrafficSystemNightTimeRange(self.trafficSystemId, nightStart, nightEnd)
end

function TrafficSystem:setEnabled(state)
	setTrafficSystemEnabled(self.trafficSystemId, state)

	self.isEnabled = state

	if state then
		self:raiseActive()
	end
end

function TrafficSystem:reset()
	resetTrafficSystem(self.trafficSystemId)
end

function TrafficSystem:onIndoorStateChanged(isIndoor)
	setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not isIndoor)
end

function TrafficSystem:updateNightTimeRange()
	local daylight = g_currentMission.environment.daylight

	self:setNightTimeRange(daylight.logicalNightStart, daylight.logicalNightEnd)
end

function TrafficSystem:onDaylightChanged()
	self:updateNightTimeRange()
end

function TrafficSystem:getSplineByIndex(splineIndex)
	return splineIndex < getNumOfChildren(self.rootNodeId) and getChildAt(self.rootNodeId, splineIndex) or nil
end
