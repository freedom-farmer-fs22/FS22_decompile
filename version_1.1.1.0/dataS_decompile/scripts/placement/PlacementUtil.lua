PlacementUtil = {
	TEST_HEIGHT = 10,
	TEST_STEP_SIZE = 1,
	NETHER_HEIGHT = -100
}

function PlacementUtil.getPlace(places, size, usage, includeDynamics, includeStatics, doExactTest)
	for _, place in pairs(places) do
		if size.width <= place.maxWidth and size.length <= place.maxLength and size.height <= place.maxHeight then
			local placeUsage = usage[place]

			if placeUsage == nil then
				placeUsage = 0
			end

			local halfSizeX = size.width * 0.5

			for width = placeUsage + halfSizeX, place.width - halfSizeX, PlacementUtil.TEST_STEP_SIZE do
				local x = place.startX + width * place.dirX
				local y = place.startY + width * place.dirY
				local z = place.startZ + width * place.dirZ
				local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
				y = math.max(terrainHeight + 0.5, y)
				PlacementUtil.tempHasCollision = false

				overlapBox(x, y, z, place.rotX, place.rotY, place.rotZ, size.width * 0.5, PlacementUtil.TEST_HEIGHT * 0.5, size.length * 0.5, "PlacementUtil.collisionTestCallback", nil, 1577471, includeDynamics, includeStatics, doExactTest)

				if not PlacementUtil.tempHasCollision then
					local vehicleX = x - size.widthOffset * place.dirX - size.lengthOffset * place.dirPerpX
					local vehicleY = y - size.widthOffset * place.dirY - size.lengthOffset * place.dirPerpY
					local vehicleZ = z - size.widthOffset * place.dirZ - size.lengthOffset * place.dirPerpZ
					terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
					y = math.max(terrainHeight + place.yOffset, y)

					return vehicleX, vehicleY, vehicleZ, place, width + halfSizeX, y - terrainHeight
				end
			end
		end
	end

	return nil
end

function PlacementUtil.markPlaceUsed(usage, place, width)
	usage[place] = width
end

function PlacementUtil.unmarkPlaceUsed(usage, place)
	usage[place] = nil
end

function PlacementUtil:collisionTestCallback(transformId)
	if g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil or g_currentMission:getNodeObject(transformId) ~= nil then
		PlacementUtil.tempHasCollision = true

		return false
	end

	return true
end

function PlacementUtil.loadPlaceFromXML(xmlFile, key, rootNode, i3dMappings)
	local startNode = xmlFile:getValue(key .. "#startNode", nil, rootNode, i3dMappings)
	local endNode = xmlFile:getValue(key .. "#endNode", nil, rootNode, i3dMappings)
	local place = PlacementUtil.loadPlaceFromNode(startNode, endNode)

	if place == nil then
		return nil
	end

	place.maxWidth = xmlFile:getValue(key .. "#maxWidth") or place.maxWidth
	place.maxLength = xmlFile:getValue(key .. "#maxLength") or place.maxLength
	place.maxHeight = xmlFile:getValue(key .. "#maxHeight") or place.maxHeight
	place.length = xmlFile:getValue(key .. "#length") or place.length

	return place
end

function PlacementUtil.loadPlaceFromNode(startNode, endNode)
	if startNode == nil then
		return nil
	end

	local place = {}
	place.startX, place.startY, place.startZ = getWorldTranslation(startNode)
	place.width = getUserAttribute(startNode, "width") or 2
	place.length = getUserAttribute(startNode, "length") or 20
	place.yOffset = getUserAttribute(startNode, "yOffset") or 1
	place.maxWidth = getUserAttribute(startNode, "maxWidth") or math.huge
	place.maxLength = getUserAttribute(startNode, "maxLength") or math.huge
	place.maxHeight = getUserAttribute(startNode, "maxHeight") or math.huge
	local numChildren = getNumOfChildren(startNode)

	if endNode == nil then
		if numChildren == 1 then
			endNode = getChildAt(startNode, 0)
		else
			Logging.warning("No end node given and no child node present for place %s", getName(startNode))
		end
	end

	if endNode ~= nil then
		local x, y, z = getWorldTranslation(endNode)
		local dx = x - place.startX
		local dy = y - place.startY
		local dz = z - place.startZ
		place.width = MathUtil.vector3Length(dx, dy, dz)
		local dirX, dirY, dirZ = MathUtil.vector3Normalize(dx, dy, dz)
		local wdirX, wdirY, wdirZ = worldDirectionToLocal(getParent(startNode), dirX, dirY, dirZ)

		setDirection(startNode, wdirX, wdirY, wdirZ, 0, 1, 0)
		rotateAboutLocalAxis(startNode, math.rad(-90), 0, 1, 0)
	end

	if numChildren > 1 then
		Logging.warning("loadPlaceFromNode: Node '%s' has more than one child node. Use 'maxLength' user- or xml-attribute to limit the maximum vehicle length.", getName(startNode))
	end

	place.rotX, place.rotY, place.rotZ = getWorldRotation(startNode)
	place.dirX, place.dirY, place.dirZ = localDirectionToWorld(startNode, 1, 0, 0)
	place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(startNode, 0, 0, 1)

	return place
end

function PlacementUtil.createRestrictedZone(node)
	local restrictedZone = {}
	local _ = nil
	restrictedZone.x, _, restrictedZone.z = getWorldTranslation(node)

	if getNumOfChildren(node) > 0 then
		local x, _, z = getTranslation(getChildAt(node, 0))
		restrictedZone.width = math.abs(x)
		restrictedZone.length = math.abs(z)

		if x < 0 then
			restrictedZone.x = restrictedZone.x + x
		end

		if z < 0 then
			restrictedZone.z = restrictedZone.z + z
		end
	else
		restrictedZone.width = 1
		restrictedZone.length = 1
	end

	return restrictedZone
end

function PlacementUtil.isInsideRestrictedZone(restrictedZones, x, y, z, doWaterCheck)
	for _, restrictedZone in pairs(restrictedZones) do
		local dx = restrictedZone.x + restrictedZone.width - x
		local dz = restrictedZone.z + restrictedZone.length - z

		if dx > 0 and dx < restrictedZone.width and dz > 0 and dz < restrictedZone.length then
			return true
		end
	end

	doWaterCheck = Utils.getNoNil(doWaterCheck, true)

	if doWaterCheck then
		local waterY = g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(x, y, z) or -2000

		if y < waterY - 0.5 then
			return true
		end
	end

	return false
end

function PlacementUtil.isInsidePlacementPlaces(places, x, y, z)
	for _, place in pairs(places) do
		local dx = place.dirX
		local dz = place.dirZ
		local sx = place.startX
		local sz = place.startZ
		local width = place.width
		local t = (x - sx) * dx + (z - sz) * dz
		local distance = nil

		if t >= 0 and t <= width then
			distance = math.abs((sz - z) * dx - (sx - x) * dz)
		elseif t < 0 then
			distance = math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z))
		else
			local ex = place.startX + width * dx
			local ez = place.startZ + width * dz
			distance = math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z))
		end

		if distance <= place.length * 0.5 then
			return true
		end
	end

	return false
end

function PlacementUtil.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#startNode", "Spawn area start node, end node default is first child")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#endNode", "Spawn area end node, end node is first child")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#width", "Spawn area width in m if no child is present for node")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#length", "Spawn area length in m if no child is present for node")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxWidth", "Spawn area maximum width of object to spawn")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxLength", "Spawn area maximum length of object to spawn")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxHeight", "Spawn area maximum height of object to spawn")
end
