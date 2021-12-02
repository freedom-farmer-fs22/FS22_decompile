ElkTrigger = {}
local ElkTrigger_mt = Class(ElkTrigger)

function ElkTrigger:onCreate(id)
	g_currentMission:addUpdateable(ElkTrigger.new(id))
end

function ElkTrigger.new(nodeId)
	local self = {}

	setmetatable(self, ElkTrigger_mt)

	self.nodeId = nodeId
	self.triggerId = getChildAt(nodeId, 0)

	addTrigger(self.triggerId, "triggerCallback", self)

	self.motherElkId = getChildAt(nodeId, 1)
	self.splinesNode = getChildAt(nodeId, 2)
	self.inProgress = false
	self.time = 0
	self.duration1 = 10000
	self.duration2 = 14000
	self.nextTriggerTime = 0
	self.elkSound = createSample("elkSound")

	loadSample(self.elkSound, "data/maps/sounds/elk.wav", false)

	self.playerInRange = false
	self.elks = {}

	for i = 1, getNumOfChildren(self.splinesNode) do
		local splineId = getChildAt(self.splinesNode, i - 1)
		local elkId1 = clone(self.motherElkId, true)
		local elkId2 = clone(self.motherElkId, true)
		local elk = {
			elkId1 = elkId1,
			elkId2 = elkId2,
			splineId = splineId
		}

		table.insert(self.elks, elk)
	end

	return self
end

function ElkTrigger:delete()
	removeTrigger(self.triggerId)
	delete(self.elkSound)
end

function ElkTrigger:update(dt)
	if not self.inProgress then
		if self.playerInRange and g_currentMission.environment.dayTime > 43200000 and g_currentMission.environment.dayTime < 43260000 and self.nextTriggerTime < g_currentMission.time then
			self.inProgress = true
			self.splinePos = 0
			self.time = 0

			for _, elk in pairs(self.elks) do
				setTranslation(elk.elkId1, 0, 0, 0)
				setTranslation(elk.elkId2, 0, 0, 0)
				setVisibility(elk.elkId1, true)
				setVisibility(elk.elkId2, true)
			end

			playSample(self.elkSound, 1, 1, 0, 0, 0)
		end
	else
		self.time = self.time + dt

		for _, elk in pairs(self.elks) do
			local splinePos = math.min(self.time / self.duration1, 1)
			local x, y, z = getSplinePosition(elk.splineId, splinePos)
			local rx, ry, rz = getSplineOrientation(elk.splineId, splinePos, 0, -1, 0)

			setTranslation(elk.elkId1, x, y, z)
			setRotation(elk.elkId1, rx, ry, rz)

			splinePos = math.min(self.time / self.duration2, 1)
			x, y, z = getSplinePosition(elk.splineId, splinePos)
			rx, ry, rz = getSplineOrientation(elk.splineId, splinePos, 0, -1, 0)

			setTranslation(elk.elkId2, x, y, z)
			setRotation(elk.elkId2, rx, ry, rz)
		end

		if self.duration2 < self.time then
			self.inProgress = false

			for _, elk in pairs(self.elks) do
				setTranslation(elk.elkId1, 0, 0, 0)
				setTranslation(elk.elkId2, 0, 0, 0)
				setVisibility(elk.elkId1, false)
				setVisibility(elk.elkId2, false)

				self.nextTriggerTime = g_currentMission.time + 10000
			end
		end
	end
end

function ElkTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		if g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			self.playerInRange = true
		end
	elseif onLeave and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		self.playerInRange = false
	end
end
