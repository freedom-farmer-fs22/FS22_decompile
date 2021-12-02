TrashBag = {}
local TrashBag_mt = Class(TrashBag)

function TrashBag.onCreate(id)
	g_currentMission:addNonUpdateable(TrashBag.new(id))
end

function TrashBag.new(id)
	local self = {}

	setmetatable(self, TrashBag_mt)

	self.id = id

	if math.random() > 0.5 then
		setVisibility(self.id, true)
	else
		setVisibility(self.id, false)
	end

	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)

	return self
end

function TrashBag:delete()
	g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
end

function TrashBag:onPeriodChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		if g_currentMission.environment.currentPeriod == 1 then
			setVisibility(self.id, false)
		elseif not getVisibility(self.id) and math.random() > 0.666 then
			setVisibility(self.id, true)
		end
	end
end
