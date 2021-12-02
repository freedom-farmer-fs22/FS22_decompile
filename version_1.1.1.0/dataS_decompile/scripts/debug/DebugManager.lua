DebugManager = {}
local DebugManager_mt = Class(DebugManager, AbstractManager)

function DebugManager.new(customMt)
	local self = AbstractManager.new(customMt or DebugManager_mt)

	return self
end

function DebugManager:initDataStructures()
	self.permanentElements = {}
	self.permanentFunctions = {}
	self.frameElements = {}

	if not self.initialized then
		addConsoleCommand("gsDebugManagerClearElements", "Removes all permanent elements and functions from DebugManager", "consoleCommandRemovePermanentElements", self)

		self.initialized = true
	end
end

function DebugManager:unloadMapData()
	self.loadedMapData = false

	self:initDataStructures()
end

function DebugManager:update(dt)
	for _, element in ipairs(self.permanentElements) do
		element:update(dt)
	end
end

function DebugManager:draw()
	for _, element in ipairs(self.permanentElements) do
		element:draw()
	end

	for _, element in ipairs(self.permanentFunctions) do
		element[1](unpack(element[2]))
	end

	for i = #self.frameElements, 1, -1 do
		self.frameElements[i]:draw()
		table.remove(self.frameElements, i)
	end
end

function DebugManager:addPermanentElement(element)
	table.addElement(self.permanentElements, element)
end

function DebugManager:removePermanentElement(element)
	table.removeElement(self.permanentElements, element)
end

function DebugManager:addFrameElement(element)
	table.addElement(self.frameElements, element)
end

function DebugManager:addPermanentFunction(funcAndParams)
	table.addElement(self.permanentFunctions, funcAndParams)
end

function DebugManager:removePermanentFunction(funcAndParams)
	table.removeElement(self.permanentFunctions, funcAndParams)
end

function DebugManager:consoleCommandRemovePermanentElements()
	self.permanentElements = {}
	self.permanentFunctions = {}

	return "Cleared all permanent debug elements"
end

g_debugManager = DebugManager.new()
