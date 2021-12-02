Benchmark = {}
local Benchmark_mt = Class(Benchmark)

function Benchmark.new(customMt)
	local self = setmetatable({}, customMt or Benchmark_mt)
	self.isRunning = false
	self.currentCamPath = nil
	self.hasFinished = false

	addConsoleCommand("gsBenchmark", "Starts a benchmark sequence with camera flight and working vehicles", "consoleCommandBenchmark", self)

	return self
end

function Benchmark:delete()
	removeConsoleCommand("gsBenchmark")
end

function Benchmark:load()
	local mapXMLFilename = Utils.getFilename(g_currentMission.missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local mapXmlFile = loadXMLFile("MapXML", mapXMLFilename)
	self.vehicles = {}
	self.idToVehicle = {}
	self.delayToAiVehicle = {}
	self.fields = {}
	self.camPaths = {}
	local benchmarkXmlFilePath = getXMLString(mapXmlFile, "map.benchmark#filename")

	if benchmarkXmlFilePath ~= nil then
		benchmarkXmlFilePath = Utils.getFilename(benchmarkXmlFilePath, g_currentMission.baseDirectory)
		local benchmarkXml = XMLFile.load("benchmarkXml", benchmarkXmlFilePath)

		if benchmarkXml ~= nil then
			log("Loading benchmark config")

			local cameraFov = benchmarkXml:getFloat("benchmark.camera#fieldOfView") or 70

			log("camera field of view", cameraFov)

			self.benchmarkCam = createCamera("benchmarkCam", math.rad(cameraFov), 1, 10000)

			link(getRootNode(), self.benchmarkCam)

			self.benmarkVehiclesXmlFilepath = Utils.getFilename(benchmarkXml:getString("benchmark.vehicles#xmlFilename"), g_currentMission.baseDirectory)

			benchmarkXml:iterate("benchmark.aiStarts.aiStart", function (index, key)
				local vehicleId = benchmarkXml:getInt(key .. "#vehicleId")
				local startDelay = benchmarkXml:getFloat(key .. "#startDelay") * 1000

				if self.delayToAiVehicle[startDelay] == nil then
					self.delayToAiVehicle[startDelay] = {}
				end

				table.insert(self.delayToAiVehicle[startDelay], vehicleId)
			end)
			benchmarkXml:iterate("benchmark.fields.field", function (index, key)
				local fieldNumber = benchmarkXml:getInt(key .. "#number")
				local fruitType = benchmarkXml:getString(key .. "#fruitType")
				local growthState = benchmarkXml:getInt(key .. "#growthState")

				table.insert(self.fields, {
					fieldNumber,
					fruitType,
					growthState
				})
			end)
			benchmarkXml:iterate("benchmark.cameraPaths.cameraPath", function (index, key)
				local i3dFilename = Utils.getFilename(benchmarkXml:getString(key .. "#i3dFilename"), g_currentMission.baseDirectory)
				local camPathSpeedScale = benchmarkXml:getString(key .. "#speedScale", 1)
				local camPath = CameraPath.createFromI3D(i3dFilename, camPathSpeedScale, self.benchmarkCam)

				table.insert(self.camPaths, camPath)
			end)

			if #self.camPaths == 0 then
				Logging.error("At least one camera path has to be defined in %s", benchmarkXmlFilePath)
			end

			benchmarkXml:delete()
		end
	else
		Logging.error("No benchmark xml defined (map.benchmark#filename) in %s", g_currentMission.missionInfo.mapXMLFilename)

		return false
	end

	return true
end

function Benchmark:startBenchmark()
	g_currentMission.player.walkingIsLocked = true

	g_currentMission.hud:setIsVisible(false)
	self:setupFields()
	self:setupVehicles()
end

function Benchmark:setupFields()
	log("Setting up fields with fruits")
	g_farmlandManager:consoleCommandBuyAllFarmlands()

	for i = 1, #self.fields do
		local fieldNumber, fruitType, growthState, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray = unpack(self.fields[i])

		g_fieldManager:consoleCommandSetFieldFruit(fieldNumber, fruitType, growthState, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray, true)
	end
end

function Benchmark:setupVehicles()
	g_currentMission:consoleCommandVehicleRemoveAll()
	log("deleted all vehicles")
	log("loading vehicles from", self.benmarkVehiclesXmlFilepath)
	VehicleLoadingUtil.loadVehiclesFromSavegame(self.benmarkVehiclesXmlFilepath, false, g_currentMission.missionInfo, g_currentMission.missionDynamicInfo, self.loadingVehiclesFinished, self, {
		self.benmarkVehiclesXmlFilepath,
		false
	})
end

function Benchmark:loadingVehiclesFinished(asyncCallbackArguments, vehiclesById)
	log("vehicle loading finished")

	self.idToVehicle = vehiclesById

	for id, vehicle in pairs(vehiclesById) do
		log(vehicle:getFullName())

		if vehicle.startMotor ~= nil then
			vehicle:startMotor()
		end

		if vehicle.setBeaconLightsVisibility ~= nil then
			vehicle:setBeaconLightsVisibility(true, true)
			vehicle:setTurnLightState(Lights.TURNLIGHT_HAZARD, true)
			vehicle:setLightsTypesMask(Lights.LIGHT_TYPE_HIGHBEAM + Lights.LIGHT_TYPE_WORK_FRONT + Lights.LIGHT_TYPE_WORK_BACK, true)
		end
	end

	self.time = 0
	self.isRunning = true
end

function Benchmark:finishBenchmark()
	if self.currentCamPath then
		self.currentCamPath:deactivate()

		self.currentCamPath = nil
	end

	if self.benchmarkCam ~= nil then
		delete(self.benchmarkCam)
	end

	for id, vehicle in pairs(self.idToVehicle) do
		if vehicle.stopCurrentAIJob then
			vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
		end
	end

	log("Finished benchmark")

	self.isRunning = false
	self.hasFinished = true
	self.time = 0
	g_currentMission.player.walkingIsLocked = false

	g_currentMission.hud:setIsVisible(true)
end

function Benchmark:update(dt)
	if self.isRunning then
		self.time = self.time + dt

		for delay, vehicleIds in pairs(self.delayToAiVehicle) do
			if delay < self.time then
				for i = 1, #vehicleIds do
					local vehicle = self.idToVehicle[vehicleIds[i]]

					if vehicle then
						log("   started ai", vehicle:getFullName())
						vehicle:startAIVehicle(nil, , vehicle.ownerFarmId)
					else
						log("unknown vehicle id", vehicleIds[i])
					end
				end

				self.delayToAiVehicle[delay] = nil
			end
		end

		if self.currentCamPath == nil then
			self.currentCamPath = table.remove(self.camPaths, 1)

			if self.currentCamPath ~= nil then
				local durationSecWithSpeedScale = self.currentCamPath.maxTime * 1 / self.currentCamPath.speedScale / 1000

				log(string.format("starting next cam path, duration %.3fs", durationSecWithSpeedScale))
				self.currentCamPath:activate()
			else
				log("no more camera paths")
				self:finishBenchmark()
			end
		else
			self.currentCamPath:update(dt)

			if self.currentCamPath.maxTime <= self.currentCamPath.time then
				log("finished camera path")
				self.currentCamPath:deactivate()

				self.currentCamPath = nil
			end
		end
	end
end

function Benchmark:consoleCommandBenchmark()
	if g_currentMission ~= nil then
		if self.isRunning then
			self:finishBenchmark()
		end

		if self:load() then
			self:startBenchmark()

			return "Started benchmark"
		end

		return "Error: Cannot run benchmark, errors in config"
	end

	return "Error: Cannot run benchmark, load a map first"
end

g_benchmark = Benchmark.new()
