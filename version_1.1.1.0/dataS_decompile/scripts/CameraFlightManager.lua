CameraFlightManager = {}
local CameraFlightManager_mt = Class(CameraFlightManager)

function CameraFlightManager.new()
	local self = {}

	setmetatable(self, CameraFlightManager_mt)

	self.cameraFlightIsActive = false
	self.abortCameraFlight = false

	return self
end

function CameraFlightManager:load(xmlFile)
	self.cameraFlights = {}
	local i = 0

	while true do
		local key = string.format("map.cameraFlights.cameraFlight(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local flightType = getXMLString(xmlFile, key .. "#type")
		local speedScale = getXMLFloat(xmlFile, key .. "#speedScale")
		local filename = getXMLString(xmlFile, key .. "#filename")
		local i3dFilename = Utils.getFilename(filename, self.baseDirectory)
		local camera = createCamera("cameraFlight_" .. flightType, math.rad(60), 1, 10000)
		local cameraFlight = CameraPath.createFromI3D(i3dFilename, speedScale, camera)

		if self.cameraFlights[flightType] == nil then
			self.cameraFlights[flightType] = cameraFlight
		end

		i = i + 1
	end

	local function onMenuAbort()
		self.abortCameraFlight = true

		g_inputBinding:removeActionEventsByTarget(self)
	end

	g_inputBinding:registerActionEvent(InputAction.MENU, self, onMenuAbort, false, true, false, true)
end

function CameraFlightManager:delete()
	for _, cameraPath in pairs(self.cameraFlights) do
		cameraPath:delete()
	end
end

function CameraFlightManager:update(dt)
	if g_server ~= nil and g_client ~= nil and self.cameraFlights.careerStart ~= nil and not self.careerStartFlightPlayed then
		local cameraPath = self.cameraFlights.careerStart

		if g_currentMission.controlledVehicle ~= nil then
			self.abortCameraFlight = true
		end

		if self.abortCameraFlight then
			cameraPath:deactivate()

			self.careerStartFlightPlayed = true
			g_currentMission.player.walkingIsLocked = false

			return
		end

		local continue = not g_gui:getIsGuiVisible()

		if continue then
			if cameraPath.time == 0 then
				cameraPath:activate()
			end

			cameraPath:update(dt)

			g_currentMission.player.walkingIsLocked = true

			if cameraPath.maxTime <= cameraPath.time then
				self.careerStartFlightPlayed = true

				cameraPath:deactivate()

				g_currentMission.player.walkingIsLocked = false
			end
		end
	end
end
