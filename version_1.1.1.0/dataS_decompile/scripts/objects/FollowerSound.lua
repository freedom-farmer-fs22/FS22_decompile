FollowerSound = {}
local FollowerSound_mt = Class(FollowerSound)

function FollowerSound:onCreate(id)
	g_currentMission:addUpdateable(FollowerSound.new(id))
end

function FollowerSound.new(id)
	local self = {}

	setmetatable(self, FollowerSound_mt)

	self.splineId = getChildAt(id, 0)
	self.soundId = getChildAt(id, 1)
	self.currentDelay = 200
	self.splineCVs = {}
	self.followAxis = Utils.getNoNil(getUserAttribute(id, "followAxis"), 1)
	self.splineCVCount = getSplineNumOfCV(self.splineId)
	self.backwards = false

	for i = 1, self.splineCVCount do
		local splineCV = {}
		splineCV[1], splineCV[2], splineCV[3] = getSplineCV(self.splineId, i - 1)

		table.insert(self.splineCVs, splineCV)
	end

	if self.splineCVs[2][self.followAxis] < self.splineCVs[1][self.followAxis] then
		self.backwards = true
	end

	return self
end

function FollowerSound:delete()
end

function FollowerSound:update(dt)
	if self.currentDelay > 0 then
		self.currentDelay = self.currentDelay - dt
	else
		self.currentDelay = 200
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

		for i = 1, self.splineCVCount - 1 do
			if self.splineCVs[i][self.followAxis] <= playerPosition[self.followAxis] and playerPosition[self.followAxis] <= self.splineCVs[i + 1][self.followAxis] then
				local normalizedPos = (playerPosition[self.followAxis] - self.splineCVs[i][self.followAxis]) / (self.splineCVs[i + 1][self.followAxis] - self.splineCVs[i][self.followAxis])
				local newPos = {}

				for j = 1, 3 do
					newPos[j] = (1 - normalizedPos) * self.splineCVs[i][j] + normalizedPos * self.splineCVs[i + 1][j]
				end

				setTranslation(self.soundId, newPos[1], newPos[2], newPos[3])
			elseif playerPosition[self.followAxis] <= self.splineCVs[i][self.followAxis] and self.splineCVs[i + 1][self.followAxis] <= playerPosition[self.followAxis] then
				local normalizedPos = (playerPosition[self.followAxis] - self.splineCVs[i + 1][self.followAxis]) / (self.splineCVs[i][self.followAxis] - self.splineCVs[i + 1][self.followAxis])
				local newPos = {}

				for j = 1, 3 do
					newPos[j] = (1 - normalizedPos) * self.splineCVs[i + 1][j] + normalizedPos * self.splineCVs[i][j]
				end

				setTranslation(self.soundId, newPos[1], newPos[2], newPos[3])
			end
		end

		if self.backwards then
			if playerPosition[self.followAxis] < self.splineCVs[self.splineCVCount][self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[self.splineCVCount][1], self.splineCVs[self.splineCVCount][2], self.splineCVs[self.splineCVCount][3])
			elseif self.splineCVs[1][self.followAxis] < playerPosition[self.followAxis] then
				setTranslation(self.soundId, self.splineCVs[1][1], self.splineCVs[1][2], self.splineCVs[1][3])
			end
		elseif playerPosition[self.followAxis] < self.splineCVs[1][self.followAxis] then
			setTranslation(self.soundId, self.splineCVs[1][1], self.splineCVs[1][2], self.splineCVs[1][3])
		elseif self.splineCVs[self.splineCVCount][self.followAxis] < playerPosition[self.followAxis] then
			setTranslation(self.soundId, self.splineCVs[self.splineCVCount][1], self.splineCVs[self.splineCVCount][2], self.splineCVs[self.splineCVCount][3])
		end
	end
end
