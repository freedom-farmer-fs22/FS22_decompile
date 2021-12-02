MapPerformanceTestUtil = {}
local MapPerformanceTestUtil_mt = Class(MapPerformanceTestUtil)

function MapPerformanceTestUtil.new()
	local self = {}

	setmetatable(self, MapPerformanceTestUtil_mt)

	self.isPrepared = false
	self.isRunning = false

	g_currentMission:addUpdateable(self)
	addConsoleCommand("gsBenchmarkMapPerformanceTest", "Runs a basic performance test for the current map", "runMapPerformanceTest", self)

	return self
end

function MapPerformanceTestUtil:delete()
	if self.testCamera ~= nil then
		delete(self.testCamera)
	end

	removeConsoleCommand("gsBenchmarkMapPerformanceTest")
end

function MapPerformanceTestUtil:update(dt)
	if self.runTest and self.isPrepared then
		self.isRunning = true

		if self.testProps.xStepCurrent <= self.testProps.xStepCount and self.testProps.zStepCurrent <= self.testProps.zStepCount then
			local x = self.testProps.xStart + self.testProps.xStepIncrement * (self.testProps.xStepCurrent - 1)
			local z = self.testProps.zStart + self.testProps.zStepIncrement * (self.testProps.zStepCurrent - 1)
			local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
			local angle = 2 * math.pi * (self.testProps.angleCurrent - 1) / self.testProps.angleCount

			setTranslation(self.testCamera, x, terrainHeight + 5, z)
			setRotation(self.testCamera, 0, angle + math.pi, 0)
			setCamera(self.testCamera)

			self.testProps.measureTimeCurrent = self.testProps.measureTimeCurrent + dt

			if self.testProps.measureTimePerAngle < self.testProps.measureTimeCurrent then
				self.testProps.measureTimeCurrent = 0
				self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].meanFps[self.testProps.angleCurrent] = self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalFrames[self.testProps.angleCurrent] / self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalTime[self.testProps.angleCurrent]
				self.testProps.angleCurrent = self.testProps.angleCurrent + 1

				if self.testProps.angleCount < self.testProps.angleCurrent then
					self.testProps.angleCurrent = 1
					self.testProps.zStepCurrent = self.testProps.zStepCurrent + 1

					if self.testProps.zStepCount < self.testProps.zStepCurrent then
						self.testProps.zStepCurrent = 1
						self.testProps.xStepCurrent = self.testProps.xStepCurrent + 1

						if self.testProps.xStepCount < self.testProps.xStepCurrent then
							self.runTest = false
							self.isRunning = false
							g_currentMission.player.walkingIsLocked = false

							self:writeTestDataToFile()
						end
					end
				end
			else
				self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalTime[self.testProps.angleCurrent] = self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalTime[self.testProps.angleCurrent] + 0.001 * dt
				self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalFrames[self.testProps.angleCurrent] = self.testData[self.testProps.xStepCurrent][self.testProps.zStepCurrent].totalFrames[self.testProps.angleCurrent] + 1
			end
		end
	end
end

