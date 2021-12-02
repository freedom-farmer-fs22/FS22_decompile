DebugFlag = {}
local DebugFlag_mt = Class(DebugFlag)

function DebugFlag.new(r, g, b, customMt)
	local self = setmetatable({}, customMt or DebugFlag_mt)
	self.z = 0
	self.y = 0
	self.x = 0
	self.dirZ = 1
	self.dirX = 0
	self.r = r or 0
	self.g = g or 0
	self.b = b or 0
	self.height = 4
	self.flagHeight = 0.7
	self.flagLength = 1
	self.numSectionsY = 4
	self.numSectionsZ = 6

	return self
end

function DebugFlag:delete()
end

function DebugFlag:update(dt)
end

function DebugFlag:setColor(r, g, b)
	self.r = r or self.r
	self.g = g or self.g
	self.b = b or self.b
end

function DebugFlag:draw()
	local x = self.x
	local y = self.y
	local z = self.z
	local tx = x + self.dirX * self.flagLength
	local tz = z + self.dirZ * self.flagLength
	local r = self.r
	local g = self.g
	local b = self.b

	drawDebugLine(x, y, z, r, g, b, x, y + self.height, z, r, g, b)

	local posYStart = y + self.height - self.flagHeight
	local posYEnd = y + self.height

	for i = 1, self.numSectionsZ do
		local offset = self.flagLength * i / self.numSectionsZ
		local lx = x + self.dirX * offset
		local lz = z + self.dirZ * offset

		drawDebugLine(lx, posYStart, lz, r, g, b, lx, posYEnd, lz, r, g, b)
	end

	for i = 0, self.numSectionsY do
		local offset = self.flagHeight * i / self.numSectionsY
		local ly = posYStart + offset

		drawDebugLine(x, ly, z, r, g, b, tx, ly, tz, r, g, b)
	end
end

function DebugFlag:create(x, y, z, dirX, dirZ)
	self.z = z
	self.y = y
	self.x = x
	self.dirZ = dirZ
	self.dirX = dirX
end
