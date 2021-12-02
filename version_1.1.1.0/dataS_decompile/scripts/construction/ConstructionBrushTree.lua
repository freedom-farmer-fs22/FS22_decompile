ConstructionBrushTree = {}
local ConstructionBrushTree_mt = Class(ConstructionBrushTree, ConstructionBrush)
ConstructionBrushTree.ERROR = {
	TOO_MANY_TREES = 201,
	NOT_ENOUGH_MONEY = 200
}
ConstructionBrushTree.ERROR_MESSAGES = {
	[ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney",
	[ConstructionBrushTree.ERROR.TOO_MANY_TREES] = "ui_construction_tooManyTrees"
}

function ConstructionBrushTree.new(subclass_mt, cursor)
	local self = ConstructionBrushTree:superClass().new(subclass_mt or ConstructionBrushTree_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsTertiaryButton = true
	self.requiredPermission = Farm.PERMISSION.LANDSCAPING

	return self
end

function ConstructionBrushTree:delete()
	ConstructionBrushTree:superClass().delete(self)
end

function ConstructionBrushTree:activate()
	ConstructionBrushTree:superClass().activate(self)
	self.cursor:setRotationEnabled(true)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	self.cursor:setShapeSize(1)
	self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
	self.cursor:setTerrainOnly(true)
	self:loadTree()
end

function ConstructionBrushTree:deactivate()
	self:unloadTree()
	self.cursor:setTerrainOnly(false)
	ConstructionBrushTree:superClass().deactivate(self)
end

function ConstructionBrushTree:setTree(type, stage)
	if not self.isActive then
		self.treeType = type
		self.treeStage = stage
	end
end

function ConstructionBrushTree:setParameters(treeType, treeStage)
	self:setTree(treeType, tonumber(treeStage))
end

function ConstructionBrushTree:update(dt)
	ConstructionBrushTree:superClass().update(self, dt)
	self:updateTreePosition()
end

function ConstructionBrushTree:updateTreePosition()
	if self.tree ~= nil then
		local x, y, z = self.cursor:getHitTerrainPosition()

		if self.cursor.isVisible then
			if x ~= nil then
				local rotY = self.cursor:getRotation()

				setWorldTranslation(self.tree, x, y, z)
				setRotation(self.tree, 0, rotY, 0)

				local err = self:verifyPlacement(x, y, z)

				if err ~= nil then
					local message = g_i18n:getText(ConstructionBrushTree.ERROR_MESSAGES[err] or ConstructionBrush.ERROR_MESSAGES[err])

					self.cursor:setErrorMessage(message)
				else
					self.cursor:setMessage(g_i18n:formatMoney(self:getPrice(), 0, true, true))
				end
			else
				self.cursor:setErrorMessage(g_i18n:getText("ui_construction_spaceAlreadyOccupied"))
			end
		end

		setVisibility(self.tree, self.cursor.isVisible)
	end
end

function ConstructionBrushTree:verifyPlacement(x, y, z)
	local err = self:verifyAccess(x, y, z)

	if err ~= nil then
		return err
	end

	local enoughMoney = self:getPrice() <= g_currentMission:getMoney()

	if not enoughMoney then
		return ConstructionBrushTree.ERROR.NOT_ENOUGH_MONEY
	end

	if not g_treePlantManager:canPlantTree() then
		return ConstructionBrushTree.ERROR.TOO_MANY_TREES
	end

	return nil
end

function ConstructionBrushTree:getPrice()
	return g_currentMission.economyManager:getBuyPrice(self.storeItem)
end

function ConstructionBrushTree:loadTree()
	if self.treeType == nil or self.treeStage == nil then
		Logging.error("Tree brush has no tree type or stage set")

		return
	end

	local treeDesc = g_treePlantManager:getTreeTypeDescFromName(self.treeType)

	if treeDesc == nil then
		Logging.error("Tree type %s does not exist", self.treeType)

		return
	end

	self.treeFilename = treeDesc.treeFilenames[self.treeStage]

	if self.treeFilename == nil then
		Logging.error("Tree type %s does not have stage %d", self.treeType, self.treeStage)

		return
	end

	self.treeGrowth = self.treeStage / #treeDesc.treeFilenames
	self.treeTypeIndex = treeDesc.index

	setSplitShapesLoadingFileId(-1)
	setSplitShapesNextFileId(true)

	local node, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(self.treeFilename, false, false)
	self.sharedLoadRequestId = sharedLoadRequestId

	self:onTreeLoaded(node, failedReason)
end

function ConstructionBrushTree:onTreeLoaded(node, failedReason)
	if node == nil or node == 0 then
		Logging.warning("Failed to load tree")

		return
	end

	if not self.isActive then
		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

			self.sharedLoadRequestId = nil
		end

		delete(node)

		return
	end

	link(getRootNode(), node)
	I3DUtil.setShaderParameterRec(node, "windSnowLeafScale", 0, 0, 1, 80)

	self.tree = node
end

function ConstructionBrushTree:unloadTree()
	if self.tree ~= nil then
		delete(self.tree)

		self.tree = nil

		if self.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

			self.sharedLoadRequestId = nil
		end

		self.treeFilename = nil
	end
end

function ConstructionBrushTree:onButtonPrimary()
	if self.tree == nil then
		return
	end

	local x, y, z = self.cursor:getHitTerrainPosition()

	if x ~= nil and self:verifyPlacement(x, y, z) == nil then
		local rx = 0
		local ry = self.cursor:getRotation()
		local rz = 0
		local growing = false

		if g_server ~= nil then
			g_treePlantManager:plantTree(self.treeTypeIndex, x, y, z, rx, ry, rz, self.treeGrowth, nil, growing)
			g_currentMission:addMoney(-self:getPrice(), g_currentMission.player.farmId, MoneyType.SHOP_PROPERTY_BUY, true)
		else
			g_client:getServerConnection():sendEvent(TreePlantEvent.new(self.treeTypeIndex, x, y, z, rx, ry, rz, self.treeGrowth, nil, growing, self:getPrice(), g_currentMission.player.farmId))
		end
	end
end

function ConstructionBrushTree:onButtonTertiary()
	self.cursor:setRotation(math.random() * 2 * math.pi)
end

function ConstructionBrushTree:getButtonPrimaryText()
	return "$l10n_input_CONSTRUCTION_PLACE"
end

function ConstructionBrushTree:getButtonTertiaryText()
	return "$l10n_input_CONSTRUCTION_RANDOM_ROTATE"
end
