FindDeletedObjectReferences = {
	references = {},
	currentReferences = nil,
	init = function ()
		addConsoleCommand("findDeletedObjectReferences", "", "findReferences", FindDeletedObjectReferences)
	end
}

function FindDeletedObjectReferences.addReference(ref, name)
	if StartParams.getIsSet("findDeletedReferences") then
		local text = tostring(ref) .. " " .. tostring(name) .. " " .. (ref.configFileName or "")
		local refNameFull = tostring(ref) .. tostring(ClassUtil.getClassNameByObject(ref))
		local timeDelay = tonumber(StartParams.getValue("autoCheckReferences")) or 600000

		table.insert(FindDeletedObjectReferences.references, {
			autoDeleteTime = g_time + timeDelay,
			ref = ref,
			refName = tostring(ref),
			refNameFull = refNameFull,
			text = text
		})
	end
end

function FindDeletedObjectReferences.clear()
	FindDeletedObjectReferences.references = {}
end

function FindDeletedObjectReferences.findReferences()
	if FindDeletedObjectReferences.currentReferences ~= nil then
		return "There's already a check running. Please wait..."
	end

	FindDeletedObjectReferences.currentReferences = FindDeletedObjectReferences.references
	FindDeletedObjectReferences.currentRefIndex = 1
	FindDeletedObjectReferences.references = {}

	return "Starting references lookup...(total: " .. #FindDeletedObjectReferences.currentReferences .. ")"
end

function FindDeletedObjectReferences.update(dt)
	if FindDeletedObjectReferences.currentReferences ~= nil then
		local nextRef = FindDeletedObjectReferences.currentReferences[FindDeletedObjectReferences.currentRefIndex]
		FindDeletedObjectReferences.currentRefIndex = FindDeletedObjectReferences.currentRefIndex + 1

		if nextRef ~= nil then
			print(FindDeletedObjectReferences.currentRefIndex .. "/" .. #FindDeletedObjectReferences.currentReferences .. ": Find references for " .. nextRef.text)
			FindDeletedObjectReferences.findReference(nextRef.ref, nil, , _G, {}, {
				_G = true
			}, 1)
		else
			print("Finished references lookup!")

			FindDeletedObjectReferences.currentReferences = nil
		end
	end

	if FindDeletedObjectReferences.currentReferences == nil and StartParams.getIsSet("autoCheckReferences") then
		local firstElem = FindDeletedObjectReferences.references[1]

		if firstElem ~= nil and firstElem.autoDeleteTime < g_time then
			table.remove(FindDeletedObjectReferences.references, 1)
			print("Find references for " .. firstElem.text)
			FindDeletedObjectReferences.findReference(firstElem.ref, nil, , _G, {}, {
				_G = true
			}, 1)
		end
	end
end

function FindDeletedObjectReferences.findReference(ref, parent, key, value, path, checked, depth)
	if type(value) ~= "table" then
		return 1
	end

	if value == FindDeletedObjectReferences then
		return 1
	end

	if checked[value] ~= nil then
		return 1
	end

	if ref ~= value then
		checked[value] = true
	end

	path[depth] = {
		parent = parent,
		key = key,
		value = value
	}

	if value == ref then
		local pathItems = {}

		for k, item in ipairs(path) do
			if item.key ~= nil then
				local currentClassName = ""

				if type(item.parent) == "table" then
					local currentClass = ClassUtil.getClassNameByObject(item.parent)
					currentClassName = currentClass and tostring(currentClass) .. "." or ""
				end

				table.insert(pathItems, currentClassName .. tostring(item.key))
			end
		end

		print("   Ref: " .. table.concat(pathItems, " | "))

		return 1
	end

	local checks = 1

	for k, v in pairs(value) do
		checks = checks + FindDeletedObjectReferences.findReference(ref, value, v, k, path, checked, depth + 1)
		checks = checks + FindDeletedObjectReferences.findReference(ref, value, k, v, path, checked, depth + 1)
	end

	path[depth] = nil

	return checks
end

function FindDeletedObjectReferences.draw()
	if StartParams.getIsSet("findDeletedReferences") then
		renderText(0.8, 0.978, 0.015, string.format("Deleted Objects %d", #FindDeletedObjectReferences.references))
	end
end
