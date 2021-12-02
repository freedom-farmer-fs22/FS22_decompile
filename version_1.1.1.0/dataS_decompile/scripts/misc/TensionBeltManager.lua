TensionBeltManager = {}
local TensionBeltManager_mt = Class(TensionBeltManager)

function TensionBeltManager.new(customMt)
	if customMt == nil then
		customMt = TensionBeltManager_mt
	end

	local self = {}

	setmetatable(self, customMt)
	self:initDataStructures()

	return self
end

function TensionBeltManager:initDataStructures()
	self.belts = {}
	self.defaultBeltData = nil
end

function TensionBeltManager:unloadMapData()
	self:initDataStructures()
end

function TensionBeltManager.onCreateTensionBelt(_, id)
	local self = g_tensionBeltManager
	local name = Utils.getNoNil(getUserAttribute(id, "name"), "default")
	local width = Utils.getNoNil(getUserAttribute(id, "width"), 0.15)
	local beltType = self:getType(name)

	if self.belts[beltType] ~= nil then
		print("Warning: Tension belt type '" .. name .. "' already exists!")

		return
	end

	local belt = {
		width = width
	}

	for i = 0, getNumOfChildren(id) - 1 do
		local node = getChildAt(id, i)

		if getUserAttribute(node, "isMaterial") then
			belt.material = {
				materialId = getMaterial(node, 0),
				uvScale = Utils.getNoNil(getUserAttribute(node, "uvScale"), 0.1)
			}
		elseif getUserAttribute(node, "isDummyMaterial") then
			belt.dummyMaterial = {
				materialId = getMaterial(node, 0),
				uvScale = Utils.getNoNil(getUserAttribute(node, "uvScale"), 0.1)
			}
		elseif getUserAttribute(node, "isHook") then
			if belt.hook ~= nil then
				local _, _, z = getTranslation(getChildAt(node, 0))
				belt.hook2 = {
					node = node,
					sizeRatio = z
				}
			else
				local _, _, z = getTranslation(getChildAt(node, 0))
				belt.hook = {
					node = node,
					sizeRatio = z
				}
			end
		elseif getUserAttribute(node, "isRatchet") then
			local _, _, z = getTranslation(getChildAt(node, 0))
			belt.ratchet = {
				node = node,
				sizeRatio = z
			}
		end
	end

	if belt.material == nil then
		print("Warning: No material defined for tension belt type '" .. name .. "'!")

		return
	end

	if belt.dummyMaterial == nil then
		print("Warning: No material defined for tension belt type '" .. name .. "'!")

		return
	end

	self.belts[beltType] = belt

	if self.defaultBeltData == nil then
		self.defaultBeltData = belt
	end
end

function TensionBeltManager:getType(beltName)
	return "BELT_TYPE_" .. string.upper(beltName)
end

function TensionBeltManager:getBeltData(beltName)
	if beltName == nil then
		return self.defaultBeltData
	end

	local beltType = self:getType(beltName)
	local beltData = self.belts[beltType]

	if beltData == nil then
		return self.defaultBeltData
	end

	return beltData
end

g_tensionBeltManager = TensionBeltManager.new()
