SimpleState = {}
local SimpleState_mt = Class(SimpleState)

function SimpleState.new(id, owner, stateMachine, custom_mt)
	local self = {}

	setmetatable(self, custom_mt or SimpleState_mt)

	self.id = id
	self.owner = owner
	self.stateMachine = stateMachine

	return self
end

function SimpleState:delete()
end

function SimpleState:activate(parms)
end

function SimpleState:deactivate()
end

function SimpleState:update(dt)
end
