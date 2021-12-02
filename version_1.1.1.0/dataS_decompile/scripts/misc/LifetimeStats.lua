LifetimeStats = {
	MS_TO_HOUR = 2.7777777777777776e-07,
	SAVE_PERIOD = 60000
}
local LifetimeStats_mt = Class(LifetimeStats)

function LifetimeStats.new(customMt)
	local self = setmetatable({}, LifetimeStats_mt or customMt)
	self.xmlFilename = Utils.getFilename("lifetimeStats.xml", getUserProfileAppPath())
	self.saveTimer = LifetimeStats.SAVE_PERIOD
	self.totalRuntimeUpToStart = 0
	self.gameRateMessagesShown = 0
	self.runtimeSinceLoad = 0

	return self
end

function LifetimeStats:delete()
end

function LifetimeStats:load()
	if not GS_PLATFORM_PHONE then
		return
	end

	if fileExists(self.xmlFilename) then
		local xmlFile = loadXMLFile("lifetimeStats", self.xmlFilename)
		self.totalRuntimeUpToStart = Utils.getNoNil(getXMLFloat(xmlFile, "lifetimeStats.totalRuntime"), self.totalRuntimeUpToStart)
		self.gameRateMessagesShown = Utils.getNoNil(getXMLInt(xmlFile, "lifetimeStats.gameRateMessagesShown"), self.gameRateMessagesShown)
		self.runtimeSinceLoad = g_time

		delete(xmlFile)
	end
end

function LifetimeStats:save()
	if GS_PLATFORM_ID ~= PlatformId.IOS and GS_PLATFORM_ID ~= PlatformId.ANDROID then
		return
	end

	local xmlFile = createXMLFile("lifetimeStats", self.xmlFilename, "lifetimeStats")

	setXMLFloat(xmlFile, "lifetimeStats.totalRuntime", self:getTotalRuntime())
	setXMLInt(xmlFile, "lifetimeStats.gameRateMessagesShown", self.gameRateMessagesShown)
	saveXMLFile(xmlFile)
	delete(xmlFile)

	self.saveTimer = LifetimeStats.SAVE_PERIOD
end

function LifetimeStats:reload()
	self.totalRuntimeUpToStart = 0
	self.gameRateMessagesShown = 0

	self:load()
end

function LifetimeStats:update(dt)
	self.saveTimer = self.saveTimer - dt

	if self.saveTimer < 0 then
		self.saveTimer = LifetimeStats.SAVE_PERIOD

		self:save()
	end
end

function LifetimeStats:getTotalRuntime()
	return g_time * LifetimeStats.MS_TO_HOUR + self.totalRuntimeUpToStart - self.runtimeSinceLoad
end
