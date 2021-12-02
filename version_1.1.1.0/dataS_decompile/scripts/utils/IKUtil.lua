IKUtil = {}

function IKUtil.loadIKChain(xmlFile, key, targetBasenode, chainBasenode, ikTable)
	local ikChain = {
		id = getXMLString(xmlFile, key .. "#id"),
		target = I3DUtil.indexToObject(targetBasenode, getXMLString(xmlFile, key .. "#target"))
	}
	local x, y, z = string.getVector(Utils.getNoNil(getXMLString(xmlFile, key .. "#targetOffset"), "0 0 0"))
	ikChain.targetOffset = {
		x = x,
		y = y,
		z = z
	}
	ikChain.alignToTarget = Utils.getNoNil(getXMLBool(xmlFile, key .. "#alignToTarget"), false)
	ikChain.alignNodeOffset = {
		string.getVector(Utils.getNoNil(getXMLString(xmlFile, key .. "#alignNodeOffset"), "0 0 0"))
	}
	ikChain.nodes = {}
	local j = 0

	while true do
		local nodeKey = key .. string.format(".node(%d)", j)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		local node = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, nodeKey .. "#index"))

		if node ~= nil then
			local minRx = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRx"), -180))
			local maxRx = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRx"), 180))
			local minRy = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRy"), -180))
			local maxRy = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRy"), 180))
			local minRz = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRz"), -180))
			local maxRz = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRz"), 180))
			local damping = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#damping"), 30))
			local localLimits = Utils.getNoNil(getXMLBool(xmlFile, nodeKey .. "#localLimits"), false)

			table.insert(ikChain.nodes, {
				node = node,
				minRx = minRx,
				maxRx = maxRx,
				minRy = minRy,
				maxRy = maxRy,
				minRz = minRz,
				maxRz = maxRz,
				damping = damping,
				localLimits = localLimits
			})
		end

		j = j + 1
	end

	ikChain.rotationNodes = {}

	IKUtil.loadRotationNodes(ikChain.rotationNodes, xmlFile, key, chainBasenode, true)

	ikChain.poses = {}
	j = 0

	while true do
		local poseKey = key .. string.format(".pose(%d)", j)

		if not hasXMLProperty(xmlFile, poseKey) then
			break
		end

		local id = getXMLString(xmlFile, poseKey .. "#id")

		if id ~= nil then
			local pose = {
				id = id,
				isDefaultPose = Utils.getNoNil(getXMLBool(xmlFile, poseKey .. "#isDefaultPose"), false),
				rotationNodes = {}
			}

			IKUtil.loadRotationNodes(pose.rotationNodes, xmlFile, poseKey, chainBasenode, pose.isDefaultPose)

			ikChain.poses[id] = pose
		end

		j = j + 1
	end

	if #ikChain.nodes > 0 and ikChain.target ~= nil and ikChain.id ~= nil and ikTable[ikChain.id] == nil then
		ikChain.numIterations = Utils.getNoNil(getXMLInt(xmlFile, key .. "#numIterations"), 20)
		ikChain.numIterationsToApply = Utils.getNoNil(getXMLInt(xmlFile, key .. "#numIterationsInit"), ikChain.numIterations * 2)
		ikChain.positionThreshold = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#positionThreshold"), 0.005)
		ikChain.isDirty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDirtyOnLoad"), false)
		ikChain.ikChainSolver = IKChain.new(#ikChain.nodes)

		for i, node in ipairs(ikChain.nodes) do
			ikChain.ikChainSolver:setJointTransformGroup(i - 1, node.node, node.minRx, node.maxRx, node.minRy, node.maxRy, node.minRz, node.maxRz, node.damping, node.localLimits)
		end

		ikChain.isActive = true
		ikTable[ikChain.id] = ikChain

		return ikChain
	end

	return nil
end

function IKUtil.loadRotationNodes(rotationNodes, xmlFile, key, chainBasenode, apply)
	local i = 0

	while true do
		local nodeKey = key .. string.format(".rotationNode(%d)", i)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		local node = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, nodeKey .. "#index"))

		if node ~= nil then
			local rot = {
				getRotation(node)
			}
			local rotStr = getXMLString(xmlFile, nodeKey .. "#rotation")

			if rotStr ~= nil then
				rot = string.getRadians(rotStr, 3)

				if apply then
					setRotation(node, unpack(rot))
				end
			end

			table.insert(rotationNodes, {
				node = node,
				defaultRotation = rot
			})
		end

		i = i + 1
	end
end

