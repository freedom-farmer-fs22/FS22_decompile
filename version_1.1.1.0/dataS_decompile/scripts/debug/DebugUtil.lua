DebugUtil = {}

function DebugUtil.drawDebugNode(node, text, alignToGround, offsetY)
	offsetY = offsetY or 0
	local x, y, z = getWorldTranslation(node)
	local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)

	DebugUtil.drawDebugGizmoAtWorldPos(x, y + offsetY, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround)
end

function DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, color)
	local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)

	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.1
	end

	drawDebugLine(x, y, z, 1, 0, 0, x + sideX * 0.3, y + sideY * 0.3, z + sideZ * 0.3, 1, 0, 0)
	drawDebugLine(x, y, z, 0, 1, 0, x + upX * 0.3, y + upY * 0.3, z + upZ * 0.3, 0, 1, 0)
	drawDebugLine(x, y, z, 0, 0, 1, x + dirX * 0.3, y + dirY * 0.3, z + dirZ * 0.3, 0, 0, 1)

	if text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, tostring(text), getCorrectTextSize(0.012), 0, color)
	end
end

function DebugUtil.drawDebugArea(start, width, height, r, g, b, alignToGround, drawNodes, drawCircle, offsetY)
	offsetY = offsetY or 0
	local x, y, z = getWorldTranslation(start)
	local x1, y1, z1 = getWorldTranslation(width)
	local x2, y2, z2 = getWorldTranslation(height)
	y = y + offsetY
	y1 = y1 + offsetY
	y2 = y2 + offsetY

	DebugUtil.drawDebugAreaRectangle(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b)

	if drawNodes == nil or drawNodes then
		DebugUtil.drawDebugNode(start, getName(start), alignToGround, offsetY)
		DebugUtil.drawDebugNode(width, getName(width), alignToGround, offsetY)
		DebugUtil.drawDebugNode(height, getName(height), alignToGround, offsetY)
	end

	local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(start, width, height, 0.5)
	lsy = lsy + offsetY
	ley = ley + offsetY

	if alignToGround then
		lsy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lsx, 0, lsz) + 0.1
		ley = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lex, 0, lez) + 0.1
	end

	if drawCircle == nil or drawCircle then
		drawDebugLine(lsx, lsy, lsz, 1, 1, 1, lex, ley, lez, 1, 1, 1)
		DebugUtil.drawDebugCircle((lsx + lex) * 0.5, (lsy + ley) * 0.5, (lsz + lez) * 0.5, radius, 20, nil)
	end
end

function DebugUtil.drawDebugLine(x1, y1, z1, x2, y2, z2, r, g, b, radius, alignToGround)
	y1 = y1 or 0
	y2 = y2 or 0

	if alignToGround then
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + 0.1
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + 0.1
	end

	drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)

	if radius ~= nil then
		DebugUtil.drawDebugCircle(x1, y1, z1, radius, 20, nil)
		DebugUtil.drawDebugCircle(x2, y2, z2, radius, 20, nil)
	end
end

function DebugUtil.drawDebugAreaRectangle(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b)
	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.1
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + 0.1
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + 0.1
	end

	drawDebugLine(x, y, z, r, g, b, x1, y1, z1, r, g, b)
	drawDebugLine(x, y, z, r, g, b, x2, y2, z2, r, g, b)

	local dirX1 = x1 - x
	local dirY1 = y1 - y
	local dirZ1 = z1 - z
	local dirX2 = x2 - x
	local dirY2 = y2 - y
	local dirZ2 = z2 - z

	drawDebugLine(x2, y2, z2, r, g, b, x2 + dirX1, y2 + dirY1, z2 + dirZ1, r, g, b)
	drawDebugLine(x1, y1, z1, r, g, b, x1 + dirX2, y1 + dirY2, z1 + dirZ2, r, g, b)
end

function DebugUtil.drawDebugAreaRectangleFilled(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b, a)
	local x3 = x1
	local y3 = (y1 + y2) / 2
	local z3 = z2

	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.1
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + 0.1
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + 0.1
		y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3) + 0.1
	end

	drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
	drawDebugTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a, false)
end

