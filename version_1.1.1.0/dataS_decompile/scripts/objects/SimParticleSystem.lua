SimParticleSystem = {}
local SimParticleSystem_mt = Class(SimParticleSystem)

function SimParticleSystem:onCreate(id)
	g_currentMission:addNonUpdateable(SimParticleSystem.new(id))
end

function SimParticleSystem.new(name)
	local self = {}

	setmetatable(self, SimParticleSystem_mt)

	self.id = name
	local particleSystem = nil

	if getHasClassId(self.id, ClassIds.SHAPE) then
		local geometry = getGeometry(self.id)

		if geometry ~= 0 and getHasClassId(geometry, ClassIds.PRECIPITATION) then
			particleSystem = geometry
		end
	end

	if particleSystem ~= nil then
		local lifespan = getParticleSystemLifespan(particleSystem)

		addParticleSystemSimulationTime(particleSystem, lifespan)
	end

	return self
end

function SimParticleSystem:delete()
end
