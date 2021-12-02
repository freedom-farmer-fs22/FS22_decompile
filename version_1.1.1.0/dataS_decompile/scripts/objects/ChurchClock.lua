ChurchClock = {}
local ChurchClock_mt = Class(ChurchClock)

function ChurchClock:onCreate(id)
	g_currentMission:addNonUpdateable(ChurchClock.new(id))
end

function ChurchClock.new(id)
	local self = setmetatable({}, ChurchClock_mt)
	self.clocks = {}

	for i = 0, getNumOfChildren(id) - 1 do
		local node = getChildAt(id, i)

		if node ~= nil then
			local shortHand = getChildAt(node, 0)
			local longHand = getChildAt(node, 1)

			if shortHand ~= nil and longHand ~= nil then
				table.insert(self.clocks, {
					shortHand = shortHand,
					longHand = longHand
				})
			end
		end
	end

	self.hasClocks = #self.clocks > 0

	if self.hasClocks then
		g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
	end

	return self
end

function ChurchClock:delete()
	g_messageCenter:unsubscribeAll(self)
end

function ChurchClock:minuteChanged()
	if self.hasClocks then
		local shortHandRot = 2 * math.pi * g_currentMission.environment.dayTime / 43200000
		local longHandRot = 2 * math.pi * g_currentMission.environment.dayTime / 3600000

		for _, c in pairs(self.clocks) do
			setRotation(c.shortHand, 0, 0, -shortHandRot)
			setRotation(c.longHand, 0, 0, -longHandRot)
		end
	end
end