function DebugUtil.drawDebugRectangle(node, minX, maxX, minZ, maxZ, yOffset, r, g, b)
	local leftFrontX, leftFrontY, leftFrontZ = localToWorld(node, minX, yOffset, maxZ)
	local rightFrontX, rightFrontY, rightFrontZ = localToWorld(node, maxX, yOffset, maxZ)
	local leftBackX, leftBackY, leftBackZ = localToWorld(node, minX, yOffset, minZ)
	local rightBackX, rightBackY, rightBackZ = localToWorld(node, maxX, yOffset, minZ)

	drawDebugLine(leftFrontX, leftFrontY, leftFrontZ, r, g, b, rightFrontX, rightFrontY, rightFrontZ, r, g, b)
	drawDebugLine(rightFrontX, rightFrontY, rightFrontZ, r, g, b, rightBackX, rightBackY, rightBackZ, r, g, b)
	drawDebugLine(rightBackX, rightBackY, rightBackZ, r, g, b, leftBackX, leftBackY, leftBackZ, r, g, b)
	drawDebugLine(leftBackX, leftBackY, leftBackZ, r, g, b, leftFrontX, leftFrontY, leftFrontZ, r, g, b)
end

function DebugUtil.drawDebugCircle(x, y, z, radius, steps, color)
	for i = 1, steps do
		local a1 = (i - 1) / steps * 2 * math.pi
		local a2 = i / steps * 2 * math.pi
		local c = math.cos(a1) * radius
		local s = math.sin(a1) * radius
		local x1 = x + c
		local y1 = y
		local z1 = z + s
		c = math.cos(a2) * radius
		s = math.sin(a2) * radius
		local x2 = x + c
		local y2 = y
		local z2 = z + s

		if color == nil then
			drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 1, 0, 0)
		else
			drawDebugLine(x1, y1, z1, color[1], color[2], color[3], x2, y2, z2, color[1], color[2], color[3])
		end
	end
end

function DebugUtil.drawDebugCircleAtNode(node, radius, steps, color, vertical, offset)
	local ox = 0
	local oy = 0
	local oz = 0

	if offset ~= nil then
		oz = offset[3]
		oy = offset[2]
		ox = offset[1]
	end

	for i = 1, steps do
		local a1 = (i - 1) / steps * 2 * math.pi
		local a2 = i / steps * 2 * math.pi
		local c = math.cos(a1) * radius
		local s = math.sin(a1) * radius
		local x1, y1, z1 = nil

		if vertical then
			x1, y1, z1 = localToWorld(node, ox + 0, oy + c, oz + s)
		else
			x1, y1, z1 = localToWorld(node, ox + c, oy + 0, oz + s)
		end

		c = math.cos(a2) * radius
		s = math.sin(a2) * radius
		local x2, y2, z2 = nil

		if vertical then
			x2, y2, z2 = localToWorld(node, ox + 0, oy + c, oz + s)
		else
			x2, y2, z2 = localToWorld(node, ox + c, oy + 0, oz + s)
		end

		if color == nil then
			drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 1, 0, 0)
		else
			drawDebugLine(x1, y1, z1, color[1], color[2], color[3], x2, y2, z2, color[1], color[2], color[3])
		end
	end
end

function DebugUtil.drawDebugCubeAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ, r, g, b)
	local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")

	link(getRootNode(), temp)
	setTranslation(temp, x, y, z)
	setDirection(temp, dirX, dirY, dirZ, upX, upY, upZ)
	DebugUtil.drawDebugCube(temp, sizeX, sizeY, sizeZ, r, g, b)
	delete(temp)
end

function DebugUtil.drawOverlapBox(x, y, z, rotX, rotY, rotZ, extendX, extendY, extendZ, r, g, b)
	local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")

	link(getRootNode(), temp)
	setTranslation(temp, x, y, z)
	setRotation(temp, rotX, rotY, rotZ)
	DebugUtil.drawDebugCube(temp, extendX * 2, extendY * 2, extendZ * 2, r, g, b)
	delete(temp)
end

