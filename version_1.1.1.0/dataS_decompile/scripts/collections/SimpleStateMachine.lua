SimpleStateMachine = {}
local SimpleStateMachine_mt = Class(SimpleStateMachine)

function SimpleStateMachine.new(custom_mt)
	local self = {}

	setmetatable(self, custom_mt or SimpleStateMachine_mt)

	self.currentState = nil
	self.states = {}

	return self
end

function SimpleStateMachine:delete()
	self:reset()
end

function SimpleStateMachine:addState(stateId, state)
	self.states[stateId] = state
end

function SimpleStateMachine:removeState(stateId)
	if self.currentState == self.states[stateId] then
		self.currentState = nil
	end

	self.states[stateId] = nil
end

function SimpleStateMachine:reset()
	self.states = {}
	self.currentState = nil
end

function SimpleStateMachine:changeState(stateId, parms)
	if self.states[stateId] ~= nil then
		if self.currentState ~= nil then
			self.currentState:deactivate()
		end

		self.currentState = self.states[stateId]

		self.currentState:activate(parms)
	end
end

function SimpleStateMachine:update(dt)
	if self.currentState ~= nil then
		self.currentState:update(dt)
	end
end
