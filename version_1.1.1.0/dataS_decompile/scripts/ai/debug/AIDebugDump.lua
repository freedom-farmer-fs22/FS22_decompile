AIDebugDump = {}
local AIDebugDump_mt = Class(AIDebugDump)

function AIDebugDump.new(vehicle, agentId, customMt)
	local self = setmetatable({}, customMt or AIDebugDump_mt)
	self.vehicle = vehicle
	self.agentId = agentId
	self.dumpedAgent = false

	return self
end

function AIDebugDump:delete()
	self:stopRecording()
end

function AIDebugDump:setTarget(x, y, z, dirX, dirY, dirZ, cx, cy, cz, cDirX, cDirY, cDirZ)
	if self.dump ~= nil then
		local currentTarget = {
			frames = {},
			target = {
				x,
				y,
				z,
				dirX,
				dirY,
				dirZ
			},
			start = {
				cx,
				cy,
				cz,
				cDirX,
				cDirY,
				cDirZ
			}
		}

		table.insert(self.dump.targets, currentTarget)
	end
end

function AIDebugDump:addData(dt, x, y, z, dirX, dirY, dirZ, lastSpeed, curvature, maxSpeed, status)
	if self.dump ~= nil then
		local debugData = {
			dt = dt,
			pos = {
				x,
				y,
				z
			},
			dir = {
				dirX,
				dirY,
				dirZ
			},
			lastSpeed = lastSpeed,
			curvature = curvature,
			speed = maxSpeed,
			status = status
		}

		table.insert(self.dump.targets[#self.dump.targets].frames, debugData)

		if not self.dumpedAgent then
			self.dumpedAgent = true

			dumpVehicleNavigationAgent(self.agentId, self.folder .. self.filename .. ".dat")
		end
	end
end

function AIDebugDump:startRecording(minTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripedalAcceleration)
	if self.dump == nil then
		self.dumpedAgent = false
		self.folder = getUserProfileAppPath() .. "aiSystem/"

		createFolder(self.folder)

		self.filename = getDate("%Y_%m_%d_%H_%M_%S") .. "_dump"

		beginVehicleNavigationDebugLogging(self.agentId)

		self.dump = {
			minTurningRadius = minTurningRadius,
			allowBackwards = allowBackwards,
			width = width,
			length = length,
			lengthOffset = lengthOffset,
			frontOffset = frontOffset,
			maxBrakeAcceleration = maxBrakeAcceleration,
			maxCentripedalAcceleration = maxCentripedalAcceleration,
			targets = {}
		}
	end
end

function AIDebugDump:stopRecording()
	if self.dump ~= nil then
		Logging.info("Writing debug dump...")

		local folder = self.folder
		local filename = self.filename
		local logFilename = folder .. filename .. ".log"
		local dumpXMLFilename = folder .. filename .. ".xml"

		endVehicleNavigationDebugLogging(self.agentId, logFilename)

		local xmlFile = createXMLFile("dumpData", dumpXMLFilename, "dumpData")

		setXMLString(xmlFile, "dumpData.vehicle", self.vehicle.configFileName)
		setXMLFloat(xmlFile, "dumpData.settings#minTurningRadius", self.dump.minTurningRadius)
		setXMLBool(xmlFile, "dumpData.settings#allowBackwards", self.dump.allowBackwards)
		setXMLFloat(xmlFile, "dumpData.settings#width", self.dump.width)
		setXMLFloat(xmlFile, "dumpData.settings#length", self.dump.length)
		setXMLFloat(xmlFile, "dumpData.settings#lengthOffset", self.dump.lengthOffset)
		setXMLFloat(xmlFile, "dumpData.settings#frontOffset", self.dump.frontOffset)
		setXMLFloat(xmlFile, "dumpData.settings#maxBrakeAcceleration", self.dump.maxBrakeAcceleration)
		setXMLFloat(xmlFile, "dumpData.settings#maxCentripedalAcceleration", self.dump.maxCentripedalAcceleration)

		local stateCache = {}

		for k, target in ipairs(self.dump.targets) do
			local key = string.format("dumpData.targets.target(%d)", k - 1)

			setXMLFloat(xmlFile, key .. ".start#x", target.start[1])
			setXMLFloat(xmlFile, key .. ".start#y", target.start[2])
			setXMLFloat(xmlFile, key .. ".start#z", target.start[3])
			setXMLFloat(xmlFile, key .. ".start#xDir", target.start[4])
			setXMLFloat(xmlFile, key .. ".start#yDir", target.start[5])
			setXMLFloat(xmlFile, key .. ".start#zDir", target.start[6])
			setXMLFloat(xmlFile, key .. ".target#x", target.target[1])
			setXMLFloat(xmlFile, key .. ".target#y", target.target[2])
			setXMLFloat(xmlFile, key .. ".target#z", target.target[3])
			setXMLFloat(xmlFile, key .. ".target#xDir", target.target[4])
			setXMLFloat(xmlFile, key .. ".target#yDir", target.target[5])
			setXMLFloat(xmlFile, key .. ".target#zDir", target.target[6])

			for j, frameData in ipairs(target.frames) do
				local frameKey = string.format("%s.frames.frame(%d)", key, j - 1)
				local stateName = stateCache[frameData.status]

				if stateName == nil then
					stateName = AISystem.getAgentStateName(frameData.status)
					stateCache[frameData.status] = stateName
				end

				setXMLString(xmlFile, frameKey .. "#status", stateName)
				setXMLFloat(xmlFile, frameKey .. "#speed", frameData.speed)
				setXMLFloat(xmlFile, frameKey .. "#curvature", frameData.curvature)
				setXMLFloat(xmlFile, frameKey .. "#dt", frameData.dt)
				setXMLFloat(xmlFile, frameKey .. "#x", frameData.pos[1])
				setXMLFloat(xmlFile, frameKey .. "#y", frameData.pos[2])
				setXMLFloat(xmlFile, frameKey .. "#z", frameData.pos[3])
				setXMLFloat(xmlFile, frameKey .. "#dirX", frameData.dir[1])
				setXMLFloat(xmlFile, frameKey .. "#dirY", frameData.dir[2])
				setXMLFloat(xmlFile, frameKey .. "#dirZ", frameData.dir[3])
				setXMLFloat(xmlFile, frameKey .. "#lastSpeed", frameData.lastSpeed)
			end
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end
