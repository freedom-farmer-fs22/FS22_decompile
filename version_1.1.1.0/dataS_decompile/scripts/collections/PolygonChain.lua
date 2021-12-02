PolygonChain = {}
local PolygonChain_mt = Class(PolygonChain)

function PolygonChain.new(customMt)
	local self = {}

	setmetatable(self, customMt or PolygonChain_mt)

	self.controlNodes = {}

	return self
end

function PolygonChain:delete()
	self.controlNodes = nil
end

function PolygonChain:addControlNode(node)
	table.insert(self.controlNodes, node)
end

function PolygonChain:drawDebug(r, g, b)
	local startX, startY, startZ = nil

	for _, node in ipairs(self.controlNodes) do
		local endX, endY, endZ = getWorldTranslation(node)

		DebugUtil.drawDebugNode(node, nil, )

		if startX ~= nil then
			drawDebugLine(startX, startY, startZ, r, g, b, endX, endY, endZ, r, g, b)
		end

		startZ = endZ
		startY = endY
		startX = endX
	end
end

function PolygonChain:getClosestPoint(x, y, z)
	local distance = math.huge
	local tX, tY, tZ, startX, startY, startZ = nil

	for _, node in ipairs(self.controlNodes) do
		local endX, endY, endZ = getWorldTranslation(node)

		if startX ~= nil then
			local cpX, cpY, cpZ = MathUtil.getClosestPointOnLineSegment(startX, startY, startZ, endX, endY, endZ, x, y, z)
			local newDistance = MathUtil.vector3Length(x - cpX, y - cpY, z - cpZ)

			if newDistance < distance then
				tZ = cpZ
				tY = cpY
				tX = cpX
				distance = newDistance
			end
		end

		startZ = endZ
		startY = endY
		startX = endX
	end

	return tX, tY, tZ
end
