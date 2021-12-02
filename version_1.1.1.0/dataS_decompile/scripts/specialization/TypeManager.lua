TypeManager = {}
local TypeManager_mt = Class(TypeManager)

function TypeManager.new(typeName, rootElementName, xmlFilename, specializationManager, customMt)
	local self = setmetatable({}, customMt or TypeManager_mt)
	self.types = {}
	self.typeName = typeName
	self.rootElementName = rootElementName
	self.xmlFilename = xmlFilename
	self.specializationManager = specializationManager

	return self
end

function TypeManager:loadMapData()
	local xmlFile = loadXMLFile("typesXML", self.xmlFilename)
	local i = 0

	while true do
		local key = string.format("%s.type(%d)", self.rootElementName, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		g_asyncTaskManager:addSubtask(function ()
			self:loadTypeFromXML(xmlFile, key, nil, , )
		end)

		i = i + 1
	end

	g_asyncTaskManager:addSubtask(function ()
		delete(xmlFile)
	end)
	g_asyncTaskManager:addSubtask(function ()
		print("  Loaded " .. self.typeName .. " types")
	end)

	return true
end

function TypeManager:unloadMapData()
	self.types = {}
end

function TypeManager:addType(typeName, className, filename, customEnvironment, parent)
	if self.types[typeName] ~= nil then
		Logging.error("Multiple specifications of %s type '%s'", self.typeName, typeName)

		return false
	elseif className == nil then
		Logging.error("No className specified for %s type '%s'", self.typeName, typeName)

		return false
	elseif filename == nil then
		Logging.error("No filename specified for %s type '%s'", self.typeName, typeName)

		return false
	else
		customEnvironment = customEnvironment or ""

		source(filename, customEnvironment)

		local typeEntry = {
			name = typeName,
			className = className,
			filename = filename,
			specializations = {},
			specializationNames = {},
			specializationsByName = {},
			functions = {},
			events = {},
			eventListeners = {},
			customEnvironment = customEnvironment,
			parent = parent
		}
		self.types[typeName] = typeEntry
	end

	return true
end

function TypeManager:loadTypeFromXML(xmlFile, key, isDLC, modDir, modName)
	local typeName = getXMLString(xmlFile, key .. "#name")
	local parentName = getXMLString(xmlFile, key .. "#parent")

	if typeName == nil and parentName == nil then
		Logging.error("Missing name or parent for placeableType '%s'", key)

		return false
	end

	local parent = nil

	if parentName ~= nil then
		parent = self.types[parentName]

		if parent == nil then
			Logging.error("Parent %s type '%s' is not defined!", self.typeName, parentName)

			return false
		end
	end

	local className = getXMLString(xmlFile, key .. "#className")
	local filename = getXMLString(xmlFile, key .. "#filename")

	if parent ~= nil then
		className = className or parent.className
		filename = filename or parent.filename
	end

	if modName ~= nil and modName ~= "" then
		typeName = modName .. "." .. typeName
	end

	if className ~= nil and filename ~= nil then
		local customEnvironment = nil

		if modDir ~= nil then
			local useModDirectory = nil
			filename, useModDirectory = Utils.getFilename(filename, modDir)

			if useModDirectory then
				customEnvironment = modName
				className = modName .. "." .. className
			end
		end

		if Platform.allowsScriptMods or isDLC or customEnvironment == nil then
			self:addType(typeName, className, filename, customEnvironment, parent)

			if parent ~= nil then
				for _, specName in ipairs(parent.specializationNames) do
					self:addSpecialization(typeName, specName)
				end
			end

			local j = 0

			while true do
				local specKey = string.format("%s.specialization(%d)", key, j)

				if not hasXMLProperty(xmlFile, specKey) then
					break
				end

				local specName = getXMLString(xmlFile, specKey .. "#name")
				local entry = self.specializationManager:getSpecializationByName(specName)

				if entry == nil then
					if modName ~= nil then
						specName = modName .. "." .. specName
					end

					entry = self.specializationManager:getSpecializationByName(specName)

					if entry == nil then
						Logging.error("Could not find specialization '%s' for %s type '%s'.", specName, self.typeName, typeName)

						specName = nil
					end
				end

				if specName ~= nil then
					self:addSpecialization(typeName, specName)
				end

				j = j + 1
			end

			return true
		else
			Logging.error("Can't register %s type '%s' with scripts on consoles.", self.typeName, typeName)
		end
	end

	return false
end

function TypeManager:addSpecialization(typeName, specName)
	local typeEntry = self.types[typeName]

	if typeEntry ~= nil then
		if typeEntry.specializationsByName[specName] == nil then
			local spec = self.specializationManager:getSpecializationObjectByName(specName)

			if spec == nil then
				Logging.error("%s type '%s' has unknown specialization '%s!", self.typeName, tostring(typeName), tostring(specName))

				return false
			end

			table.insert(typeEntry.specializations, spec)
			table.insert(typeEntry.specializationNames, specName)

			typeEntry.specializationsByName[specName] = spec
		else
			Logging.error("Specialization '%s' already exists for %s type '%s'!", specName, typeName, self.typeName)
		end
	else
		Logging.error("%s type '%s' is not defined!", self.typeName, typeName)
	end
end

function TypeManager:validateTypes()
	for typeName, typeEntry in pairs(self.types) do
		g_asyncTaskManager:addSubtask(function ()
			for _, specName in ipairs(typeEntry.specializationNames) do
				local spec = typeEntry.specializationsByName[specName]

				if not spec.prerequisitesPresent(typeEntry.specializations) then
					Logging.error("Not all prerequisites of specialization '%s' in %s type '%s' are fulfilled", specName, self.typeName, typeName)
					self:removeType(typeName)
				end
			end
		end)
	end
end

function TypeManager:finalizeTypes()
	for typeName, typeEntry in pairs(self.types) do
		g_asyncTaskManager:addSubtask(function ()
			local classObject = ClassUtil.getClassObject(typeEntry.className)

			if classObject.registerEvents ~= nil then
				classObject.registerEvents(typeEntry)
			end

			if classObject.registerFunctions ~= nil then
				classObject.registerFunctions(typeEntry)
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEvents ~= nil then
					specialization.registerEvents(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerFunctions ~= nil then
					specialization.registerFunctions(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerOverwrittenFunctions ~= nil then
					specialization.registerOverwrittenFunctions(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEventListeners ~= nil then
					specialization.registerEventListeners(typeEntry)
				end
			end

			if typeEntry.customEnvironment ~= "" then
				print(string.format("  Register %s type: %s", self.typeName, typeName))
			end
		end)
	end

	return true
end

function TypeManager:getTypes()
	return self.types
end

function TypeManager:removeType(typeName)
	self.types[typeName] = nil
end

function TypeManager:getTypeByName(typeName)
	if typeName ~= nil then
		return self.types[typeName]
	end
end

g_vehicleTypeManager = TypeManager.new("vehicle", "vehicleTypes", "dataS/vehicleTypes.xml", g_specializationManager)
g_placeableTypeManager = TypeManager.new("placeable", "placeableTypes", "dataS/placeableTypes.xml", g_placeableSpecializationManager)
