SkyBoxUpdater = {
	RAIN_FADE_IN = 7200000
}
local SkyBoxUpdater_mt = Class(SkyBoxUpdater)

function SkyBoxUpdater.new(customMt)
	local self = setmetatable({}, customMt or SkyBoxUpdater_mt)
	self.w = 0
	self.z = 0
	self.y = 0
	self.x = 1
	self.rainScale = 0
	self.loadRequestId = nil

	return self
end

function SkyBoxUpdater:load(xmlFile, key)
	local i3dFilename = getXMLString(xmlFile, key .. "#filename")
	self.loadRequestId = g_i3DManager:loadI3DFileAsync(i3dFilename, false, false, SkyBoxUpdater.skyNodeLoaded, self, nil)
	self.skyCurve = AnimCurve.new(linearInterpolator4)

	self.skyCurve:loadCurveFromXML(xmlFile, key .. ".curve", loadInterpolator4Curve)
end

function SkyBoxUpdater:skyNodeLoaded(i3dNode, failedReason, args)
	if i3dNode ~= nil and i3dNode ~= 0 then
		self.skyNode = i3dNode

		link(getRootNode(), self.skyNode)

		self.skyId = getChildAt(self.skyNode, 0)
	end
end

function SkyBoxUpdater:delete()
	if self.skyNode ~= nil then
		delete(self.skyNode)
	end
end

function SkyBoxUpdater:update(dt, dayTime, rainScale, timeUntilRain)
	rainScale = rainScale > 0 and 1 or 0

	if rainScale < self.rainScale then
		rainScale = self.rainScale * 0.99 + rainScale * 0.01
	end

	if timeUntilRain < SkyBoxUpdater.RAIN_FADE_IN then
		rainScale = math.min((1 - timeUntilRain / SkyBoxUpdater.RAIN_FADE_IN)^0.5, 1)
	end

	local dayMinutes = dayTime / 60000
	local x, y, z, w = self.skyCurve:get(dayMinutes)
	w = w * (1 - rainScale)
	z = z * (1 - rainScale)
	y = y * (1 - rainScale)
	x = x * (1 - rainScale)

	self:setPartScale(x, y, z, w)
	self:setRainScale(rainScale)
end

function SkyBoxUpdater:setPartScale(x, y, z, w)
	if self.skyId ~= nil then
		setShaderParameter(self.skyId, "partScale", x, y, z, w)
	end

	self.w = w
	self.z = z
	self.y = y
	self.x = x
end

function SkyBoxUpdater:setRainScale(scale)
	if self.skyId ~= nil then
		setShaderParameter(self.skyId, "rainScale", scale, 0, 0, 0)
	end

	self.rainScale = scale
end

function SkyBoxUpdater:addDebugValues(data)
	table.insert(data, {
		value = "",
		name = "SKYBOX"
	})
	table.insert(data, {
		name = "partScale",
		value = string.format("%.2f %.2f %.2f %.2f", self.x, self.y, self.z, self.w)
	})
	table.insert(data, {
		name = "rainScale",
		value = string.format("%.2f", self.rainScale)
	})
end
