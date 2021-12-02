Watermill = {}
local Watermill_mt = Class(Watermill)

function Watermill:onCreate(id)
	g_currentMission:addUpdateable(Watermill.new(id))
end

function Watermill.new(name)
	local instance = {}

	setmetatable(instance, Watermill_mt)

	instance.wheelId = getChildAt(name, 0)

	return instance
end

function Watermill:delete()
end

function Watermill:update(dt)
	rotate(self.wheelId, -0.0005 * dt, 0, 0)
end