function IKUtil.setRotationNodes(rotationNodes)
	for _, rotationNode in pairs(rotationNodes) do
		setRotation(rotationNode.node, unpack(rotationNode.defaultRotation))
	end
end

function IKUtil.updateAlignNodes(ikChains, getParentFunc, owner, parentComponent)
	for _, chain in pairs(ikChains) do
		IKUtil.updateAlignNode(chain, getParentFunc, owner, parentComponent)
	end
end

function IKUtil.updateAlignNode(chain, getParentFunc, owner, parentComponent)
	if chain.alignToTarget and chain.isActive then
		chain.alignNode = chain.nodes[#chain.nodes].node

		if getParentFunc == nil and parentComponent == nil then
			printCallstack()
		end

		local node = parentComponent

		if node == nil then
			node = getParentFunc(owner, chain.alignNode)
		end

		chain.alignNodeDir = {
			localDirectionToLocal(chain.alignNode, node, 0, 0, 1)
		}
		chain.alignNodeUp = {
			localDirectionToLocal(chain.alignNode, node, 0, 1, 0)
		}
	end
end

function IKUtil.deleteIKChain(ikTable, id)
	local ikChain = ikTable[id]

	if ikChain ~= nil then
		ikChain.ikChainSolver = nil
	end

	ikTable[id] = nil
end

function IKUtil.setTarget(ikTable, id, target)
	local ikChain = ikTable[id]

	if ikChain ~= nil then
		if target ~= nil then
			if ikChain.defaultTarget == nil then
				ikChain.defaultTarget = ikChain.target
			end

			ikChain.target = target.targetNode

			if target.targetOffset ~= nil then
				ikChain.targetOffset.x = Utils.getNoNil(target.targetOffset[1], ikChain.targetOffset.x)
				ikChain.targetOffset.y = Utils.getNoNil(target.targetOffset[2], ikChain.targetOffset.y)
				ikChain.targetOffset.z = Utils.getNoNil(target.targetOffset[3], ikChain.targetOffset.z)
			end

			if target.rotationNodes ~= nil then
				for _, rotationNode in pairs(target.rotationNodes) do
					local rotNode = ikChain.rotationNodes[rotationNode.id]

					if rotNode ~= nil then
						setRotation(rotNode.node, unpack(rotationNode.rotation))
					end
				end
			end

			if target.poseId ~= nil then
				IKUtil.setIKChainPose(ikTable, id, target.poseId)
			end
		elseif ikChain.defaultTarget ~= nil then
			ikChain.target = ikChain.defaultTarget

			IKUtil.setRotationNodes(ikChain.rotationNodes)
		end
	end
end

function IKUtil.updateIKChains(ikChains)
	for _, ikChain in pairs(ikChains) do
		if ikChain.isDirty and ikChain.isActive then
			ikChain.isDirty = false

			IKUtil.updateIKChain(ikChain, ikChain.numIterationsToApply, ikChain.positionThreshold)

			ikChain.numIterationsToApply = ikChain.numIterations
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		IKUtil.debugDrawChains(ikChains, true)
	end
end

function IKUtil.debugDrawChains(ikChains, drawLimits)
	for _, ikChain in pairs(ikChains) do
		if ikChain.isActive then
			IKUtil.debugDrawChain(ikChain, drawLimits)
		end
	end
end

function IKUtil.debugDrawChain(ikChain, drawLimits)
	if drawLimits == nil then
		drawLimits = true
	end

	ikChain.ikChainSolver:debugDraw(drawLimits)

	local x1, y1, z1 = getWorldTranslation(ikChain.nodes[1].node)
	local x2, y2, z2 = getWorldTranslation(ikChain.target)

	drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0)
end

function IKUtil.updateIKChain(ikChain, numIterations, positionThreshold)
	local x, y, z = localToWorld(ikChain.target, ikChain.targetOffset.x, ikChain.targetOffset.y, ikChain.targetOffset.z)

	ikChain.ikChainSolver:solve(x, y, z, numIterations, positionThreshold)

	if ikChain.alignToTarget and ikChain.isActive then
		local dirX, dirY, dirZ = localDirectionToWorld(ikChain.target, unpack(ikChain.alignNodeDir))
		local upX, upY, upZ = localDirectionToWorld(ikChain.target, unpack(ikChain.alignNodeUp))

		I3DUtil.setWorldDirection(ikChain.alignNode, dirX, dirY, dirZ, upX, upY, upZ)
	end
end

