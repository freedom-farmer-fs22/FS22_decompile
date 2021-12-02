Ship = {}
local Ship_mt = Class(Ship)

function Ship:onCreate(id)
	g_currentMission:addUpdateable(Ship.new(id))
end

function Ship.new(id)
	local instance = {}

	setmetatable(instance, Ship_mt)

	instance.nurbsId = getChildAt(id, 0)
	instance.shipIds = {}

	table.insert(instance.shipIds, getChildAt(id, 1))

	instance.times = {}

	table.insert(instance.times, 0)

	local length = getSplineLength(instance.nurbsId)
	instance.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
	local numShips = Utils.getNoNil(getUserAttribute(id, "numShips"), 1)

	for i = 2, numShips do
		local shipId = clone(instance.shipIds[1], false, true)

		link(id, shipId)
		table.insert(instance.shipIds, shipId)
		table.insert(instance.times, 1 / numShips * (i - 1))
	end

	if length ~= 0 then
		instance.timeScale = instance.timeScale / length
	end

	instance.initCount = 0

	return instance
end

function Ship:delete()
end

function Ship:update(dt)
	if self.initCount > 0 then
		for i = 1, table.getn(self.shipIds) do
			self.times[i] = self.times[i] - 0.001 * dt * self.timeScale

			if self.times[i] < 0 then
				self.times[i] = self.times[i] + 1
			end

			if self.times[i] > 1 then
				self.times[i] = self.times[i] - 1
			end

			local x, y, z = getSplinePosition(self.nurbsId, self.times[i])
			local rx, ry, rz = getSplineOrientation(self.nurbsId, self.times[i], 0, -1, 0)

			setTranslation(self.shipIds[i], x, y, z)
			setRotation(self.shipIds[i], rx, ry, rz)
		end
	else
		self.initCount = self.initCount + 1
	end
end
