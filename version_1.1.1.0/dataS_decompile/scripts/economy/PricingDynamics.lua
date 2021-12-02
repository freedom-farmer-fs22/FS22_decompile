PricingDynamics = {}
local PricingDynamics_mt = Class(PricingDynamics)
PricingDynamics.VERSION = 1
PricingDynamics.AMP_DIST_CONSTANT = 1
PricingDynamics.AMP_DIST_LINEAR_DOWN = 2
PricingDynamics.AMP_DIST_LINEAR_UP = 3
PricingDynamics.TREND_PLATEAU = 1
PricingDynamics.TREND_CLIMBING = 2
PricingDynamics.TREND_FALLING = 3

function PricingDynamics.new(mean, amp, ampVar, ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction, customMt)
	if customMt == nil then
		customMt = PricingDynamics_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.curves = {}
	self.plateauDuration = per * plateauFactor
	self.meanValue = mean
	self.isInPlateau = math.random() < initialPlateauFraction
	self.nextPlateauNumber = 0
	self.baseCurve = self:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)
	local sinePeriod = self.baseCurve.period

	if self.isInPlateau then
		self.plateauTime = math.random() * self.plateauDuration

		if Utils.getCoinToss() then
			self.baseCurve.time = sinePeriod * 0.25
		else
			self.baseCurve.time = sinePeriod * 0.75
			self.nextPlateauNumber = 1
		end
	else
		self.plateauTime = 0
		local t = self.baseCurve.time

		if t >= self.baseCurve.period * 0.5 and t < self.baseCurve.period * 0.75 then
			self.nextPlateauNumber = 1
		end
	end

	return self
end

function PricingDynamics:addCurve(amp, ampVar, ampDist, per, perVar, perDist)
	local curve = self:startFirstCycle(nil, amp, ampVar, ampDist, per, perVar, perDist)

	table.insert(self.curves, curve)
end

function PricingDynamics:update(dt)
	if self.isInPlateau then
		local newTime = self.plateauTime + dt

		if self.plateauDuration <= newTime then
			self.isInPlateau = false
			self.plateauTime = 0
			self.nextPlateauNumber = 1 - self.nextPlateauNumber
		else
			self.plateauTime = newTime
		end

		return
	end

	local newTime = self.baseCurve.time + dt

	self:updateCurve(self.baseCurve, dt)

	for _, curve in pairs(self.curves) do
		self:updateCurve(curve, dt)
	end

	local nextPlateauTime = self.baseCurve.period * 0.25

	if self.nextPlateauNumber == 1 then
		nextPlateauTime = self.baseCurve.period * 0.75
	end

	if not self.isInPlateau and nextPlateauTime < newTime and newTime < nextPlateauTime + self.baseCurve.period * 0.25 then
		self.isInPlateau = true
		self.plateauTime = 0
		self.baseCurve.time = nextPlateauTime
	end
end

function PricingDynamics:evaluate()
	local value = self.meanValue
	value = value + self:evaluateCurve(self.baseCurve)

	for _, curve in pairs(self.curves) do
		value = value + self:evaluateCurve(curve)
	end

	return value
end

function PricingDynamics:getBaseCurveTrend()
	if self.isInPlateau then
		return PricingDynamics.TREND_PLATEAU
	elseif self.baseCurve.time >= self.baseCurve.period * 0.25 and self.baseCurve.time <= self.baseCurve.period * 0.75 then
		return PricingDynamics.TREND_FALLING
	end

	return PricingDynamics.TREND_CLIMBING
end

function PricingDynamics:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#priceVersion", PricingDynamics.VERSION)
	xmlFile:setValue(key .. "#isInPlateau", self.isInPlateau)
	xmlFile:setValue(key .. "#nextPlateauNumber", self.nextPlateauNumber)
	xmlFile:setValue(key .. "#plateauDuration", self.plateauDuration)
	xmlFile:setValue(key .. "#meanValue", self.meanValue)
	xmlFile:setValue(key .. "#plateauTime", self.plateauTime)
	self:saveCurveToXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")

	for k, curve in pairs(self.curves) do
		self:saveCurveToXMLFile(xmlFile, key, curve, k)
	end
end

function PricingDynamics:loadFromXMLFile(xmlFile, key)
	if xmlFile:getValue(key .. "#priceVersion", 0) ~= PricingDynamics.VERSION then
		return
	end

	self.isInPlateau = xmlFile:getValue(key .. "#isInPlateau", self.isInPlateau)
	self.nextPlateauNumber = xmlFile:getValue(key .. "#nextPlateauNumber", self.nextPlateauNumber)
	self.meanValue = xmlFile:getValue(key .. "#meanValue", self.meanValue)
	self.plateauTime = xmlFile:getValue(key .. "#plateauTime", self.plateauTime)
	self.plateauDuration = xmlFile:getValue(key .. "#plateauDuration", self.plateauDuration)

	self:loadCurveFromXMLFile(xmlFile, key, self.baseCurve, "BaseCurve")

	for k, curve in pairs(self.curves) do
		self:loadCurveFromXMLFile(xmlFile, key, curve, k)
	end
end

