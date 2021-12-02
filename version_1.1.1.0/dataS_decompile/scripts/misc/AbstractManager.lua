AbstractManager = {}
local AbstractManager_mt = Class(AbstractManager)

function AbstractManager.new(customMt)
	if customMt ~= nil and type(customMt) ~= "table" then
		printCallstack()
	end

	local self = setmetatable({}, customMt or AbstractManager_mt)

	self:initDataStructures()

	self.loadedMapData = false

	return self
end

function AbstractManager:initDataStructures()
end

function AbstractManager:load()
	return true
end

function AbstractManager:loadMapData()
	if g_isDevelopmentVersion and self.loadedMapData then
		Logging.error("Manager map-data already loaded or not deleted after last game load!")
		printCallstack()
	end

	self.loadedMapData = true

	return true
end

function AbstractManager:unloadMapData()
	self.loadedMapData = false

	self:initDataStructures()
end
