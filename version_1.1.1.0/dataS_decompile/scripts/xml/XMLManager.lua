XMLManager = {}
local XMLManager_mt = Class(XMLManager)

function XMLManager.new(customMt)
	local self = setmetatable({}, customMt or XMLManager_mt)
	self.schemas = {}
	self.files = {}
	self.createSchemaFunctions = {}
	self.initSchemaFunctions = {}

	return self
end

function XMLManager:unloadMapData()
	self.schemas = {}
end

function XMLManager:addSchema(schema)
	table.insert(self.schemas, schema)
end

function XMLManager:addFile(file)
	self.files[file.handle] = file
end

function XMLManager:removeFile(file)
	self.files[file.handle] = nil
end

function XMLManager:getFileByHandle(handle)
	return self.files[handle]
end

function XMLManager:addCreateSchemaFunction(func)
	table.insert(self.createSchemaFunctions, func)
end

function XMLManager:createSchemas()
	for _, func in ipairs(self.createSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function ()
			func()
		end)
	end
end

function XMLManager:addInitSchemaFunction(func)
	table.insert(self.initSchemaFunctions, func)
end

function XMLManager:initSchemas()
	for _, func in ipairs(self.initSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function ()
			func()
		end)
	end
end

function XMLManager.consoleCommandGenerateSchemas()
	if g_xmlManager ~= nil then
		for i = 1, #g_xmlManager.schemas do
			local schema = g_xmlManager.schemas[i]

			schema:generateSchema()
			schema:generateHTML()
		end
	end
end

addConsoleCommand("gsXMLGenerateSchemas", "Generates xml schemas", "XMLManager.consoleCommandGenerateSchemas", nil)

g_xmlManager = XMLManager.new()