function PricingDynamics:saveCurveToXMLFile(xmlFile, key, curve, name)
	local curveKey = string.format("%s.curve%s", key, tostring(name))

	xmlFile:setValue(curveKey .. "#nominalAmplitude", curve.nominalAmplitude)
	xmlFile:setValue(curveKey .. "#nominalAmplitudeVariation", curve.nominalAmplitudeVariation)
	xmlFile:setValue(curveKey .. "#amplitudeDistribution", curve.amplitudeDistribution)
	xmlFile:setValue(curveKey .. "#nominalPeriod", curve.nominalPeriod)
	xmlFile:setValue(curveKey .. "#nominalPeriodVariation", curve.nominalPeriodVariation)
	xmlFile:setValue(curveKey .. "#periodDistribution", curve.periodDistribution)
	xmlFile:setValue(curveKey .. "#amplitude", curve.amplitude)
	xmlFile:setValue(curveKey .. "#period", curve.period)
	xmlFile:setValue(curveKey .. "#time", curve.time)
end

function PricingDynamics:loadCurveFromXMLFile(xmlFile, key, curve, name)
	curve.nominalAmplitude = xmlFile:getValue(key .. ".curve" .. name .. "#nominalAmplitude", curve.nominalAmplitude)
	curve.nominalAmplitudeVariation = xmlFile:getValue(key .. ".curve" .. name .. "#nominalAmplitudeVariation", curve.nominalAmplitudeVariation)
	curve.amplitudeDistribution = xmlFile:getValue(key .. ".curve" .. name .. "#amplitudeDistribution", curve.amplitudeDistribution)
	curve.nominalPeriod = xmlFile:getValue(key .. ".curve" .. name .. "#nominalPeriod", curve.nominalPeriod)
	curve.nominalPeriodVariation = xmlFile:getValue(key .. ".curve" .. name .. "#nominalPeriodVariation", curve.nominalPeriodVariation)
	curve.periodDistribution = xmlFile:getValue(key .. ".curve" .. name .. "#periodDistribution", curve.periodDistribution)
	curve.amplitude = xmlFile:getValue(key .. ".curve" .. name .. "#amplitude", curve.amplitude)
	curve.period = xmlFile:getValue(key .. ".curve" .. name .. "#period", curve.period)
	curve.time = xmlFile:getValue(key .. ".curve" .. name .. "#time", curve.time)
end

function PricingDynamics:startFirstCycle(curve, amp, ampVar, ampDist, per, perVar, perDist)
	curve = Utils.getNoNil(curve, {})
	curve.nominalAmplitude = amp
	curve.nominalAmplitudeVariation = ampVar
	curve.amplitudeDistribution = ampDist
	curve.nominalPeriod = per
	curve.nominalPeriodVariation = perVar
	curve.periodDistribution = perDist

	self:startNewCycle(curve)

	curve.time = math.random() * curve.period

	return curve
end

function PricingDynamics:startNewCycle(curve)
	local sinePeriod = curve.nominalPeriod - 2 * self.plateauDuration
	local sinePeriodVariation = sinePeriod * curve.nominalPeriodVariation / curve.nominalPeriod
	curve.amplitude = self:getRandomValue(curve.nominalAmplitude, curve.nominalAmplitudeVariation, curve.amplitudeDistribution)
	curve.period = self:getRandomValue(sinePeriod, sinePeriodVariation, curve.periodDistribution)
	curve.time = 0
end

function PricingDynamics:updateCurve(curve, dt)
	curve.time = curve.time + dt

	if curve.period <= curve.time then
		self:startNewCycle(curve)
	end
end

function PricingDynamics:evaluateCurve(curve)
	return curve.amplitude * math.sin(2 * math.pi * curve.time / curve.period)
end

function PricingDynamics:getRandomValue(center, deviation, distribution)
	local minValue = center - deviation
	local maxValue = center + deviation

	if distribution == PricingDynamics.AMP_DIST_CONSTANT then
		return Utils.randomFloat(minValue, maxValue)
	elseif distribution == PricingDynamics.AMP_DIST_LINEAR_DOWN then
		local r = math.random()

		return maxValue + math.sqrt(r) * (minValue - maxValue)
	elseif distribution == PricingDynamics.AMP_DIST_LINEAR_UP then
		local r = math.random()

		return minValue - math.sqrt(r) * (maxValue - minValue)
	end

	return -math.huge
end

function PricingDynamics.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#priceVersion", "Price version (If version is outdated values are reseted)", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#isInPlateau", "Is in plateau")
	schema:register(XMLValueType.INT, basePath .. "#nextPlateauNumber", "Next plateau number")
	schema:register(XMLValueType.FLOAT, basePath .. "#meanValue", "Mean value")
	schema:register(XMLValueType.FLOAT, basePath .. "#plateauTime", "Plateau time")
	schema:register(XMLValueType.INT, basePath .. "#plateauDuration", "Plateau duration")
	PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, "BaseCurve")
	PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, "1")
end

function PricingDynamics.registerSavegameCurveXMLPaths(schema, basePath, name)
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#nominalAmplitude", "Normal amplitude")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#nominalAmplitudeVariation", "Normal amplitude variation")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#amplitudeDistribution", "Amplitude fistribution")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#nominalPeriod", "Nominal period")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#nominalPeriodVariation", "Nominal period variation")
	schema:register(XMLValueType.INT, basePath .. ".curve" .. name .. "#periodDistribution", "Period distribution")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#amplitude", "Amplitude")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#period", "Period")
	schema:register(XMLValueType.FLOAT, basePath .. ".curve" .. name .. "#time", "Time")
end