function DebugUtil.drawDebugCube(node, sizeX, sizeY, sizeZ, r, g, b, offsetX, offsetY, offsetZ)
	sizeZ = sizeZ * 0.5
	sizeY = sizeY * 0.5
	sizeX = sizeX * 0.5
	local x, y, z = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
	local up1X, up1Y, up1Z = localDirectionToWorld(node, 1, 0, 0)
	local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
	up1Z = up1Z * sizeX
	up1Y = up1Y * sizeX
	up1X = up1X * sizeX
	upZ = upZ * sizeY
	upY = upY * sizeY
	upX = upX * sizeY
	dirZ = dirZ * sizeZ
	dirY = dirY * sizeZ
	dirX = dirX * sizeZ

	drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)
	drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
	drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
	drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)
	drawDebugLine(x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b, x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b)
	drawDebugLine(x - up1X - dirX + upX, y - up1Y - dirY + upY, z - up1Z - dirZ + upZ, r, g, b, x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b)
	drawDebugLine(x - up1X + dirX + upX, y - up1Y + dirY + upY, z - up1Z + dirZ + upZ, r, g, b, x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b)
	drawDebugLine(x + up1X + dirX + upX, y + up1Y + dirY + upY, z + up1Z + dirZ + upZ, r, g, b, x + up1X - dirX + upX, y + up1Y - dirY + upY, z + up1Z - dirZ + upZ, r, g, b)
	drawDebugLine(x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b, x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b)
	drawDebugLine(x - up1X - dirX - upX, y - up1Y - dirY - upY, z - up1Z - dirZ - upZ, r, g, b, x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b)
	drawDebugLine(x - up1X + dirX - upX, y - up1Y + dirY - upY, z - up1Z + dirZ - upZ, r, g, b, x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b)
	drawDebugLine(x + up1X + dirX - upX, y + up1Y + dirY - upY, z + up1Z + dirZ - upZ, r, g, b, x + up1X - dirX - upX, y + up1Y - dirY - upY, z + up1Z - dirZ - upZ, r, g, b)
end

function DebugUtil.drawSimpleDebugCube(x, y, z, width, r, g, b)
	local halfWidth = width * 0.5

	drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z - halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z - halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y - halfWidth, z - halfWidth, r, g, b, x - halfWidth, y - halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x + halfWidth, y + halfWidth, z + halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y - halfWidth, z + halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x - halfWidth, y + halfWidth, z + halfWidth, r, g, b)
	drawDebugLine(x - halfWidth, y + halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
	drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y + halfWidth, z - halfWidth, r, g, b)
	drawDebugLine(x + halfWidth, y - halfWidth, z - halfWidth, r, g, b, x + halfWidth, y - halfWidth, z + halfWidth, r, g, b)
	drawDebugPoint(x, y, z, r, g, b, 1)
end

function DebugUtil.drawDebugReferenceAxisFromNode(node)
	if node ~= nil then
		local x, y, z = getWorldTranslation(node)
		local yx, yy, yz = localDirectionToWorld(node, 0, 1, 0)
		local zx, zy, zz = localDirectionToWorld(node, 0, 0, 1)

		DebugUtil.drawDebugReferenceAxis(x, y, z, yx, yy, yz, zx, zy, zz)
	end
end

function DebugUtil.drawDebugReferenceAxis(posX, posY, posZ, upX, upY, upZ, dirX, dirY, dirZ)
	local sideX, sideY, sideZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	local length = 0.2

	drawDebugLine(posX - sideX * length, posY - sideY * length, posZ - sideZ * length, 1, 1, 1, posX + sideX * length, posY + sideY * length, posZ + sideZ * length, 1, 0, 0)
	drawDebugLine(posX - upX * length, posY - upY * length, posZ - upZ * length, 1, 1, 1, posX + upX * length, posY + upY * length, posZ + upZ * length, 0, 1, 0)
	drawDebugLine(posX - dirX * length, posY - dirY * length, posZ - dirZ * length, 1, 1, 1, posX + dirX * length, posY + dirY * length, posZ + dirZ * length, 0, 0, 1)
end

function DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, heightOffset, r, g, b, a, fixedHeight)
	local x0 = x
	local z0 = z
	local y0 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x0, 0, z0) + heightOffset
	local x1 = x0 + widthX
	local z1 = z0 + widthZ
	local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + heightOffset
	local x2 = x0 + heightX
	local z2 = z0 + heightZ
	local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + heightOffset
	local x3 = x0 + widthX + heightX
	local z3 = z0 + widthZ + heightZ
	local y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3) + heightOffset

	if fixedHeight then
		y3 = heightOffset
		y2 = heightOffset
		y1 = heightOffset
		y0 = heightOffset
	end

	drawDebugTriangle(x0, y0, z0, x1, y1, z1, x2, y2, z2, r, g, b, a, false)
	drawDebugTriangle(x1, y1, z1, x3, y3, z3, x2, y2, z2, r, g, b, a, false)
	drawDebugTriangle(x0, y0, z0, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
	drawDebugTriangle(x2, y2, z2, x3, y3, z3, x1, y1, z1, r, g, b, a, false)
	drawDebugLine(x0, y0, z0, r, g, b, x1, y1, z1, r, g, b)
	drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b)
	drawDebugLine(x2, y2, z2, r, g, b, x0, y0, z0, r, g, b)
	drawDebugLine(x1, y1, z1, r, g, b, x3, y3, z3, r, g, b)
	drawDebugLine(x3, y3, z3, r, g, b, x2, y2, z2, r, g, b)
end

function DebugUtil.drawArea(area, r, g, b, a)
	local x0, _, z0 = getWorldTranslation(area.start)
	local x1, _, z1 = getWorldTranslation(area.width)
	local x2, _, z2 = getWorldTranslation(area.height)
	local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)

	DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, r, g, b, a)
end

function DebugUtil.printTableRecursively(inputTable, inputIndent, depth, maxDepth)
	inputIndent = inputIndent or "  "
	depth = depth or 0
	maxDepth = maxDepth or 3

	if depth > maxDepth then
		return
	end

	local debugString = ""

	for i, j in pairs(inputTable) do
		print(inputIndent .. tostring(i) .. " :: " .. tostring(j))

		if type(j) == "table" then
			DebugUtil.printTableRecursively(j, inputIndent .. "    ", depth + 1, maxDepth)
		end
	end

	return debugString
end

function DebugUtil.debugTableToString(inputTable, inputIndent, depth, maxDepth)
	inputIndent = inputIndent or "  "
	depth = depth or 0
	maxDepth = maxDepth or 2

	if depth > maxDepth then
		return nil
	end

	local string1 = ""

	for i, j in pairs(inputTable) do
		string1 = string1 .. string.format("\n%s %s :: %s", inputIndent, tostring(i), tostring(j))

		if type(j) == "table" then
			local string2 = DebugUtil.debugTableToString(j, inputIndent .. "    ", depth + 1, maxDepth)

			if string2 ~= nil then
				string1 = string1 .. string2
			end
		end
	end

	return string1
end

function DebugUtil.renderTable(posX, posY, textSize, data, nextColumnOffset)
	local i = 0

	setTextColor(1, 1, 1, 1)
	setTextBold(false)

	textSize = getCorrectTextSize(textSize)

	for _, valuePair in ipairs(data) do
		if valuePair.name ~= "" then
			local offset = i * textSize * 1.05

			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(posX, posY - offset, textSize, tostring(valuePair.name) .. ":")
			setTextAlignment(RenderText.ALIGN_LEFT)

			if type(valuePair.value) == "number" then
				renderText(posX, posY - offset, textSize, " " .. string.format("%.4f", valuePair.value))
			else
				renderText(posX, posY - offset, textSize, " " .. tostring(valuePair.value))
			end
		end

		i = i + 1

		if valuePair.newColumn or valuePair.columnOffset then
			i = 0
			posX = posX + (valuePair.columnOffset or nextColumnOffset)
		end
	end
end

function DebugUtil.printNodeHierarchy(node, offset)
	offset = offset or ""

	log(offset .. getName(node))

	for i = 0, getNumOfChildren(node) - 1 do
		DebugUtil.printNodeHierarchy(getChildAt(node, i), offset .. " ")
	end
end

function DebugUtil.printCallingFunctionLocation()
	local stackLevel = 3
	local location = debug.getinfo(stackLevel, "Sl")
	local callerScript = location.source
	local callerLine = location.currentline

	print(string.format("%s, line %d", tostring(callerScript), callerLine))
end

function DebugUtil.tableToColor(tbl, alpha)
	alpha = alpha or 1
	local tableIdHex = tostring(tbl):sub(10)
	local color = {
		tonumber(tableIdHex:sub(-2), 16) / 255,
		tonumber(tableIdHex:sub(-4, -3), 16) / 255,
		tonumber(tableIdHex:sub(-6, -5), 16) / 255,
		alpha
	}

	return color
end
