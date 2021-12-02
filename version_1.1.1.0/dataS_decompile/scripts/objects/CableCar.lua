CableCar = {}
local CableCar_mt = Class(CableCar)

function CableCar:onCreate(id)
	g_currentMission:addUpdateable(CableCar.new(id))
end

function CableCar.new(id)
	local instance = {}

	setmetatable(instance, CableCar_mt)

	instance.nurbsId = getChildAt(id, 0)
	instance.cableCarIds = {}

	table.insert(instance.cableCarIds, getChildAt(id, 1))

	instance.times = {}

	table.insert(instance.times, 0)

	instance.truckIds = {}

	table.insert(instance.truckIds, getChildAt(getChildAt(id, 1), 0))

	local length = getSplineLength(instance.nurbsId)
	instance.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
	local numCableCars = Utils.getNoNil(getUserAttribute(id, "numCableCars"), 1)

	for i = 2, numCableCars do
		local cableCarId = clone(instance.cableCarIds[1], false, true)

		link(id, cableCarId)
		table.insert(instance.cableCarIds, cableCarId)
		table.insert(instance.times, 1 / numCableCars * (i - 1))
		table.insert(instance.truckIds, getChildAt(cableCarId, 0))
	end

	if length ~= 0 then
		instance.timeScale = instance.timeScale / length
	end

	return instance
end

function CableCar:delete()
end

function CableCar:update(dt)
	for i = 1, table.getn(self.cableCarIds) do
		self.times[i] = self.times[i] - 0.001 * dt * self.timeScale

		if self.times[i] < 0 then
			self.times[i] = self.times[i] + 1
		end

		if self.times[i] > 1 then
			self.times[i] = self.times[i] - 1
		end

		local x, y, z = getSplinePosition(self.nurbsId, self.times[i])
		local dx, dy, dz = getSplineDirection(self.nurbsId, self.times[i])

		setTranslation(self.cableCarIds[i], x, y, z)
		setDirection(self.cableCarIds[i], dx, 0, dz, 0, 1, 0)

		local _, dy1, dz1 = worldDirectionToLocal(self.cableCarIds[i], dx, dy, dz, 0, 1, 0)

		setDirection(self.truckIds[i], 0, dy1, dz1, 0, 1, 0)
	end
end
