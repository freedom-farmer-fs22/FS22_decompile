DistantTrain = {}
local DistantTrain_mt = Class(DistantTrain)

function DistantTrain:onCreate(id)
	g_currentMission:addUpdateable(DistantTrain.new(id))
end

function DistantTrain.new(id)
	local self = setmetatable({}, DistantTrain_mt)
	self.nurbsId = getChildAt(id, 0)
	self.distantTrainId = getChildAt(id, 1)
	self.time = 1
	self.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 100
	self.delayMin = Utils.getNoNil(getUserAttribute(id, "delayMin"), 10) * 1000
	self.delayMax = Utils.getNoNil(getUserAttribute(id, "delayMax"), 30) * 1000
	self.currentDelay = math.random(self.delayMin, self.delayMax)
	local dx, _, dz = getSplineDirection(self.nurbsId, 0.5)

	setDirection(self.distantTrainId, dx, 0, dz, 0, 1, 0)

	return self
end

function DistantTrain:delete()
end

function DistantTrain:update(dt)
	if self.currentDelay > 0 then
		self.currentDelay = self.currentDelay - dt
	else
		self.time = self.time - 0.001 * dt * self.timeScale

		if self.time < 0 then
			self.time = 1
			self.currentDelay = math.random(self.delayMin, self.delayMax)
		end

		local x, y, z = getSplinePosition(self.nurbsId, self.time)

		setTranslation(self.distantTrainId, x, y, z)
	end
end
