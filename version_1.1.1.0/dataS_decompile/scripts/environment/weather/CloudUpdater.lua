CloudUpdater = {}
local CloudUpdater_mt = Class(CloudUpdater)

function CloudUpdater.new(index, customMt)
	local self = setmetatable({}, customMt or CloudUpdater_mt)
	self.index = index
	self.lastClouds = {
		type = 1,
		cloudBaseShapeTiling = 2500,
		cloudErosionTiling = 2500,
		precipitation = 0,
		combinedNoiseEdge0 = 0.49,
		combinedNoiseEdge1 = 1,
		noise0Weight = 0.314507,
		noise0Edge0 = 0.09,
		noise0Edge1 = 0.99,
		noise1Weight = 0.525494,
		noise1Edge0 = 0,
		noise1Edge1 = 0.88,
		noise2Weight = 0.16,
		noise2Edge0 = 0,
		noise2Edge1 = 0.9,
		erosionWeight = 0.3,
		cirrusCoverage = 0.05,
		lightDamping = 0,
		envMapCloudProbeIndex = 1
	}
	self.currentClouds = {
		type = 1,
		cloudBaseShapeTiling = 2500,
		cloudErosionTiling = 2500,
		precipitation = 0,
		combinedNoiseEdge0 = 0.49,
		combinedNoiseEdge1 = 1,
		noise0Weight = 0.314507,
		noise0Edge0 = 0.09,
		noise0Edge1 = 0.99,
		noise1Weight = 0.525494,
		noise1Edge0 = 0,
		noise1Edge1 = 0.88,
		noise2Weight = 0.16,
		noise2Edge0 = 0,
		noise2Edge1 = 0.9,
		erosionWeight = 0.3,
		cirrusCoverage = 0.05,
		lightDamping = 0,
		envMapCloudProbeIndex = 1
	}
	self.targetClouds = table.copy(self.lastClouds, math.huge)
	self.windDirX = 1
	self.windDirZ = 0
	self.windVelocity = 1
	self.cirrusCloudSpeedFactor = 1
	self.speedScale = 1
	self.alpha = 1
	self.duration = 1
	self.isDirty = true

	return self
end

function CloudUpdater:delete()
end

