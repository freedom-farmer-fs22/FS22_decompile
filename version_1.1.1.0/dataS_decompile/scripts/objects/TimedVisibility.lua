TimedVisibility = {}
local TimedVisibility_mt = Class(TimedVisibility)

function TimedVisibility.onCreate(id)
	g_currentMission:addNonUpdateable(TimedVisibility.new(id))
end

function TimedVisibility.new(id)
	local self = {}

	setmetatable(self, TimedVisibility_mt)

	self.id = id
	self.startHour = Utils.getNoNil(getUserAttribute(self.id, "startHour"), 0)
	self.endHour = Utils.getNoNil(getUserAttribute(self.id, "endHour"), 24)
	self.wrap = self.endHour < self.startHour

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		self:hourChanged()
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end

	return self
end

function TimedVisibility:delete()
	g_messageCenter:unsubscribeAll(self)
end

function TimedVisibility:hourChanged()
	local currentHour = g_currentMission.environment.currentHour

	if self.wrap then
		setVisibility(self.id, self.startHour <= currentHour or currentHour < self.endHour)
	else
		setVisibility(self.id, self.startHour <= currentHour and currentHour < self.endHour)
	end
end
