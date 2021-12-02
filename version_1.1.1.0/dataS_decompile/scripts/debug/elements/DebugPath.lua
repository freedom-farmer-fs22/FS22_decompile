DebugPath = {}
local DebugPath_mt = Class(DebugPath)

function DebugPath.new(color, alignToGround, autoAddOffset, solid, customMt)
	local self = setmetatable({}, customMt or DebugPath_mt)
	self.color = color or {
		1,
		1,
		1
	}
	self.points = {}
	self.isVisible = true
	self.alignToGround = Utils.getNoNil(alignToGround, false)
	self.autoAddOffset = autoAddOffset
	self.solid = Utils.getNoNil(solid, true)

	return self
end

function DebugPath:delete()
end

function DebugPath:update(dt)
end

function DebugPath:draw(forcedY)
	if self.isVisible then
		local r, g, b = unpack(self.color)

		for k, p in ipairs(self.points) do
			local np = self.points[k + 1]

			if np ~= nil then
				local px = p[1]
				local py = p[2]
				local pz = p[3]
				local npx = np[1]
				local npy = np[2]
				local npz = np[3]

				if self.alignToGround then
					py = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, px, 0, pz) + 0.025
					npy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, npx, 0, npz) + 0.025
				end

				drawDebugLine(px, forcedY or py, pz, r, g, b, npx, forcedY or npy, npz, r, g, b, self.solid)
			end
		end
	end
end

function DebugPath:addPoint(x, y, z)
	local addPoint = true

	if self.autoAddOffset ~= nil then
		local p = self.points[#self.points]

		if p ~= nil then
			local distance = MathUtil.vector3Length(p[1] - x, p[2] - y, p[3] - z)

			if distance < self.autoAddOffset then
				addPoint = false
			end
		end
	end

	if addPoint then
		table.insert(self.points, {
			x,
			y,
			z
		})
	end
end

function DebugPath:setVisible(isVisible)
	self.isVisible = isVisible
end

function DebugPath:clear()
	self.points = {}
end

function DebugPath:setColor(r, g, b)
	self.color[1] = r or self.color[1]
	self.color[2] = g or self.color[2]
	self.color[3] = b or self.color[3]
end