function CloudUpdater:update(scaledDt)
	if self.alpha ~= 1 or self.isDirty then
		self.alpha = math.min(self.alpha + scaledDt / self.duration, 1)
		local lastClouds = self.lastClouds
		local targetClouds = self.targetClouds
		local combinedNoiseEdge0 = MathUtil.lerp(lastClouds.combinedNoiseEdge0, targetClouds.combinedNoiseEdge0, self.alpha)
		local combinedNoiseEdge1 = MathUtil.lerp(lastClouds.combinedNoiseEdge1, targetClouds.combinedNoiseEdge1, self.alpha)
		local noise0Weight = MathUtil.lerp(lastClouds.noise0Weight, targetClouds.noise0Weight, self.alpha)
		local noise0Edge0 = MathUtil.lerp(lastClouds.noise0Edge0, targetClouds.noise0Edge0, self.alpha)
		local noise0Edge1 = MathUtil.lerp(lastClouds.noise0Edge1, targetClouds.noise0Edge1, self.alpha)
		local noise1Weight = MathUtil.lerp(lastClouds.noise1Weight, targetClouds.noise1Weight, self.alpha)
		local noise1Edge0 = MathUtil.lerp(lastClouds.noise1Edge0, targetClouds.noise1Edge0, self.alpha)
		local noise1Edge1 = MathUtil.lerp(lastClouds.noise1Edge1, targetClouds.noise1Edge1, self.alpha)
		local noise2Weight = MathUtil.lerp(lastClouds.noise2Weight, targetClouds.noise2Weight, self.alpha)
		local noise2Edge0 = MathUtil.lerp(lastClouds.noise2Edge0, targetClouds.noise2Edge0, self.alpha)
		local noise2Edge1 = MathUtil.lerp(lastClouds.noise2Edge1, targetClouds.noise2Edge1, self.alpha)
		local erosionWeight = MathUtil.lerp(lastClouds.erosionWeight, targetClouds.erosionWeight, self.alpha)
		local precipitation = MathUtil.lerp(lastClouds.precipitation, targetClouds.precipitation, self.alpha)
		local cloudBaseShapeTiling = MathUtil.lerp(lastClouds.cloudBaseShapeTiling, targetClouds.cloudBaseShapeTiling, self.alpha)
		local cloudErosionTiling = MathUtil.lerp(lastClouds.cloudErosionTiling, targetClouds.cloudErosionTiling, self.alpha)

		if combinedNoiseEdge1 < combinedNoiseEdge0 then
			combinedNoiseEdge1 = combinedNoiseEdge0
			combinedNoiseEdge0 = combinedNoiseEdge1
		end

		if noise0Edge1 < noise0Edge0 then
			noise0Edge1 = noise0Edge0
			noise0Edge0 = noise0Edge1
		end

		if noise1Edge1 < noise1Edge0 then
			noise1Edge1 = noise1Edge0
			noise1Edge0 = noise1Edge1
		end

		if noise2Edge1 < noise2Edge0 then
			noise2Edge1 = noise2Edge0
			noise2Edge0 = noise2Edge1
		end

		local weight = noise0Weight + noise1Weight + noise2Weight
		noise0Weight = noise0Weight / weight
		noise1Weight = noise1Weight / weight
		noise2Weight = noise2Weight / weight

		setGlobalCloudCoverage(combinedNoiseEdge0, combinedNoiseEdge1, noise0Weight, noise0Edge0, noise0Edge1, noise1Weight, noise1Edge0, noise1Edge1, noise2Weight, noise2Edge0, noise2Edge1, erosionWeight)

		local cirrusCoverage = MathUtil.lerp(lastClouds.cirrusCoverage, targetClouds.cirrusCoverage, self.alpha)
		local lightDamping = MathUtil.lerp(lastClouds.lightDamping, targetClouds.lightDamping, self.alpha)

		setScatteringLightSourceDamping(lightDamping)
		setCirrusCloudCoverage(cirrusCoverage)
		setCloudType(lastClouds.type, targetClouds.type, self.alpha, cloudBaseShapeTiling, cloudErosionTiling)
		setCloudPrecipitation(precipitation)

		self.currentClouds.type = MathUtil.lerp(lastClouds.type, targetClouds.type, self.alpha)
		self.currentClouds.precipitation = precipitation
		self.currentClouds.cloudBaseShapeTiling = cloudBaseShapeTiling
		self.currentClouds.cloudErosionTiling = cloudErosionTiling
		self.currentClouds.combinedNoiseEdge0 = combinedNoiseEdge0
		self.currentClouds.combinedNoiseEdge1 = combinedNoiseEdge1
		self.currentClouds.noise0Weight = noise0Weight
		self.currentClouds.noise0Edge0 = noise0Edge0
		self.currentClouds.noise0Edge1 = noise0Edge1
		self.currentClouds.noise1Weight = noise1Weight
		self.currentClouds.noise1Edge0 = noise1Edge0
		self.currentClouds.noise1Edge1 = noise1Edge1
		self.currentClouds.noise2Weight = noise2Weight
		self.currentClouds.noise2Edge0 = noise2Edge0
		self.currentClouds.noise2Edge1 = noise2Edge1
		self.currentClouds.erosionWeight = erosionWeight
		self.currentClouds.cirrusCoverage = cirrusCoverage
		self.currentClouds.lightDamping = lightDamping
		self.currentClouds.envMapCloudProbeIndex = lastClouds.envMapCloudProbeIndex
		self.isDirty = false
	end
end

function CloudUpdater:setTargetClouds(clouds, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastClouds = self.targetClouds
	self.targetClouds = clouds
end

function CloudUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.windDirX = windDirX
	self.windDirZ = windDirZ
	self.windVelocity = windVelocity
	self.cirrusCloudSpeedFactor = cirrusCloudSpeedFactor

	self:updateCloudWind()
end

function CloudUpdater:updateCloudWind()
	local windDirX = self.windDirX
	local windDirZ = self.windDirZ
	local cirrusCloudSpeedFactor = self.cirrusCloudSpeedFactor
	local windVelocity = self.windVelocity * self.speedScale

	if self.slowModeEnabled then
		windVelocity = windVelocity / 100
	end

	setCloudWind(-windDirX, windDirZ, windVelocity, -windDirX, -windDirZ, windVelocity * cirrusCloudSpeedFactor)
end

function CloudUpdater:setTimeScale(scale)
	self.speedScale = scale
	self.isDirty = true

	self:updateCloudWind()
end

function CloudUpdater:setSlowModeEnabled(enabled)
	self.slowModeEnabled = enabled
end

function CloudUpdater:getCurrentValues()
	return self.currentClouds
end
