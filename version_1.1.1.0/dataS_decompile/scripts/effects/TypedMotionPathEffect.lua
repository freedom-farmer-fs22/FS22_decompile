TypedMotionPathEffect = {}
local TypedMotionPathEffect_mt = Class(TypedMotionPathEffect, MotionPathEffect)

function TypedMotionPathEffect.new(customMt)
	local self = MotionPathEffect.new(customMt or TypedMotionPathEffect_mt)
	self.fruitTypeIndex = FruitType.UNKNOWN
	self.fillTypeIndex = FillType.UNKNOWN
	self.growthState = 0

	return self
end

function TypedMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not TypedMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.meshType = xmlFile:getValue(key .. "#meshType")
	self.materialType = xmlFile:getValue(key .. "#materialType")
	local forcedFillTypeName = xmlFile:getValue(key .. "#forcedFillType")
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(forcedFillTypeName)

	if fillTypeIndex ~= nil then
		self.forcedFillType = fillTypeIndex
		self.fillTypeIndex = fillTypeIndex
	end

	local forcedFruitTypeName = xmlFile:getValue(key .. "#forcedFruitType")
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(forcedFruitTypeName)

	if fruitTypeDesc ~= nil then
		self.forcedFruitType = fruitTypeDesc.index
		self.fruitTypeIndex = fruitTypeDesc.index
	end

	self.forcedGrowthState = xmlFile:getValue(key .. "#forcedGrowthState")

	if self.forcedGrowthState ~= nil then
		self.growthState = self.forcedGrowthState
	end

	local requiredFillTypeName = xmlFile:getValue(key .. "#requiredFillType")
	fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(requiredFillTypeName)

	if fillTypeIndex ~= nil then
		self.requiredFillType = fillTypeIndex
	end

	local requiredFruitTypeName = xmlFile:getValue(key .. "#requiredFruitType")
	fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(requiredFruitTypeName)

	if fruitTypeDesc ~= nil then
		self.requiredFruitType = fruitTypeDesc.index
	end

	self.requiredGrowthState = xmlFile:getValue(key .. "#requiredGrowthState")

	return true
end

function TypedMotionPathEffect:setFruitType(fruitTypeIndex, growthState)
	if fruitTypeIndex ~= self.fruitTypeIndex or growthState ~= self.growthState then
		local changed = false

		if self.forcedFruitType == nil and (self.requiredFruitType == nil or self.requiredFruitType == fruitTypeIndex) then
			self.fruitTypeIndex = fruitTypeIndex
			changed = true
		end

		if self.forcedGrowthState == nil and (self.requiredGrowthState == nil or self.requiredGrowthState == growthState) then
			self.growthState = growthState
			changed = true
		end

		if changed then
			self:loadSharedMotionPathEffect()
		end
	end
end

function TypedMotionPathEffect:setFillType(fillTypeIndex, growthState)
	if fillTypeIndex ~= self.fillTypeIndex or growthState ~= self.growthState then
		local changed = false

		if self.forcedFillType == nil and (self.requiredFillType == nil or self.requiredFillType == fillTypeIndex) then
			self.fillTypeIndex = fillTypeIndex
			changed = true
		end

		if growthState ~= nil and self.forcedGrowthState == nil and (self.requiredGrowthState == nil or self.requiredGrowthState == growthState) then
			self.growthState = growthState
			changed = true
		end

		if changed then
			self:loadSharedMotionPathEffect()
		end
	end
end

function TypedMotionPathEffect:getIsSharedEffectMatching(sharedEffect, alternativeCheck)
	if not TypedMotionPathEffect:superClass().getIsSharedEffectMatching(self, sharedEffect, alternativeCheck) then
		return false
	end

	if not self:getIsEffectSpecificDataMatching(sharedEffect, alternativeCheck) then
		return false
	end

	return true
end

function TypedMotionPathEffect:getIsEffectMeshMatching(effectMesh, alternativeCheck)
	if not TypedMotionPathEffect:superClass().getIsEffectMeshMatching(self, effectMesh, alternativeCheck) then
		return false
	end

	if effectMesh.meshType ~= self.meshType then
		return false
	end

	if not self:getIsEffectSpecificDataMatching(effectMesh, alternativeCheck) then
		return false
	end

	return true
end

function TypedMotionPathEffect:getIsEffectMaterialMatching(effectMaterial, alternativeCheck)
	if not TypedMotionPathEffect:superClass().getIsEffectMaterialMatching(self, effectMaterial, alternativeCheck) then
		return false
	end

	if effectMaterial.materialType ~= self.materialType then
		return false
	end

	if not self:getIsEffectSpecificDataMatching(effectMaterial, alternativeCheck) then
		return false
	end

	return true
