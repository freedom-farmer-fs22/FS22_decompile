FogUpdater = {}
local FogUpdater_mt = Class(FogUpdater)

function FogUpdater.new(customMt)
	local self = setmetatable({}, customMt or FogUpdater_mt)
	self.isDirty = false
	self.alpha = 1
	self.duration = 1
	self.currentMieScale = 1
	self.lastMieScale = 0
	self.targetMieScale = 0
	self.fogColor = {
		0.3,
		0.3,
		0.3
	}

	self:setFogMieScale(self.currentMieScale)

	return self
end

function FogUpdater:delete()
end

function FogUpdater:update(dt)
	if self.alpha ~= 1 then
		self.alpha = math.min(self.alpha + dt / self.duration, 1)
		self.currentMieScale = MathUtil.lerp(self.lastMieScale, self.targetMieScale, self.alpha)
		self.isDirty = true
	end

	if self.isDirty then
		self:setFogMieScale(self.forcedTargetMieScale or self.currentMieScale)

		self.isDirty = false
	end
end

function FogUpdater:getCurrentValues()
	return self.currentMieScale
end

function FogUpdater:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key .. "#currentMieScale", self.currentMieScale)
	setXMLFloat(xmlFile, key .. "#lastMieScale", self.lastMieScale)
	setXMLFloat(xmlFile, key .. "#targetMieScale", self.targetMieScale)
	setXMLFloat(xmlFile, key .. "#alpha", self.alpha)
	setXMLFloat(xmlFile, key .. "#duration", self.duration)
end

function FogUpdater:loadFromXMLFile(xmlFile, key)
	self.currentMieScale = getXMLFloat(xmlFile, key .. "#currentMieScale") or self.currentMieScale
	self.lastMieScale = getXMLFloat(xmlFile, key .. "#lastMieScale") or self.lastMieScale
	self.targetMieScale = getXMLFloat(xmlFile, key .. "#targetMieScale") or self.targetMieScale
	self.alpha = getXMLFloat(xmlFile, key .. "#alpha") or self.alpha
	self.duration = getXMLFloat(xmlFile, key .. "#duration") or self.duration
	self.isDirty = true
end

function FogUpdater:setTargetValues(targetMieScale, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastMieScale = self.currentMieScale
	self.targetMieScale = math.max(1, targetMieScale)
end

function FogUpdater:setForcedTargetValues(targetMieScale, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastMieScale = self.currentMieScale
	self.forcedTargetMieScale = targetMieScale and math.max(1, targetMieScale) or nil
end

function FogUpdater:setHeight(height)
	setFogPlaneHeight(height)
end

function FogUpdater:getHeight()
	return getFogPlaneHeight()
end

function FogUpdater:setFogMieScale(mieScale)
	setFogPlaneMieScale(mieScale)
end
