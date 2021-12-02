SpecializationUtil = {
	raiseEvent = function (object, eventName, ...)
		assert(object.eventListeners[eventName] ~= nil, "Error: Event '" .. tostring(eventName) .. "' is not registered for type '" .. tostring(object.type.name) .. "'!")

		for _, spec in ipairs(object.eventListeners[eventName]) do
			spec[eventName](object, ...)
		end
	end,
	registerEvent = function (objectType, eventName)
		if objectType.functions[eventName] ~= nil or objectType.events[eventName] ~= nil or eventName == nil or eventName == "" then
			printCallstack()
		end

		assert(objectType.functions[eventName] == nil, "Error: Event '" .. tostring(eventName) .. "' already registered as function in type '" .. tostring(objectType.name) .. "'!")
		assert(objectType.events[eventName] == nil, "Error: Event '" .. tostring(eventName) .. "' already registered as event in type '" .. tostring(objectType.name) .. "'!")
		assert(eventName ~= nil and eventName ~= "", "Error: Event '" .. tostring(eventName) .. "' is 'nil' or empty!")

		objectType.events[eventName] = eventName
		objectType.eventListeners[eventName] = {}
	end,
	registerFunction = function (objectType, funcName, func)
		if objectType.functions[funcName] ~= nil or objectType.events[funcName] ~= nil or func == nil then
			printCallstack()
		end

		assert(objectType.functions[funcName] == nil, "Error: Function '" .. tostring(funcName) .. "' already registered as function in type '" .. tostring(objectType.name) .. "'!")
		assert(objectType.events[funcName] == nil, "Error: Function '" .. tostring(funcName) .. "' already registered as event in type '" .. tostring(objectType.name) .. "'!")
		assert(func ~= nil, "Error: Given reference for Function '" .. tostring(funcName) .. "' is 'nil'!")

		objectType.functions[funcName] = func
	end,
	registerOverwrittenFunction = function (objectType, funcName, func)
		assert(func ~= nil, "Error: Given reference for OverwrittenFunction '" .. tostring(funcName) .. "' is 'nil'!")

		if objectType.functions[funcName] ~= nil then
			objectType.functions[funcName] = Utils.overwrittenFunction(objectType.functions[funcName], func)
		end
	end,
	registerEventListener = function (objectType, eventName, spec)
		local className = ClassUtil.getClassName(spec)

		assert(objectType.eventListeners ~= nil, "Error: Invalid type for specialization '" .. tostring(className) .. "'!")

		if objectType.eventListeners[eventName] == nil then
			return
		end

		assert(spec[eventName] ~= nil, "Error: Event listener function '" .. tostring(eventName) .. "' not defined in specialization '" .. tostring(className) .. "'!")

		local found = false

		for _, registeredSpec in pairs(objectType.eventListeners[eventName]) do
			if registeredSpec == spec then
				found = true

				break
			end
		end

		assert(not found, "Error: Eventlistener for '" .. eventName .. "' already registered in specialization '" .. tostring(className) .. "'!")
		table.insert(objectType.eventListeners[eventName], spec)
	end,
	removeEventListener = function (object, eventName, specClass)
		local listeners = object.eventListeners[eventName]

		if listeners ~= nil then
			for i = #listeners, 1, -1 do
				if ClassUtil.getClassName(listeners[i]) == ClassUtil.getClassName(specClass) then
					table.remove(listeners, i)
				end
			end
		end
	end,
	hasSpecialization = function (spec, specializations)
		for _, v in pairs(specializations) do
			if v == spec then
				return true
			end
		end

		return false
	end
}