end

function TypedMotionPathEffect:getEffectMatchingString()
	local str = TypedMotionPathEffect:superClass().getEffectMatchingString(self)

	if self.materialType ~= nil then
		str = str .. string.format(", materialType '%s'", self.materialType)
	end

	if self.meshType ~= nil then
		str = str .. string.format(", meshType '%s'", self.meshType)
	end

	if self.fruitTypeIndex ~= nil then
		str = str .. string.format(", fruitType '%s'", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
	end

	if self.growthState ~= nil then
		str = str .. string.format(", growthState '%s'", self.growthState)
	end

	if self.fillTypeIndex ~= nil then
		str = str .. string.format(", fillType '%s'", g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex))
	end

	return str
end

function TypedMotionPathEffect:getIsEffectSpecificDataMatching(target, alternativeCheck)
	if target.fruitTypes ~= nil then
		local found = false

		for i = 1, #target.fruitTypes do
			if target.fruitTypes[i] == self.fruitTypeIndex then
				found = true
			end
		end

		if not found then
			return false
		end
	end

	if target.growthStates ~= nil then
		local foundState = false

		for i = 1, #target.growthStates do
			if target.growthStates[i] == self.growthState then
				foundState = true
			end
		end

		if not foundState then
			return false
		end
	elseif not alternativeCheck then
		return false
	end

	if target.fillTypes ~= nil then
		local found = false

		for i = 1, #target.fillTypes do
			if target.fillTypes[i] == self.fillTypeIndex then
				found = true
			end
		end

		if not found then
			return false
		end
	end

	return true
end

function TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	MotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(effectMaterial, xmlFile, key)

	effectMaterial.materialType = xmlFile:getValue(key .. "#materialType")
end

function TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	MotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(effectMesh, xmlFile, key)

	effectMesh.meshType = xmlFile:getValue(key .. "#meshType")
end

function TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	MotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectSpecificDataFromXML(motionPathEffect, xmlFile, key)
end

function TypedMotionPathEffect.loadEffectSpecificDataFromXML(target, xmlFile, key)
	local fruitTypeNames = xmlFile:getValue(key .. "#fruitTypes")

	if fruitTypeNames ~= nil then
		target.fruitTypes = {}
		local fruitTypes = fruitTypeNames:split(" ")

		for i = 1, #fruitTypes do
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(fruitTypes[i])

			if fruitTypeDesc ~= nil then
				table.insert(target.fruitTypes, fruitTypeDesc.index)
			end
		end
	end

	target.growthStates = xmlFile:getValue(key .. "#growthStates", nil, true)

	if #target.growthStates == 0 then
		target.growthStates = nil
	end

	local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")

	if fillTypeNames ~= nil then
		target.fillTypes = {}
		local fillTypes = fillTypeNames:split(" ")

		for i = 1, #fillTypes do
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypes[i])

			if fillTypeIndex ~= FillType.UNKNOWN then
				table.insert(target.fillTypes, fillTypeIndex)
			end
		end
	end
end

function TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
end

function TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#meshType", "(TypedMotionPathEffect) Mesh Type")
end

function TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(TypedMotionPathEffect) Material Type")
end

function TypedMotionPathEffect.registerEffectSpecificDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#fruitTypes", "(TypedMotionPathEffect) Fruit Type Names")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#growthStates", "(TypedMotionPathEffect) All harvesting states of fruit type")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "(TypedMotionPathEffect) Fill Type Names")
end

function TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	MotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#meshType", "(TypedMotionPathEffect) Mesh Type")
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(TypedMotionPathEffect) Material Type")
	schema:register(XMLValueType.STRING, basePath .. "#forcedFillType", "(TypedMotionPathEffect) Forced fill type that is always applied")
	schema:register(XMLValueType.STRING, basePath .. "#forcedFruitType", "(TypedMotionPathEffect) Forced fruit type that is always applied")
	schema:register(XMLValueType.INT, basePath .. "#forcedGrowthState", "(TypedMotionPathEffect) Forced growth state that is always applied")
	schema:register(XMLValueType.STRING, basePath .. "#requiredFillType", "(TypedMotionPathEffect) Effect will only be used for this fill type")
	schema:register(XMLValueType.STRING, basePath .. "#requiredFruitType", "(TypedMotionPathEffect) Effect will only be used for this fruit type")
	schema:register(XMLValueType.INT, basePath .. "#requiredGrowthState", "(TypedMotionPathEffect) Effect will only be used for this growth state")
end
