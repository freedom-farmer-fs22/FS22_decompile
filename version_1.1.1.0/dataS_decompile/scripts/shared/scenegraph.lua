function translate(name, dx, dy, dz)
	local x, y, z = getTranslation(name)

	setTranslation(name, x + dx, y + dy, z + dz)
end

function rotate(name, dx, dy, dz)
	local x, y, z = getRotation(name)

	setRotation(name, (x + dx) % (2 * math.pi), (y + dy) % (2 * math.pi), (z + dz) % (2 * math.pi))
end

function toggleVisibility(name)
	local state = getVisibility(name)

	setVisibility(name, not state)
end

function printScenegraph(node, visibleOnly)
	printScenegraphRec(node, 0, visibleOnly)
end

function printScenegraphRec(node, level, visibleOnly)
	local ident = ""

	for i = 1, level do
		ident = ident .. "    "
	end

	if visibleOnly == nil or not visibleOnly or visibleOnly and getVisibility(node) then
		print(string.format("%s%s(%d) | %s", ident, getName(node), node, tostring(getVisibility(node))))

		local num = getNumOfChildren(node)

		for i = 0, num - 1 do
			printScenegraphRec(getChildAt(node, i), level + 1)
		end
	end
end

function exportScenegraphToGraphviz(node, filename)
	if node ~= nil and node ~= 0 then
		if filename == nil then
			filename = string.format("%s_output.gv", getName(node))
		end

		local fileId = createFile(filename, FileAccess.WRITE)
		local result = "// LSIM2019 Scenegraph export for Graphviz\n"
		result = string.format("%s// Start Node is '%s_(%d)'\n", result, getName(node), node)
		result = string.format("%sdigraph G {\n", result)
		result = string.format("%s%s_%d  [shape=box,color=red,style=filled]\n", result, getName(node), node)
		result = exportScenegraphToGraphvizRec(node, result)
		result = string.format("%s\n}", result)

		fileWrite(fileId, result)
		delete(fileId)
	end
end

function exportScenegraphToGraphvizRec(node, result)
	local num = getNumOfChildren(node)

	for i = 0, num - 1 do
		local child = getChildAt(node, i)
		result = string.format("%s %s_%d -> %s_%d\n", result, string.gsub(getName(node), "[%(%)]", "_"), node, string.gsub(getName(child), "[%(%)]", "_"), child)
		result = exportScenegraphToGraphvizRec(getChildAt(node, i), result)
	end

	return result
end
