ConstructionBrushTypeManager = {}
local ConstructionBrushTypeManager_mt = Class(ConstructionBrushTypeManager, AbstractManager)

function ConstructionBrushTypeManager.new(customMt)
	local self = ConstructionBrushTypeManager:superClass().new(customMt or ConstructionBrushTypeManager_mt)

	return self
end

function ConstructionBrushTypeManager:initDataStructures()
	self.brushTypes = {}
	self.brushTypesSorted = {}
end

function ConstructionBrushTypeManager:loadMapData()
	ConstructionBrushTypeManager:superClass().loadMapData(self)

	local xmlFile = XMLFile.load("BrushTypesXML", "dataS/constructionBrushTypes.xml")

	xmlFile:iterate("constructionBrushTypes.constructionBrushType", function (index, key)
		local typeName = xmlFile:getString(key .. "#name")

		if typeName == nil then
			return
		end

		local className = xmlFile:getString(key .. "#className")
		local filename = xmlFile:getString(key .. "#filename")

		self:addBrushType(typeName, className, filename, "")
	end)
	xmlFile:delete()
	Logging.info("  Loaded construction brush types")

	return true
end

function ConstructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
	if not ClassUtil.getIsValidClassName(typeName) then
		print("Warning: Invalid construction brush typeName: " .. tostring(typeName) .. ". Ignoring type!")

		return false
	elseif self.brushTypes[typeName] ~= nil then
		print("Error: Construction brush type '" .. tostring(typeName) .. "' already exists. Ignoring it!")

		return false
	elseif className == nil then
		print("Error: No className specified for construction brush type '" .. tostring(typeName) .. "'. Ignoring it!")

		return false
	elseif filename == nil then
		print("Error: No filename specified for construction brush type '" .. tostring(typeName) .. "'. Ignoring it!")

		return false
	else
		source(filename, customEnvironment)

		local typeEntry = {
			name = typeName,
			className = className,
			filename = filename
		}

		if customEnvironment ~= "" then
			print("  Register construction brush type: " .. tostring(typeName))
		end

		self.brushTypes[typeName] = typeEntry

		table.insert(self.brushTypesSorted, typeEntry)
	end

	return true
end

function ConstructionBrushTypeManager:getClassObjectByTypeName(typeName)
	if typeName ~= nil then
		local brushTypes = self.brushTypes[typeName]

		if brushTypes ~= nil then
			return ClassUtil.getClassObject(brushTypes.className)
		end
	end

	return nil
end

function ConstructionBrushTypeManager:initBrushTypes()
	for _, typeEntry in pairs(self.brushTypesSorted) do
		local classObj = ClassUtil.getClassObject(typeEntry.className)

		if rawget(classObj, "initBrushType") then
			classObj.initBrushType()
		end
	end
end

g_constructionBrushTypeManager = ConstructionBrushTypeManager.new()