function MapPerformanceTestUtil:runMapPerformanceTest(xStart, zStart, xSize, zSize, xSteps, zSteps)
	xStart = Utils.getNoNil(tonumber(xStart), 0)
	zStart = Utils.getNoNil(tonumber(zStart), 0)
	xSize = Utils.getNoNil(tonumber(xSize), 100)
	zSize = Utils.getNoNil(tonumber(zSize), 100)
	xSteps = Utils.getNoNil(tonumber(xSteps), 3)
	zSteps = Utils.getNoNil(tonumber(zSteps), 3)
	self.runTest = not self.runTest

	if self.runTest then
		if not self.isPrepared then
			local mapName = ""

			if g_currentMission.missionInfo ~= nil then
				mapName = tostring(g_currentMission.missionInfo.name)
				local map = g_mapManager:getMapById(g_currentMission.missionInfo.mapId)

				if map ~= nil and g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
					mapName = map.title
				end
			end

			mapName = string.gsub(mapName, " ", "")
			local foldername = getUserProfileAppPath() .. "mapPerformaceTests/"

			createFolder(foldername)

			local filename = foldername .. tostring(mapName) .. getDate("_%Y_%m_%d") .. ".ppm"

			deleteFile(filename)

			self.fileId = createFile(filename, FileAccess.WRITE)

			if self.fileId ~= nil and self.fileId ~= 0 then
				for _, vehicle in pairs(g_currentMission.vehicles) do
					if vehicle.stopCurrentAIJob ~= nil then
						vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
					end
				end

				if g_currentMission.controlledVehicle ~= nil then
					g_currentMission.controlledVehicle:leaveVehicle()

					g_currentMission.player.walkingIsLocked = true
				end

				self.testCamera = createCamera("MapPerformanceTestCamera", math.rad(60), 0.15, 6000)

				link(getRootNode(), self.testCamera)

				self.testProps = {
					angleCount = 8,
					angleCurrent = 1,
					measureTimePerAngle = 1000,
					measureTimeCurrent = 0,
					xStart = xStart + xSize,
					xEnd = xStart - xSize,
					zStart = zStart + zSize,
					zEnd = zStart - zSize,
					xStepCount = xSteps,
					zStepCount = zSteps
				}
				self.testProps.xStepIncrement = (self.testProps.xEnd - self.testProps.xStart) / (self.testProps.xStepCount - 1)
				self.testProps.zStepIncrement = (self.testProps.zEnd - self.testProps.zStart) / (self.testProps.zStepCount - 1)
				self.testProps.xStepCurrent = 1
				self.testProps.zStepCurrent = 1
				self.testData = {}

				for x = 1, self.testProps.xStepCount do
					self.testData[x] = {}

					for _ = 1, self.testProps.zStepCount do
						local entry = {
							totalTime = {},
							totalFrames = {},
							meanFps = {}
						}

						for i = 1, self.testProps.angleCount do
							entry.totalTime[i] = 0
							entry.totalFrames[i] = 0
							entry.meanFps[i] = 0
						end

						table.insert(self.testData[x], entry)
					end
				end

				self.isPrepared = true
			else
				print("Could not create file '" .. tostring(filename) .. "'. Aborting MapPerformanceTestUtil")
			end
		end
	else
		self.isPrepared = false
	end

	if self.runTest then
		return "PerformanceTest started"
	else
		return "PerformanceTest stopped"
	end
end

function MapPerformanceTestUtil:writeTestDataToFile()
	if self.fileId ~= nil and self.fileId ~= 0 then
		local terrainSize = g_currentMission.terrainSize
		local terrainSize_2 = terrainSize / 2
		local imageSize = 512
		local imageSize_2 = imageSize / 2

		fileWrite(self.fileId, string.format([[
P3
%d %d
#comment, could contain PC specs
255
]], imageSize, imageSize))

		local imageData = {}

		for xi = 1, imageSize do
			imageData[xi] = {}

			for zi = 1, imageSize do
				imageData[xi][zi] = {
					0,
					0,
					0
				}
			end
		end

		for xi = 1, self.testProps.xStepCount do
			local x0 = self.testProps.xStart + self.testProps.xStepIncrement * (xi - 1)

			for zi = 1, self.testProps.zStepCount do
				local z0 = self.testProps.zStart + self.testProps.zStepIncrement * (zi - 1)
				local xImage = math.floor(x0 / terrainSize_2 * imageSize_2 + imageSize_2 + 0.5)
				local zImage = math.floor(z0 / terrainSize_2 * imageSize_2 + imageSize_2 + 0.5)

				for i = 1, self.testProps.angleCount do
					local angle = 2 * math.pi * (i - 1) / self.testProps.angleCount
					local x = math.floor(xImage + math.sin(angle) + 0.5)
					local z = math.floor(zImage + math.cos(angle) + 0.5)

					if self.testData[xi][zi].meanFps[i] > 60 then
						local value = math.max(0, math.min(60, self.testData[xi][zi].meanFps[i] - 60)) / 60
						imageData[z][x][1] = 255 * (1 - value)
						imageData[z][x][2] = 255
						imageData[z][x][3] = 0
					else
						local value = math.max(0, self.testData[xi][zi].meanFps[i]) / 60
						imageData[z][x][1] = 255
						imageData[z][x][2] = 255 * value
						imageData[z][x][3] = 0
					end
				end

				imageData[zImage][xImage][1] = 125
				imageData[zImage][xImage][2] = 125
				imageData[zImage][xImage][3] = 125
			end
		end

		for xi = 1, imageSize do
			local lineString = ""

			for zi = 1, imageSize do
				lineString = lineString .. string.format("%d %d %d ", imageData[xi][zi][1], imageData[xi][zi][2], imageData[xi][zi][3])
			end

			fileWrite(self.fileId, lineString .. "\n")
		end

		self.testProps = {}
	else
		print("Error: Could not write to file")
	end
end