function IKUtil.setIKChainDirty(ikTable, id)
	local ikChain = ikTable[id]

	if ikChain ~= nil then
		ikChain.isDirty = true
	end
end

function IKUtil.setIKChainActive(ikTable, id)
	local ikChain = ikTable[id]

	if ikChain ~= nil then
		ikChain.isActive = true
	end
end

function IKUtil.setIKChainInactive(ikTable, id)
	local ikChain = ikTable[id]

	if ikChain ~= nil then
		ikChain.isActive = false
	end
end

function IKUtil.setIKChainPose(ikTable, chainId, poseId)
	local ikChain = ikTable[chainId]

	if ikChain ~= nil then
		local pose = ikChain.poses[poseId]

		if pose ~= nil then
			IKUtil.setRotationNodes(pose.rotationNodes)
		end
	end
end

function IKUtil.getIKChainByTarget(ikTable, targetNode)
	for _, ikChain in pairs(ikTable) do
		if ikChain.target == targetNode then
			return ikChain
		end
	end
end

function IKUtil.loadIKChainTargets(xmlFile, baseName, rootNode, targets, i3dMappings)
	local i = 0

	while true do
		local key = string.format(baseName .. ".target(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local ikName = xmlFile:getValue(key .. "#ikChain")
		local targetNode = xmlFile:getValue(key .. "#targetNode", nil, rootNode, i3dMappings)

		if targetNode ~= nil then
			if ikName ~= nil then
				local target = {
					ikName = ikName,
					targetNode = targetNode,
					targetOffset = xmlFile:getValue(key .. "#targetOffset", nil, true),
					setDirty = xmlFile:getValue(key .. "#setDirty", true),
					rotationNodes = {}
				}
				local j = 0

				while true do
					local nodeKey = key .. string.format(".rotationNode(%d)", j)

					if not xmlFile:hasProperty(nodeKey) then
						break
					end

					local id = xmlFile:getValue(nodeKey .. "#id")

					if id ~= nil then
						local rotation = xmlFile:getValue(nodeKey .. "#rotation", "0 0 0", true)

						table.insert(target.rotationNodes, {
							id = id,
							rotation = rotation
						})
					end

					j = j + 1
				end

				target.poseId = xmlFile:getValue(key .. "#poseId")
				targets[target.ikName] = target
			else
				Logging.xmlWarning(xmlFile, "Missing ikName for target '%s'", key)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing targetNode in '%s' for chain '%s'", key, ikName)
		end

		i = i + 1
	end
end

function IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".target(?)#ikChain", "IK chain name")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".target(?)#targetNode", "Target node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".target(?)#targetOffset", "Target offset")
	schema:register(XMLValueType.BOOL, basePath .. ".target(?)#setDirty", "Is dirty", true)
	schema:register(XMLValueType.INT, basePath .. ".target(?).rotationNode(?)#id", "Rotation node index")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".target(?).rotationNode(?)#rotation", "Rotation node rotation")
	schema:register(XMLValueType.STRING, basePath .. ".target(?)#poseId", "Pose id")
end

function IKUtil.registerIKChainXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "Chain identifier")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#target", "Target node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#targetOffset", "Target offset", "0 0 0")
	schema:register(XMLValueType.BOOL, basePath .. "#alignToTarget", "Align to target", false)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#alignNodeOffset", "Align node offset", "0 0 0")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#index", "Chain node")
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRx", "Min. rotation X", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRx", "Max. rotation X", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRy", "Min. rotation Y", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRy", "Max. rotation Y", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRy", "Min. rotation Z", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRy", "Max. rotation Z", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#damping", "Damping", 30)
	schema:register(XMLValueType.BOOL, basePath .. ".node(?)#localLimits", "Local limits", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rotationNode(?)#index", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation")
	schema:register(XMLValueType.STRING, basePath .. ".pose(?)#id", "Pose id")
	schema:register(XMLValueType.BOOL, basePath .. ".pose(?)#isDefaultPose", "Is default pose", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pose(?).rotationNode(?)#index", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pose(?).rotationNode(?)#rotation", "Rotation")
	schema:register(XMLValueType.INT, basePath .. "#numIterations", "Max. number of iterations", 20)
	schema:register(XMLValueType.INT, basePath .. "#numIterationsInit", "Initial max. number of iterations", "numIterations * 2")
	schema:register(XMLValueType.FLOAT, basePath .. "#positionThreshold", "Position threshold", 0.005)
	schema:register(XMLValueType.BOOL, basePath .. "#isDirtyOnLoad", "Is dirty on load", false)
end
