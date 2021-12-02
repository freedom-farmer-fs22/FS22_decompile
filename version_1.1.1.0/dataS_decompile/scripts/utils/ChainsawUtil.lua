ChainsawUtil = {}

function ChainsawUtil.cutSplitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
	local splitTypeName = ""
	local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(shape))

	if splitType ~= nil then
		splitTypeName = splitType.name
	end

	local farm = g_farmManager:getFarmById(farmId)

	if math.abs(ny) < 0.866 then
		ChainsawUtil.curSplitShapes = {}

		g_currentMission:removeKnownSplitShape(shape)

		ChainsawUtil.shapeBeingCut = shape
		ChainsawUtil.fromTree = getRigidBodyType(shape) == RigidBodyType.STATIC

		splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
		g_treePlantManager:removingSplitShape(shape)

		if table.getn(ChainsawUtil.curSplitShapes) == 2 then
			local split0 = ChainsawUtil.curSplitShapes[1]
			local split1 = ChainsawUtil.curSplitShapes[2]
			local type0 = getRigidBodyType(split0.shape)
			local type1 = getRigidBodyType(split1.shape)
			local dynamicSplit = nil
			local isTree = false

			if type0 == RigidBodyType.STATIC and type1 == RigidBodyType.DYNAMIC then
				dynamicSplit = split1
				isTree = true
			elseif type1 == RigidBodyType.STATIC and type0 == RigidBodyType.DYNAMIC then
				dynamicSplit = split0
				isTree = true
			end

			if isTree then
				if farm ~= nil then
					local cutTreeCount = farm.stats:updateStats("cutTreeCount", 1)

					g_achievementManager:tryUnlock("CutTreeFirst", cutTreeCount)
					g_achievementManager:tryUnlock("CutTree", cutTreeCount)

					if splitTypeName ~= "" then
						farm.stats:updateTreeTypesCut(splitTypeName)
					end
				end

				local treeCuttingsample = g_currentMission.cuttingSounds.tree
				local sizeX, sizeY, sizeZ, _, _ = getSplitShapeStats(dynamicSplit.shape)
				local bvVolume = 0

				if sizeX ~= nil then
					bvVolume = sizeX * sizeY * sizeZ
				end

				if treeCuttingsample ~= nil and bvVolume > 1 then
					g_soundManager:playSample(treeCuttingsample)
					setTranslation(treeCuttingsample.soundNode, x, y, z)
				end
			end
		end
	else
		ChainsawUtil.curSplitShapes = {}

		g_currentMission:removeKnownSplitShape(shape)

		ChainsawUtil.shapeBeingCut = shape
		ChainsawUtil.fromTree = getRigidBodyType(shape) == RigidBodyType.STATIC

		splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
		g_treePlantManager:removingSplitShape(shape)

		if table.getn(ChainsawUtil.curSplitShapes) == 2 then
			local split0 = ChainsawUtil.curSplitShapes[1]
			local split1 = ChainsawUtil.curSplitShapes[2]
			local type0 = getRigidBodyType(split0.shape)
			local type1 = getRigidBodyType(split1.shape)
			local dynamicSplit, staticSplit = nil
			local isTree = false

			if type0 == RigidBodyType.STATIC and type1 == RigidBodyType.DYNAMIC then
				staticSplit = split0
				dynamicSplit = split1
				isTree = true
			elseif type1 == RigidBodyType.STATIC and type0 == RigidBodyType.DYNAMIC then
				staticSplit = split1
				dynamicSplit = split0
				isTree = true
			end

			if isTree then
				local treeCuttingsample = g_currentMission.cuttingSounds.tree
				local sizeX, sizeY, sizeZ, _, _ = getSplitShapeStats(dynamicSplit.shape)
				local bvVolume = 0

				if sizeX ~= nil then
					bvVolume = sizeX * sizeY * sizeZ
				end

				if treeCuttingsample ~= nil and bvVolume > 1 then
					g_soundManager:playSample(treeCuttingsample)
					setTranslation(treeCuttingsample.soundNode, x, y, z)
				end
			end

			if dynamicSplit ~= nil then
				local distY = dynamicSplit.minY + (dynamicSplit.maxY - dynamicSplit.minY) * 0.75
				local distZ = (dynamicSplit.minZ + dynamicSplit.maxZ) * 0.5
				local zx, zy, zz = MathUtil.crossProduct(nx, ny, nz, yx, yy, yz)
				local angle = math.rad(40)
				local scale0 = math.sin(1.5707 - angle)
				local scale1 = math.sin(angle)

				if dynamicSplit.isBelow then
					scale1 = -scale1
				end

				local nx2 = nx * scale0 + yx * scale1
				local ny2 = ny * scale0 + yy * scale1
				local nz2 = nz * scale0 + yz * scale1
				local yx2, yy2, yz2 = MathUtil.crossProduct(zx, zy, zz, nx2, ny2, nz2)
				local cx = x + yx * distY - yx2 * cutSizeY * 0.1
				local cy = y + yy * distY - yy2 * cutSizeY * 0.1
				local cz = z + yz * distY - yz2 * cutSizeY * 0.1

				g_currentMission:removeKnownSplitShape(staticSplit.shape)

				ChainsawUtil.shapeBeingCut = staticSplit.shape

				splitShape(staticSplit.shape, cx, cy, cz, nx2, ny2, nz2, yx2, yy2, yz2, cutSizeY * 1.1, cutSizeZ, "ChainsawUtil.cutSplitShapeCallbackCutJoint", nil)
				g_treePlantManager:removingSplitShape(staticSplit.shape)

				local jx = x + yx * distY + zx * distZ
				local jy = y + yy * distY + zy * distZ
				local jz = z + yz * distY + zz * distZ
				local constr = JointConstructor.new()

				constr:setActors(0, dynamicSplit.shape)
				constr:setJointWorldAxes(nx, ny, nz, nx, ny, nz)
				constr:setJointWorldNormals(yx, yy, yz, yx, yy, yz)
				constr:setJointWorldPositions(jx, jy, jz, jx, jy, jz)
				constr:setRotationLimit(0, 0, 0)
				constr:setTranslationLimit(0, false, 0, 0)
				constr:setEnableCollision(true)

				local jointIndex = constr:finalize()
				local ax, ay, az = MathUtil.crossProduct(0, 0.8, 0, yx, yy, yz)

				setAngularVelocity(dynamicSplit.shape, ax, ay, az)
				g_treePlantManager:addTreeCutJoint(jointIndex, dynamicSplit.shape, nx, ny, nz, math.rad(45), 2000)

				if farm ~= nil then
					local cutTreeCount = farm.stats:updateStats("cutTreeCount", 1)

					g_achievementManager:tryUnlock("CutTreeFirst", cutTreeCount)
					g_achievementManager:tryUnlock("CutTree", cutTreeCount)

					if splitTypeName ~= "" then
						farm.stats:updateTreeTypesCut(splitTypeName)
					end
				end
			end
		end
	end
end

function ChainsawUtil.cutSplitShapeCallback(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, ChainsawUtil.fromTree)
	table.insert(ChainsawUtil.curSplitShapes, {
		shape = shape,
		isBelow = isBelow,
		isAbove = isAbove,
		minY = minY,
		maxY = maxY,
		minZ = minZ,
		maxZ = maxZ
	})
end

function ChainsawUtil.cutSplitShapeCallbackCutJoint(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, true)
end
