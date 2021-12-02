PedestrianSystem = {}
local PedestrianSystem_mt = Class(PedestrianSystem)

function PedestrianSystem:onCreate(transformId)
	local xmlFilename = getUserAttribute(transformId, "xmlFile")

	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, g_currentMission.loadingMapBaseDirectory)

		PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId)
	else
		Logging.error("Missing 'xmlFile'-attribute for pedestrian system in " .. getName(transformId))
	end
end

function PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId)
	local existingPedestrianSystem = g_currentMission:getPedestrianSystem()

	if existingPedestrianSystem ~= nil and existingPedestrianSystem.pedestrianSystemId ~= nil then
		Logging.error("Pedestrian system already present")

		return false
	end

	local pedestrianSystem = PedestrianSystem.new()
	local animNodeCharacter = g_animCache:getNode(AnimationCache.CHARACTER)
	local animNodePedestrian = g_animCache:getNode(AnimationCache.PEDESTRIAN)

	if animNodeCharacter == nil or animNodePedestrian == nil then
		Logging.error("Unable to find Pedestrian Animation.")

		return false
	end

	if not pedestrianSystem:load(xmlFilename, transformId, animNodeCharacter, animNodePedestrian) then
		pedestrianSystem:delete()

		return false
	end

	if g_currentMission:setPedestrianSystem(pedestrianSystem) then
		g_currentMission:addUpdateable(pedestrianSystem)
	else
		pedestrianSystem:delete()

		return false
	end

	return true
end

function PedestrianSystem.new()
	local self = setmetatable({}, PedestrianSystem_mt)
	self.pedestrianSystemId = nil
	self.isEnabled = false
	self.xmlFilename = nil
	self.transformId = nil

	return self
end

function PedestrianSystem:load(xmlFilename, transformId, referenceNodeIdCharacter, referenceNodeIdPedestrian)
	local blockingCollisionMask = CollisionFlag.VEHICLE
	local pedestrianSystemId = createPedestrianSystem(xmlFilename, transformId, referenceNodeIdCharacter, referenceNodeIdPedestrian, CollisionMask.TERRAIN, blockingCollisionMask)

	if pedestrianSystemId == 0 then
		Logging.error("Unable to create PedestrianSystem from '%s' and '%s'", xmlFilename, I3DUtil.getNodePath(transformId))

		return false
	end

	self.pedestrianSystemId = pedestrianSystemId
	self.xmlFilename = xmlFilename
	self.transformId = transformId

	self:updateNightTimeRange()
	g_messageCenter:subscribe(MessageType.DAYLIGHT_CHANGED, self.onDaylightChanged, self)
	addConsoleCommand("gsPedestrianSystemToggle", "Toggle pedestrian system", "consoleCommandPedestrianSystemToggle", self)
	addConsoleCommand("gsPedestrianSystemReload", "Reload pedestrian system xml", "consoleCommandPedestrianSystemReload", self)
	g_soundManager:addIndoorStateChangedListener(self)
	setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())

	return true
end

function PedestrianSystem:delete()
	if self.pedestrianSystemId ~= nil then
		setPedestrianSystemEnabled(self.pedestrianSystemId, false)

		if g_currentMission:getHasUpdateable(self) then
			g_currentMission:removeUpdateable(self)
		end

		g_currentMission:setPedestrianSystem(nil)
		delete(self.pedestrianSystemId)

		self.pedestrianSystemId = nil
	end

	g_messageCenter:unsubscribeAll(self)
	g_soundManager:removeIndoorStateChangedListener(self)
	removeConsoleCommand("gsPedestrianSystemToggle")
	removeConsoleCommand("gsPedestrianSystemReload")
end

function PedestrianSystem:update(dt)
	if self.pedestrianSystemId ~= nil then
		setPedestrianSystemDaytime(self.pedestrianSystemId, g_currentMission.environment.dayTime)
	end
end

function PedestrianSystem:setEnabled(state)
	if self.pedestrianSystemId ~= nil then
		setPedestrianSystemEnabled(self.pedestrianSystemId, state)

		self.isEnabled = state
	end
end

function PedestrianSystem:setNightTimeRange(nightStart, nightEnd)
	if self.pedestrianSystemId ~= nil then
		setPedestrianSystemNightTimeRange(self.pedestrianSystemId, nightStart, nightEnd)
	end
end

function PedestrianSystem:updateNightTimeRange()
	local daylight = g_currentMission.environment.daylight

	self:setNightTimeRange(daylight.logicalNightStart, daylight.logicalNightEnd)
end

function PedestrianSystem:onDaylightChanged()
	self:updateNightTimeRange()
end

function PedestrianSystem:consoleCommandPedestrianSystemToggle(state)
	local pedestrianSystem = g_currentMission:getPedestrianSystem()

	if pedestrianSystem == nil or pedestrianSystem.pedestrianSystemId == nil then
		return "Error: No pedestrian system available"
	end

	state = Utils.stringToBoolean(state) or not pedestrianSystem.isEnabled

	pedestrianSystem:setEnabled(state)

	return "setPedestrianSystemEnabled=" .. tostring(state)
end

function PedestrianSystem:consoleCommandPedestrianSystemReload()
	local oldPedestrianSystem = g_currentMission:getPedestrianSystem()

	if oldPedestrianSystem == nil or oldPedestrianSystem.pedestrianSystemId == nil then
		return "Error: No pedestrian system to reload"
	end

	local xmlFilename = oldPedestrianSystem.xmlFilename
	local transformId = oldPedestrianSystem.transformId
	local isEnabled = oldPedestrianSystem.isEnabled

	oldPedestrianSystem:delete()

	if PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId) then
		g_currentMission:getPedestrianSystem():setEnabled(isEnabled)

		return string.format("Reloaded pedestrian system from '%s'", xmlFilename)
	else
		return "Error while reloading pedestrian system"
	end
end

function PedestrianSystem:onIndoorStateChanged(isIndoor)
	setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())
end
