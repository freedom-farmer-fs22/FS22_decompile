Butterfly = {}
local Butterfly_mt = Class(Butterfly)

function Butterfly:onCreate(id)
	g_currentMission:addUpdateable(Butterfly.new(id))
end

function Butterfly.new(id)
	local self = {}

	setmetatable(self, Butterfly_mt)

	self.id = id
	self.butterflies = {}

	for i = 1, getNumOfChildren(id) do
		local butterflyId = getChildAt(id, i - 1)
		local splineId = getChildAt(butterflyId, 0)
		local meshId = getChildAt(butterflyId, 1)
		local speed = Utils.getNoNil(getUserAttribute(butterflyId, "speed"), 0.005)
		local butterfly = {
			splinePos = 0,
			butterflyId = butterflyId,
			splineId = splineId,
			meshId = meshId,
			speed = speed
		}

		table.insert(self.butterflies, butterfly)
	end

	self.time = 0
	self.animTimer = 0
	self.animDelay = 100
	self.flip = true
	self.checkClosestButterflyTimer = 0
	self.checkClosestButterflyInterval = 2000
	self.activeButterfly = nil
	self.isSunOn = true

	return self
end

function Butterfly:delete()
end

function Butterfly:update(dt)
	if g_currentMission.environment.isSunOn ~= self.isSunOn then
		self.isSunOn = g_currentMission.environment.isSunOn

		if self.isSunOn then
			setVisibility(self.id, true)
		else
			setVisibility(self.id, false)
		end
	end

	if self.isSunOn then
		self.checkClosestButterflyTimer = self.checkClosestButterflyTimer - dt

		if self.checkClosestButterflyTimer <= 0 then
			local closestDistance = 100000000
			local closestButterfly = nil
			local playerPosition = {
				0,
				0,
				0
			}

			if g_currentMission.controlPlayer then
				if g_currentMission.player ~= nil then
					playerPosition[1], playerPosition[2], playerPosition[3] = getWorldTranslation(g_currentMission.player.rootNode)
				end
			elseif g_currentMission.controlledVehicle ~= nil then
				playerPosition[1], playerPosition[2], playerPosition[3] = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
			end

			local butterflyPosition = {
				0,
				0,
				0
			}

			for _, butterfly in pairs(self.butterflies) do
				butterflyPosition[1], butterflyPosition[2], butterflyPosition[3] = getWorldTranslation(butterfly.splineId)
				local distance = math.sqrt((playerPosition[1] - butterflyPosition[1]) * (playerPosition[1] - butterflyPosition[1]) + (playerPosition[2] - butterflyPosition[2]) * (playerPosition[2] - butterflyPosition[2]) + (playerPosition[3] - butterflyPosition[3]) * (playerPosition[3] - butterflyPosition[3]))

				if distance < closestDistance then
					closestDistance = distance
					closestButterfly = butterfly
				end
			end

			if closestDistance < 150 then
				for _, butterfly in pairs(self.butterflies) do
					if butterfly.butterflyId == closestButterfly.butterflyId then
						setVisibility(butterfly.butterflyId, true)
					else
						setVisibility(butterfly.butterflyId, false)
					end
				end

				self.activeButterfly = closestButterfly
			else
				for _, butterfly in pairs(self.butterflies) do
					setVisibility(butterfly.butterflyId, false)
				end

				self.activeButterfly = nil
			end

			self.checkClosestButterflyTimer = self.checkClosestButterflyInterval
		end

		if self.activeButterfly ~= nil then
			self.animTimer = self.animTimer - dt

			if self.animTimer <= 0 then
				self.flip = not self.flip

				setVisibility(getChildAt(self.activeButterfly.meshId, 0), self.flip)
				setVisibility(getChildAt(self.activeButterfly.meshId, 1), not self.flip)

				self.animTimer = self.animDelay
			end

			self.time = self.time + dt * math.random() * 1
			self.activeButterfly.splinePos = self.activeButterfly.splinePos + dt * math.random() * 1 * self.activeButterfly.speed * 0.01
			local offset1 = math.sin(self.time * 0.005) * math.cos(self.time * 0.025) * 0.05
			local offset2 = math.sin(self.time * 0.0175) * math.cos(self.time * 0.0125) * 0.05

			if self.activeButterfly.splinePos > 1 then
				self.activeButterfly.splinePos = self.activeButterfly.splinePos - 1
			end

			local x, y, z = getSplinePosition(self.activeButterfly.splineId, self.activeButterfly.splinePos)
			local rx, ry, rz = getSplineOrientation(self.activeButterfly.splineId, self.activeButterfly.splinePos, 0, -1, 0)

			setTranslation(self.activeButterfly.meshId, x + offset1, y + offset2, z + offset1)
			setRotation(self.activeButterfly.meshId, rx, ry, rz)
		end
	end
end
